import Foundation
import CoreLocation
import Observation

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

    /// Propagate a city change to all city-aware services.
    func updateCity(_ city: CityConfig) {
        cityManager.selectCity(city)
        transportService.updateCity(city)
        routeService.updateCity(city)
        Task {
            await vehicleRadarService.updateCity(city)
        }
    }
}
