// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest

extension JSONSerialization {
    /// A helper for reducing boilerplate code.
    static func jsonDictionary(with data: Data?, options opt: ReadingOptions = []) throws -> [String: Any] {
        try XCTUnwrap(jsonObject(with: XCTUnwrap(data)) as? [String: Any])
    }
}
