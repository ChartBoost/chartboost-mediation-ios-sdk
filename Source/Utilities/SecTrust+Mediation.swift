// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension SecTrust {
    /// @function evaluateForHost
    /// @abstract Evaluates a trust reference synchronously.
    /// @param host A string representing a URL host.
    /// @result A boolean value indicating whether the certificate is trusted
    /// @discussion
    /// (Copied from the `SecTrustEvaluateWithError` header):
    /// This function will completely evaluate trust before returning,
    /// possibly including network access to fetch intermediate certificates or to
    /// perform revocation checking. Since this function can block during those
    /// operations, you should call it from within a function that is placed on a
    /// dispatch queue, or in a separate thread from your application's main
    /// run loop 1.
    func evaluateForHost(_ host: String) -> Bool {
        let policy = SecPolicyCreateSSL(true, host as CFString?)
        let osStatus = SecTrustSetPolicies(self, [policy] as CFArray)
        logger.debug("SecTrustSetPolicies host: \(host), result: \(osStatus)")

        var error: CFError?
        let result = SecTrustEvaluateWithError(self, &error)
        if let error {
            logger.error("SecTrustEvaluateWithError host: \(host), error: \(error.localizedDescription)")
        }
        return result
    }
}
