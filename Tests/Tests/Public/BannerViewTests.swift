// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation
import XCTest

class BannerAdViewTests: ChartboostMediationTestCase {
    lazy var bannerView: BannerAdView = setUpView()
    var controller = BannerSwapControllerProtocolMock()
    var networkManager: NetworkManagerProtocolMock { mocks.networkManager as! NetworkManagerProtocolMock }

    override func setUp() {
        super.setUp()

        // Create a fresh controller and set that as the return value on the mock adFactory.
        controller = BannerSwapControllerProtocolMock()
        mocks.adFactory.setReturnValue(controller, for: .makeBannerSwapController)

        bannerView = setUpView()

        // Remove all records.
        controller.removeAllRecords()
    }

    // MARK: - Properties
    func testsPassesThroughKeywords() {
        var keywords = ["testKey": "testValue"]
        bannerView.keywords = keywords
        XCTAssertEqual(controller.keywords, keywords)

        keywords = ["testKey2": "testValue2"]
        controller.keywords = keywords
        XCTAssertEqual(bannerView.keywords, keywords)
    }

    func testReturnsControllersRequest() {
        XCTAssertNil(bannerView.request)

        let request = BannerAdLoadRequest.test(placement: "placement", size: .adaptive(width: 200.0))
        controller.request = request
        XCTAssertEqual(bannerView.request, request)
    }

