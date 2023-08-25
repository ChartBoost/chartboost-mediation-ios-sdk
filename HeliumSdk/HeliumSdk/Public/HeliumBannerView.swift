// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

// Concrete class that implements the public HeliumBannerAd protocol.
// These are the ad instances that publishers use to ask Helium to load and show ads.
// Publishers are responsible for keeping them alive.
// - note: Unlike InterstitialAd and RewardedAd, BannerAd does not make delegate calls itself.
// This is because of the BannerController that lies between the BannerAd and the AdController, and manages
// the banner auto-refresh logic. BannerController is in charge of making these delegate calls.

/// Helium banner ad view.
/// 
/// Add this view to the view hierarchy before showing the banner ad.
@objc
public class HeliumBannerView: UIView, HeliumBannerAd {
    
    private let controller: BannerControllerProtocol
    private let size: CGSize
    
    init(size: CGSize, controller: BannerControllerProtocol) {
        self.controller = controller
        self.size = size
        super.init(frame: CGRect(origin: .zero, size: size))
        self.backgroundColor = .clear
        controller.bannerContainer = self
        sendVisibilityStateToController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - HeliumBannerAd
    
    /// Optional keywords that can be associated with the advertisement placement.
    public var keywords: HeliumKeywords? {
        get { controller.keywords }
        set { controller.keywords = newValue }
    }

    public func load(with viewController: UIViewController) {
        controller.loadAd(with: viewController)
    }

    public func clear() {
        controller.clearAd()
    }
    
    // MARK: - UIView
    
    public override var intrinsicContentSize: CGSize {
        size
    }
    
    public override var isHidden: Bool {
        didSet {
            sendVisibilityStateToController()
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        sendVisibilityStateToController()
    }
    
    private func sendVisibilityStateToController() {
        // The view is considered not visible if it's removed from the view hierarchy or if it's hidden.
        let visible = !isHidden && superview != nil
        controller.viewVisibilityDidChange(on: self, to: visible)
    }
}
