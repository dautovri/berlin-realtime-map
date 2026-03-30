import Foundation

enum Env {
    static var overrideBaseURL: String? {
        ProcessInfo.processInfo.environment["VBB_BASE_URL"]
    }
}
