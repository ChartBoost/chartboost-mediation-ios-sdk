// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class HeliumBannerViewTests: ChartboostMediationTestCase {
    
    lazy var banner: HeliumBannerView = {
        let banner = HeliumBannerView(controller: mocks.bannerController, delegate: mocks.bannerDelegate)
        // viewVisibilityDidChange() is called on controller from the banner's init. we clean that up here to avoid doing it in every test
        mocks.bannerController.removeAllRecords()
        return banner
    }()
    let size = CHBHBannerSize.standard.cgSize
    
    func testInitialProperties() {
        XCTAssertEqual(banner.backgroundColor, .clear)
        XCTAssertEqual(banner.keywords?.dictionary, mocks.bannerController.keywords)
    }
    
    func testSizes() {
        let standardBanner = HeliumBannerView(
            controller: BannerControllerMock(request: .test(size: .standard)),
            delegate: nil
        )
        XCTAssertEqual(standardBanner.intrinsicContentSize, CGSize(width: 320, height: 50))

        let mediumBanner = HeliumBannerView(
            controller: BannerControllerMock(request: .test(size: .medium)),
            delegate: nil
        )
        XCTAssertEqual(mediumBanner.intrinsicContentSize, CGSize(width: 300, height: 250))

        let leaderboardBanner = HeliumBannerView(
            controller: BannerControllerMock(request: .test(size: .leaderboard)),
            delegate: nil
        )
        XCTAssertEqual(leaderboardBanner.intrinsicContentSize, CGSize(width: 728, height: 90))
    }
    
    func testSetKeywords() {
        let keywords = HeliumKeywords()
        
        banner.keywords = keywords
        
        XCTAssertEqual(banner.keywords, keywords)
        XCTAssertEqual(mocks.bannerController.keywords, keywords.dictionary)
    }
    
    func testLoadAd() {
        let viewController = UIViewController()
        
        banner.load(with: viewController)
        
        XCTAssertMethodCalls(mocks.bannerController, .loadAd, parameters: [viewController, XCTMethodIgnoredParameter()])
    }
    
    func testClearAd() {
        banner.clear()
        
        XCTAssertMethodCalls(mocks.bannerController, .clearAd)
    }
    
    func testHidden() {
        // Banner needs to be inside a container, otherwise it will never become visible
        let container = UIView()
        container.addSubview(banner)
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [true])
        
        // if hidden controller should be notified
        banner.isHidden = true
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [false])
        
        // if unhidden controller should be notified
        banner.isHidden = false
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [true])
    }
    
    func testMoveAndRemoveFromSuperview() {
        let container = UIView()
        
        // when adding to superview controller should be notified
        container.addSubview(banner)
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [true])

        // when removing from superview controller should be notified
        banner.removeFromSuperview()
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [false])
    }
    
    func testMoveAndRemoveFromSuperviewWhenHidden() {
        let container = UIView()
        
        // if hidden controller should be notified
        banner.isHidden = true
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [false])
        
        // when adding to superview controller should be notified
        container.addSubview(banner)
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [false])
        
        // when removing from superview controller should be notified
        banner.removeFromSuperview()
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [false])
    }
    
    /// Validates that a fresh banner that hasn't been added to a view hierarchy yet notifies the controller of its initial state
    func testVisibilityStateOnInit() {
        let banner = HeliumBannerView(controller: mocks.bannerController, delegate: nil)
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [false])
    }

    // MARK: - Ad View
    func testDisplayBannerView() {
        let expectedSize = CGSize(width: 200, height: 100)
        mocks.bannerController.request = .test(size: .init(size: expectedSize, type: .fixed))

        let view = UIView()
        banner.bannerController(mocks.bannerController, displayBannerView: view)
        XCTAssertIdentical(view.superview, banner)
        XCTAssertEqual(view.frame.origin, .zero)
        XCTAssertEqual(view.frame.size, expectedSize)
    }

    func testClearBannerView() {
        let view = UIView()
        banner.addSubview(view)
        XCTAssertIdentical(view.superview, banner)
        banner.bannerController(mocks.bannerController, clearBannerView: view)
        XCTAssertNil(view.superview)
    }

    // MARK: - Delegate
    func testCallsDelegateOnAdLoaded() {
        let expectedLoadID = "1234"
        let expectedPlacement = "mock_placement"
        let expectedWinningBidInfo = ["bidInfo": "asdf"]
        let viewController = UIViewController()
        mocks.bannerController.request = .test(placement: expectedPlacement)

        banner.load(with: viewController)

        var loadCompletion: ((ChartboostMediationBannerLoadResult) -> Void)?
        XCTAssertMethodCalls(mocks.bannerController, .loadAd, parameters: [viewController, XCTMethodCaptureParameter { (completion: @escaping (ChartboostMediationBannerLoadResult) -> Void) in loadCompletion = completion }])

        let result = ChartboostMediationBannerLoadResult(
            error: nil,
            loadID: expectedLoadID,
            metrics: nil,
            size: nil,
            winningBidInfo: expectedWinningBidInfo
        )
        loadCompletion?(result)
        XCTAssertMethodCalls(mocks.bannerDelegate, .didLoad, parameters: [expectedPlacement, expectedLoadID, expectedWinningBidInfo, nil])
    }

    func testPassesThroughDidRecordImpression() {
        let expectedPlacement = "mock_placement"
        mocks.bannerController.request = .test(placement: expectedPlacement)

        banner.bannerControllerDidRecordImpression(mocks.bannerController)

        XCTAssertMethodCalls(mocks.bannerDelegate, .didRecordImpression, parameters: [expectedPlacement])
    }

    func testPassesThroughDidClick() {
        let expectedPlacement = "mock_placement"
        mocks.bannerController.request = .test(placement: expectedPlacement)

        banner.bannerControllerDidClick(mocks.bannerController)

        XCTAssertMethodCalls(mocks.bannerDelegate, .didClick, parameters: [expectedPlacement, nil])
    }
}
