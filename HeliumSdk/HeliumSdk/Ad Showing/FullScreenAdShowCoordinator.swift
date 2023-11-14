// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// An observer that wants to get notified whenever a full-screen ad is shown or closed.
protocol FullScreenAdShowObserver {
    /// Called when a full-screen ad was shown.
    func didShowFullScreenAd()
    /// Called when a full-screen ad was closed.
    func didCloseFullScreenAd()
}

/// Manages a list of observers and forwards full-screen ad show and close events to them when they happen.
protocol FullScreenAdShowCoordinator {
    /// Adds an observer, which will start receiveing ad show and close events.
    /// Observers are automatically removed when deallocated.
    func addObserver(_ observer: FullScreenAdShowObserver)
}

/// Coordinates full-screen ad show and close events.
/// It acts as a middle man for another object who is responsible for identifying when these events happen
/// and calling the FullScreenAdShowObserver methods on this class to notify it.
/// Then the coordinator will forward these events to its observers.
final class MiddleManFullScreenAdShowCoordinator: FullScreenAdShowCoordinator, FullScreenAdShowObserver {
    /// List of added observers. We use WeakReferences to avoid holding strong references to the observers, which would
    /// lead to strong reference cycles unless they were properly removed, which is not obvious when to do in some cases.
    private var observers = WeakReferences<FullScreenAdShowObserver>()
    @Injected(\.taskDispatcher) private var taskDispatcher
    
    func addObserver(_ observer: FullScreenAdShowObserver) {
        taskDispatcher.async(on: .background) { [weak self] in
            self?.observers.add(observer)
        }
    }
    
    func didShowFullScreenAd() {
        taskDispatcher.async(on: .background) { [weak self] in
            self?.observers.forEach {
                $0.didShowFullScreenAd()
            }
        }
    }
    
    func didCloseFullScreenAd() {
        taskDispatcher.async(on: .background) { [weak self] in
            self?.observers.forEach {
                $0.didCloseFullScreenAd()
            }
        }
    }
}
