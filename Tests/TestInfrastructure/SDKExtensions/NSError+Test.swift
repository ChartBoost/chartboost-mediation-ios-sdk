// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension NSError {
    /// A convenience factory method to obtain a NSError instance with minimum boilerplate code.
    static func test(domain: String = "helium.tests", code: Int = 42, userInfo: [String: Any]? = nil) -> NSError {
        NSError(domain: domain, code: code, userInfo: userInfo)
    }
}
