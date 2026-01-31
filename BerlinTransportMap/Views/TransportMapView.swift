import SwiftUI
import MapKit
import UIKit

enum DataSource {
    case network
    case cache
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
    @State private var showingDepartures = false
    @State private var showingVehicleInfo = false
    @State private var showingDeveloperInfo = false
    @State private var lastLoadTime: Date?
    @State private var lastVehiclesLoadTime: Date?
    @State private var isLoadingVehicles = false
    @State private var isLiveUpdating = true
    @State private var favoritesService: FavoritesService?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastLocationUpdate = Date.distantPast
    @State private var pollingInterval: TimeInterval = 5.0
    @State private var dataSource: DataSource = .network
    @State private var cacheAge: TimeInterval?
    @State private var showingCacheInfo = false
    @State private var events: [Event] = []
    @State private var selectedEvent: Event?
    @State private var showingEventDetails = false

    @State private var route: Route?
    @State private var routeAccentColor: Color = .blue
    @State private var pollingTimer: Timer?

    @State private var showingFavorites = false
    @State private var showingAbout = false
    @State private var showingHelp = false
    @State private var showingSettings = false
    @State private var showingOfflineMode = false

    private let services = ServiceContainer.shared

    var isOffline: Bool { !services.networkMonitor.isConnected }

    private var isZoomedIn: Bool {
        guard let region = currentRegion else { return false }
        return region.span.latitudeDelta <= 0.02
    }

