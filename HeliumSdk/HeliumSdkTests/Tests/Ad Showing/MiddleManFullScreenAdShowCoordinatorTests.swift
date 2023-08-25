// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class MiddleManFullScreenAdShowCoordinatorTests: HeliumTestCase {

    lazy var coordinator = MiddleManFullScreenAdShowCoordinator()
    
    func testObserverIsNotRetained() {
        var observer: FullScreenAdShowObserver?
        autoreleasepool {
            observer = FullScreenAdShowObserverMock()
            coordinator.addObserver(observer!)
            observer = nil
        }
        XCTAssertNil(observer)
        
        coordinator.didShowFullScreenAd()   // just to make sure nothing happens
    }
    
    func testDidShowFullScreenAdWithNoObservers() {
        coordinator.didShowFullScreenAd()   // just to make sure nothing happens
    }
    
    func testDidShowFullScreenAdWithOneObservers() {
        let observer = FullScreenAdShowObserverMock()
        coordinator.addObserver(observer)
        
        coordinator.didShowFullScreenAd()
        
        XCTAssertEqual(observer.recordedMethods, [.didShowFullScreenAd])
    }
    
    func testDidShowFullScreenAdWithThreeObservers() {
        let observer1 = FullScreenAdShowObserverMock()
        let observer2 = FullScreenAdShowObserverMock()
        let observer3 = FullScreenAdShowObserverMock()
        coordinator.addObserver(observer1)
        coordinator.addObserver(observer2)
        coordinator.addObserver(observer3)
        
        coordinator.didShowFullScreenAd()
        
        XCTAssertEqual(observer1.recordedMethods, [.didShowFullScreenAd])
        XCTAssertEqual(observer2.recordedMethods, [.didShowFullScreenAd])
        XCTAssertEqual(observer3.recordedMethods, [.didShowFullScreenAd])
    }
    
    func testDidCloseFullScreenAdWithNoObservers() {
        coordinator.didCloseFullScreenAd()   // just to make sure nothing happens
    }
    
    func testDidCloseFullScreenAdWithOneObservers() {
        let observer = FullScreenAdShowObserverMock()
        coordinator.addObserver(observer)
        
        coordinator.didCloseFullScreenAd()
        
        XCTAssertEqual(observer.recordedMethods, [.didCloseFullScreenAd])
    }
    
    func testDidCloseFullScreenAdWithThreeObservers() {
        let observer1 = FullScreenAdShowObserverMock()
        let observer2 = FullScreenAdShowObserverMock()
        let observer3 = FullScreenAdShowObserverMock()
        coordinator.addObserver(observer1)
        coordinator.addObserver(observer2)
        coordinator.addObserver(observer3)
        
        coordinator.didCloseFullScreenAd()
        
        XCTAssertEqual(observer1.recordedMethods, [.didCloseFullScreenAd])
        XCTAssertEqual(observer2.recordedMethods, [.didCloseFullScreenAd])
        XCTAssertEqual(observer3.recordedMethods, [.didCloseFullScreenAd])
    }
    
    func testMultipleEventsWithMultipleObservers() {
        let observer1 = FullScreenAdShowObserverMock()
        coordinator.addObserver(observer1)
        // also add another observer in the middle to test all together
        var observer2: FullScreenAdShowObserver?
        autoreleasepool {
            observer2 = FullScreenAdShowObserverMock()
            coordinator.addObserver(observer2!)
            observer2 = nil
        }
        let observer3 = FullScreenAdShowObserverMock()
        let observer4 = FullScreenAdShowObserverMock()
        coordinator.addObserver(observer3)
        coordinator.addObserver(observer4)
        
        coordinator.didCloseFullScreenAd()
        coordinator.didShowFullScreenAd()
        coordinator.didCloseFullScreenAd()
        
        XCTAssertEqual(observer1.recordedMethods, [.didCloseFullScreenAd, .didShowFullScreenAd, .didCloseFullScreenAd])
        XCTAssertNil(observer2)
        XCTAssertEqual(observer3.recordedMethods, [.didCloseFullScreenAd, .didShowFullScreenAd, .didCloseFullScreenAd])
        XCTAssertEqual(observer4.recordedMethods, [.didCloseFullScreenAd, .didShowFullScreenAd, .didCloseFullScreenAd])
    }
}
