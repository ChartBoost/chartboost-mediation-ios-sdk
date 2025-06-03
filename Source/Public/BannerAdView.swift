// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A view that can load and display a Chartboost Mediation banner ad.
@objc(CBMBannerAdView)
public class BannerAdView: UIView {
    // MARK: - Public Settable

    /// The delegate of this banner view.
    @objc public weak var delegate: BannerAdViewDelegate?

    /// Optional keywords that can be associated with the advertisement placement.
    @objc public var keywords: [String: String]? {
        get { controller.keywords }
        set { controller.keywords = newValue }
    }

    /// Optional partner-specific settings that can be associated with the advertisement placement.
    @objc public var partnerSettings: [String: Any]? {
        get { controller.partnerSettings }
        set { controller.partnerSettings = newValue }
    }

    /// The horizontal alignment of the banner ad within this view, if the size of this view is made larger than the banner ad.
    ///
    /// Defaults to ``BannerHorizontalAlignment/center``.
    @objc public var horizontalAlignment: BannerHorizontalAlignment = .center {
        didSet {
            setNeedsLayout()
        }
    }

    /// The vertical alignment of the banner ad within this view, if the size of this view is made larger than the banner ad.
    ///
    /// Defaults to ``BannerVerticalAlignment/center``.
    @objc public var verticalAlignment: BannerVerticalAlignment = .center {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: - Public Readonly

    /// The original `request` that ``BannerAdView/load(with:viewController:completion:)`` was called with, or `nil` if a
    /// banner is not loaded.
    ///
    /// When ``BannerAdView/load(with:viewController:completion:)`` is called, this value will be available when `completion`
    /// is called. If ``BannerAdView/load(with:viewController:completion:)`` is called with a new request, this value will reflect the
    /// previous value until the new request has successfully loaded.
    @objc public var request: BannerAdLoadRequest? {
        controller.request
    }

    /// The load metrics for the most recent successful load operation, or `nil` if a banner is not loaded.
    ///
    /// If auto-refresh is enabled, this value will change over time. The
    /// ``BannerAdViewDelegate/willAppear(bannerView:)`` delegate method will be called after
    /// this value changes.
    @objc public var loadMetrics: [String: Any]? {
        controller.showingBannerAdLoadResult?.metrics
    }

    /// The actual size of the ad that has been loaded, or `nil` if a banner is not loaded.
    ///
    /// If auto-refresh is enabled, this value will change over time. The
    /// ``BannerAdViewDelegate/willAppear(bannerView:)`` delegate method will be called after
    /// this value changes.
    @objc public var size: BannerSize? {
        ad?.bannerSize
    }

    /// Information about the winning bid, or `nil` if a banner is not loaded.
    ///
    /// If auto-refresh is enabled, this value will change over time. The
    /// ``BannerAdViewDelegate/willAppear(bannerView:)`` delegate method will be called after
    /// this value changes.
    @objc public var winningBidInfo: [String: Any]? {
        ad?.bidInfo
    }

    // MARK: - Private Variables

    // Marked static so that we can initialize `controller` before calling `super.init`.
    @Injected(\.adFactory) private static var adFactory
    @Injected(\.bannerControllerConfiguration) private var configuration
    @Injected(\.networkManager) private var networkManager
    @Injected(\.taskDispatcher) private var taskDispatcher
    @Injected(\.metrics) private var metrics
    private let controller: BannerSwapControllerProtocol

    /// Convenience to get the loaded ad from the controller, or `nil` if an ad is not loaded.
    private var ad: LoadedAd? {
        try? controller.showingBannerAdLoadResult?.result.get()
    }

    // MARK: - Public Methods

    override public init(frame: CGRect) {
        self.controller = Self.adFactory.makeBannerSwapController()
        super.init(frame: frame)

        controller.delegate = self

        self.backgroundColor = .clear
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Loads a banner ad using the information provided in the request.
    ///
    /// When this banner view is visible in the app's view hierarchy it will automatically present the loaded ad.
    /// Calling this method will start the banner auto-refresh process.
    ///
    /// - Parameter request: A request containing the information used to load the ad.
    /// - Parameter viewController: View controller used to present the ad. Auto refresh might fail if this is deallocated.
    /// - Parameter completion: A closure executed when the load operation is done.
    ///
    /// - Note: Calling `load` a second time before `completion` has been called for a previous load will result in the previous
    /// `completion` not being called.
    @objc
    public func load(
        with request: BannerAdLoadRequest,
        viewController: UIViewController,
        completion: @escaping (BannerAdLoadResult) -> Void
    ) {
        controller.loadAd(request: request, viewController: viewController, completion: completion)
    }

    /// Clears the loaded ad, removes the currently presented ad if any, and stops the auto-refresh process.
    ///
    /// - Note: Calling `reset` after calling `load`, but before the load's `completion` has been called, will result in
    /// `completion` not being called.
    @objc
    public func reset() {
        controller.clearAd()
    }

    // MARK: - UIView
    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let bannerView = ad?.bannerView,
              let size = ad?.bannerSize
        else {
            return
        }

        bannerView.frame = bannerFrame(for: size)
    }

    override public var intrinsicContentSize: CGSize {
        return ad?.bannerSize?.size ??
            CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}

// MARK: - BannerSwapControllerDelegate

extension BannerAdView: BannerSwapControllerDelegate {
    func bannerSwapController(
        _ bannerController: BannerSwapControllerProtocol,
        displayBannerView bannerView: UIView
    ) {
        // The value of `shownAd` has been updated on `controller`, so we need to call `willAppear`
        // before actually adding the ad to the view heirarchy.
        delegate?.willAppear?(bannerView: self)

        self.addSubview(bannerView)
        self.setNeedsLayout()
        self.invalidateIntrinsicContentSize()
    }

    func bannerSwapController(
        _ bannerController: BannerSwapControllerProtocol,
        clearBannerView bannerView: UIView
    ) {
        // Make sure to use the `ad` passed in the delegate method, since the this call could be
        // made during a controller swap, and may possibly be made after an ad from the new
        // controller has already been displayed.
        bannerView.removeFromSuperview()
        self.invalidateIntrinsicContentSize()
    }

    func bannerSwapControllerDidRecordImpression(_ bannerController: BannerSwapControllerProtocol) {
        delegate?.didRecordImpression?(bannerView: self)

        logContainerTooSmallWarningIfNeeded()
    }

    func bannerSwapControllerDidClick(_ bannerController: BannerSwapControllerProtocol) {
        delegate?.didClick?(bannerView: self)
    }
}

// MARK: - Layout Helpers

extension BannerAdView {
    /// Returns the frame for the given `BannerSize`.
    private func bannerFrame(for size: BannerSize) -> CGRect {
        guard bounds.size.height > 0.0, size.aspectRatio > 0.0 else {
            return .zero
        }

        let cgSize = bannerCGSize(for: size)
        let origin = bannerOrigin(for: cgSize)
        return CGRect(origin: origin, size: cgSize)
    }

    /// Returns the `CGSize` for the given `BannerSize`.
    private func bannerCGSize(for size: BannerSize) -> CGSize {
        switch size.type {
        case .fixed:
            return size.size
        case .adaptive:
            // Determine if the banner needs to be pinned to the top or the sizes of the bounds
            // by comparing the aspect ratio of the bounds to the aspect ratio of the banner.
            var bannerWidth: CGFloat
            var bannerHeight: CGFloat
            let boundsAspectRatio = bounds.width / bounds.height

            if boundsAspectRatio > size.aspectRatio {
                // Bounds are wider than the aspect ratio of the banner, so we constrain the size
                // of the ad based on the height.
                bannerHeight = bounds.height
                bannerWidth = bannerHeight * size.aspectRatio
            } else {
                // Bounds are taller than the aspect ratio of the banner, so we constrain the size
                // of the ad based on the width. This also covers the case where the aspect ratios
                // are equal, and it doesn't matter which dimension we pick.
                bannerWidth = bounds.width
                bannerHeight = bannerWidth / size.aspectRatio
            }

            let minSize = minSize(for: size)

            // If one dimension is smaller than the minimum, then we need to adjust both that
            // dimension and the other dimension based on the aspect ratio.
            if bannerWidth < minSize.width {
                bannerWidth = minSize.width
                bannerHeight = bannerWidth / size.aspectRatio
            }

            if bannerHeight < minSize.height {
                bannerHeight = minSize.height
                bannerWidth = bannerHeight * size.aspectRatio
            }

            return CGSize(width: bannerWidth, height: bannerHeight)
        }
    }

    /// Determine the min width and height for the banner based on the aspect ratio of the banner.
    private func minSize(for size: BannerSize) -> CGSize {
        let minWidth: CGFloat
        let minHeight: CGFloat

        if size.aspectRatio == 1.0 {
            minWidth = Constants.minSizeFor1x1Tile
            minHeight = Constants.minSizeFor1x1Tile
        } else if size.aspectRatio > 1.0 {
            minWidth = 0
            minHeight = Constants.minHeightForHorizontal
        } else {
            minWidth = Constants.minWidthForVertical
            minHeight = 0
        }

        return CGSize(width: minWidth, height: minHeight)
    }

    /// Determine the origin of the banner view within the bounds.
    private func bannerOrigin(for cgSize: CGSize) -> CGPoint {
        let x: CGFloat
        let y: CGFloat

        switch horizontalAlignment {
        case .left: x = 0.0
        case .center: x = (bounds.width - cgSize.width) / 2.0
        case .right: x = bounds.width - cgSize.width
        }

        switch verticalAlignment {
        case .top: y = 0.0
        case .center: y = (bounds.height - cgSize.height) / 2.0
        case .bottom: y = bounds.height - cgSize.height
        }

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Other

extension BannerAdView {
    private func logContainerTooSmallWarningIfNeeded() {
        guard let ad, let bannerView = ad.bannerView, let size = ad.bannerSize else {
            return
        }

        // We will wait a bit to ensure the pub has adequate time after both the will appear and
        // impression delegate callbacks to size the view correctly.
        taskDispatcher.async(on: .main, after: configuration.bannerSizeEventDelay) { [weak self] in
            guard let self else {
                return
            }

            // Ensure the same banner is being displayed after the delay.
            guard let currentBannerView = self.ad?.bannerView, bannerView === currentBannerView else {
                return
            }

            let cgSize = self.bannerCGSize(for: size)

            if cgSize.width > self.frame.width || cgSize.height > self.frame.height {
                logger.warning("BannerView (\(self.frame.size.pretty)) is smaller than minimum creative size (\(cgSize.pretty))")

                var requestSize: BackendEncodableSize?

                if let requestCGSize = self.request?.size.size {
                    requestSize = BackendEncodableSize(cgSize: requestCGSize)
                }

                let data = AdaptiveBannerSizeData(
                    auctionID: ad.winner.auctionID,
                    // Send the size that the ad will be rendered at.
                    creativeSize: BackendEncodableSize(cgSize: cgSize),
                    containerSize: BackendEncodableSize(cgSize: self.frame.size),
                    requestSize: requestSize
                )
                self.metrics.logContainerTooSmallWarning(adFormat: ad.request.adFormat, data: data, loadID: ad.request.loadID)
            }
        }
    }
}

// MARK: - Constants

extension BannerAdView {
    private enum Constants {
        static let minHeightForHorizontal: CGFloat = 50.0
        static let minWidthForVertical: CGFloat = 160.0
        static let minSizeFor1x1Tile: CGFloat = 300.0
    }
}

extension CGSize {
    fileprivate var pretty: String {
        return "\(width)x\(height)"
    }
}
