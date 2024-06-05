// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

protocol BannerSwapControllerDelegate: AnyObject {
    /// Called when `bannerView` is ready for display, and should be added to the containing view.
    func bannerSwapController(
        _ bannerSwapController: BannerSwapControllerProtocol,
        displayBannerView bannerView: UIView
    )

    /// Called when the `bannerView` should be removed from display.
    func bannerSwapController(
        _ bannerSwapController: BannerSwapControllerProtocol,
        clearBannerView bannerView: UIView
    )

    /// Called when an impression is recorded.
    func bannerSwapControllerDidRecordImpression(
        _ bannerSwapController: BannerSwapControllerProtocol
    )

    /// Called when the banner is clicked.
    func bannerSwapControllerDidClick(_ bannerSwapController: BannerSwapControllerProtocol)
}

protocol BannerSwapControllerProtocol: AnyObject, ViewVisibilityObserver {
    /// The delegate for the banner swap controller.
    var delegate: BannerSwapControllerDelegate? { get set }

    /// Keywords to be sent in API load requests.
    var keywords: [String: String]? { get set }

    // MARK: Readonly
    /// The request that loaded the currently showing banner, or `nil` if no banner is showing.
    var request: ChartboostMediationBannerLoadRequest? { get }

    /// The `AdLoadResult` of the currently showing ad, or `nil` if an ad is not being shown.
    var showingBannerLoadResult: AdLoadResult? { get }

    /// Loads an ad and renders it using the provided view controller.
    func loadAd(
        request: ChartboostMediationBannerLoadRequest,
        viewController: UIViewController,
        completion: @escaping (ChartboostMediationBannerLoadResult) -> Void
    )

    /// Clears the loaded ad, removes the currently presented ad if any, and stops the auto-refresh process.
    func clearAd()
}

class BannerSwapController: BannerSwapControllerProtocol {
    /// The internal state of `BannerSwapController`.
    private enum State {
        /// The controller has been cleared and is not displaying a banner.
        case cleared

        /// The controller is attempting to swap between two `BannerController`. The first associated value is the pending
        /// controller, and the second associated value is the currently active controller, or `nil` if there is no active controller.
        /// The third associated value is the passed in completion block.
        case swapping(
            pending: BannerControllerProtocol,
            active: BannerControllerProtocol?,
            completion: (ChartboostMediationBannerLoadResult) -> Void
        )

        /// The associated `BannerController` is the currently active banner controller.
        case active(BannerControllerProtocol)
    }

    weak var delegate: BannerSwapControllerDelegate?

    var keywords: [String: String]? {
        // Since the controller can change over time, this controller must be the source of truth
        // of the keywords. We will update them on the controller(s) when they change.
        didSet {
            switch state {
            case .active(let activeController):
                activeController.keywords = keywords
            case .swapping(let pendingController, let activeController, _):
                activeController?.keywords = keywords
                pendingController.keywords = keywords
            case .cleared:
                break
            }
        }
    }

    var request: ChartboostMediationBannerLoadRequest? {
        activeController?.request
    }

    var showingBannerLoadResult: AdLoadResult? {
        activeController?.showingBannerLoadResult
    }

    // MARK: - Private
    @Injected(\.adFactory) private var adFactory

    /// Convenience to return the currently active controller.
    private var activeController: BannerControllerProtocol? {
        switch state {
        case .swapping(_, let activeController, _):
            return activeController
        case .active(let activeController):
            return activeController
        case .cleared:
            return nil
        }
    }

    /// The current state of this controller.
    private var state: State = .cleared {
        didSet {
            didTranstion(from: oldValue, to: state)
        }
    }

    /// Save the view visibility in case it changes before `load` is called.
    private var viewVisibility: Bool? {
        didSet {
            guard let viewVisibility else {
                return
            }

            switch state {
            case .active(let activeController):
                activeController.viewVisibilityDidChange(to: viewVisibility)
            case .swapping(let pendingController, let activeController, _):
                activeController?.viewVisibilityDidChange(to: viewVisibility)
                pendingController.viewVisibilityDidChange(to: viewVisibility)
            case .cleared:
                break
            }
        }
    }

