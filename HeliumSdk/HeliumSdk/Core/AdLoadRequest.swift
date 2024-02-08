// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A model that represents an ad load request on the Helium SDK.
struct AdLoadRequest: Equatable {
    private enum Constant {
        static let maxKeywordKeyLength = 64
        static let maxKeywordValueLength = 256
    }

    /// Ad size. Nil for full-screen ads.
    let adSize: ChartboostMediationBannerSize?
    /// Ad format.
    let adFormat: AdFormat
    /// Keywords to be sent in API load requests.
    let keywords: [String: String]?
    /// Helium's placement identifier.
    let heliumPlacement: String
    /// A unique identifier for the load request.
    let loadID: String

    init(
        adSize: ChartboostMediationBannerSize?,
        adFormat: AdFormat,
        keywords: [String: String]?,
        heliumPlacement: String,
        loadID: String
    ) {
        self.adSize = adSize
        self.adFormat = adFormat
        self.keywords = keywords?.filter { pair in
            pair.key.count <= Constant.maxKeywordKeyLength && pair.value.count <= Constant.maxKeywordValueLength
        }
        self.heliumPlacement = heliumPlacement
        self.loadID = loadID
    }
}
