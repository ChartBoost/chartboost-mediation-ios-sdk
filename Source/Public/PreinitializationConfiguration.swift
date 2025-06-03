// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Configuration for Chartboost Mediation preinitialization.
@objc(CBMPreinitializationConfiguration)
public class PreinitializationConfiguration: NSObject {
    // MARK: - Properties

    /// Set of Partner adapters to skip during Chartboost Mediation SDK initialization.
    @objc public let skippedPartnerIDs: Set<PartnerID>

    // MARK: - Initialization

    /// Initializes a `PreinitializationConfiguration` instance.
    /// - Parameter skippedPartnerIDs: Optional partner adapters to skip initialization.
    @objc public init(skippedPartnerIDs: [PartnerID]) {
        self.skippedPartnerIDs = Set(skippedPartnerIDs)
        super.init()
    }

    // MARK: - Unavailable

    @available(*, unavailable)
    override init() {
        fatalError("init() has not been implemented")
    }
}
