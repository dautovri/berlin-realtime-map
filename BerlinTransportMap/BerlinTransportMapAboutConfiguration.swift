import Foundation

/// Configuration for the AboutKit about screen
struct BerlinTransportMapAboutConfiguration {
    let appName = "BerlinTransportMap"
    let appID = "1234567890"  // Replace with actual App Store ID
    let developerName = "Ruslan Dautov"
    let developerEmail = "dautovri@outlook.com"
    let websiteURL = URL(string: "https://dautovri.com")
    let githubURL = URL(string: "https://github.com/dautovri/berlin-realtime-map")
    let linkedInURL = URL(string: "https://linkedin.com/in/dautovri")
    let twitterURL = URL(string: "https://x.com/dautovri")
    let privacyPolicyURL = URL(string: "https://dautovri.com/privacy")
    let termsOfUseURL = URL(string: "https://dautovri.com/terms")
    
    let appDescription = "Real-time Berlin public transport map showing live vehicle positions and departures."
    let appVersion = Bundle.main.appVersion
    let appBuild = Bundle.main.appBuild
}

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