    func loadAd(
        request: ChartboostMediationBannerLoadRequest,
        viewController: UIViewController,
        completion newCompletion: @escaping (ChartboostMediationBannerLoadResult) -> Void
    ) {
        switch state {
        case .active(let active) where active.request == request:
            // Reuse the existing controller if it exists and the request is the same. This will
            // just pull up the cached ad from the controller, or load a new ad if there is no
            // cached ad.
            active.loadAd(viewController: viewController, completion: newCompletion)
        case .swapping(_, let active?, _) where active.request == request:
            // Edge case: A -> B -> A, while B is still loading. We can reset the active
            // controller back to A.
            active.loadAd(viewController: viewController, completion: newCompletion)
            self.state = .active(active)
        case .swapping(let pending, let active, _) where pending.request == request:
            // Edge case: A -> B -> B, while the original call to load B is still loading. We
            // don't actually want to do anything with the controller in this in this case,
            // since if we call load again, BannerController will replace the completion block,
            // which means our completion below would not be called. Instead, we will just replace
            // the the saved completion in the pending state.
            self.state = .swapping(
                pending: pending,
                active: active,
                completion: newCompletion
            )
        default:
            // In all other cases, we need to create a new controller. We will not clear any
            // currently loaded ad here until the new controller successfully loads an ad.
            let newController = adFactory.makeBannerController(
                request: request,
                delegate: self,
                keywords: keywords
            )
            if let viewVisibility {
                newController.viewVisibilityDidChange(to: viewVisibility)
            }
            self.state = .swapping(
                pending: newController,
                active: activeController,
                completion: newCompletion
            )

            newController.loadAd(viewController: viewController) { [weak self] result in
                guard let self else {
                    return
                }

                // Ensure the state was not changed while loading. If it was, this was due to
                // an explicit call load or clearAd, so we will not call the completion.
                guard case .swapping(let pending, let active, let completion) = self.state,
                        pending === newController else {
                    return
                }

                if result.error != nil, let active {
                    // If an error occured during the load, and there's a currently active
                    // controller, reset to that controller.
                    self.state = .active(active)
                } else {
                    // If the load succeeded, or this was the first load (regardless of result),
                    // then set the active controller.
                    self.state = .active(pending)
                }

                // Ensure we call the completion block from the state, and not the passed in
                // completion block.
                completion(result)
            }
        }
    }

    func clearAd() {
        state = .cleared
    }
}

// MARK: - ViewVisibilityObserver
extension BannerSwapController: ViewVisibilityObserver {
    func viewVisibilityDidChange(to visible: Bool) {
        viewVisibility = visible
    }
}

// MARK: - BannerControllerDelegate
extension BannerSwapController: BannerControllerDelegate {
    // When a pending banner has successfully loaded, it's likely that the new controller will call
    // `displayBannerView` before `clearBannerView` has been called by the old controller. However,
    // since all these calls happen on the main thread, both of these operations should happen by
    // the end of the current run loop, and only the new banner should be rendered on screen.
    func bannerController(_ bannerController: BannerControllerProtocol, displayBannerView bannerView: UIView) {
        delegate?.bannerSwapController(self, displayBannerView: bannerView)
    }

    func bannerController(_ bannerController: BannerControllerProtocol, clearBannerView bannerView: UIView) {
        delegate?.bannerSwapController(self, clearBannerView: bannerView)
    }

    func bannerControllerDidRecordImpression(_ bannerController: BannerControllerProtocol) {
        delegate?.bannerSwapControllerDidRecordImpression(self)
    }

    func bannerControllerDidClick(_ bannerController: BannerControllerProtocol) {
        delegate?.bannerSwapControllerDidClick(self)
    }
}

// MARK: - Private
extension BannerSwapController {
    private func didTranstion(from oldState: State, to newState: State) {
        switch (oldState, newState) {
        case (.swapping(let pending, let active, _), .cleared):
            active?.clearAd()
            pending.clearAd()
        case (.active(let active), .cleared):
            active.clearAd()
        case (.active(let active), .swapping(_, _, _)):
            active.isPaused = true
        case (.swapping(let pending, let oldActive, _), .active(let newActive)):
            if newActive === pending {
                // If the pending controller is successful in loading, we are getting rid of the
                // old active controller.
                oldActive?.clearAd()
            } else {
                // Otherwise, we reverted back to the old active controller. We need to unpause
                // the old active controller, and we will clear the pending controller before
                // getting rid of the reference for good measure.
                newActive.isPaused = false
                pending.clearAd()
            }
        case (.swapping(let oldPending, _, _), .swapping(let newPending, _, _)):
            if oldPending !== newPending {
                // In the edge case where we go from A -> B -> C, before B has finished loading, we
                // will clear the old pending controller.
                oldPending.clearAd()
            }
        default:
            break
        }
    }
}
