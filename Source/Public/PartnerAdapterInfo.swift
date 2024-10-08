// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// General info about a partner adapter.
@objc(CBMPartnerAdapterInfo)
public class PartnerAdapterInfo: NSObject {
    /// The version of the partner SDK.
    @objc public var partnerVersion: String { partnerAdapterInfo.partnerVersion }
    /// The version of the adapter.
    @objc public var adapterVersion: String { partnerAdapterInfo.adapterVersion }
    /// The partner's unique identifier.
    @objc public var partnerID: PartnerID { partnerAdapterInfo.partnerID }
    /// The human-friendly partner name.
    @objc public var partnerDisplayName: String { partnerAdapterInfo.partnerDisplayName }

    private let partnerAdapterInfo: InternalPartnerAdapterInfo

    init(partnerAdapterInfo: InternalPartnerAdapterInfo) {
        self.partnerAdapterInfo = partnerAdapterInfo
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InternalPartnerAdapterInfo else {
            return false
        }

        return partnerAdapterInfo == other
    }
}
