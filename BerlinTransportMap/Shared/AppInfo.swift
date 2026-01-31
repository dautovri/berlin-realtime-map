import Foundation

struct AppInfo {
    let name: String
    let version: String
    let build: String

    static let current = AppInfo(
        name: Bundle.main.displayName ?? Bundle.main.bundleName ?? "App",
        version: Bundle.main.appVersion,
        build: Bundle.main.appBuild
    )
}

extension Bundle {
    var displayName: String? {
        infoDictionary?["CFBundleDisplayName"] as? String
    }

    var bundleName: String? {
        infoDictionary?["CFBundleName"] as? String
    }

    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
