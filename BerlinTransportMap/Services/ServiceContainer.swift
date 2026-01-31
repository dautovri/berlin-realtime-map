import Foundation
import CoreLocation

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    let transportService: TransportService
    let routeService: RouteService
    let vehicleRadarService: VehicleRadarService
    let cacheService: CacheService
    let predictionService: PredictionService
    let networkMonitor: NetworkMonitor
    let eventsService: EventsService
    let predictiveLoader: PredictiveLoader
    
    private init() {
        self.transportService = TransportService()
        self.routeService = RouteService()
        self.vehicleRadarService = VehicleRadarService()
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
}
