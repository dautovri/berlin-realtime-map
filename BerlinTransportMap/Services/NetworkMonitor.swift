import Network
import Observation
import SwiftUI

@MainActor
@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private nonisolated(unsafe) var monitorTask: Task<Void, Never>?

    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    init() {
        let stream = AsyncStream<NWPath> { continuation in
            monitor.pathUpdateHandler = { path in
                continuation.yield(path)
            }
            monitor.start(queue: .global(qos: .utility))
            continuation.onTermination = { [weak self] _ in
                self?.monitor.cancel()
            }
        }
        monitorTask = Task { [weak self] in
            for await path in stream {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }

    deinit {
        monitorTask?.cancel()
    }
}