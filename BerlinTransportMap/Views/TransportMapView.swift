import StoreKit
import SwiftUI
import MapKit

enum DataSource {
    case network  // just successfully fetched
    case stale    // last in-memory positions; next fetch in progress or errored
}

private enum MapSheet: Identifiable {
    case about, help, settings, favorites, developerInfo
    var id: Self { self }
}

private struct VehicleTrailPoint {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
}

/// Projects a vehicle's position `seconds` into the future using schedule data.
private func projectCoordinate(
    from current: CLLocationCoordinate2D,
    nextStop: CLLocationCoordinate2D,
    arrivalDate: Date,
    seconds: TimeInterval
) -> CLLocationCoordinate2D {
    let total = arrivalDate.timeIntervalSince(Date())
    guard total > 1 else { return nextStop }
    let progress = min(seconds / total, 1.0)
    return CLLocationCoordinate2D(
        latitude:  current.latitude  + progress * (nextStop.latitude  - current.latitude),
        longitude: current.longitude + progress * (nextStop.longitude - current.longitude)
    )
}

struct TransportMapView: View {
    private static let berlinCenter = CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954)
    private static let nearbySpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    private static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: berlinCenter, span: defaultSpan)
    )

    @State private var locationManager = LocationManager()
    @State private var hasInitializedLocation = false
    @State private var stops: [TransportStop] = []
    @State private var vehicles: [Vehicle] = []
    @State private var restDepartures: [RESTDeparture] = []
    @State private var isLoadingDepartures = false
    @State private var selectedStop: TransportStop?
    @State private var selectedVehicle: Vehicle?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentRegion: MKCoordinateRegion?
    @State private var lastLoadTime: Date?
    @State private var lastVehiclesLoadTime: Date?
    @State private var isLoadingVehicles = false
    @State private var isLiveUpdating = true
    @State private var vehicleHeadings: [String: Double] = [:]
    @State private var vehicleTrails: [String: [VehicleTrailPoint]] = [:]
    /// Projected end-of-interval positions. Set once per poll; MapKit animates to them smoothly.
    @State private var vehicleProjectedPositions: [String: CLLocationCoordinate2D] = [:]
    @State private var favoritesService: FavoritesService?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastLocationUpdate = Date.distantPast
    @State private var pollingInterval: TimeInterval = 5.0
    @State private var dataSource: DataSource = .network
    @State private var showingCacheInfo = false
    @State private var events: [Event] = []
    @State private var selectedEvent: Event?

    @State private var route: Route?
    @State private var routeAccentColor: Color = .blue
    @State private var stopsLoadTask: Task<Void, Never>?
    @State private var favoritesFeedbackTrigger = 0

    @State private var activeSheet: MapSheet?
    @AppStorage("vehicleFetchCount") private var vehicleFetchCount = 0
    @Environment(\.requestReview) private var requestReview

    private let services = ServiceContainer.shared
    private let offlineDatabase = OfflineStopsDatabase.shared
    
    var isOffline: Bool { !services.networkMonitor.isConnected }

    private var isZoomedIn: Bool {
        guard let region = currentRegion else { return false }
        return region.span.latitudeDelta <= 0.02
    }

    private var shouldRenderTrails: Bool {
        isZoomedIn && vehicles.count <= 180
    }

    private var shouldAnimateVehiclePulse: Bool {
        isZoomedIn && vehicles.count <= 120
    }

    private var vehiclesToRender: [Vehicle] {
        guard let region = currentRegion else {
            return Array(vehicles.prefix(180))
        }

        let zoom = region.span.latitudeDelta
        let limit: Int
        switch zoom {
        case ...0.02:
            limit = 500
        case ...0.05:
            limit = 260
        case ...0.10:
            limit = 150
        default:
            limit = 90
        }

        return Array(vehicles.prefix(limit))
    }

    @MapContentBuilder
    private var mapContent: some MapContent {
        UserAnnotation()
        stopAnnotations
        trailOverlay
        vehicleAnnotations
        routeOverlay
    }

    @MapContentBuilder
    private var trailOverlay: some MapContent {
        if shouldRenderTrails {
            ForEach(vehiclesToRender.prefix(120)) { vehicle in
                if let trail = vehicleTrails[vehicle.id], trail.count >= 2 {
                    MapPolyline(coordinates: trail.map(\.coordinate))
                        .stroke(Color(hex: vehicle.line?.color ?? "#007AFF").opacity(0.35), lineWidth: 2)
                }
            }
        }
    }

    @MapContentBuilder
    private var stopAnnotations: some MapContent {
        ForEach(stops) { stop in
            Annotation("", coordinate: CLLocationCoordinate2D(
                latitude: stop.latitude,
                longitude: stop.longitude
            )) {
                Button {
                    openDepartures(for: stop)
                } label: {
                    StopAnnotationView(
                        stop: stop,
                        departures: nil,
                        showLabel: isZoomedIn || selectedStop?.id == stop.id
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(stop.name)
                .accessibilityHint("Shows departures for this stop")
            }
        }
    }

    @MapContentBuilder
    private var vehicleAnnotations: some MapContent {
        ForEach(vehiclesToRender) { vehicle in
            vehicleAnnotation(for: vehicle)
        }
    }

    @MapContentBuilder
    private func vehicleAnnotation(for vehicle: Vehicle) -> some MapContent {
        // Use the projected (animated) position when available so the vehicle
        // glides smoothly toward its next stop over the polling interval.
        if let coordinate = vehicleProjectedPositions[vehicle.id] ?? vehicle.currentLocation {
            let title = vehicle.line?.displayName ?? "?"
            Annotation(title, coordinate: coordinate) {
                Button {
                    selectedVehicle = vehicle
                } label: {
                    LiveVehicleMarkerView(
                        vehicle: vehicle,
                        headingDegrees: vehicleHeadings[vehicle.id],
                        isMoving: true,
                        isPulseEnabled: shouldAnimateVehiclePulse,
                        isSelected: vehicle.id == selectedVehicle?.id
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(vehicleAccessibilityLabel(for: vehicle))
                .accessibilityHint("Shows route and trip details")
            }
            .tag(vehicle.id)
        }
    }

    @MapContentBuilder
    private var routeOverlay: some MapContent {
        if let route = route {
            MapPolyline(coordinates: route.coordinates)
                .stroke(.black.opacity(0.35), lineWidth: 8)
            MapPolyline(coordinates: route.coordinates)
                .stroke(routeAccentColor, lineWidth: 4)
        }
    }

    private var cacheStatusIconName: String {
        if !services.networkMonitor.isConnected {
            return "wifi.slash"
        }
        return dataSource == .stale ? "clock.arrow.circlepath" : "wifi"
    }

    private var cacheStatusText: String {
        if !services.networkMonitor.isConnected {
            return "Offline"
        }
        return dataSource == .stale ? "Stale" : "Live"
    }

    private var cacheBadgeColor: Color {
        if !services.networkMonitor.isConnected {
            return Color.red.opacity(0.9)
        }
        return dataSource == .stale ? Color.orange.opacity(0.9) : Color.green.opacity(0.9)
    }

    private var cacheInfoText: String {
        if !services.networkMonitor.isConnected {
            return "You're currently offline. Showing last known vehicle positions."
        }
        if dataSource == .stale {
            return "Last known positions shown. Waiting for next update."
        }
        return "Showing live data from the network."
    }

    var body: some View {
        contentWithSheets
            .transportMapFeedback(trigger: favoritesFeedbackTrigger)
            .task {
                if let region = currentRegion {
                    await loadStopsForRegion(region)
                    await loadVehicles(for: region)
                }
            }
            .task {
                // Adaptive polling loop.
                // VBB positions update server-side every ~30s; projecting to
                // end-of-interval and animating with withAnimation gives smooth
                // movement without per-second state thrashing.
                while !Task.isCancelled {
                    let interval: TimeInterval = Date().timeIntervalSince(lastLocationUpdate) < 60 ? 15 : 30
                    pollingInterval = interval
                    try? await Task.sleep(for: .seconds(interval))
                    guard !Task.isCancelled else { break }
                    if isLiveUpdating && scenePhase == .active, let region = currentRegion {
                        await loadVehicles(for: region)
                    }
                }
            }
            .onDisappear {
                stopsLoadTask?.cancel()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    services.predictiveLoader.startPredictiveLoading()
                case .inactive, .background:
                    services.predictiveLoader.stopPredictiveLoading()
                @unknown default:
                    break
                }
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let location = newLocation {
                    lastLocationUpdate = Date()
                    services.predictiveLoader.handleLocationUpdate(location)
                }
            }
    }

    private var mainContent: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                mapContent
            }
            .accessibilityIgnoresInvertColors()
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .continuous) { context in
                let newRegion = context.region
                let oldRegion = currentRegion

                currentRegion = newRegion

                if let old = oldRegion {
                    let centerChanged = abs(newRegion.center.latitude - old.center.latitude) > 0.01 ||
                                         abs(newRegion.center.longitude - old.center.longitude) > 0.01
                    let spanChanged = abs(newRegion.span.latitudeDelta - old.span.latitudeDelta) > 0.005

                    if centerChanged || spanChanged {
                        scheduleStopsLoad(for: newRegion)
                    }
                } else {
                    // First camera event — map has rendered its initial position.
                    // Kick off both stops and vehicles immediately rather than
                    // waiting up to 20s for the first polling tick.
                    scheduleStopsLoad(for: newRegion)
                    Task { await loadVehicles(for: newRegion) }
                }
            }
            .navigationTitle("Berlin Transport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCacheInfo = true
                    } label: {
                        statusBadge
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Data source")
                    .accessibilityValue(cacheStatusText)
                    .accessibilityHint("Shows whether the app is using live or cached data")
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        triggerFavoritesFeedback()
                        activeSheet = .favorites
                    } label: {
                        Label("Favorites", systemImage: "star")
                    }
                    Spacer()
                    Menu {
                        Button {
                            activeSheet = .settings
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        Button {
                            activeSheet = .help
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                        Button {
                            activeSheet = .about
                        } label: {
                            Label("About", systemImage: "info.circle")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .toolbarBackground(.visible, for: .bottomBar)
            .toolbarBackground(.ultraThinMaterial, for: .bottomBar)
            .alert("Data Source", isPresented: $showingCacheInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(cacheInfoText)
            }
        }
    }

    private var contentWithSheets: some View {
        mainContent
            .sheet(item: $selectedStop) { stop in
                RESTDeparturesSheet(
                    stop: stop,
                    departures: restDepartures,
                    isLoading: isLoadingDepartures,
                    predictionService: services.predictionService,
                    onClose: {
                        selectedStop = nil
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedVehicle) { vehicle in
                VehicleInfoSheet(
                    vehicle: vehicle,
                    onClose: {
                        selectedVehicle = nil
                    },
                    onShowRoute: {
                        Task {
                            await loadRoute(for: vehicle)
                        }
                    }
                )
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .about:
                    BerlinTransportMapAboutView()
                case .help:
                    BerlinTransportMapHelpCenterView()
                case .settings:
                    SettingsView()
                case .favorites:
                    favoritesSheet
                case .developerInfo:
                    DeveloperInfoSheet()
                        .presentationDetents([.medium])
                }
            }
    }

    private var favoritesSheet: some View {
        FavoritesView(
            onSelectStop: { stop in
                // Navigate to stop
                cameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
            },
            onSelectRoute: { route in
                self.route = route
                if let firstCoord = route.coordinates.first {
                    cameraPosition = .region(MKCoordinateRegion(center: firstCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                }
            },
            onClose: {
                activeSheet = nil
            }
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: cacheStatusIconName)
                .font(.caption)
            Text(cacheStatusText)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(cacheBadgeColor)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }



    @MainActor
    private func openDepartures(for stop: TransportStop) {
        selectedStop = stop
        restDepartures = []
        isLoadingDepartures = true

        Task {
            await loadDepartures(for: stop)
        }
    }

    @MainActor
    private func loadDepartures(for stop: TransportStop) async {
        do {
            let departures = try await services.vehicleRadarService.fetchDepartures(stopId: stop.vbbStopId)
            restDepartures = departures
        } catch {
            errorMessage = "Failed to load departures: \(error.localizedDescription)"
            restDepartures = []
        }
        isLoadingDepartures = false
    }



    private func centerOnUserLocation() {
        if locationManager.isAuthorized, let location = locationManager.location {
            if reduceMotion {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: Self.nearbySpan
                    )
                )
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: Self.nearbySpan
                        )
                    )
                }
            }
        } else {
            locationManager.requestPermission()
        }
    }

    @MainActor
    private func loadVehicles(for region: MKCoordinateRegion) async {
        let now = Date()
        if let last = lastVehiclesLoadTime, now.timeIntervalSince(last) < 1.0 {
            return
        }
        lastVehiclesLoadTime = now

        guard !isLoadingVehicles else { return }
        isLoadingVehicles = true
        defer { isLoadingVehicles = false }

        let center = region.center
        let latDelta = region.span.latitudeDelta / 2
        let lonDelta = region.span.longitudeDelta / 2

        let north = center.latitude + latDelta
        let west = center.longitude - lonDelta
        let south = center.latitude - latDelta
        let east = center.longitude + lonDelta

        do {
            // Vehicles are real-time — never read from or write to disk cache.
            // If offline or errored, the existing in-memory `vehicles` state
            // already holds the last known positions; just mark as stale.
            guard services.networkMonitor.isConnected else {
                dataSource = .stale
                return
            }

            let fetchedVehicles = try await services.vehicleRadarService.fetchVehicles(
                north: north,
                west: west,
                south: south,
                east: east,
                duration: 30
            )

            updateVehiclesWithAnimation(fetchedVehicles)
            dataSource = .network
            vehicleFetchCount += 1
            if vehicleFetchCount == 5 || vehicleFetchCount == 20 {
                requestReview()
            }
            let anchored = fetchedVehicles.filter { $0.nextStopCoordinate != nil && $0.nextStopArrival != nil }.count
            print("VehicleRadar: Fetched \(fetchedVehicles.count) vehicles, \(anchored) with next-stop anchors ✓")
        } catch {
            // Keep the existing in-memory positions — do not overwrite with stale disk data.
            errorMessage = "Failed to load vehicles: \(error.localizedDescription)"
            dataSource = .stale
            print("VehicleRadar: Fetch error — \(error.localizedDescription)")
        }
    }

    @MainActor
    private func updateVehiclesWithAnimation(_ incoming: [Vehicle]) {
        let previousCoordinates: [String: CLLocationCoordinate2D] = vehicles.reduce(into: [:]) { result, vehicle in
            guard let coordinate = vehicle.currentLocation else { return }
            result[vehicle.id] = coordinate
        }

        let now = Date()
        let cutoff = now.addingTimeInterval(-45)
        let shouldTrackTrails = shouldRenderTrails || selectedVehicle != nil
        let activeVehicleIDs = Set(incoming.map(\.id))

        var updatedHeadings = vehicleHeadings
        updatedHeadings = updatedHeadings.filter { activeVehicleIDs.contains($0.key) }

        var updatedTrails = vehicleTrails
        updatedTrails = updatedTrails.filter { activeVehicleIDs.contains($0.key) }

        if !shouldTrackTrails {
            updatedTrails.removeAll(keepingCapacity: true)
        }

        for vehicle in incoming {
            guard
                let newCoordinate = vehicle.currentLocation,
                let oldCoordinate = previousCoordinates[vehicle.id]
            else {
                if shouldTrackTrails, let newCoordinate = vehicle.currentLocation {
                    var trail = updatedTrails[vehicle.id] ?? []
                    trail.append(VehicleTrailPoint(coordinate: newCoordinate, timestamp: now))
                    updatedTrails[vehicle.id] = Array(trail.suffix(12))
                }
                continue
            }

            let distance = approximateDistanceMeters(from: oldCoordinate, to: newCoordinate)

            // Ignore tiny jitter to avoid noisy heading changes.
            if distance > 8 {
                updatedHeadings[vehicle.id] = bearing(from: oldCoordinate, to: newCoordinate)
            }

            if shouldTrackTrails {
                var trail = updatedTrails[vehicle.id] ?? []
                if trail.last.map({ approximateDistanceMeters(from: $0.coordinate, to: newCoordinate) > 4 }) ?? true {
                    trail.append(VehicleTrailPoint(coordinate: newCoordinate, timestamp: now))
                }

                trail = trail.filter { $0.timestamp >= cutoff }
                updatedTrails[vehicle.id] = Array(trail.suffix(12))
            }
        }

        vehicleTrails = updatedTrails

        // For each vehicle, compute where it should be at the END of the next
        // polling interval using schedule/stop data. We then animate from the
        // current screen position to that projected position over the full
        // polling interval with ONE withAnimation call — no per-second state
        // thrashing, no annotation rebuilds between polls.
        let now2 = Date()
        var projected: [String: CLLocationCoordinate2D] = [:]
        for vehicle in incoming {
            guard let from = vehicle.currentLocation else { continue }

            if let to = vehicle.nextStopCoordinate,
               let arrival = vehicle.nextStopArrival,
               arrival > now2 {
                // Project to where this vehicle will be at end of next interval.
                projected[vehicle.id] = projectCoordinate(
                    from: from,
                    nextStop: to,
                    arrivalDate: arrival,
                    seconds: pollingInterval
                )
                updatedHeadings[vehicle.id] = bearing(from: from, to: to)
            } else {
                // No schedule data — annotation stays at current position.
                projected[vehicle.id] = from
            }
        }

        // Single write — covers both trail-based and projection-based headings.
        vehicleHeadings = updatedHeadings
        vehicles = incoming

        // Animate all annotations to their projected end-of-interval positions.
        // This runs once per poll (every 15-30s), NOT every second.
        let animDuration = max(pollingInterval - 1.0, 1.0)
        if reduceMotion {
            vehicleProjectedPositions = projected
        } else {
            withAnimation(.linear(duration: animDuration)) {
                vehicleProjectedPositions = projected
            }
        }
    }

    private func vehicleAccessibilityLabel(for vehicle: Vehicle) -> String {
        let lineName = vehicle.line?.displayName ?? "Unknown line"
        let destination = vehicle.direction ?? "Unknown destination"
        return "\(lineName) toward \(destination)"
    }

    private func approximateDistanceMeters(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        // Fast equirectangular approximation; accurate enough for short map deltas.
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        let x = (lon2 - lon1) * cos((lat1 + lat2) / 2)
        let y = lat2 - lat1
        return sqrt(x * x + y * y) * 6_371_000
    }

    private func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let radians = atan2(y, x)
        var degrees = radians * 180 / .pi
        if degrees < 0 {
            degrees += 360
        }
        return degrees
    }

    @MainActor
    private func loadStopsForRegion(_ region: MKCoordinateRegion) async {
        let now = Date()
        if let lastLoad = lastLoadTime, now.timeIntervalSince(lastLoad) < 1.0 {
            return
        }
        lastLoadTime = now

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        let center = region.center
        let maxDistance = Int(region.span.latitudeDelta * 111_000)

        // Use offline database first - it's always available and fast
        await offlineDatabase.loadIfNeeded()
        
        let nearbyStops = offlineDatabase.findStops(
            latitude: center.latitude,
            longitude: center.longitude,
            maxDistance: maxDistance
        )
        
        if !nearbyStops.isEmpty {
            self.stops = nearbyStops
            // Stop locations are static data — loading from offline DB is normal
            // operation, not a degraded state. Don't change the vehicle dataSource.
            print("OfflineDB: Found \(nearbyStops.count) stops within \(maxDistance)m")
        } else {
            // Fallback to API if offline DB has no data (first launch)
            do {
                let fetchedStops = try await services.transportService.queryNearbyStops(
                    latitude: center.latitude,
                    longitude: center.longitude,
                    maxDistance: min(maxDistance, 5000),
                    maxLocations: 100
                )
                self.stops = fetchedStops
                print("API: Fetched \(fetchedStops.count) stops from network")
            } catch {
                errorMessage = error.localizedDescription
                self.stops = []
            }
        }

        isLoading = false
    }

    @MainActor
    private func scheduleStopsLoad(for region: MKCoordinateRegion) {
        stopsLoadTask?.cancel()
        stopsLoadTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            await loadStopsForRegion(region)
        }
    }

    private func formattedAge(_ age: TimeInterval) -> String {
        if age < 60 {
            return "<1m"
        } else if age < 3600 {
            return "\(Int(age / 60))m"
        } else {
            return "\(Int(age / 3600))h"
        }
    }

    private func triggerFavoritesFeedback() {
        favoritesFeedbackTrigger += 1
    }
    
    private func refreshData() {
        services.cacheService.clear()
        if let region = currentRegion {
            Task {
                await loadStopsForRegion(region)
                await loadVehicles(for: region)
            }
        }
    }

    @MainActor
    private func loadRoute(for vehicle: Vehicle) async {
        do {
            if let tripRoute = try await services.vehicleRadarService.fetchTripRoute(tripId: vehicle.tripId) {
                let leg = RouteLeg(type: "publicTransport", departureTime: nil, arrivalTime: nil, coordinates: tripRoute.routeCoordinates)
                let newRoute = Route(
                    id: tripRoute.id ?? vehicle.tripId,
                    legs: [leg],
                    totalDuration: 0,
                    departureTime: Date(),
                    arrivalTime: Date()
                )
                route = newRoute
                routeAccentColor = Color(hex: vehicle.line?.color ?? "#007AFF")
                if let firstCoord = leg.coordinates.first {
                    cameraPosition = .region(MKCoordinateRegion(center: firstCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                }
            }
        } catch {
            errorMessage = "Failed to load route: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func loadEvents() async {
        do {
            events = try await services.eventsService.fetchEvents()
        } catch {
            print("Failed to load events: \(error)")
        }
    }
}

private extension View {
    @ViewBuilder
    func transportMapFeedback(trigger: Int) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.sensoryFeedback(.impact(flexibility: .soft), trigger: trigger)
        } else {
            self
        }
    }
}