    @MapContentBuilder
    private var mapContent: some MapContent {
        UserAnnotation()
        stopAnnotations
        vehicleAnnotations
        routeOverlay
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
            }
        }
    }

    @MapContentBuilder
    private var vehicleAnnotations: some MapContent {
        ForEach(vehicles) { vehicle in
            vehicleAnnotation(for: vehicle)
        }
    }

    @MapContentBuilder
    private func vehicleAnnotation(for vehicle: Vehicle) -> some MapContent {
        if let coordinate = vehicle.currentLocation {
            let title = vehicle.line?.displayName ?? "?"
            Annotation(title, coordinate: coordinate) {
                LiveVehicleMarkerView(vehicle: vehicle, isSelected: vehicle.id == selectedVehicle?.id)
                    .onTapGesture {
                        selectedVehicle = vehicle
                        showingVehicleInfo = true
                    }
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
        return dataSource == .cache ? "clock.arrow.circlepath" : "wifi"
    }

    private var cacheStatusText: String {
        if !services.networkMonitor.isConnected {
            return "Offline"
        }
        return dataSource == .cache ? "Cached" : "Live"
    }

    private var cacheBadgeColor: Color {
        if !services.networkMonitor.isConnected {
            return Color.red.opacity(0.9)
        }
        return dataSource == .cache ? Color.orange.opacity(0.9) : Color.green.opacity(0.9)
    }

    var body: some View {
        contentWithSheets
            .task {
                if let region = currentRegion {
                    await loadStopsForRegion(region)
                    await loadVehicles(for: region)
                }
            }
            .task {
                while !Task.isCancelled {
                    pollingInterval = Date().timeIntervalSince(lastLocationUpdate) < 60 ? 3 : 10
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            .onChange(of: pollingInterval) { _, _ in
                startPolling()
            }
            .onAppear {
                startPolling()
            }
            .onDisappear {
                pollingTimer?.invalidate()
            }
            .onChange(of: services.networkMonitor.isConnected) { _, isConnected in
                if !isConnected {
                    showingOfflineMode = true
                }
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
                        Task {
                            await loadStopsForRegion(newRegion)
                        }
                    }
                } else {
                    Task {
                        await loadStopsForRegion(newRegion)
                    }
                }
            }
            .navigationTitle("Berlin Transport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        print("TransportMapView: Opening favorites sheet")
                        showingFavorites = true
                    } label: {
                        Label("Favorites", systemImage: "star")
                    }
                    Spacer()
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        Button {
                            showingHelp = true
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                        Button {
                            showingAbout = true
                        } label: {
                            Label("About", systemImage: "info.circle")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .toolbarBackground(.visible, for: .bottomBar)
        }
    }

    private var contentWithSheets: some View {
        mainContent
            .sheet(isPresented: $showingDepartures) {
                departuresSheet
            }
            .sheet(isPresented: $showingVehicleInfo) {
                vehicleInfoSheet
            }
            .sheet(isPresented: $showingAbout) {
                BerlinTransportMapAboutView()
            }
            .sheet(isPresented: $showingHelp) {
                BerlinTransportMapHelpCenterView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingFavorites) {
                favoritesSheet
            }
            .sheet(isPresented: $showingDeveloperInfo) {
                DeveloperInfoSheet()
                    .presentationDetents([.medium])
            }
    }

    @ViewBuilder
    private var departuresSheet: some View {
        if let stop = selectedStop {
            RESTDeparturesSheet(
                stop: stop,
                departures: restDepartures,
                isLoading: isLoadingDepartures,
                predictionService: services.predictionService,
                onClose: {
                    showingDepartures = false
                    selectedStop = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var vehicleInfoSheet: some View {
        if let vehicle = selectedVehicle {
            VehicleInfoSheet(
                vehicle: vehicle,
                onClose: {
                    showingVehicleInfo = false
                    selectedVehicle = nil
                },
                onShowRoute: {
                    Task {
                        await loadRoute(for: vehicle)
                    }
                }
            )
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
                showingFavorites = false
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
        .foregroundColor(.white)
        .clipShape(Capsule())
    }



    @MainActor
    private func openDepartures(for stop: TransportStop) {
        selectedStop = stop
        showingDepartures = true
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

    @MainActor
    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { _ in
            Task { @MainActor in
                if isLiveUpdating && scenePhase == .active, let region = currentRegion {
                    await loadVehicles(for: region)
                }
            }
        }
    }

    private func centerOnUserLocation() {
        if locationManager.isAuthorized, let location = locationManager.location {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: Self.nearbySpan
                    )
                )
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
            if !services.networkMonitor.isConnected {
                if let cachedVehicles = services.cacheService.getVehicles(forBoundingBox: north, west: west, south: south, east: east, duration: 30) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.vehicles = cachedVehicles
                    }
                    dataSource = .cache
                    cacheAge = services.cacheService.age(of: services.cacheService.getVehiclesCacheKey(forBoundingBox: north, west: west, south: south, east: east, duration: 30))
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.vehicles = []
                    }
                }
                return
            }

            let fetchedVehicles = try await services.vehicleRadarService.fetchVehicles(
                north: north,
                west: west,
                south: south,
                east: east,
                duration: 30
            )

            services.cacheService.setVehicles(fetchedVehicles, forBoundingBox: north, west: west, south: south, east: east, duration: 30)

            withAnimation(.easeInOut(duration: 0.3)) {
                self.vehicles = fetchedVehicles
            }
        } catch {
            errorMessage = "Failed to load vehicles: \(error.localizedDescription)"
            if let cachedVehicles = services.cacheService.getVehicles(forBoundingBox: north, west: west, south: south, east: east, duration: 30) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.vehicles = cachedVehicles
                }
                dataSource = .cache
                cacheAge = services.cacheService.age(of: services.cacheService.getVehiclesCacheKey(forBoundingBox: north, west: west, south: south, east: east, duration: 30))
            }
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

        do {
            let center = region.center
            let maxDistance = Int(region.span.latitudeDelta * 111_000)

            // Check cache first - only fetch from network if cache is expired or missing
            let cacheKey = services.cacheService.getStopsCacheKey(forLocation: center.latitude, longitude: center.longitude, maxDistance: maxDistance)
            
            var fetchedStops: [TransportStop]?
            
            // Check for preloaded stops first
            if let preloadedStops = services.predictiveLoader.getPreloadedStops(for: center, maxDistance: maxDistance) {
                fetchedStops = preloadedStops
                dataSource = .cache
                cacheAge = 0
                print("Using preloaded stops data")
            } else if let cachedStops = services.cacheService.getStops(forLocation: center.latitude, longitude: center.longitude, maxDistance: maxDistance) {
                // Cache hit - use cached data
                fetchedStops = cachedStops
                dataSource = .cache
                cacheAge = services.cacheService.age(of: cacheKey)
                print("Using cached stops (age: \(formattedAge(cacheAge ?? 0)))")
            }
            
            // Only fetch from network if we don't have cached data
            if fetchedStops == nil {
                print("Cache miss - fetching stops from network")
                dataSource = .network
                cacheAge = nil
                
                fetchedStops = try await services.transportService.queryNearbyStops(
                    latitude: center.latitude,
                    longitude: center.longitude,
                    maxDistance: min(maxDistance, 5000),
                    maxLocations: 100
                )
                
                // Save to cache for next time
                services.cacheService.setStops(
                    fetchedStops!,
                    forLocation: center.latitude,
                    longitude: center.longitude,
                    maxDistance: min(maxDistance, 5000)
                )
            }
            
            self.stops = fetchedStops!
        } catch {
            errorMessage = error.localizedDescription
            // Try to use cache as fallback
            if let cachedStops = services.cacheService.getStops(forLocation: region.center.latitude, longitude: region.center.longitude, maxDistance: Int(region.span.latitudeDelta * 111_000)) {
                self.stops = cachedStops
                dataSource = .cache
                cacheAge = services.cacheService.age(of: services.cacheService.getStopsCacheKey(forLocation: region.center.latitude, longitude: region.center.longitude, maxDistance: Int(region.span.latitudeDelta * 111_000)))
            } else {
                self.stops = []
            }
        }

        isLoading = false
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

// MARK: - Supporting Views

struct LiveVehicleMarkerView: View {
    let vehicle: Vehicle
    let isSelected: Bool

    var body: some View {
        ZStack {
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
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
            when: nil
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
            }

            Divider()

            HStack(spacing: 20) {
                if let coord = vehicle.currentLocation {
                    VStack(spacing: 2) {
                        Text("Lat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.5f", coord.latitude))
                            .font(.caption.monospaced())
                    }
                    VStack(spacing: 2) {
                        Text("Lon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.5f", coord.longitude))
                            .font(.caption.monospaced())
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Speed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let speed = vehicle.speedKPH, speed > 0 {
                        Text(String(format: "%.0f km/h", speed))
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text("---")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
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
                            .foregroundColor(.blue)

                        VStack(alignment: .center, spacing: 4) {
                            Text("Berlin Transport Map")
                                .font(.headline)
                            Text("Live vehicle radar and nearby stops")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("by \(developerName)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
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
                                        .foregroundColor(.primary)
                                    Text("GitHub")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundColor(.primary)
                        }

                        if let linkedInURL {
                            Link(destination: linkedInURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundColor(.primary)
                                    Text("LinkedIn")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundColor(.primary)
                        }

                        if let twitterURL {
                            Link(destination: twitterURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundColor(.primary)
                                    Text("X (Twitter)")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundColor(.primary)
                        }

                        if let emailURL {
                            Link(destination: emailURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .foregroundColor(.primary)
                                    Text("Email")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundColor(.primary)
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
                                    .foregroundColor(.blue)
                                Text("Visit Portfolio")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .foregroundColor(.primary)
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
