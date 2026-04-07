import Foundation

struct ActivationMetricsSummary: Codable, Sendable {
    let firstSessionAt: Date?
    let lastSessionAt: Date?
    let sessionCount: Int
    let activeDays: Int
    let favoriteSaveCount: Int
    let stopDetailOpenCount: Int
    let recentSessionCount7Days: Int
    let recentFavoriteSaveCount7Days: Int
    let recentStopDetailOpenCount7Days: Int

    var hasRepeatUsage: Bool {
        activeDays >= 2 || sessionCount >= 2
    }
}

final class ActivationMetricsService: @unchecked Sendable {
    static let shared = ActivationMetricsService()

    private struct EventBucket: Codable, Sendable {
        let dayKey: String
        var sessionCount: Int
        var favoriteSaveCount: Int
        var stopDetailOpenCount: Int
    }

    private struct StoredMetrics: Codable, Sendable {
        var firstSessionAt: Date?
        var lastSessionAt: Date?
        var lastSessionRecordAt: Date?
        var buckets: [EventBucket]
    }

    private static let maxBucketCount = 35
    private static let minimumSessionGap: TimeInterval = 20 * 60
    private static let fileURL: URL = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "activation_metrics.json")
    }()

    private let calendar: Calendar
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.dautov.berlintransportmap.activation-metrics", qos: .utility)
    private var storage: StoredMetrics

    init(calendar: Calendar = .current, fileURL: URL? = nil, loadExisting: Bool = true) {
        self.calendar = calendar
        let resolvedFileURL = fileURL ?? Self.fileURL
        self.fileURL = resolvedFileURL
        self.storage = loadExisting ? Self.loadStoredMetrics(with: decoder, from: resolvedFileURL) : StoredMetrics(firstSessionAt: nil, lastSessionAt: nil, lastSessionRecordAt: nil, buckets: [])
    }

    func recordSession(at date: Date = .now) {
        queue.sync {
            if let lastSessionRecordAt = storage.lastSessionRecordAt,
               date.timeIntervalSince(lastSessionRecordAt) < Self.minimumSessionGap {
                storage.lastSessionAt = max(lastSessionRecordAt, date)
                persist()
                return
            }

            if storage.firstSessionAt == nil {
                storage.firstSessionAt = date
            }
            storage.lastSessionAt = date
            storage.lastSessionRecordAt = date
            mutateBucket(for: date) { bucket in
                bucket.sessionCount += 1
            }
            persist()
        }
    }

    func recordFavoriteSave(at date: Date = .now) {
        queue.sync {
            mutateBucket(for: date) { bucket in
                bucket.favoriteSaveCount += 1
            }
            persist()
        }
    }

    func recordStopDetailOpen(at date: Date = .now) {
        queue.sync {
            mutateBucket(for: date) { bucket in
                bucket.stopDetailOpenCount += 1
            }
            persist()
        }
    }

    func summary(referenceDate: Date = .now) -> ActivationMetricsSummary {
        queue.sync {
            let recentDayKeys = Set(dayKeys(endingAt: referenceDate, days: 7))
            let buckets = storage.buckets

            return ActivationMetricsSummary(
                firstSessionAt: storage.firstSessionAt,
                lastSessionAt: storage.lastSessionAt,
                sessionCount: buckets.reduce(0) { $0 + $1.sessionCount },
                activeDays: buckets.filter { $0.sessionCount > 0 }.count,
                favoriteSaveCount: buckets.reduce(0) { $0 + $1.favoriteSaveCount },
                stopDetailOpenCount: buckets.reduce(0) { $0 + $1.stopDetailOpenCount },
                recentSessionCount7Days: buckets
                    .filter { recentDayKeys.contains($0.dayKey) }
                    .reduce(0) { $0 + $1.sessionCount },
                recentFavoriteSaveCount7Days: buckets
                    .filter { recentDayKeys.contains($0.dayKey) }
                    .reduce(0) { $0 + $1.favoriteSaveCount },
                recentStopDetailOpenCount7Days: buckets
                    .filter { recentDayKeys.contains($0.dayKey) }
                    .reduce(0) { $0 + $1.stopDetailOpenCount }
            )
        }
    }

    func exportSummaryData(referenceDate: Date = .now) -> Data? {
        try? encoder.encode(summary(referenceDate: referenceDate))
    }

    func reset() {
        queue.sync {
            storage = StoredMetrics(firstSessionAt: nil, lastSessionAt: nil, lastSessionRecordAt: nil, buckets: [])
            persist()
        }
    }

    private func mutateBucket(for date: Date, update: (inout EventBucket) -> Void) {
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        if let index = storage.buckets.firstIndex(where: { $0.dayKey == dayKey }) {
            update(&storage.buckets[index])
        } else {
            var bucket = EventBucket(dayKey: dayKey, sessionCount: 0, favoriteSaveCount: 0, stopDetailOpenCount: 0)
            update(&bucket)
            storage.buckets.append(bucket)
            storage.buckets.sort { $0.dayKey < $1.dayKey }
        }

        if storage.buckets.count > Self.maxBucketCount {
            storage.buckets.removeFirst(storage.buckets.count - Self.maxBucketCount)
        }
    }

    private func dayKeys(endingAt referenceDate: Date, days: Int) -> [String] {
        guard days > 0 else { return [] }

        return (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: referenceDate).map {
                Self.dayKey(for: $0, calendar: calendar)
            }
        }
    }

    private func persist() {
        guard let encoded = try? encoder.encode(storage) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }

    private static func loadStoredMetrics(with decoder: JSONDecoder, from fileURL: URL) -> StoredMetrics {
        guard let data = try? Data(contentsOf: fileURL),
              let metrics = try? decoder.decode(StoredMetrics.self, from: data) else {
            return StoredMetrics(firstSessionAt: nil, lastSessionAt: nil, lastSessionRecordAt: nil, buckets: [])
        }

        return metrics
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}