import Foundation

struct HistoricalData: Codable, Identifiable {
    let id: UUID
    let stopId: String
    let vehicleId: String
    let lineName: String
    let dayOfWeek: Int // 1-7 (Sunday = 1)
    let hourOfDay: Int // 0-23
    let actualArrivalTime: Date
    let scheduledArrivalTime: Date?
    let delayMinutes: Int
    
    init(stopId: String, vehicleId: String, lineName: String, dayOfWeek: Int, hourOfDay: Int, actualArrivalTime: Date, scheduledArrivalTime: Date?, delayMinutes: Int) {
        self.id = UUID()
        self.stopId = stopId
        self.vehicleId = vehicleId
        self.lineName = lineName
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
        self.actualArrivalTime = actualArrivalTime
        self.scheduledArrivalTime = scheduledArrivalTime
        self.delayMinutes = delayMinutes
    }
    
    // Create from current vehicle arrival
    init?(from vehicle: Vehicle, at stop: TransportStop, scheduledTime: Date?) {
        guard let currentLocation = vehicle.currentLocation else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let delayMinutes = scheduledTime != nil ? Int(now.timeIntervalSince(scheduledTime!) / 60) : 0
        
        self.init(
            stopId: stop.id,
            vehicleId: vehicle.tripId,
            lineName: vehicle.line?.displayName ?? "?",
            dayOfWeek: calendar.component(.weekday, from: now),
            hourOfDay: calendar.component(.hour, from: now),
            actualArrivalTime: now,
            scheduledArrivalTime: scheduledTime,
            delayMinutes: delayMinutes
        )
    }
}

// Storage manager for historical data — keeps an in-memory cache so that
// repeated reads don't re-decode the full JSON from disk every time.
class HistoricalDataStorage {
    private let maxEntries = 2000 // Reduced from 10k — older entries are low-value

    // MARK: - File-backed storage (avoids UserDefaults plist overhead)

    private static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "historicalTransportData.json")
    }()

    // In-memory cache — loaded lazily once, then kept in sync.
    private var cache: [HistoricalData]?
    private var pendingWrites = 0
    private let writeBatchThreshold = 5 // Flush to disk every N saves
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Migrate old UserDefaults data (one-time)

    private let migrationKey = "historicalData_migrated_v1"

    private func migrateFromUserDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        UserDefaults.standard.set(true, forKey: migrationKey)

        guard let data = UserDefaults.standard.data(forKey: "historicalTransportData"),
              let decoded = try? decoder.decode([HistoricalData].self, from: data) else { return }

        cache = Array(decoded.suffix(maxEntries))
        flushToDisk()
        UserDefaults.standard.removeObject(forKey: "historicalTransportData")
    }

    // MARK: - Public API

    func save(_ data: HistoricalData) {
        loadCacheIfNeeded()
        cache?.append(data)

        // Trim if over limit
        if let count = cache?.count, count > maxEntries {
            cache = Array(cache!.suffix(maxEntries))
        }

        pendingWrites += 1
        if pendingWrites >= writeBatchThreshold {
            flushToDisk()
        }
    }

    func load() -> [HistoricalData] {
        loadCacheIfNeeded()
        return cache ?? []
    }

    func load(for stopId: String, lineName: String, dayOfWeek: Int, hourOfDay: Int) -> [HistoricalData] {
        loadCacheIfNeeded()
        return (cache ?? []).filter {
            $0.stopId == stopId &&
            $0.lineName == lineName &&
            $0.dayOfWeek == dayOfWeek &&
            abs($0.hourOfDay - hourOfDay) <= 1
        }
    }

    // MARK: - Private

    private func loadCacheIfNeeded() {
        guard cache == nil else { return }
        migrateFromUserDefaultsIfNeeded()
        guard cache == nil else { return } // migration may have populated it

        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? decoder.decode([HistoricalData].self, from: data) else {
            cache = []
            return
        }
        cache = decoded
    }

    private func flushToDisk() {
        pendingWrites = 0
        guard let cache else { return }
        guard let encoded = try? encoder.encode(cache) else { return }
        try? encoded.write(to: Self.fileURL, options: .atomic)
    }
}