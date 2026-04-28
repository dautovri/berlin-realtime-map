import StoreKit
import SwiftUI
import MapKit
import SwiftData

enum DataSource {
    case network  // just successfully fetched
    case stale    // last in-memory positions; next fetch in progress or errored
}

private enum MapSheet: Identifiable {
    case about, help, settings, favorites, developerInfo, journeyPlanner, cityPicker
    var id: Self { self }
}

private struct VehicleTrailPoint {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
}

private struct VehicleMotionPlan {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let startDate: Date
    let endDate: Date

    func coordinate(at date: Date) -> CLLocationCoordinate2D {
        let totalDuration = endDate.timeIntervalSince(startDate)
        guard totalDuration > 0 else { return endCoordinate }

        let elapsed = date.timeIntervalSince(startDate)
        let progress = min(max(elapsed / totalDuration, 0), 1)

        return CLLocationCoordinate2D(
            latitude: startCoordinate.latitude + (endCoordinate.latitude - startCoordinate.latitude) * progress,
            longitude: startCoordinate.longitude + (endCoordinate.longitude - startCoordinate.longitude) * progress
        )
    }
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
    private static let nearbySpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    private static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: ServiceContainer.shared.cityManager.currentCity.centerCoordinate,
            span: defaultSpan
        )
    )

    @State private var locationManager = LocationManager()
    @State private var hasInitializedLocation = false
    @State private var hasAutocentered = false
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
    @State private var vehicleRenderedPositions: [String: CLLocationCoordinate2D] = [:]
    @State private var vehicleMotionPlans: [String: VehicleMotionPlan] = [:]
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
    @State private var dismissedEventsCard = false

    @State private var route: Route?
    @State private var routeAccentColor: Color = .blue
    @State private var stopsLoadTask: Task<Void, Never>?
    @State private var vehiclesLoadTask: Task<Void, Never>?
    @State private var favoritesFeedbackTrigger = 0

    @State private var activeSheet: MapSheet?
    @AppStorage("vehicleFetchCount") private var vehicleFetchCount = 0
    @AppStorage("hasSeenOnboardingV2") private var hasSeenOnboardingV2 = false
    @Environment(\.requestReview) private var requestReview

    private let services = ServiceContainer.shared
    private let offlineDatabase = OfflineStopsDatabase.shared

    private var cityManager: CityManager { services.cityManager }

    var isOffline: Bool { !services.networkMonitor.isConnected }

    private var activeEventsCardEvent: Event? {
        guard let center = currentRegion?.center else { return nil }
        let now = Date()
        let fourHoursLater = now.addingTimeInterval(4 * 3600)
        return events.first { event in
            let eventCoord = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
            let mapCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let eventLoc = CLLocation(latitude: eventCoord.latitude, longitude: eventCoord.longitude)
            let distanceKm = mapCenter.distance(from: eventLoc) / 1000
            return distanceKm <= 2.0 && event.date >= now && event.date <= fourHoursLater
        }
    }

    private var isZoomedIn: Bool {
        guard let region = currentRegion else { return false }
        return region.span.latitudeDelta <= 0.02
    }

    private var shouldRenderTrails: Bool {
        selectedVehicle != nil
    }

    private var stopAnnotationLimit: Int {
        guard let region = currentRegion else {
            return 100
        }

        switch region.span.latitudeDelta {
        case ...0.008:
            return 120
        case ...0.02:
            return 80
        case ...0.04:
            return 55
        default:
            return 0   // hide stops entirely when zoomed out
        }
    }

    private var stopsToRender: [TransportStop] {
        Array(stops.prefix(stopAnnotationLimit))
    }

    private var vehiclesToRender: [Vehicle] {
        guard let region = currentRegion else {
            return Array(vehicles.prefix(180))
        }

        let zoom = region.span.latitudeDelta
        let limit: Int
        switch zoom {
        case ...0.02:
            limit = 180
        case ...0.05:
            limit = 120
        case ...0.10:
            limit = 80
        default:
            limit = 50
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
            ForEach(vehiclesToRender.filter { $0.id == selectedVehicle?.id }.prefix(1)) { vehicle in
                if let trail = vehicleTrails[vehicle.id], trail.count >= 2 {
                    MapPolyline(coordinates: trail.map(\.coordinate))
                        .stroke(Color(hex: vehicle.line?.color ?? "#007AFF").opacity(0.35), lineWidth: 2)
                }
            }
        }
    }

    @MapContentBuilder
    private var stopAnnotations: some MapContent {
        ForEach(stopsToRender) { stop in
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
                        showLabel: selectedStop?.id == stop.id
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("stop_annotation")
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
        if let coordinate = vehicleRenderedPositions[vehicle.id] ?? vehicle.currentLocation {
            Annotation("", coordinate: coordinate) {
                Button {
                    selectedVehicle = vehicle
                } label: {
                    LiveVehicleMarkerView(
                        vehicle: vehicle,
                        headingDegrees: vehicleHeadings[vehicle.id],
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
            return Color(hex: "#C41E3A")
        }
        return dataSource == .stale ? Color(hex: "#8A8A8E") : Color(hex: "#00A550")
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
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(750))
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        advanceVehicleMotion(to: .now)
                    }
                }
            }
            .task {
                await loadEvents()
            }
            .onDisappear {
                stopsLoadTask?.cancel()
                vehiclesLoadTask?.cancel()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    ActivationMetricsService.shared.recordSession()
                    services.predictiveLoader.startPredictiveLoading()
                case .inactive, .background:
                    services.predictiveLoader.stopPredictiveLoading()
                @unknown default:
                    break
                }
            }
            .onChange(of: cityManager.currentCity) { _, newCity in
                // Clear stale data from previous city
                vehicles = []
                stops = []
                vehicleRenderedPositions = [:]
                vehicleMotionPlans = [:]
                vehicleHeadings = [:]
                vehicleTrails = [:]
                route = nil
                selectedStop = nil
                selectedVehicle = nil

                let region = MKCoordinateRegion(
                    center: newCity.centerCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(region)
                }
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let location = newLocation {
                    lastLocationUpdate = Date()
                    services.predictiveLoader.handleLocationUpdate(location)
                    if !hasAutocentered {
                        hasAutocentered = true
                        centerOnUserLocation()
                    }
                }
            }
