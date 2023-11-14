// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

protocol LoadRateLimiting {
    /// Specifies how much time from now that the next load is allowed for a specified placement.
    /// - Parameter placement: The placement in question.
    /// - Returns: The TimeInterval from now.
    func timeUntilNextLoadIsAllowed(placement: String) -> TimeInterval

    /// Specifies the rate limit for a specified placement.
    /// - Parameter placement: The placement in question.
    /// - Returns: The rate limit for the placement, 0 if there is no limit.
    func loadRateLimit(placement: String) -> TimeInterval

    /// Define the rate limit for a specified placement.
    /// - Parameter value: The rate limit.  0 to indicate no limit.
    /// - Parameter placement: The placement in question.
    func setLoadRateLimit(_ value: TimeInterval, placement: String)
}