    func testReturnsControllersLoadMetrics() {
        XCTAssertNil(bannerView.loadMetrics)

        let metrics: [String: Any] = ["metric": "value"]
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(.test()), metrics: metrics)
        XCTAssertEqual(bannerView.loadMetrics?["metric"] as? String, "value")
    }

    func testReturnsControllersAdSize() {
        XCTAssertNil(bannerView.size)

        let size = BannerSize(size: CGSize(width: 100.0, height: 50.0), type: .adaptive)
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(.test(bannerSize: size)), metrics: nil)
        XCTAssertEqual(bannerView.size, size)
    }

    func testReturnsControllersBidInfo() {
        XCTAssertNil(bannerView.winningBidInfo)

        let bidInfo = ["key": "value"]
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(.test(bidInfo: bidInfo)), metrics: nil)
        XCTAssertEqual(bannerView.winningBidInfo?["key"] as? String, "value")
    }

    // MARK: - Init
    func testSetsBackgroundColorToClearOnInit() {
        XCTAssertEqual(bannerView.backgroundColor, .clear)
    }

    func testSetsDelegateOnInit() {
        XCTAssertIdentical(controller.delegate, bannerView)
    }

    // MARK: - Public Methods
    func testSendsLoadToController() {
        let request = BannerAdLoadRequest.test()
        let viewController = UIViewController()

        bannerView.load(with: request, viewController: viewController) { result in }
        XCTAssertMethodCalls(controller, .loadAd, parameters: [request, viewController, XCTMethodIgnoredParameter()])
    }

    func testSendsClearAdToController() {
        bannerView.reset()
        XCTAssertMethodCalls(controller, .clearAd)
    }

    // MARK: - Layout

    func testDoesNotLayoutBannerWhenHeightIsZero() {
        bannerView.frame = .zero
        
        let view = UIView()
        view.frame.size = CGSize(width: 100.0, height: 100.0)
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        // Ensure the ad's frame is set to 0 when the height of the bannerView is 0.
        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame, .zero)
    }

    func testDoesNotLayoutBannerWhenAspectRatioIsZero() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        view.frame.size = CGSize(width: 100.0, height: 100.0)
        let size = BannerSize(size: .zero, type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        // Ensure the ad's frame is set to 0 when the aspect ratio of the size is 0.
        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame, .zero)
    }

    func testDoesNotLayoutBannerWhenBannerSizeIsNegative() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        view.frame.size = CGSize(width: 100.0, height: 100.0)
        let size = BannerSize(size: CGSize(width: -1000.0, height: -1000.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        // Ensure the ad's frame is set to 0 when the aspect ratio of the size is 0.
        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame, .zero)
    }

    func testFixedBannerLayoutWhenSizeMatches() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame.size.width, 320.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.size.height, 50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testFixedBannerLayoutWhenSizeDoesNotMatch() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame.size.width, 320.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.size.height, 50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.x, 40.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 25.0, accuracy: Constants.accuracy)
    }

    // MARK: Alignment
    func testBannerAlignmentWhenSizeMatches() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHorizontalAlignmentLeft() {
        bannerView.frame.size = CGSize(width: 400.0, height: 50.0)
        bannerView.horizontalAlignment = .left

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHorizontalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 400.0, height: 50.0)
        bannerView.horizontalAlignment = .center

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 40.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHorizontalAlignmentRight() {
        bannerView.frame.size = CGSize(width: 400.0, height: 50.0)
        bannerView.horizontalAlignment = .right

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 80.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerVerticalAlignmentTop() {
        bannerView.frame.size = CGSize(width: 320.0, height: 100.0)
        bannerView.verticalAlignment = .top

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHVerticalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)
        bannerView.verticalAlignment = .center

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 25.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerVerticalAlignmentBottom() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)
        bannerView.verticalAlignment = .bottom

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 50.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHorizontalAlignmentLeft() {
        bannerView.frame.size = CGSize(width: 200.0, height: 50.0)
        bannerView.horizontalAlignment = .left

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHorizontalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 200.0, height: 50.0)
        bannerView.horizontalAlignment = .center

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -60.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHorizontalAlignmentRight() {
        bannerView.frame.size = CGSize(width: 200.0, height: 50.0)
        bannerView.horizontalAlignment = .right

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -120.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerVerticalAlignmentTop() {
        bannerView.frame.size = CGSize(width: 320.0, height: 20.0)
        bannerView.verticalAlignment = .top

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHVerticalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 400.0, height: 20.0)
        bannerView.verticalAlignment = .center

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, -15.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerVerticalAlignmentBottom() {
        bannerView.frame.size = CGSize(width: 400.0, height: 20.0)
        bannerView.verticalAlignment = .bottom

        let view = UIView()
        let size = BannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, -30.0, accuracy: Constants.accuracy)
    }

    // MARK: - Sizing

    func testHorizontalAdaptiveBannerWhenContainerSizeMatches() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 100.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeMatches() {
        bannerView.frame.size = CGSize(width: 200.0, height: 400.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 200.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 400.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeMatches() {
        bannerView.frame.size = CGSize(width: 400.0, height: 400.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 400.0, accuracy: Constants.accuracy)
    }

    // Container larger than ad, aspect ratio is taller than the aspect ratio of the ad.
    func testHorizontalAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 600.0, height: 200.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 25.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 600.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 150.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 300.0, height: 800.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 600.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 600.0, height: 800.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 600.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 600.0, accuracy: Constants.accuracy)
    }

    // Container smaller than ad min size, aspect ratio is taller than the aspect ratio of the ad.
    func testHorizontalAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 120.0, height: 40.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -40.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -5.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 200.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 50.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 100.0, height: 300.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -30.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -10.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 160.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 320.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 100.0, height: 200.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 300.0, accuracy: Constants.accuracy)
    }

    // Container larger than ad, aspect ratio is wider than the aspect ratio of the ad.
    func testHorizontalAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 1000.0, height: 200.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 800.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 200.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 400.0, height: 600.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 600.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 800.0, height: 600.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 600.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 600.0, accuracy: Constants.accuracy)
    }

    // Container smaller than ad min size, aspect ratio is wider than the aspect ratio of the ad.
    func testHorizontalAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 100.0, height: 20.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -15.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 200.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 50.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 100.0, height: 100.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -30.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -110.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 160.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 320.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 200.0, height: 100.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 300.0, accuracy: Constants.accuracy)
    }

    func testHorizonalAdaptiveBannerWhenAspectRatioIsVeryLarge() {
        bannerView.frame.size = CGSize(width: 500.0, height: 100.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 100.0, height: 1.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        // The container is larger than the minimum size, but since aspect fitting the banner within
        // the container would shrink the height to be smaller than the minimum, the minimum sizing
        // for the height kicks in.
        XCTAssertEqual(view.frame.origin.x, -2_250.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 25.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 5_000.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 50.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenAspectRatioIsVerySmall() {
        bannerView.frame.size = CGSize(width: 400.0, height: 400.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 1.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        // The container is larger than the minimum size, but since aspect fitting the banner within
        // the container would shrink the width to be smaller than the minimum, the minimum sizing
        // for the width kicks in.
        XCTAssertEqual(view.frame.origin.x, 120.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -7_800.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 160.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 16_000.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenSizeIsVerySmall() {
        bannerView.frame.size = CGSize(width: 400.0, height: 400.0)

        let view = UIView()
        let size = BannerSize(size: CGSize(width: 0.001, height: 0.001), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 400.0, accuracy: Constants.accuracy)
    }

    // MARK: - UIView

    func testIntrinsicContentSizeWithNoBanner() {
        XCTAssertEqual(bannerView.intrinsicContentSize.width, UIView.noIntrinsicMetric)
        XCTAssertEqual(bannerView.intrinsicContentSize.height, UIView.noIntrinsicMetric)
    }

    func testIntrinsicContentSize() {
        let size = BannerSize(size: CGSize(width: 100.0, height: 50.0), type: .adaptive)
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(.test(bannerSize: size)), metrics: nil)

        XCTAssertEqual(bannerView.intrinsicContentSize.width, 100.0)
        XCTAssertEqual(bannerView.intrinsicContentSize.height, 50.0)
    }

    // MARK: - Delegate
    func testDisplayBannerViewCallsDelegateBeforeAddingView() {
        let mockBannerAd = UIView()

        // Use a mock delegate with a block so we can ensure the state is correct after the delegate
        // method is called, but before it returns.
        let mockDelegate = DelegateMock()
        mockDelegate.willAppearBlock = {
            // Ensure the delegate method is called before the subview is added.
            XCTAssertEqual(self.bannerView.subviews.count, 0)
        }
        bannerView.delegate = mockDelegate

        XCTAssertEqual(self.bannerView.subviews.count, 0)
        bannerView.bannerSwapController(controller, displayBannerView: mockBannerAd)
        XCTAssertEqual(bannerView.subviews, [mockBannerAd])
    }

    func testClearBannerViewRemovesSubview() {
        let mockBannerAd = UIView()
        bannerView.bannerSwapController(controller, displayBannerView: mockBannerAd)
        XCTAssertEqual(bannerView.subviews, [mockBannerAd])

        bannerView.bannerSwapController(controller, clearBannerView: mockBannerAd)
        XCTAssertNil(mockBannerAd.superview)
    }

    func testPassesThroughDidRecordImpression() {
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.bannerAdViewDelegate, .didRecordImpression, parameters: [bannerView])
    }

    func testPassesThroughDidClick() {
        bannerView.bannerSwapControllerDidClick(controller)
        XCTAssertMethodCalls(mocks.bannerAdViewDelegate, .didClick, parameters: [bannerView])
    }

    // MARK: - Container too small error
    func testDoesNotSendContainerTooSmallErrorIfClearedBeforeTimerFires() throws {
        bannerView.frame.size = CGSize(width: 100.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 200.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])

        // Fake clearing the result.
        controller.showingBannerAdLoadResult = nil
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfNewBannerIsShownBeforeTimerFires() throws {
        bannerView.frame.size = CGSize(width: 100.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 200.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])

        // Fake displaying a new banner.
        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfFixedBannerIsSmallerThanContainer() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfAdaptiveBannerIsSmallerThanContainer() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 350.0, height: 80.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfFixedBannerIsEqualToContainer() throws {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfAdaptiveBannerIsEqualToContainer() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfAdaptiveBannerCanBeShrunkToFitInContainer() throws {
        bannerView.frame.size = CGSize(width: 300.0, height: 50.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    // MARK: Error cases
    func testContainerTooSmallErrorUsesConfigTime() throws {
        let expectedDelay: TimeInterval = 2.0
        mocks.bannerControllerConfiguration.bannerSizeEventDelay = expectedDelay

        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 400.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), expectedDelay])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning)
    }

    func testSendsContainerTooSmallErrorIfWidthOfContainerIsSmallerThanBannerFixed() throws {
        bannerView.frame.size = CGSize(width: 300.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning)
    }

    func testSendsContainerTooSmallErrorIfHeightContainerIsSmallerThanBannerFixed() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning)
    }

    func testSendsContainerTooSmallErrorIfWidthOfContainerIsSmallerThanBannerAdaptive() throws {
        // The width must be small enough so that the aspect fit height is smaller than the minimum.
        bannerView.frame.size = CGSize(width: 100.0, height: 50.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning)
    }

    func testSendsContainerTooSmallErrorIfHeightContainerIsSmallerThanBannerAdaptive() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: BannerSize(size: CGSize(width: 400.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning)
    }

    func testContainerTooSmallErrorFields() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        // Manually set up since we need to specify some values
        let view = UIView()
        let adSize = BannerSize(size: CGSize(width: 400.0, height: 50.0), type: .adaptive)
        let bid = Bid.test(
            identifier: "test_bid_id",
            partnerID: "test_partner_identifier",
            // The placement is pulled from the partner request, we'll set this to something else
            // to make sure we don't use this value.
            partnerPlacement: "incorrect_placement",
            lineItemIdentifier: "test_line_item_id",
            auctionID: "test_auction_id"
        )
        let adapter = PartnerAdapterMock()
        PartnerAdapterConfigurationMock1.partnerID = "test_partner_name"
        let partnerAdRequest = PartnerAdLoadRequest.test(partnerPlacement: "test_partner_placement")
        let partnerAd = PartnerBannerAdMock(adapter: adapter, request: partnerAdRequest, view: view)
        let adRequest = InternalAdLoadRequest.test(heliumPlacement: "test_placement_name", loadID: "test_load_id")
        let ad = LoadedAd(bids: [bid], winner: bid, bidInfo: [:], partnerAd: partnerAd, bannerSize: adSize, request: adRequest)
        controller.request = .test(size: BannerSize(size: CGSize(width: 500.0, height: 100.0), type: .adaptive))
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(ad), metrics: nil)
        bannerView.bannerSwapController(controller, displayBannerView: view)
        XCTAssertEqual(view.superview, bannerView)
        bannerView.layoutSubviews()

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        // Verify that `logContainerTooSmallWarning` is called with the correct parameters
        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning, parameters: [
            ad.request.adFormat,
            XCTMethodCaptureParameter { (data: AdaptiveBannerSizeData) in
                XCTAssertEqual(data.auctionID, "test_auction_id")
                XCTAssertEqual(data.creativeSize?.width, 400)
                XCTAssertEqual(data.creativeSize?.height, 50)
                XCTAssertEqual(data.containerSize?.width, 400)
                XCTAssertEqual(data.containerSize?.height, 40)
                XCTAssertEqual(data.requestSize?.width, 500)
                XCTAssertEqual(data.requestSize?.height, 100)
            },
            "test_load_id"
        ])
    }

    func testContainerTooSmallErrorSampledCreativeSize() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        // Manually set up since we need to specify some values
        let view = UIView()
        let adSize = BannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)

        let bid = Bid.test(
            identifier: "test_bid_id",
            partnerID: "test_partner_identifier",
            partnerPlacement: "incorrect_placement",
            lineItemIdentifier: "test_line_item_id",
            auctionID: "test_auction_id"
        )
        let adapter = PartnerAdapterMock()
        PartnerAdapterConfigurationMock1.partnerID = "test_partner_name"
        let partnerAdRequest = PartnerAdLoadRequest.test(partnerPlacement: "test_partner_placement")
        let partnerAd = PartnerBannerAdMock(adapter: adapter, request: partnerAdRequest, view: view)

        let adRequest = InternalAdLoadRequest.test(heliumPlacement: "test_placement_name", loadID: "test_load_id")
        let ad = LoadedAd(bids: [bid], winner: bid, bidInfo: [:], partnerAd: partnerAd, bannerSize: adSize, request: adRequest)
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(ad), metrics: nil)
        bannerView.layoutSubviews()

        // Ensure the loadID is correct
        XCTAssertEqual(ad.request.loadID, "test_load_id")

        // Fake the impression
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        // Verify that `logContainerTooSmallWarning` is called with the correct parameters
        XCTAssertMethodCalls(mocks.metrics, .logContainerTooSmallWarning, parameters: [
            ad.request.adFormat,
            XCTMethodCaptureParameter { (data: AdaptiveBannerSizeData) in
                XCTAssertEqual(data.creativeSize?.width, 200)
                XCTAssertEqual(data.creativeSize?.height, 50)
            },
            "test_load_id"
        ])
    }
}