#if targetEnvironment(macCatalyst)
            .onReceive(NotificationCenter.default.publisher(for: .showAboutSheet)) { _ in
                activeSheet = .about
            }
            .onReceive(NotificationCenter.default.publisher(for: .showSettingsSheet)) { _ in
                activeSheet = .settings
            }
#endif
            .onReceive(NotificationCenter.default.publisher(for: .showDeparturesForStop)) { note in
                guard let stopId = note.userInfo?["stopId"] as? String,
                      let stopName = note.userInfo?["stopName"] as? String else { return }
                let stop = TransportStop(
                    id: stopId,
                    name: stopName,
                    latitude: 52.52,
                    longitude: 13.405
                )
                openDepartures(for: stop)
            }
    }

    private var mainContent: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                mapContent
            }
            .accessibilityIdentifier("transport_map_canvas")
            .accessibilityIgnoresInvertColors()
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                let newRegion = context.region
                let oldRegion = currentRegion

                if let old = oldRegion {
                    if shouldCommitVisibleRegionChange(from: old, to: newRegion) {
                        currentRegion = newRegion
                    }

                    guard shouldReloadTransportData(from: old, to: newRegion) else {
                        return
                    }

                    scheduleStopsLoad(for: newRegion)
                    scheduleVehicleLoad(for: newRegion)
                } else {
                    currentRegion = newRegion
                    // First camera event — map has rendered its initial position.
                    // Kick off both stops and vehicles immediately rather than
                    // waiting up to 20s for the first polling tick.
                    scheduleStopsLoad(for: newRegion)
                    scheduleVehicleLoad(for: newRegion, delay: .milliseconds(120))
                }
            }
            .overlay(alignment: .top) {
                if isOffline {
                    OfflineBanner()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottom) {
                if let event = activeEventsCardEvent, !dismissedEventsCard {
                    EventsCard(event: event) {
                        withAnimation { dismissedEventsCard = true }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isOffline)
            .animation(.easeInOut(duration: 0.3), value: activeEventsCardEvent?.id)
            .navigationTitle("\(cityManager.currentCity.name) Transport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    statusBadge
                        .onTapGesture { showingCacheInfo = true }
                        .accessibilityLabel("Data source")
                        .accessibilityValue(cacheStatusText)
                        .accessibilityHint("Shows whether the app is using live or cached data")
                        .accessibilityAddTraits(.isButton)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        triggerFavoritesFeedback()
                        activeSheet = .favorites
                    } label: {
                        Label("Favorites", systemImage: "star")
                    }
                    Spacer()
                    Button {
                        activeSheet = .journeyPlanner
                    } label: {
                        Label("Plan", systemImage: "map")
                    }
                    Spacer()
                    Menu {
                        Button {
                            activeSheet = .cityPicker
                        } label: {
                            Label("Change City", systemImage: "building.2")
                        }
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
                case .journeyPlanner:
                    JourneyPlannerSheet(
                        transportService: services.transportService,
                        routeService: services.routeService,
                        onRouteSelected: { selectedRoute in
                            self.route = selectedRoute
                            focusCamera(on: selectedRoute.coordinates)
                            activeSheet = nil
                        }
                    )
                case .cityPicker:
                    CityPickerView()
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
                focusCamera(on: route.coordinates)
            },
            onClose: {
                activeSheet = nil
            }
        )
    }

    private var statusBadge: some View {
        Text(cacheStatusText)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(cacheBadgeColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }



    @MainActor
    private func openDepartures(for stop: TransportStop) {
        ActivationMetricsService.shared.recordStopDetailOpen()
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
            let departures = try await services.vehicleRadarService.fetchDepartures(stopId: stop.stopId)
            guard selectedStop?.id == stop.id else { isLoadingDepartures = false; return }
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

    private func focusCamera(
        on coordinates: [CLLocationCoordinate2D],
        fallback fallbackCoordinate: CLLocationCoordinate2D? = nil
    ) {
        let validCoordinates = coordinates.filter(CLLocationCoordinate2DIsValid)
        let focusCoordinates = validCoordinates.isEmpty
            ? [fallbackCoordinate].compactMap { $0 }
            : validCoordinates + [fallbackCoordinate].compactMap { $0 }

        guard let region = regionFitting(focusCoordinates) else { return }

        if reduceMotion {
            cameraPosition = .region(region)
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .region(region)
            }
        }
    }

    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        let validCoordinates = coordinates.filter(CLLocationCoordinate2DIsValid)
        guard let first = validCoordinates.first else { return nil }

        guard validCoordinates.count > 1 else {
            return MKCoordinateRegion(center: first, span: Self.nearbySpan)
        }

        let latitudes = validCoordinates.map(\.latitude)
        let longitudes = validCoordinates.map(\.longitude)

        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return nil
        }

        let latitudePadding = max((maxLatitude - minLatitude) * 0.25, 0.004)
        let longitudePadding = max((maxLongitude - minLongitude) * 0.25, 0.004)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(maxLatitude - minLatitude + latitudePadding, Self.nearbySpan.latitudeDelta),
                longitudeDelta: max(maxLongitude - minLongitude + longitudePadding, Self.nearbySpan.longitudeDelta)
            )
        )
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
            if vehicleFetchCount < 21 { vehicleFetchCount += 1 }
            if hasSeenOnboardingV2 && (vehicleFetchCount == 5 || vehicleFetchCount == 20) {
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

        // Build explicit motion plans and advance them on a timer.
        // SwiftUI Map doesn't reliably animate annotation coordinates from a
        // single implicit animation transaction, so we update rendered marker
        // positions periodically between backend polls.
        let now2 = Date.now
        var renderedPositions: [String: CLLocationCoordinate2D] = [:]
        var motionPlans: [String: VehicleMotionPlan] = [:]
        for vehicle in incoming {
            guard let from = vehicle.currentLocation else { continue }
            renderedPositions[vehicle.id] = from

            if let to = vehicle.nextStopCoordinate,
               let arrival = vehicle.nextStopArrival,
               arrival > now2 {
                let projectedCoordinate = projectCoordinate(
                    from: from,
                    nextStop: to,
                    arrivalDate: arrival,
                    seconds: pollingInterval
                )

                if approximateDistanceMeters(from: from, to: projectedCoordinate) > 2 {
                    let planEndDate = min(arrival, now2.addingTimeInterval(max(pollingInterval, 1)))
                    motionPlans[vehicle.id] = VehicleMotionPlan(
                        startCoordinate: from,
                        endCoordinate: projectedCoordinate,
                        startDate: now2,
                        endDate: planEndDate
                    )
                    updatedHeadings[vehicle.id] = bearing(from: from, to: projectedCoordinate)
                }
            }
        }

        // Single write — covers both trail-based and projection-based headings.
        vehicleHeadings = updatedHeadings
        vehicles = incoming
        vehicleMotionPlans = motionPlans
        vehicleRenderedPositions = renderedPositions
        advanceVehicleMotion(to: now2)
    }

    @MainActor
    private func advanceVehicleMotion(to date: Date) {
        guard !reduceMotion else { return }

        var updatedPositions = vehicleRenderedPositions
        let activeVehicleIDs = Set(vehicles.map(\.id))
        updatedPositions = updatedPositions.filter { activeVehicleIDs.contains($0.key) }

        for vehicle in vehicles {
            guard let current = vehicle.currentLocation else { continue }
            if let plan = vehicleMotionPlans[vehicle.id] {
                updatedPositions[vehicle.id] = plan.coordinate(at: date)
            } else {
                updatedPositions[vehicle.id] = current
            }
        }

        vehicleRenderedPositions = updatedPositions
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

    private func shouldCommitVisibleRegionChange(from old: MKCoordinateRegion, to new: MKCoordinateRegion) -> Bool {
        let centerShift = approximateDistanceMeters(from: old.center, to: new.center)
        let zoomDelta = abs(log(max(new.span.latitudeDelta, 0.0001) / max(old.span.latitudeDelta, 0.0001)))

        return centerShift > 90 || zoomDelta > 0.12
    }

    private func shouldReloadTransportData(from old: MKCoordinateRegion, to new: MKCoordinateRegion) -> Bool {
        let centerShift = approximateDistanceMeters(from: old.center, to: new.center)
        let zoomDelta = abs(log(max(new.span.latitudeDelta, 0.0001) / max(old.span.latitudeDelta, 0.0001)))
        let reloadThreshold = max(new.span.latitudeDelta * 111_000 * 0.3, 250)

        return centerShift > reloadThreshold || zoomDelta > 0.28
    }

    private func sortedStops(_ stops: [TransportStop], around center: CLLocationCoordinate2D) -> [TransportStop] {
        stops.sorted { left, right in
            let leftCoordinate = CLLocationCoordinate2D(latitude: left.latitude, longitude: left.longitude)
            let rightCoordinate = CLLocationCoordinate2D(latitude: right.latitude, longitude: right.longitude)
            return approximateDistanceMeters(from: leftCoordinate, to: center)
                < approximateDistanceMeters(from: rightCoordinate, to: center)
        }
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
        
        let nearbyStops = sortedStops(await offlineDatabase.findStops(
            latitude: center.latitude,
            longitude: center.longitude,
            maxDistance: maxDistance
        ), around: center)
        
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
                self.stops = sortedStops(fetchedStops, around: center)
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
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await loadStopsForRegion(region)
        }
    }

    @MainActor
    private func scheduleVehicleLoad(for region: MKCoordinateRegion, delay: Duration = .milliseconds(650)) {
        vehiclesLoadTask?.cancel()
        vehiclesLoadTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await loadVehicles(for: region)
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
                focusCamera(on: leg.coordinates, fallback: vehicle.currentLocation)
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

// MARK: - Offline Banner

private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.caption.bold())
            Text("Offline — showing cached data")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "#8A8A8E"), in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

