// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Delegate for receiving ``Helium`` SDK initialization callbacks.
@objc
public protocol HeliumSdkDelegate: NSObjectProtocol {
    /// Chartboost Mediation SDK has finished initializing.
    /// - Parameter error: Optional error if the Chartboost Mediation SDK did not initialize properly.
    func heliumDidStartWithError(_ error: ChartboostMediationError?)
}