// MARK: - Helpers
extension BannerAdViewTests {
    private class DelegateMock: BannerAdViewDelegate {
        var willAppearBlock: (() -> Void)?

        func willAppear(bannerView: BannerAdView) {
            willAppearBlock?()
        }
    }

    private func setUpView() -> BannerAdView {
        let result = BannerAdView()
        result.delegate = mocks.bannerAdViewDelegate
        return result
    }

    private func setUpControllerWithBanner(view: UIView, size: BannerSize) {
        let partnerAd = PartnerBannerAdMock(view: view)
        let ad = LoadedAd.test(partnerAd: partnerAd, bannerSize: size)
        controller.showingBannerAdLoadResult = InternalAdLoadResult(result: .success(ad), metrics: nil)
        bannerView.bannerSwapController(controller, displayBannerView: view)
        XCTAssertEqual(view.superview, bannerView)
        bannerView.layoutSubviews()
    }

    private func assertSendsNetworkRequest<T: HTTPRequest>() throws -> T {
        var result: T?
        let captureExpectation = expectation(description: "Capture parameter expectation")
        XCTAssertMethodCalls(
            networkManager,
            .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
            parameters: [
                XCTMethodCaptureParameter { request in
                    result = request
                    captureExpectation.fulfill()
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ])
        waitForExpectations(timeout: 1.0)
        return try XCTUnwrap(result)
    }
}

extension BannerAdViewTests {
    private struct Constants {
        static let accuracy: Double = 0.001
    }
}
