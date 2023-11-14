// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

final class LoadRateLimiter: LoadRateLimiting {

    // MARK: - LoadRateLimiting

    /// Specifies how much time from now that the next load is allowed for a specified placement.
    /// - Parameter placement: The placement in question.
    /// - Returns: The TimeInterval from now.
    func timeUntilNextLoadIsAllowed(placement: String) -> TimeInterval {
        queue.sync {
            guard let configuration = configurations[placement] else {
                return 0
            }
            guard configuration.rateLimit > 0 else {
                return 0
            }
            let intervalSinceLastLoaded = configuration.lastLoadedDate.timeIntervalSinceNow
            let until = max(0, configuration.rateLimit + intervalSinceLastLoaded)
            return until
        }
    }

    /// Specifies the rate limit for a specified placement.
    /// - Parameter placement: The placement in question.
    /// - Returns: The rate limit for the placement, 0 if there is no limit.
    func loadRateLimit(placement: String) -> TimeInterval {
        queue.sync {
            configurations[placement]?.rateLimit ?? 0
        }
    }

    /// Define the rate limit for a specified placement.
    /// - Parameter value: The rate limit.  0 to indicate no limit.
    /// - Parameter placement: The placement in question.
    func setLoadRateLimit(_ value: TimeInterval, placement: String) {
        queue.sync {
          configurations[placement] = Configuration(rateLimit: max(value, 0))
        }
    }

    // MARK: - Private

    /// Configuration data for a specific placement.
    fileprivate struct Configuration {
        /// The rate limit for the placement.
        let rateLimit: TimeInterval
        /// When the placement was last loaded.
        let lastLoadedDate: Date = Date()
    }

    private var configurations: [String: Configuration] = .init()
    private let queue = DispatchQueue(label: "com.chartboost.mediation.LoadRateLimiter")
}
