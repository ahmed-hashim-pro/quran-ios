//
//  NetworkConnection.swift
//

import Foundation
import Network

/// The network the device uses now, which quran_android checks before downloading audio.
public protocol NetworkConnection: Sendable {
    func isOnWiFi() async -> Bool
}

/// Watches the network from creation, so the answer is current by the time anyone asks.
public final class DefaultNetworkConnection: NetworkConnection, @unchecked Sendable {
    // MARK: Lifecycle

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update(path)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: Public

    /// Like Android's check, Wi-Fi only: a wired or cellular connection, or none, isn't Wi-Fi.
    public func isOnWiFi() async -> Bool {
        let path = await currentPath()
        return path.status == .satisfied && path.usesInterfaceType(.wifi)
    }

    // MARK: Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.quran.network-connection")

    // Read and written on `queue` only.
    private var path: NWPath?
    private var waitingForPath: [CheckedContinuation<NWPath, Never>] = []

    private func update(_ path: NWPath) {
        self.path = path
        let waiting = waitingForPath
        waitingForPath = []
        waiting.forEach { $0.resume(returning: path) }
    }

    /// The monitor reports its first path shortly after starting, so an early question waits for it.
    private func currentPath() async -> NWPath {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                if let path {
                    continuation.resume(returning: path)
                } else {
                    waitingForPath.append(continuation)
                }
            }
        }
    }
}
