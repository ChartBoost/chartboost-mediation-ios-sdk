// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class BundleInfoProviderMock: BundleInfoProviding {
    var mainBundle: Bundle {
        /// In unit test, `Bundle.main` is the XCTest driver bundle, not the unit test bundle.
        /// Return the unit test bundle in unit tests by `Bundle(for: Self.self)`.
        Bundle(for: Self.self)
    }
}
