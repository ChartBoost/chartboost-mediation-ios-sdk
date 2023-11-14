// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension MetricsEvent {
    
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(bid: Bid? = nil, errorCode: ChartboostMediationError.Code? = nil, loadTime: TimeInterval = 0) -> Self {
        MetricsEvent(
            start: Date().addingTimeInterval(-loadTime),
            error: errorCode.map { ChartboostMediationError.init(code: $0) },
            partnerIdentifier: bid?.partnerIdentifier ?? "partner_id_\(Int.random(in: 1...99990))",
            partnerPlacement: bid?.partnerPlacement ?? "partner_placement_\(Int.random(in: 1...99990))",
            networkType: bid?.lineItemIdentifier != nil ? .mediation : .bidding,
            lineItemIdentifier: bid?.lineItemIdentifier ?? "line_item_id_\(Int.random(in: 1...99990))"
        )
    }
}
