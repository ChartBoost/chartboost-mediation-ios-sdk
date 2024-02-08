// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Options for Helium initialization.
@objc(HeliumInitializationOptions)
public class HeliumInitializationOptions: NSObject {
    // MARK: - Properties

    /// Set of Partner adapters to skip during Helium SDK initialization.
    @objc public let skippedPartnerIdentifiers: Set<PartnerIdentifier>

    // MARK: - Initialization

    /// Initializes a `HeliumInitializationOptions` instance.
    /// - Parameter skippedPartnerIdentifiers: Optional partner adapters to skip initialization.
    @objc public init(skippedPartnerIdentifiers: [PartnerIdentifier]?) {
        self.skippedPartnerIdentifiers = Set(skippedPartnerIdentifiers ?? [])
        super.init()
    }

    // MARK: - Unavailable

    override private init() {
        self.skippedPartnerIdentifiers = Set()
        super.init()
    }
}
