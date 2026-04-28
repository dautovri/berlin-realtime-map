import Foundation
import CoreLocation
import Observation
import WidgetKit

@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()

    let cityManager: CityManager
    let transportService: TransportService
    let routeService: RouteService
    let vehicleRadarService: VehicleRadarService
    let cacheService: CacheService
    let predictionService: PredictionService
    let networkMonitor: NetworkMonitor
    let eventsService: EventsService
    let predictiveLoader: PredictiveLoader

    private init() {
        let cityManager = CityManager()
        let city = cityManager.currentCity
        self.cityManager = cityManager
        self.transportService = TransportService(city: city)
        self.routeService = RouteService(city: city)
        self.vehicleRadarService = VehicleRadarService(city: city)
        self.cacheService = CacheService()
        self.predictionService = PredictionService()
        self.networkMonitor = NetworkMonitor()
        self.eventsService = EventsService()
        self.predictiveLoader = PredictiveLoader(
            transportService: transportService,
            vehicleRadarService: vehicleRadarService,
            cacheService: cacheService,
            networkMonitor: networkMonitor
        )
    }

    /// Propagate a city change to every city-aware component.
    /// Awaits the radar update + offline DB switch before returning so callers
    /// can rely on services pointing at the new city when this resolves —
    /// no race window where a fetch lands on the old baseURL.
    func updateCity(_ city: CityConfig) async {
        // Order matters: cityManager.currentCity is the source of truth observed by views.
        // Update services first (so they're ready when views react), then publish the change.
        transportService.updateCity(city)
        routeService.updateCity(city)
        predictiveLoader.clearPreloadedData()
        await vehicleRadarService.updateCity(city)
        await OfflineStopsDatabase.shared.switchCity(city)
        // EventsService has no per-city endpoint; gating happens at the call site
        // via cityManager.currentCity.supportsEvents.
        cityManager.selectCity(city)
        // Widget timelines may reference stops in the previous city; force a refresh.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
