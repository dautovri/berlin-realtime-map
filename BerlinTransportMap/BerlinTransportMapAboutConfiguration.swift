import Foundation

/// Configuration for the AboutKit about screen
struct BerlinTransportMapAboutConfiguration {
    let appName = AppInfo.current.name
    /// Set this once the app has an App Store ID (e.g. "1234567890").
    /// When nil, App Store review/share rows are hidden.
    let appStoreID: String? = nil
    let developerName = "Ruslan Dautov"
    let developerEmail = "dautovri@outlook.com"
    let websiteURL = URL(string: "https://dautovri.com")
    let githubURL = URL(string: "https://github.com/dautovri/berlin-realtime-map")
    let linkedInURL = URL(string: "https://linkedin.com/in/dautovri")
    let twitterURL = URL(string: "https://x.com/dautovri")
    let privacyPolicyURL = URL(string: "https://dautovri.com/privacy")
    let termsOfUseURL = URL(string: "https://dautovri.com/terms")
    
    let appDescription = "Real-time Berlin public transport map showing live vehicle positions and departures."
    let appVersion = AppInfo.current.version
    let appBuild = AppInfo.current.build

    var appStorePageURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    var writeReviewURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    var shareURL: URL? {
        appStorePageURL ?? websiteURL ?? githubURL
    }

    var issuesURL: URL? {
        githubURL?.appendingPathComponent("issues")
    }
}
