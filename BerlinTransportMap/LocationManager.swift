import Foundation
import CoreLocation
import UIKit

/// Observable location manager for tracking user location
@Observable
@MainActor
final class LocationManager: NSObject {
    private let manager = CLLocationManager()

    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
        
        // Add observers for app lifecycle to optimize battery
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func startUpdating() {
        // Prefer one-shot location to avoid continuous tracking / battery drain.
        manager.requestLocation()
    }

    func stopUpdating() {
        // No-op for one-shot requests.
    }
    
    @objc private func appWillEnterForeground() {
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    @objc private func appDidEnterBackground() {
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last
        Task { @MainActor in
            self.location = lastLocation
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let shouldStart = status == .authorizedWhenInUse || status == .authorizedAlways
        Task { @MainActor in
            self.authorizationStatus = status
            if shouldStart {
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
