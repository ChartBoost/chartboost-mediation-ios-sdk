// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension URL {
    /// A failable init to avoid encoding invalid `unsafeString` characters in the `URL`.
    /// On iOS 17+, `URL(string:)` assumes `encodingInvalidCharacters` being `true`, which is
    /// inconsistent with older iOS versions and makes bad URL less obvious.
    /// - Parameter unsafeString: An unsanitized string that potentially contains invalid characters for representing a URL.
    init?(unsafeString: String) {
        if #available(iOS 17.0, *) {
            self.init(string: unsafeString, encodingInvalidCharacters: false)
        } else {
            self.init(string: unsafeString)
        }
    }
}