// MARK: - Events Card

private struct EventsCard: View {
    let event: Event
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title3)
                .foregroundStyle(Color(hex: "#6B4E9E"))

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(event.location) · \(event.date.formatted(.dateTime.hour().minute())) — expect delays nearby")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .contentShape(Rectangle())
            }
        }
        .padding(14)
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}

// MARK: - Journey Planner Sheet

struct JourneyPlannerSheet: View {
    let transportService: TransportService
    let routeService: RouteService
    let onRouteSelected: (Route) -> Void

    @State private var fromQuery = ""
    @State private var toQuery = ""
    @State private var fromStop: TransportStop?
    @State private var toStop: TransportStop?
    @State private var fromResults: [TransportStop] = []
    @State private var toResults: [TransportStop] = []
    @State private var isSearchingFrom = false
    @State private var isSearchingTo = false
    @State private var route: Route?
    @State private var isPlanning = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    stopPicker(
                        label: "From",
                        query: $fromQuery,
                        selected: $fromStop,
                        results: $fromResults,
                        isSearching: $isSearchingFrom,
                        icon: "circle.fill",
                        iconColor: Color(hex: "#00A550")
                    )

                    stopPicker(
                        label: "To",
                        query: $toQuery,
                        selected: $toStop,
                        results: $toResults,
                        isSearching: $isSearchingTo,
                        icon: "mappin.circle.fill",
                        iconColor: Color(hex: "#C41E3A")
                    )

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let route {
                        routeResultView(route)
                    }

