import Foundation

// MARK: - StoreKit Product IDs
/// StoreKit configuration for optional monetization features.
///
/// Note: This app intentionally derives product identifiers from the app's bundle identifier.
/// In App Store Connect, create consumable products that match these IDs.
enum StoreKitConfiguration {
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.example.app"
    }

    /// Consumable Tip Jar product identifiers.
    ///
    /// Suggested App Store Connect setup (Consumable):
    /// - <bundleID>.tip.small
    /// - <bundleID>.tip.medium
    /// - <bundleID>.tip.large
    static var tipProductIDs: [String] {
        [
            "\(bundleIdentifier).tip.small",
            "\(bundleIdentifier).tip.medium",
            "\(bundleIdentifier).tip.large",
        ]
    }
}
