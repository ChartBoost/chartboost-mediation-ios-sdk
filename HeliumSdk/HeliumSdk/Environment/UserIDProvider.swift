// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol UserIDProviding: AnyObject {

    /// Optional user ID specified by the publisher.
    /// This generally represents the user in the publisher's ecosystem.
    var publisherUserID: String? { get set }

    /// Optional user ID owned by this SDK.
    var userID: String? { get }
}

final class UserIDProvider: UserIDProviding {

    @Injected(\.appTrackingInfo) var appTrackingInfo
    @Injected(\.chartboostIDProvider) var chartboostIDProvider

    var publisherUserID: String?

    var userID: String? {
        if !appTrackingInfo.isLimitAdTrackingEnabled,
           let idfa = appTrackingInfo.idfa,
           idfa != AppTrackingInfoProvider.Constant.zeroUUID
        {
            return idfa
        } else if let idfv = appTrackingInfo.idfv, idfv != AppTrackingInfoProvider.Constant.zeroUUID {
            return idfv
        } else {
            return chartboostIDProvider.chartboostID
        }
    }
}