// MARK: - Supporting Views

struct LiveVehicleMarkerView: View {
    let vehicle: Vehicle
    let headingDegrees: Double?
    let isMoving: Bool
    let isPulseEnabled: Bool
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            if isMoving && isPulseEnabled && !reduceMotion {
                Circle()
                    .stroke(vehicleColor.opacity(0.45), lineWidth: 2)
                    .frame(width: isSelected ? 50 : 44, height: isSelected ? 50 : 44)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0.0 : 0.65)
            }

            Image(systemName: "location.north.fill")
                .font(.system(size: isSelected ? 11 : 10, weight: .bold))
                .foregroundStyle(vehicleColor.opacity(0.95))
                .rotationEffect(.degrees(headingDegrees ?? 0))
                .offset(y: isSelected ? -22 : -19)

            Circle()
                .stroke(vehicleColor.opacity(0.3), lineWidth: isSelected ? 4 : 3)
                .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)

            Circle()
                .fill(vehicleColor)
                .frame(width: isSelected ? 32 : 28, height: isSelected ? 32 : 28)
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 4 : 3, x: 0, y: 2)

            Text(vehicle.line?.displayName ?? "?")
                .font(.system(size: isSelected ? 10 : 9, weight: .bold))
                .foregroundStyle(Color(hex: vehicle.line?.foregroundColor ?? "#FFFFFF"))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: headingDegrees)
        .onAppear {
            guard isMoving, isPulseEnabled, !reduceMotion else { return }
            pulse = true
        }
        .onChange(of: isMoving) { _, moving in
            pulse = moving && isPulseEnabled && !reduceMotion
        }
        .onChange(of: isPulseEnabled) { _, enabled in
            pulse = enabled && isMoving && !reduceMotion
        }
        .onChange(of: reduceMotion) { _, isReduced in
            pulse = !isReduced && isMoving && isPulseEnabled
        }
        .animation(
            (!reduceMotion && isMoving && isPulseEnabled)
                ? .easeOut(duration: 1.4).repeatForever(autoreverses: false)
                : nil,
            value: pulse
        )
    }

    var vehicleColor: Color {
        if let colorHex = vehicle.line?.color, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        switch vehicle.line?.productType {
        case .tram:
            return Color(hex: "#D8232A")
        case .subway:
            return Color(hex: "#0066CC")
        case .suburbanTrain:
            return Color(hex: "#008C3C")
        case .bus:
            return Color(hex: "#993399")
        case .ferry:
            return Color(hex: "#0099CC")
        case .regionalTrain:
            return Color(hex: "#EC192E")
        default:
            return .gray
        }
    }
}

