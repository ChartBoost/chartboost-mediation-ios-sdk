// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import SystemConfiguration

enum NetworkStatus: Int {
    case unknown = -1
    case notReachable = 0
    case reachableViaWiFi = 1
    case reachableViaWWAN = 2
}

protocol NetworkStatusProviding {
    var status: NetworkStatus { get }
}

protocol Reachability: NetworkStatusProviding {
    @discardableResult func startNotifier() -> Bool
    func stopNotifier()
}

final class ReachabilityMonitor: Reachability {
    // MARK: - Lifecycle

    class func make() -> Reachability {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
        return ReachabilityMonitor(networkReachability: defaultRouteReachability)
    }

    init(networkReachability: SCNetworkReachability?) {
        self.networkReachability = networkReachability
        updateFlags()
    }

    // MARK: - Properties

    var status: NetworkStatus {
       guard let flags else {
           return .notReachable
       }
       var status: NetworkStatus = .unknown
       if !flags.contains(.connectionRequired) {
           // If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
           status = .reachableViaWiFi
       }
       if flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic) {
           // ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
           if !flags.contains(.interventionRequired) {
               // ... and no [user] intervention is needed...
               status = .reachableViaWiFi
           }
       }
       if flags.contains(.isWWAN) {
           // ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
           status = .reachableViaWWAN
       }
       return status
    }

    // MARK: - Methods

    @discardableResult
    func startNotifier() -> Bool {
        guard !notifierIsRunning, let networkReachability else {
            return false
        }

        let weakReachability = WeakReachability(reachability: self)
        let opaqueWeakReachability = Unmanaged<WeakReachability>.passUnretained(weakReachability).toOpaque()

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(opaqueWeakReachability),
            retain: { info in
                let unmanagedWeakReachability = Unmanaged<WeakReachability>.fromOpaque(info)
                _ = unmanagedWeakReachability.retain()
                return UnsafeRawPointer(unmanagedWeakReachability.toOpaque())
            },
            release: { info in
                let unmanagedWeakReachability = Unmanaged<WeakReachability>.fromOpaque(info)
                unmanagedWeakReachability.release()
            },
            copyDescription: { info in
                let unmanagedWeakReachability = Unmanaged<WeakReachability>.fromOpaque(info)
                let weakReachability = unmanagedWeakReachability.takeUnretainedValue()
                let description = weakReachability.reachability.map(String.init(describing:)) ?? "nil"
                return Unmanaged.passRetained(description as CFString)
            }
        )
        guard SCNetworkReachabilitySetCallback(networkReachability, reachabilityCallback, &context) else {
            stopNotifier()
            return false
        }
        guard SCNetworkReachabilitySetDispatchQueue(networkReachability, queue) else {
            stopNotifier()
            return false
        }
        notifierIsRunning = true
        return true
    }

    func stopNotifier() {
        defer { notifierIsRunning = false }
        guard let networkReachability else {
            return
        }
        SCNetworkReachabilitySetCallback(networkReachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(networkReachability, nil)
    }

    // MARK: - Private

    private let networkReachability: SCNetworkReachability?
    private let queue = DispatchQueue(label: "com.chartboost.mediation.ReachabilityMonitor.queue")
    private var notifierIsRunning = false

    private let reachabilityCallback: SCNetworkReachabilityCallBack = { _, flags, info in
        guard let info else { return }
        let weakReachability = Unmanaged<WeakReachability>.fromOpaque(info).takeUnretainedValue()
        weakReachability.reachability?.flags = flags
    }

    private var flags: SCNetworkReachabilityFlags?

    private func updateFlags() {
        guard let networkReachability else {
            return
        }
        queue.sync {
            var flags = SCNetworkReachabilityFlags()
            guard SCNetworkReachabilityGetFlags(networkReachability, &flags) else {
                return stopNotifier()
            }
            self.flags = flags
        }
    }
}

private class WeakReachability {
    weak var reachability: ReachabilityMonitor?

    init(reachability: ReachabilityMonitor) {
        self.reachability = reachability
    }
}
