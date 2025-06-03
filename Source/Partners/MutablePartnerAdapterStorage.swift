// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A `PartnerAdapterStorage` whose contents can be mutated.
final class MutablePartnerAdapterStorage: PartnerAdapterStorage {
    /// List of `PartnerAd` instances created by a `PartnerAdapter` that have not been disposed of yet.
    var ads: [PartnerAd] = []
}
