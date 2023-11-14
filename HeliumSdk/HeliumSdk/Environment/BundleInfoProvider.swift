// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol BundleInfoProviding {

    /// In unit test, `Bundle.main` is the XCTest driver bundle, not the unit test bundle.
    /// Return the unit test bundle in unit tests by `Bundle(for: Self.self)`.
    var mainBundle: Bundle { get }
}

/// Note: This is a `class` so that `Bundle(for: type(of: self))` compiles.
final class BundleInfoProvider: BundleInfoProviding {
    let mainBundle = Bundle.main
}
