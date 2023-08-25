// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class HeliumBannerViewTests: HeliumTestCase {
    
    lazy var banner: HeliumBannerView = {
        let banner = HeliumBannerView(size: size, controller: mocks.bannerController)
        // viewVisibilityDidChange() is called on controller from the banner's init. we clean that up here to avoid doing it in every test
        mocks.bannerController.removeAllRecords()
        return banner
    }()
    let size = CHBHBannerSize.standard.cgSize
    
    func testInitialProperties() {
        XCTAssertEqual(banner.backgroundColor, .clear)
        XCTAssertEqual(banner.keywords, mocks.bannerController.keywords)
    }
    
    func testSizes() {
        let standardBanner = HeliumBannerView(size: CHBHBannerSize.standard.cgSize, controller: mocks.bannerController)
        XCTAssertEqual(standardBanner.intrinsicContentSize, CGSize(width: 320, height: 50))
        
        let mediumBanner = HeliumBannerView(size: CHBHBannerSize.medium.cgSize, controller: mocks.bannerController)
        XCTAssertEqual(mediumBanner.intrinsicContentSize, CGSize(width: 300, height: 250))
        
        let leaderboardBanner = HeliumBannerView(size: CHBHBannerSize.leaderboard.cgSize, controller: mocks.bannerController)
        XCTAssertEqual(leaderboardBanner.intrinsicContentSize, CGSize(width: 728, height: 90))
    }
    
    func testSetKeywords() {
        let keywords = HeliumKeywords()
        
        banner.keywords = keywords
        
        XCTAssertIdentical(banner.keywords, keywords)
        XCTAssertIdentical(mocks.bannerController.keywords, keywords)
    }
    
    func testLoadAd() {
        let viewController = UIViewController()
        
        banner.load(with: viewController)
        
        XCTAssertMethodCalls(mocks.bannerController, .loadAd, parameters: [viewController])
    }
    
    func testClearAd() {
        banner.clear()
        
        XCTAssertMethodCalls(mocks.bannerController, .clearAd)
    }
    
    func testHidden() {
        // Banner needs to be inside a container, otherwise it will never become visible
        let container = UIView()
        container.addSubview(banner)
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, true])
        
        // if hidden controller should be notified
        banner.isHidden = true
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, false])
        
        // if unhidden controller should be notified
        banner.isHidden = false
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, true])
    }
    
    func testMoveAndRemoveFromSuperview() {
        let container = UIView()
        
        // when adding to superview controller should be notified
        container.addSubview(banner)
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, true])

        // when removing from superview controller should be notified
        banner.removeFromSuperview()
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, false])
    }
    
    func testMoveAndRemoveFromSuperviewWhenHidden() {
        let container = UIView()
        
        // if hidden controller should be notified
        banner.isHidden = true
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, false])
        
        // when adding to superview controller should be notified
        container.addSubview(banner)
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, false])
        
        // when removing from superview controller should be notified
        banner.removeFromSuperview()
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, false])
    }
    
    /// Validates that a fresh banner that hasn't been added to a view hierarchy yet notifies the controller of its initial state
    func testVisibilityStateOnInit() {
        let banner = HeliumBannerView(size: size, controller: mocks.bannerController)
        
        XCTAssertMethodCalls(mocks.bannerController, .viewVisibilityDidChange, parameters: [banner, false])
        XCTAssertIdentical(mocks.bannerController.bannerContainer, banner)
    }
}
