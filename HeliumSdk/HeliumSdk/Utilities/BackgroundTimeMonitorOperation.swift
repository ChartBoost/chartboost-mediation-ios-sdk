// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A protocol to define the controllable behavior of an object that is reponsible for monitoring when the application migrates to 
/// and from the background and foreground.
protocol BackgroundTimeMonitorOperator {
    func backgroundTimeUntilNow() -> TimeInterval
}

/// An implementation of `BackgroundTimeMonitorOperator`
class BackgroundTimeMonitorOperation: BackgroundTimeMonitorOperator, ApplicationBackgroundObserver, ApplicationForegroundObserver {
    @Injected(\.application) private var application

    private let startedOn = Date()
    private let queue = DispatchQueue(label: "com.chartboost.mediation.BackgroundTimeMonitorOperation")
    private var backgroundedIntervals: [DateInterval] = []
    private var lastBackgroundedOn: Date?

    init() {
        application.addObserver(self)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.application.state == .background {
                self.lastBackgroundedOn = Date()
            }
        }
    }

    // MARK: - BackgroundTimeMonitorOperator

    func backgroundTimeUntilNow() -> TimeInterval {
        let dateInterval = DateInterval(start: startedOn, end: Date())

        // If in the background right now while still monitoring, need to add in that time.
        commitLastBackgroundedOn()

        var backgroundTime: TimeInterval = 0
        queue.sync {
            backgroundedIntervals.forEach { backgroundedInterval in
                guard let intersectedInterval = backgroundedInterval.intersection(with: dateInterval) else {
                    return
                }
                backgroundTime += intersectedInterval.duration
            }
        }

        return backgroundTime
    }

    // MARK: - ApplicationStateObserver

    func applicationDidEnterBackground() {
        lastBackgroundedOn = Date()
    }

    func applicationWillEnterForeground() {
        commitLastBackgroundedOn()
    }

    // MARK: - Private

    private func commitLastBackgroundedOn() {
        guard let lastBackgroundedOn else { return }
        let dateInterval = DateInterval(start: lastBackgroundedOn, end: Date())
        self.lastBackgroundedOn = nil
        queue.sync {
            backgroundedIntervals.append(dateInterval)
        }
    }
}
