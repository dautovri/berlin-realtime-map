import SwiftUI
import MapKit

struct TransportMapView: View {
    // Berlin center as fallback
    private static let berlinCenter = CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954)
    // Small radius for initial "nearby" view (about 500m)
    private static let nearbySpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    // Wider view for when location unavailable
    private static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: berlinCenter, span: defaultSpan)
    )

    @State private var locationManager = LocationManager()
    @State private var hasInitializedLocation = false
    @State private var transportService = TransportService()
    @State private var radarService = VehicleRadarService()
    @State private var stops: [TransportStop] = []
    @State private var vehicles: [Vehicle] = []
    @State private var restDepartures: [RESTDeparture] = []
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
    @State private var routeService = RouteService()
    @State private var route: Route?
    @State private var showingRoutePlanner = false
    @State private var predictionService = PredictionService()
    @State private var favoritesService: FavoritesService?

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(stops) { stop in
                    Annotation(coordinate: CLLocationCoordinate2D(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )) {
                        StopAnnotationView(stop: stop, departures: nil)
                    }
                }

                ForEach(vehicles) { vehicle in
                    Annotation(
                        vehicle.line?.displayName ?? "?",
                        coordinate: CLLocationCoordinate2D(
                            latitude: vehicle.latitude,
                            longitude: vehicle.longitude
                        )
                    ) {
                        LiveVehicleMarkerView(vehicle: vehicle, isSelected: vehicle.id == selectedVehicle?.id)
                    }
                    .tag(vehicle.id)
                }

                if let route = route {
                    MapPolyline(coordinates: route.coordinates)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            
            // Floating buttons
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Spacer()
                    Button {
                        showingFavorites = true
                    } label: {
                        Image(systemName: "star")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.yellow)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    
                    Button {
                        showingRoutePlanner = true
                    } label: {
                        Image(systemName: "route")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingDepartures) {
            if let stop = selectedStop {
                RESTDeparturesSheet(
                    stop: stop,
                    departures: restDepartures,
                    predictionService: predictionService,
                    onClose: {
                        showingDepartures = false
                        selectedStop = nil
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingVehicleInfo) {
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
        .sheet(isPresented: $showingAbout) {
            BerlinTransportMapAboutView()
        }
        .sheet(isPresented: $showingHelp) {
            BerlinTransportMapHelpCenterView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingRoutePlanner) {
            RoutePlannerView { start, end, mode in
                Task {
                    await planRoute(start: start, end: end, mode: mode)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingFavorites) {
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
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAbout) {
            BerlinTransportMapAboutView()
        }
        .sheet(isPresented: $showingDeveloperInfo) {
            DeveloperInfoSheet()
                .presentationDetents([.medium])
        }
        .task {
            if let region = currentRegion {
                await loadStopsForRegion(region)
                await loadVehicles(for: region)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                if isLiveUpdating, let region = currentRegion {
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
    private func planRoute(start: String, end: String, mode: TransportMode) async {
        do {
            // First, find the stops by name
            let startStops = try await transportService.searchLocations(query: start, maxLocations: 1)
            let endStops = try await transportService.searchLocations(query: end, maxLocations: 1)
            
            guard let startStop = startStops.first, let endStop = endStops.first else {
                errorMessage = "Could not find stops for the given names"
                return
            }
            
            let plannedRoute = try await routeService.planRoute(start: startStop, end: endStop, mode: mode)
            self.route = plannedRoute
            showingRoutePlanner = false
            
            // Optionally zoom to route
            if let firstCoord = plannedRoute.coordinates.first {
                cameraPosition = .region(MKCoordinateRegion(center: firstCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            }
        } catch {
            errorMessage = "Failed to plan route: \(error.localizedDescription)"
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

        do {
            let fetchedVehicles = try await radarService.fetchVehicles(
                north: center.latitude + latDelta,
                west: center.longitude - lonDelta,
                south: center.latitude - latDelta,
                east: center.longitude + lonDelta,
                duration: 30
            )

            withAnimation(.easeInOut(duration: 0.3)) {
                self.vehicles = fetchedVehicles
            }
        } catch {
            errorMessage = "Failed to load vehicles: \(error.localizedDescription)"
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

            let fetchedStops = try await transportService.queryNearbyStops(
                latitude: center.latitude,
                longitude: center.longitude,
                maxDistance: min(maxDistance, 5000),
                maxLocations: 100
            )

            self.stops = fetchedStops
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func loadDepartures(for stop: TransportStop) async {
        do {
            let fetchedDepartures = try await radarService.fetchDepartures(stopId: stop.vbbStopId)
            self.restDepartures = fetchedDepartures
        } catch {
            errorMessage = "Failed to load departures: \(error.localizedDescription)"
            self.restDepartures = []
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
    let predictionService: PredictionService
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if departures.isEmpty {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
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
            location: nil
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

                if let delay = departure.delayMinutes, delay > 0 {
                    Text("+\(delay) min")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if departure.cancelled == true {
                    Text("Cancelled")
                        .font(.caption)
                        .foregroundStyle(.red)
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
        VStack(spacing: 16) {
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
            }

            Divider()

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
        .presentationDetents([.height(180)])
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

#Preview {
    TransportMapView()
}
