// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation
import XCTest

class ChartboostMediationBannerViewTests: HeliumTestCase {
    lazy var bannerView: ChartboostMediationBannerView = setUpView()
    var controller: BannerSwapControllerMock = BannerSwapControllerMock()
    var networkManager = CompleteNetworkManagerMock()

    override func setUp() {
        super.setUp()

        networkManager = CompleteNetworkManagerMock()
        mocks.networkManager = networkManager

        // Create a fresh controller and set that as the return value on the mock adFactory.
        controller = BannerSwapControllerMock()
        mocks.adFactory.setReturnValue(controller, for: .makeBannerSwapController)

        bannerView = setUpView()

        // Remove all records to remove the call to viewVisibilityDidChange.
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

        let request = ChartboostMediationBannerLoadRequest.test(placement: "placement", size: .adaptive(width: 200.0))
        controller.request = request
        XCTAssertEqual(bannerView.request, request)
    }

    func testReturnsControllersLoadMetrics() {
        XCTAssertNil(bannerView.loadMetrics)

        let metrics: [String: Any] = ["metric": "value"]
        controller.showingBannerLoadResult = AdLoadResult(result: .success(.test()), metrics: metrics)
        XCTAssertEqual(bannerView.loadMetrics?["metric"] as? String, "value")
    }

    func testReturnsControllersAdSize() {
        XCTAssertNil(bannerView.size)

        let size = ChartboostMediationBannerSize(size: CGSize(width: 100.0, height: 50.0), type: .adaptive)
        controller.showingBannerLoadResult = AdLoadResult(result: .success(.test(adSize: size)), metrics: nil)
        XCTAssertEqual(bannerView.size, size)
    }

    func testReturnsControllersBidInfo() {
        XCTAssertNil(bannerView.winningBidInfo)

        let bidInfo = ["key": "value"]
        controller.showingBannerLoadResult = AdLoadResult(result: .success(.test(bidInfo: bidInfo)), metrics: nil)
        XCTAssertEqual(bannerView.winningBidInfo?["key"] as? String, "value")
    }

    // MARK: - Init
    func testSetsBackgroundColorToClearOnInit() {
        XCTAssertEqual(bannerView.backgroundColor, .clear)
    }

