// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A base class inherited by other request types.
@objc(CBMAdLoadRequest)
public class AdLoadRequest: NSObject {
    /// Placement from the Chartboost Mediation dashboard.
    @objc public let placement: String

    /// Initializes the request with the desired parameters.
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    init(placement: String) {
        self.placement = placement
    }
}
