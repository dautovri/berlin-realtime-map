import Foundation

enum Env {
    static var overrideBaseURL: String? {
        ProcessInfo.processInfo.environment["VBB_BASE_URL"]
    }

    /// Resolved API base URL: environment override > current city config
    static func resolvedBaseURL(for city: CityConfig) -> String {
        overrideBaseURL ?? city.apiBaseURL
    }
}
