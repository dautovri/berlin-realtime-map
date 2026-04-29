import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Cancel any in-flight map snapshots to prevent the process from lingering
        // after the user quits (macOS App Review guideline 2.4.5(iii))
        MapTilePreloader.shared.cancelAll()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Show notification banner even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap: extract stopId from userInfo and open departure board.
    /// Forwards `cityId` (added in v1.7) so the receiver can switch cities before
    /// fetching — otherwise a Munich alert opens Berlin's API with a Munich stopId.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let stopId = userInfo["stopId"] as? String,
           let stopName = userInfo["stopName"] as? String,
           !stopId.isEmpty {
            let cityId = (userInfo["cityId"] as? String) ?? "berlin"
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .showDeparturesForStop,
                    object: nil,
                    userInfo: ["stopId": stopId, "stopName": stopName, "cityId": cityId]
                )
            }
        }
        completionHandler()
    }
}