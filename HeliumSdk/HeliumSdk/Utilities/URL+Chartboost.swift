// Copyright 2022-2023 Chartboost, Inc.
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
            // TODO: HB-6484: make call to the new API after Xcode 15 is adopted in CI universally
            // (both `XCODE_VERSION_CANARY` and `XCODE_VERSION_RELEASE` in fastlane/.env being "15.0")
            // self.init(string: unsafeString, encodingInvalidCharacters: false)
            self.init(string: unsafeString)
        } else {
            self.init(string: unsafeString)
        }
    }
}
