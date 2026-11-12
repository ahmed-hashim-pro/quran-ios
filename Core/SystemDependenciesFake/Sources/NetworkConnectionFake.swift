//
//  NetworkConnectionFake.swift
//

import Foundation
import SystemDependencies

public final class NetworkConnectionFake: NetworkConnection, @unchecked Sendable {
    // MARK: Lifecycle

    public init(onWiFi: Bool = true) {
        self.onWiFi = onWiFi
    }

    // MARK: Public

    public var onWiFi: Bool

    public func isOnWiFi() async -> Bool {
        onWiFi
    }
}
