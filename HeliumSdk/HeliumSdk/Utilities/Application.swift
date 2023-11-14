// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// Provides information about the application and is used for depedency injection purposes.
protocol Application {
    /// The app’s current state, or that of its most active scene.
    var state: UIApplication.State { get }
    func addObserver(_ observer: ApplicationStateObserver)
}

@objc protocol ApplicationStateObserver {}

@objc protocol ApplicationActivationObserver: ApplicationStateObserver {
    func applicationDidBecomeActive()
}

@objc protocol ApplicationInactivationObserver: ApplicationStateObserver {
    func applicationWillBecomeInactive()
}

@objc protocol ApplicationTerminationObserver: ApplicationStateObserver {
    func applicationWillTerminate()
}

extension UIApplication : Application {
    
    // MARK: - Application
    
    var state: UIApplication.State {
        applicationState
    }
    
    func addObserver(_ observer: ApplicationStateObserver) {
        if observer is ApplicationActivationObserver {
            NotificationCenter.default.addObserver(
                observer,
                selector: #selector(ApplicationActivationObserver.applicationDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
        if observer is ApplicationInactivationObserver {
            NotificationCenter.default.addObserver(
                observer,
                selector: #selector(ApplicationInactivationObserver.applicationWillBecomeInactive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }
        if observer is ApplicationTerminationObserver {
            NotificationCenter.default.addObserver(
                observer,
                selector: #selector(ApplicationTerminationObserver.applicationWillTerminate),
                name: UIApplication.willTerminateNotification,
                object: nil
            )
        }
    }
}
