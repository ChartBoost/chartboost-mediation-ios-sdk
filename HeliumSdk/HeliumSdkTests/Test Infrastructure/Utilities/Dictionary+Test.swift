// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest

extension Dictionary where Key == String, Value == Any {

    /// The provided dictionaries are expected to have unique keys, otherwise `XCTFail()` is called.
    static func merge(_ dictionaries: [Key: Value]...) -> [Key: Value] {
        var result: [Key: Value] = [:]
        dictionaries.forEach {
            result.merge($0) { current, new in
                XCTFail("Dictionary key conflict during merge: \(current) vs \(new)")
                return new
            }
        }
        return result
    }
}
