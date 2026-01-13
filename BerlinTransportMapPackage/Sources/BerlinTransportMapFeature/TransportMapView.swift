import SwiftUI
import MapKit

public struct TransportMapView: View {
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
    @State private var lastLoadTime: Date?
    @State private var lastVehiclesLoadTime: Date?
    @State private var isLoadingVehicles = false
    @State private var isLiveUpdating = true
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var routeColor: Color = .blue
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // Show user location
                UserAnnotation()
                
                // Display stops as markers
                ForEach(stops) { stop in
                    Annotation(
                        stop.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: stop.latitude,
                            longitude: stop.longitude
                        ),
                        anchor: .center
                    ) {
                        StopMarkerView(stop: stop, isSelected: selectedStop?.id == stop.id)
                            .onTapGesture {
                                selectedStop = stop
                                Task {
                                    await loadDepartures(for: stop)
                                }
                                showingDepartures = true
                            }
                    }
                }
                
                // Display real-time vehicles
                ForEach(vehicles) { vehicle in
                    if let coord = vehicle.currentLocation {
                        Annotation(
                            vehicle.line?.displayName ?? "?",
                            coordinate: coord,
                            anchor: .center
                        ) {
                            LiveVehicleMarkerView(vehicle: vehicle, isSelected: selectedVehicle?.id == vehicle.id)
                                .onTapGesture {
                                    selectedVehicle = vehicle
                                    showingVehicleInfo = true
                                }
                        }
                    }
                }
                
                // Display route polyline
                if !routeCoordinates.isEmpty {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(routeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onMapCameraChange { context in
                currentRegion = context.region
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                Task {
                    await loadStopsForRegion(context.region)
                }
            }
            
            VStack {
                // Loading indicator
                if isLoading {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading...")
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
                
                // Error message
                if let error = errorMessage {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(error)
                            .foregroundStyle(.white)
                            .font(.subheadline)
						
                        HStack {
                            Button("Dismiss") {
                                errorMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.9))
						
                            if let region = currentRegion {
                                Button("Retry") {
                                    Task {
                                        await loadStopsForRegion(region)
                                        if isLiveUpdating {
                                            await loadVehicles(for: region)
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.white)
                            }
                        }
                    }
                    .padding()
                    .background(.red.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Live indicator
                    Button {
                        isLiveUpdating.toggle()
                        if isLiveUpdating, let region = currentRegion {
                            Task { await loadVehicles(for: region) }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isLiveUpdating ? .green : .gray)
                                .frame(width: 8, height: 8)
                            Text(isLiveUpdating ? "LIVE" : "PAUSED")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Location button
                    Button {
                        centerOnUserLocation()
                    } label: {
                        Image(systemName: locationManager.isAuthorized ? "location.fill" : "location")
                            .font(.system(size: 20))
                            .foregroundStyle(locationManager.isAuthorized ? .blue : .secondary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            // Center on user location when first obtained
            if !hasInitializedLocation, let location = newLocation {
                hasInitializedLocation = true
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: Self.nearbySpan
                        )
                    )
                }
            }
        }
        .sheet(isPresented: $showingDepartures) {
            if let stop = selectedStop {
                RESTDeparturesSheet(
                    stop: stop,
                    departures: restDepartures,
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
        .task {
            // Initial load
            if let region = currentRegion {
                await loadStopsForRegion(region)
                await loadVehicles(for: region)
            }
        }
        .task {
            // Auto-refresh vehicles every 5 seconds
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
    private func loadRoute(for vehicle: Vehicle) async {
        do {
            if let tripRoute = try await radarService.fetchTripRoute(tripId: vehicle.tripId) {
                // Use the routeCoordinates from the trip (extracted from polyline Point features)
                let coordinates = tripRoute.routeCoordinates
                
                // Set route color based on vehicle line
                let lineColor = Color(hex: vehicle.line?.color ?? "#007AFF")
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.routeCoordinates = coordinates
                    self.routeColor = lineColor
                }

            }
        } catch {
			errorMessage = "Failed to load route: \(error.localizedDescription)"
        }
    }
    
    private func clearRoute() {
        withAnimation(.easeInOut(duration: 0.3)) {
            routeCoordinates = []
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
        // Debounce requests
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
            let maxDistance = Int(region.span.latitudeDelta * 111_000) // Approximate meters
            
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
            // Use REST API for departures with VBB-compatible stop ID
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
            // Pulse animation ring
            Circle()
                .stroke(vehicleColor.opacity(0.3), lineWidth: isSelected ? 4 : 3)
                .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)
            
            // Main vehicle circle
            Circle()
                .fill(vehicleColor)
                .frame(width: isSelected ? 32 : 28, height: isSelected ? 32 : 28)
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 4 : 3, x: 0, y: 2)
            
            // Line label
            Text(vehicle.line?.displayName ?? "?")
                .font(.system(size: isSelected ? 10 : 9, weight: .bold))
                .foregroundStyle(Color(hex: vehicle.line?.foregroundColor ?? "#FFFFFF"))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
    
    var vehicleColor: Color {
        // Use API color or default BVG colors
        if let colorHex = vehicle.line?.color, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        // Fallback to product type colors
        switch vehicle.line?.productType {
        case .tram:
            return Color(hex: "#D8232A") // BVG Tram red
        case .subway:
            return Color(hex: "#0066CC") // BVG U-Bahn blue
        case .suburbanTrain:
            return Color(hex: "#008C3C") // BVG S-Bahn green
        case .bus:
            return Color(hex: "#993399") // BVG Bus purple
        case .ferry:
            return Color(hex: "#0099CC") // BVG Ferry cyan
        case .regionalTrain:
            return Color(hex: "#EC192E") // DB Regional red
        default:
            return .gray
        }
    }
}

struct StopMarkerView: View {
    let stop: TransportStop
    let isSelected: Bool
    
    // Traditional German Haltestelle colors
    private let haltestelleYellow = Color(hex: "#FFD800")
    private let haltestelleGreen = Color(hex: "#006F3C")
    
    var body: some View {
        ZStack {
            // Yellow background circle
            Circle()
                .fill(haltestelleYellow)
                .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 4 : 2, y: 1)
            
            // Green border
            Circle()
                .stroke(haltestelleGreen, lineWidth: isSelected ? 3 : 2)
                .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
            
            // Green "H" for Haltestelle
            Text("H")
                .font(.system(size: isSelected ? 16 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(haltestelleGreen)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct StatView: View {
    let icon: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text("\(count)")
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80)
    }
}

struct RESTDeparturesSheet: View {
    let stop: TransportStop
    let departures: [RESTDeparture]
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
                        RESTDepartureRow(departure: departure)
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Line badge
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
            
            // Destination
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
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                if let time = departure.displayTime {
                    Text(time, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
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

struct DeparturesSheet: View {
    let stop: TransportStop
    let departures: [TransportDeparture]
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
                        DepartureRow(departure: departure)
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

struct DepartureRow: View {
    let departure: TransportDeparture
    
    var body: some View {
        HStack(spacing: 12) {
            // Line badge
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: departure.line.color))
                    .frame(width: 44, height: 28)
                
                Text(departure.line.displayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: departure.line.foregroundColor))
            }
            
            // Destination
            VStack(alignment: .leading, spacing: 2) {
                Text(departure.destination)
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
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                if let time = departure.displayTime {
                    Text(time, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if let delay = departure.delayMinutes, delay > 0 {
                    Text("+\(delay) min")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if departure.isCancelled {
                    Text("Cancelled")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .opacity(departure.isCancelled ? 0.5 : 1.0)
    }
}

// MARK: - Vehicle Info Sheet

struct VehicleInfoSheet: View {
    let vehicle: Vehicle
    let onClose: () -> Void
    let onShowRoute: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with line badge
            HStack(spacing: 12) {
                // Line badge
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
            
            // Show route button
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

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
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
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
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
