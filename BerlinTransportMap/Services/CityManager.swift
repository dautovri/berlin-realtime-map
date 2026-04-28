import Foundation
import Observation

/// Manages the currently selected city and persists the choice to UserDefaults.
@MainActor
@Observable
final class CityManager {
    private static let selectedCityKey = "selectedCityId"

    /// The currently active city configuration.
    var currentCity: CityConfig {
        didSet {
            UserDefaults.standard.set(currentCity.id, forKey: Self.selectedCityKey)
        }
    }

    init() {
        if let savedId = UserDefaults.standard.string(forKey: Self.selectedCityKey),
           let city = CityConfig.city(forId: savedId) {
            self.currentCity = city
        } else {
            self.currentCity = .berlin
        }
    }

    /// All available cities.
    var availableCities: [CityConfig] {
        CityConfig.allCities
    }

    /// Switch to a different city.
    func selectCity(_ city: CityConfig) {
        currentCity = city
    }
}