                    Button {
                        Task { await planJourney() }
                    } label: {
                        HStack {
                            if isPlanning {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            }
                            Text(isPlanning ? "Planning…" : "Plan Route")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(canPlan ? Color.accentColor : Color.secondary.opacity(0.3), in: .rect(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .disabled(!canPlan || isPlanning)
                }
                .padding(20)
            }
            .navigationTitle("Plan Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var canPlan: Bool { fromStop != nil && toStop != nil }

    private func stopPicker(
        label: String,
        query: Binding<String>,
        selected: Binding<TransportStop?>,
        results: Binding<[TransportStop]>,
        isSearching: Binding<Bool>,
        icon: String,
        iconColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)

                if let stop = selected.wrappedValue {
                    HStack {
                        Text(stop.name)
                            .font(.subheadline.bold())
                            .fontDesign(.rounded)
                        Spacer()
                        Button {
                            selected.wrappedValue = nil
                            query.wrappedValue = ""
                            results.wrappedValue = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
                } else {
                    TextField(label, text: query)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
                        .onChange(of: query.wrappedValue) { _, q in
                            Task { await searchStops(query: q, results: results, isSearching: isSearching) }
                        }
                }
            }

            if !results.wrappedValue.isEmpty && selected.wrappedValue == nil {
                VStack(spacing: 0) {
                    ForEach(results.wrappedValue.prefix(5)) { stop in
                        Button {
                            selected.wrappedValue = stop
                            query.wrappedValue = stop.name
                            results.wrappedValue = []
                        } label: {
                            HStack {
                                Image(systemName: "tram.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Text(stop.name)
                                    .font(.subheadline)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        if stop.id != results.wrappedValue.prefix(5).last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
            }
        }
    }

    private func routeResultView(_ route: Route) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Route")
                    .font(.headline)
                Spacer()
                let mins = Int(route.totalDuration / 60)
                Text("\(mins) min")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(route.legs.enumerated()), id: \.offset) { _, leg in
                HStack(spacing: 10) {
                    if let line = leg.line {
                        Text(line.name ?? "?")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: line.color ?? "#666666"), in: .rect(cornerRadius: 5))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let dep = leg.departureStop {
                            Text(dep.name)
                                .font(.caption)
                                .fontDesign(.rounded)
                        }
                        if let arr = leg.arrivalStop {
                            Text("→ \(arr.name)")
                                .font(.caption)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Button {
                onRouteSelected(route)
            } label: {
                Text("Show on Map")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.15), in: .rect(cornerRadius: 12))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
    }

    private func searchStops(query: String, results: Binding<[TransportStop]>, isSearching: Binding<Bool>) async {
        guard query.count >= 2 else { results.wrappedValue = []; return }
        isSearching.wrappedValue = true
        defer { isSearching.wrappedValue = false }
        results.wrappedValue = (try? await transportService.searchLocations(query: query)) ?? []
    }

    private func planJourney() async {
        guard let from = fromStop, let to = toStop else { return }
        isPlanning = true
        errorMessage = nil
        route = nil
        defer { isPlanning = false }
        do {
            route = try await routeService.planRoute(start: from, end: to, mode: .subway)
        } catch {
            errorMessage = "Couldn't plan route — check your connection and try again."
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
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(vehicle.line?.displayName ?? "?")
            .font(.system(size: isSelected ? 12 : 10, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, isSelected ? 6 : 5)
            .padding(.vertical, isSelected ? 3 : 2)
            .background(vehicleColor, in: .rect(cornerRadius: 5))
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Helpers

    var vehicleColor: Color {
        if let colorHex = vehicle.line?.color, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        switch vehicle.line?.productType {
        case .tram:                      return Color(hex: "#D8232A")
        case .subway:                    return Color(hex: "#0066CC")
        case .suburbanTrain:             return Color(hex: "#008C3C")
        case .bus:                       return Color(hex: "#993399")
        case .ferry:                     return Color(hex: "#0099CC")
        case .regionalTrain:            return Color(hex: "#EC192E")
        default:                        return .gray
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
    @State private var isFavorite = false

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
                        Label("Add Favorite", systemImage: isFavorite ? "star.fill" : "star")
                    }
                    .disabled(isFavorite)
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
            .task(id: stop.id) {
                let stopId = stop.id
                let existing = try? modelContext.fetch(FetchDescriptor<Favorite>(predicate: #Predicate { $0.stopId == stopId }))
                isFavorite = !(existing?.isEmpty ?? true)
            }
        }
    }

    private func addFavorite() {
        do {
            let service = FavoritesService(modelContext: modelContext)
            try service.saveStopFavorite(name: stop.name, stop: stop)
            favoriteMessage = "Added to Favorites"
            isFavorite = true
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

    private var mockVehicle: Vehicle {
        Vehicle(
            tripId: departure.tripId,
            line: departure.line,
            direction: departure.direction,
            location: nil,
            when: nil,
            nextStopovers: nil
        )
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

                PredictionBadge(predictionService: predictionService, vehicle: mockVehicle, stop: stop)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let time = departure.displayTime {
                    Text(time, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }

                if let delay = departure.delay, delay > 0 {
                    Text("+\(delay / 60) min")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#E8641A"))
                } else if departure.cancelled == true {
                    Text("Cancelled")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#C41E3A"))
                }
            }
        }
        .opacity(departure.cancelled == true ? 0.5 : 1.0)
    }
}

private struct PredictionBadge: View {
    let predictionService: PredictionService
    let vehicle: Vehicle
    let stop: TransportStop

    @State private var info: (confidence: Double, averageDelayMinutes: Double)?

    var body: some View {
        Group {
            if let info, info.confidence >= 0.5 {
                let delayMin = Int(info.averageDelayMinutes.rounded())
                if delayMin > 1 {
                    badgeView(text: "Usually \(delayMin) min late", color: Color(hex: "#E8641A"))
                } else if info.confidence >= 0.8 {
                    badgeView(text: "Usually on time", color: Color(hex: "#00A550"))
                }
            }
        }
        .onAppear {
            info = predictionService.predictionInfo(for: vehicle, at: stop)
        }
    }

    private func badgeView(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: .rect(cornerRadius: 4))
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
        .presentationDetents([.height(160)])
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
