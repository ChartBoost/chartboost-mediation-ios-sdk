// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class NotificationCenterILRDEventPublisherTests: ChartboostMediationTestCase {

    lazy var publisher = NotificationCenterILRDEventPublisher()
    var callCount = 0
    
    /// Validates that a NotificationCenter notification is posted passing a valid ImpressionData object
    func testPost() {
        let placement = "some placement"
        let jsonData = ["key1": 23, "key2": "hello", "ket3": [1, 2, 3]] as [String: Any]
        
        // not using XCTest expectation(forNotification:object:handler:) because it was found unreliable to catch notifications during our tests
        let expectation = expectation(description: "wait to receive notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .chartboostMediationDidReceiveILRD,
            object: nil,
            queue: nil
        ) { notification in
            let ilrd = notification.object as? ImpressionData
            
            XCTAssertNotNil(ilrd)
            XCTAssertEqual(ilrd?.placement, placement)
            XCTAssertJSONEqual(ilrd?.jsonData, jsonData)
            
            expectation.fulfill()
        }
        
        publisher.postILRDEvent(forPlacement: placement, ilrdJSON: jsonData)
        
        wait(for: [expectation], timeout: 2)
        NotificationCenter.default.removeObserver(observer)
    }
}