    func testSendsVisibilityUpdateToControllerOnInit() {
        // We remove the viewVisibilityDidChange record by default, so we'll create a local
        // controller and banner here to test this.
        let controller = BannerSwapControllerMock()
        mocks.adFactory.setReturnValue(controller, for: .makeBannerSwapController)
        let bannerView = ChartboostMediationBannerView()
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, false])
    }

    func testSetsDelegateOnInit() {
        XCTAssertIdentical(controller.delegate, bannerView)
    }

    // MARK: - Public Methods
    func testSendsLoadToController() {
        let request = ChartboostMediationBannerLoadRequest.test()
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
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        // Ensure the ad's frame is set to 0 when the height of the bannerView is 0.
        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame, .zero)
    }

    func testDoesNotLayoutBannerWhenAspectRatioIsZero() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        view.frame.size = CGSize(width: 100.0, height: 100.0)
        let size = ChartboostMediationBannerSize(size: .zero, type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        // Ensure the ad's frame is set to 0 when the aspect ratio of the size is 0.
        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame, .zero)
    }

    func testDoesNotLayoutBannerWhenBannerSizeIsNegative() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        view.frame.size = CGSize(width: 100.0, height: 100.0)
        let size = ChartboostMediationBannerSize(size: CGSize(width: -1000.0, height: -1000.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        // Ensure the ad's frame is set to 0 when the aspect ratio of the size is 0.
        XCTAssertEqual(view.superview, bannerView)
        XCTAssertEqual(view.frame, .zero)
    }

    func testFixedBannerLayoutWhenSizeMatches() {
        bannerView.frame.size = CGSize(width: 320.0, height: 50.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
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
        let size = ChartboostMediationBannerSize.standard
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
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHorizontalAlignmentLeft() {
        bannerView.frame.size = CGSize(width: 400.0, height: 50.0)
        bannerView.horizontalAlignment = .left

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHorizontalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 400.0, height: 50.0)
        bannerView.horizontalAlignment = .center

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 40.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHorizontalAlignmentRight() {
        bannerView.frame.size = CGSize(width: 400.0, height: 50.0)
        bannerView.horizontalAlignment = .right

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 80.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerVerticalAlignmentTop() {
        bannerView.frame.size = CGSize(width: 320.0, height: 100.0)
        bannerView.verticalAlignment = .top

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerHVerticalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)
        bannerView.verticalAlignment = .center

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 25.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsLargerVerticalAlignmentBottom() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)
        bannerView.verticalAlignment = .bottom

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 50.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHorizontalAlignmentLeft() {
        bannerView.frame.size = CGSize(width: 200.0, height: 50.0)
        bannerView.horizontalAlignment = .left

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHorizontalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 200.0, height: 50.0)
        bannerView.horizontalAlignment = .center

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -60.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHorizontalAlignmentRight() {
        bannerView.frame.size = CGSize(width: 200.0, height: 50.0)
        bannerView.horizontalAlignment = .right

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -120.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerVerticalAlignmentTop() {
        bannerView.frame.size = CGSize(width: 320.0, height: 20.0)
        bannerView.verticalAlignment = .top

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerHVerticalAlignmentCenter() {
        bannerView.frame.size = CGSize(width: 400.0, height: 20.0)
        bannerView.verticalAlignment = .center

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, -15.0, accuracy: Constants.accuracy)
    }

    func testBannerAlignmentWhenContainerIsSmallerVerticalAlignmentBottom() {
        bannerView.frame.size = CGSize(width: 400.0, height: 20.0)
        bannerView.verticalAlignment = .bottom

        let view = UIView()
        let size = ChartboostMediationBannerSize.standard
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.y, -30.0, accuracy: Constants.accuracy)
    }

    // MARK: - Sizing

    func testHorizontalAdaptiveBannerWhenContainerSizeMatches() {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 100.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeMatches() {
        bannerView.frame.size = CGSize(width: 200.0, height: 400.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 200.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 400.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeMatches() {
        bannerView.frame.size = CGSize(width: 400.0, height: 400.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 25.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 600.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 150.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 300.0, height: 800.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 600.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 600.0, height: 800.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -40.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -5.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 200.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 50.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 100.0, height: 300.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -30.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -10.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 160.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 320.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsTaller() {
        bannerView.frame.size = CGSize(width: 100.0, height: 200.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 800.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 200.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 400.0, height: 600.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, 50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, 0.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 600.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsLargerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 800.0, height: 600.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -15.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 200.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 50.0, accuracy: Constants.accuracy)
    }

    func testVerticalAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 100.0, height: 100.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -30.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -110.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 160.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 320.0, accuracy: Constants.accuracy)
    }

    func testTileAdaptiveBannerWhenContainerSizeIsSmallerAndAspectRatioIsWider() {
        bannerView.frame.size = CGSize(width: 200.0, height: 100.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 400.0), type: .adaptive)
        setUpControllerWithBanner(view: view, size: size)

        XCTAssertEqual(view.frame.origin.x, -50.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.origin.y, -100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.width, 300.0, accuracy: Constants.accuracy)
        XCTAssertEqual(view.frame.height, 300.0, accuracy: Constants.accuracy)
    }

    func testHorizonalAdaptiveBannerWhenAspectRatioIsVeryLarge() {
        bannerView.frame.size = CGSize(width: 500.0, height: 100.0)

        let view = UIView()
        let size = ChartboostMediationBannerSize(size: CGSize(width: 100.0, height: 1.0), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 1.0, height: 100.0), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 0.001, height: 0.001), type: .adaptive)
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
        let size = ChartboostMediationBannerSize(size: CGSize(width: 100.0, height: 50.0), type: .adaptive)
        controller.showingBannerLoadResult = AdLoadResult(result: .success(.test(adSize: size)), metrics: nil)

        XCTAssertEqual(bannerView.intrinsicContentSize.width, 100.0)
        XCTAssertEqual(bannerView.intrinsicContentSize.height, 50.0)
    }

    func testHidden() {
        // Banner needs to be inside a container, otherwise it will never become visible
        let container = UIView()
        container.addSubview(bannerView)
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, true])

        // if hidden controller should be notified
        bannerView.isHidden = true
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, false])

        // if unhidden controller should be notified
        bannerView.isHidden = false
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, true])
    }

    func testMoveAndRemoveFromSuperview() {
        let container = UIView()

        // when adding to superview controller should be notified
        container.addSubview(bannerView)
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, true])

        // when removing from superview controller should be notified
        bannerView.removeFromSuperview()
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, false])
    }

    func testMoveAndRemoveFromSuperviewWhenHidden() {
        let container = UIView()

        // if hidden controller should be notified
        bannerView.isHidden = true
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, false])

        // when adding to superview controller should be notified
        container.addSubview(bannerView)
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, false])

        // when removing from superview controller should be notified
        bannerView.removeFromSuperview()
        XCTAssertMethodCalls(controller, .viewVisibilityDidChange, parameters: [bannerView, false])
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
        XCTAssertMethodCalls(mocks.chartboostMediationBannerViewDelegate, .didRecordImpression, parameters: [bannerView])
    }

    func testPassesThroughDidClick() {
        bannerView.bannerSwapControllerDidClick(controller)
        XCTAssertMethodCalls(mocks.chartboostMediationBannerViewDelegate, .didClick, parameters: [bannerView])
    }

    // MARK: - Container too small error
    func testDoesNotSendContainerTooSmallErrorIfClearedBeforeTimerFires() throws {
        bannerView.frame.size = CGSize(width: 100.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])

        // Fake clearing the result.
        controller.showingBannerLoadResult = nil
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfNewBannerIsShownBeforeTimerFires() throws {
        bannerView.frame.size = CGSize(width: 100.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 200.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])

        // Fake displaying a new banner.
        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )
        mocks.taskDispatcher.performDelayedWorkItems()

        XCTAssertNoMethodCalls(networkManager)
    }

    func testDoesNotSendContainerTooSmallErrorIfFixedBannerIsSmallerThanContainer() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
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
            size: ChartboostMediationBannerSize(size: CGSize(width: 350.0, height: 80.0), type: .adaptive)
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
            size: ChartboostMediationBannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
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
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
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
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
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
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), expectedDelay])
        mocks.taskDispatcher.performDelayedWorkItems()

        let _: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
    }

    func testSendsContainerTooSmallErrorIfWidthOfContainerIsSmallerThanBannerFixed() throws {
        bannerView.frame.size = CGSize(width: 300.0, height: 100.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        let _: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
    }

    func testSendsContainerTooSmallErrorIfHeightContainerIsSmallerThanBannerFixed() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 320.0, height: 50.0), type: .fixed)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        let _: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
    }

    func testSendsContainerTooSmallErrorIfWidthOfContainerIsSmallerThanBannerAdaptive() throws {
        // The width must be small enough so that the aspect fit height is smaller than the minimum.
        bannerView.frame.size = CGSize(width: 100.0, height: 50.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        let _: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
    }

    func testSendsContainerTooSmallErrorIfHeightContainerIsSmallerThanBannerAdaptive() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 50.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        let _: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
    }

    func testContainerTooSmallErrorFields() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        // Manually set up since we need to specify some values
        let view = UIView()
        let adSize = ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 50.0), type: .adaptive)
        let bid = Bid.makeMock(
            identifier: "test_bid_id",
            partnerIdentifier: "test_partner_identifier",
            // The placement is pulled from the partner request, we'll set this to something else
            // to make sure we don't use this value.
            partnerPlacement: "incorrect_placement",
            lineItemIdentifier: "test_line_item_id",
            auctionIdentifier: "test_auction_id"
        )
        let adapter = PartnerAdapterMock()
        adapter.partnerIdentifier = "test_partner_name"
        let partnerAdRequest = PartnerAdLoadRequest.test(partnerPlacement: "test_partner_placement")
        let partnerAd = PartnerAdMock(adapter: adapter, request: partnerAdRequest, inlineView: view)
        let adRequest = HeliumAdLoadRequest.test(heliumPlacement: "test_placement_name", loadID: "test_load_id")
        let ad = HeliumAd(bid: bid, bidInfo: [:], partnerAd: partnerAd, adSize: adSize, request: adRequest)
        controller.request = .test(size: ChartboostMediationBannerSize(size: CGSize(width: 500.0, height: 100.0), type: .adaptive))
        controller.showingBannerLoadResult = AdLoadResult(result: .success(ad), metrics: nil)
        bannerView.bannerSwapController(controller, displayBannerView: view)
        XCTAssertEqual(view.superview, bannerView)
        bannerView.layoutSubviews()

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        // Ensure that we send the minimum size of the banner at the time of sampling.
        let request: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
        XCTAssertEqual(request.customHeaders["x-mediation-load-id"], "test_load_id")
        XCTAssertEqual(request.body.auctionID, "test_auction_id")
        XCTAssertEqual(request.body.creativeSize?.width, 400)
        XCTAssertEqual(request.body.creativeSize?.width, 400)
        XCTAssertEqual(request.body.creativeSize?.height, 50)
        XCTAssertEqual(request.body.containerSize?.width, 400)
        XCTAssertEqual(request.body.containerSize?.height, 40)
        XCTAssertEqual(request.body.requestSize?.width, 500)
        XCTAssertEqual(request.body.requestSize?.height, 100)
    }

    func testContainerTooSmallErrorSampledCreativeSize() throws {
        bannerView.frame.size = CGSize(width: 400.0, height: 40.0)

        setUpControllerWithBanner(
            view: UIView(),
            size: ChartboostMediationBannerSize(size: CGSize(width: 400.0, height: 100.0), type: .adaptive)
        )

        // Fake the impression.
        bannerView.bannerSwapControllerDidRecordImpression(controller)

        // Fake the delay.
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        mocks.taskDispatcher.performDelayedWorkItems()

        // Ensure that we send the minimum size of the banner at the time of sampling.
        let request: AdaptiveBannerSizeHTTPRequest = try assertSendsNetworkRequest()
        XCTAssertEqual(request.body.creativeSize?.width, 200)
        XCTAssertEqual(request.body.creativeSize?.height, 50)
    }
}