struct StopMarkerView: View {
    let stop: TransportStop
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let haltestelleYellow = Color(hex: "#FFD800")
    private let haltestelleGreen = Color(hex: "#006F3C")

    var body: some View {
        ZStack {
            Circle()
                .fill(haltestelleYellow)
                .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 4 : 2, y: 1)

            Circle()
                .stroke(haltestelleGreen, lineWidth: isSelected ? 3 : 2)
                .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)

            Text("H")
                .font(.system(size: isSelected ? 16 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(haltestelleGreen)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isSelected)
    }
}

struct RESTDeparturesSheet: View {
    let stop: TransportStop
    let departures: [RESTDeparture]
    let isLoading: Bool
    let predictionService: PredictionService
    let onClose: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var favoriteMessage: String?
    @State private var showingFavoriteAlert = false

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading departures...")
                        Spacer()
                    }
                } else if departures.isEmpty {
                    ContentUnavailableView(
                        "No Departures",
                        systemImage: "tram",
                        description: Text("No upcoming departures at this stop")
                    )
                } else {
                    ForEach(departures) { departure in
                        RESTDepartureRow(departure: departure, predictionService: predictionService, stop: stop)
                    }
                }
            }
            .navigationTitle(stop.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        addFavorite()
                    } label: {
                        Label("Add Favorite", systemImage: "star")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
            .alert(favoriteMessage ?? "", isPresented: $showingFavoriteAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    private func addFavorite() {
        do {
            let service = FavoritesService(modelContext: modelContext)
            try service.saveStopFavorite(name: stop.name, stop: stop)
            favoriteMessage = "Added to Favorites"
        } catch {
            favoriteMessage = "Failed to add favorite: \(error.localizedDescription)"
        }
        showingFavoriteAlert = true
    }
}

struct RESTDepartureRow: View {
    let departure: RESTDeparture
    let predictionService: PredictionService
    let stop: TransportStop
    
    var predictedArrivalTime: Date? {
        // Create a mock vehicle for prediction
        let mockVehicle = Vehicle(
            tripId: departure.tripId,
            line: departure.line,
            direction: departure.direction,
            location: nil,
            when: nil,
            nextStopovers: nil
        )
        return predictionService.predictArrival(for: mockVehicle, at: stop)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: departure.line?.color ?? "#666666"))
                    .frame(width: 50, height: 28)

                Text(departure.line?.displayName ?? "?")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: departure.line?.foregroundColor ?? "#FFFFFF"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(departure.direction ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let platform = departure.platform {
                    Text("Platform \(platform)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let time = departure.displayTime {
                    Text(time, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if let delay = departure.delay, delay > 0 {
                    Text("+\(delay) min")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if departure.cancelled == true {
                    Text("Cancelled")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Predicted arrival time
                if let predictedTime = predictedArrivalTime {
                    Text("Predicted: \(predictedTime, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .opacity(departure.cancelled == true ? 0.5 : 1.0)
    }
}

// MARK: - Vehicle Info Sheet

struct VehicleInfoSheet: View {
    let vehicle: Vehicle
    let onClose: () -> Void
    let onShowRoute: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(vehicle.line?.displayName ?? "?")
                    .font(.title2.bold())
                    .foregroundStyle(Color(hex: vehicle.line?.foregroundColor ?? "#FFFFFF"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: vehicle.line?.color ?? "#666666"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    if let direction = vehicle.direction {
                        Text("→ \(direction)")
                            .font(.headline)
                    }
                    if let line = vehicle.line {
                        Text(productTypeDisplayName(line.productType))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let tripId = vehicle.line?.fahrtNr, !tripId.isEmpty {
                        Text("Trip: \(tripId)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Close")
                .accessibilityInputLabels(["Close"])
                .accessibilityShowsLargeContentViewer {
                    Label("Close", systemImage: "xmark.circle.fill")
                }
            }

            Divider()

            HStack(spacing: 20) {
                if let coord = vehicle.currentLocation {
                    VStack(spacing: 2) {
                        Text("Lat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(coord.latitude.formatted(.number.precision(.fractionLength(5))))
                            .font(.caption.monospaced())
                    }
                    VStack(spacing: 2) {
                        Text("Lon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(coord.longitude.formatted(.number.precision(.fractionLength(5))))
                            .font(.caption.monospaced())
                    }
                }


            }

            Button {
                onShowRoute()
                onClose()
            } label: {
                Label("Show Route", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: vehicle.line?.color ?? "#007AFF"))
                    .foregroundStyle(Color(hex: vehicle.line?.foregroundColor ?? "#FFFFFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }

    private func productTypeDisplayName(_ type: VehicleProduct) -> String {
        switch type {
        case .suburbanTrain: return "S-Bahn"
        case .subway: return "U-Bahn"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .ferry: return "Ferry"
        case .regionalTrain: return "Regional Train"
        }
    }
}

// MARK: - Developer Info

struct DeveloperInfoSheet: View {
    private let developerName = "Ruslan Dautov"
    private let websiteURL = URL(string: "https://dautovri.com")
    private let githubURL = URL(string: "https://github.com/dautovri")
    private let linkedInURL = URL(string: "https://linkedin.com/in/dautovri")
    private let twitterURL = URL(string: "https://x.com/dautovri")
    private let emailURL = URL(string: "mailto:dautovri@outlook.com")

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        VStack(alignment: .center, spacing: 4) {
                            Text("Berlin Transport Map")
                                .font(.headline)
                            Text("Live vehicle radar and nearby stops")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("by \(developerName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text("About App")
                } footer: {
                    Text("Explore Berlin transit with live vehicles, nearby stops, and clean map controls.")
                }

                Section {
                    VStack(spacing: 10) {
                        if let githubURL {
                            Link(destination: githubURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundStyle(.primary)
                                    Text("GitHub")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundStyle(.primary)
                        }

                        if let linkedInURL {
                            Link(destination: linkedInURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundStyle(.primary)
                                    Text("LinkedIn")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundStyle(.primary)
                        }

                        if let twitterURL {
                            Link(destination: twitterURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundStyle(.primary)
                                    Text("X (Twitter)")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundStyle(.primary)
                        }

                        if let emailURL {
                            Link(destination: emailURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundStyle(.primary)
                                    Text("Email")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Connect with Developer")
                } footer: {
                    Text("Follow Ruslan Dautov on social media or get in touch via email.")
                }

                Section {
                    if let websiteURL {
                        Link(destination: websiteURL) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(.blue)
                                Text("Visit Portfolio")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("More")
                } footer: {
                    Text("Explore more projects and technical work on the developer's portfolio.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("About")
        }
    }
}

// MARK: - Color Extension

// MARK: - Event Details Sheet

struct EventDetailsSheet: View {
    let event: Event
    @Binding var isPresented: Bool
    let onPlanRoute: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.name)
                    .font(.title)
                Text(event.location)
                    .font(.subheadline)
                Text(event.date, style: .date)
                if let desc = event.description {
                    Text(desc)
                        .font(.body)
                }
                Button("Plan Route to Event") {
                    onPlanRoute()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    TransportMapView()
}
