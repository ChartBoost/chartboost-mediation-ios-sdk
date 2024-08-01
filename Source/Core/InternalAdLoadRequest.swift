// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A model that represents an ad load request on the Chartboost Mediation SDK.
struct InternalAdLoadRequest {
    private enum Constant {
        static let maxKeywordKeyLength = 64
        static let maxKeywordValueLength = 256
    }

    /// Ad size. Nil for full-screen ads.
    let adSize: BannerSize?
    /// Ad format.
    let adFormat: AdFormat
    /// Keywords to be sent in API load requests.
    let keywords: [String: String]?
    /// Chartboost Mediation's placement identifier.
    let mediationPlacement: String
    /// A unique identifier for the load request.
    let loadID: String
    /// Local extras which should be passed to adapter calls and merged with the backend extras.
    let partnerSettings: [String: Any]
    /// The unique identifier for the FullscreenAdQueue that initiated this load. Nil for requests not originating from a queue.
    let queueID: String?

    init(
        adSize: BannerSize?,
        adFormat: AdFormat,
        keywords: [String: String]?,
        mediationPlacement: String,
        loadID: String,
        partnerSettings: [String: Any],
        queueID: String? = nil
    ) {
        self.adSize = adSize
        self.adFormat = adFormat
        self.keywords = keywords?.filter { pair in
            pair.key.count <= Constant.maxKeywordKeyLength && pair.value.count <= Constant.maxKeywordValueLength
        }
        self.mediationPlacement = mediationPlacement
        self.loadID = loadID
        self.partnerSettings = partnerSettings
        self.queueID = queueID
    }
}
