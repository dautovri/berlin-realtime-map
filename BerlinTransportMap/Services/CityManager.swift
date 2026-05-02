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
        // Restore the saved city, but fall back to Berlin if the saved city's
        // backend has been disabled (e.g. supportsDepartures flipped to false in
        // a later release). Otherwise the user lands on a city whose primary
        // feature 500s on every interaction.
        if let savedId = UserDefaults.standard.string(forKey: Self.selectedCityKey),
           let city = CityConfig.city(forId: savedId),
           city.supportsDepartures {
            self.currentCity = city
        } else {
            self.currentCity = .berlin
        }
    }

    /// Cities the user can pick today. Filters out cities whose backend is
    /// currently broken (`supportsDepartures == false`).
    var availableCities: [CityConfig] {
        CityConfig.availableCities
    }

    /// Switch to a different city.
    func selectCity(_ city: CityConfig) {
        currentCity = city
    }
}
