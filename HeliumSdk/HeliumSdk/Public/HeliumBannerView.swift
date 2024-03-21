// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

// Concrete class that implements the public HeliumBannerAd protocol.
// These are the ad instances that publishers use to ask Chartboost Mediation to load and show ads.
// Publishers are responsible for keeping them alive.
// - note: Unlike InterstitialAd and RewardedAd, BannerAd does not make delegate calls itself.
// This is because of the BannerController that lies between the BannerAd and the AdController, and manages
// the banner auto-refresh logic. BannerController is in charge of making these delegate calls.

/// Chartboost Mediation banner ad view.
///
/// Add this view to the view hierarchy before showing the banner ad.
@objc
public class HeliumBannerView: UIView, HeliumBannerAd {
    private let controller: BannerControllerProtocol
    public weak var delegate: HeliumBannerAdDelegate?

    init(
        controller: BannerControllerProtocol,
        delegate: HeliumBannerAdDelegate?
    ) {
        self.controller = controller
        self.delegate = delegate
        super.init(frame: CGRect(origin: .zero, size: controller.request.size.size))
        self.backgroundColor = .clear
        self.controller.delegate = self
        sendVisibilityStateToController()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - HeliumBannerAd

    /// Optional keywords that can be associated with the advertisement placement.
    public var keywords: HeliumKeywords? {
        get { HeliumKeywords(controller.keywords) }
        set { controller.keywords = newValue?.dictionary }
    }

    public func load(with viewController: UIViewController) {
        controller.loadAd(
            viewController: viewController
        ) { [weak self] result in
            guard let self else {
                return
            }

            let placement = self.controller.request.placement
            self.delegate?.heliumBannerAd(
                placementName: placement,
                requestIdentifier: result.loadID,
                winningBidInfo: result.winningBidInfo,
                didLoadWithError: result.error
            )
        }
    }

    public func clear() {
        controller.clearAd()
    }

    // MARK: - UIView
    override public var intrinsicContentSize: CGSize {
        controller.request.size.size
    }

    override public var isHidden: Bool {
        didSet {
            sendVisibilityStateToController()
        }
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        sendVisibilityStateToController()
    }

    private func sendVisibilityStateToController() {
        // The view is considered not visible if it's removed from the view hierarchy or if it's hidden.
        let visible = !isHidden && superview != nil
        controller.viewVisibilityDidChange(to: visible)
    }
}

extension HeliumBannerView: BannerControllerDelegate {
    func bannerController(
        _ bannerController: BannerControllerProtocol,
        displayBannerView bannerView: UIView
    ) {
        // Legacy code used the requested ad size, so we will do the same here.
        let size = bannerController.request.size.size
        bannerView.frame = CGRect(origin: .zero, size: size)
        addSubview(bannerView)
    }

    func bannerController(
        _ bannerController: BannerControllerProtocol,
        clearBannerView bannerView: UIView
    ) {
        bannerView.removeFromSuperview()
    }

    func bannerControllerDidRecordImpression(_ bannerController: BannerControllerProtocol) {
        let placement = bannerController.request.placement
        delegate?.heliumBannerAdDidRecordImpression?(placementName: placement)
    }

    func bannerControllerDidClick(_ bannerController: BannerControllerProtocol) {
        let placement = bannerController.request.placement
        delegate?.heliumBannerAd?(placementName: placement, didClickWithError: nil)
    }
}
