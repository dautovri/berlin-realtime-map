import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Cancel any in-flight map snapshots to prevent the process from lingering
        // after the user quits (macOS App Review guideline 2.4.5(iii))
        MapTilePreloader.shared.cancelAll()
    }
}