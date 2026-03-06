import Foundation

enum Config {
    static var apiAuthorization: [String: Any] {
        if let aid = Env.apiAid {
            return ["type": "AID", "aid": aid]
        }
        return ["type": "AID", "aid": "1Rxs112shyHLatUX4fofnmdxK"]
    }
}

enum Env {
    static var apiAid: String? {
        ProcessInfo.processInfo.environment["VBB_API_AID"]
    }
}