// MARK: - Helpers
extension ChartboostMediationBannerViewTests {
    private class DelegateMock: ChartboostMediationBannerViewDelegate {
        var willAppearBlock: (() -> Void)?

        func willAppear(bannerView: ChartboostMediationBannerView) {
            willAppearBlock?()
        }
    }

    private func setUpView() -> ChartboostMediationBannerView {
        let result = ChartboostMediationBannerView()
        result.delegate = mocks.chartboostMediationBannerViewDelegate
        return result
    }

    private func setUpControllerWithBanner(view: UIView, size: ChartboostMediationBannerSize) {
        let partnerAd = PartnerAdMock(inlineView: view)
        let ad = HeliumAd.test(partnerAd: partnerAd, adSize: size)
        controller.showingBannerLoadResult = AdLoadResult(result: .success(ad), metrics: nil)
        bannerView.bannerSwapController(controller, displayBannerView: view)
        XCTAssertEqual(view.superview, bannerView)
        bannerView.layoutSubviews()
    }

    private func assertSendsNetworkRequest<T: HTTPRequest>() throws -> T {
        var result: T?
        let captureExpectation = expectation(description: "Capture parameter expectation")
        XCTAssertMethodCalls(
            networkManager,
            .send,
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

extension ChartboostMediationBannerViewTests {
    private struct Constants {
        static let accuracy: Double = 0.001
    }
}
