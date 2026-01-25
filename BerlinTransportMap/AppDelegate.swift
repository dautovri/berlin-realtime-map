import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Optimized for fast initialization
        // Defer non-critical setup to background
        DispatchQueue.global(qos: .background).async {
            // Initialize services here if needed
        }
        return true
    }

}