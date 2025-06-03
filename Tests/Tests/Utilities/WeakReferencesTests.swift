// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
import UIKit
@testable import ChartboostMediationSDK

class WeakReferencesTests: ChartboostMediationTestCase {
    
    /// Validates WeakReferences functionality when empty.
    func testEmpty() {
        // Create the sequence
        let references = WeakReferences<UIView>()
        
        // Check nothing breaks if it's empty
        for _ in references {
            XCTFail("Sequence is empty so this should not execute")
        }
    }

    /// Validates WeakReferences functionality with a NSObject element type.
    func testWithObjClassElement() {
        // Create the sequence
        let references = WeakReferences<UIView>()
        
        // Add elements
        let addedElements = [UIView(), UIView(), UIView()]
        references.add(addedElements[0])
        references.add(addedElements[1])
        references.add(addedElements[2])
        
        // Check that the sequence can properly iterate over its elements
        var visitedElements: [UIView] = []
        for element in references {
            XCTAssertTrue(addedElements.contains(element))
            XCTAssertFalse(visitedElements.contains(element))
            visitedElements.append(element)
        }
        XCTAssertEqual(visitedElements.count, addedElements.count)
    }
    
    /// Just for testing.
    private class SomeClass {}
    
    /// Validates WeakReferences functionality with a non-ObjC non-NSObject element type.
    func testWithNonObjClassElement() {
        // Create the sequence
        let references = WeakReferences<SomeClass>()
        
        // Add elements
        let addedElements = [SomeClass(), SomeClass(), SomeClass()]
        references.add(addedElements[0])
        references.add(addedElements[1])
        references.add(addedElements[2])
        
        // Check that the sequence can properly iterate over its elements
        var visitedElements: [SomeClass] = []
        for element in references {
            XCTAssertTrue(addedElements.contains(where: { $0 === element }))
            XCTAssertFalse(visitedElements.contains(where: { $0 === element }))
            visitedElements.append(element)
        }
        XCTAssertEqual(visitedElements.count, addedElements.count)
    }
    
    /// Validates WeakReferences does not retain elements.
    func testElementsAreNotRetained() {
        // Create the sequence
        let references = WeakReferences<UIView>()
        
        // Add elements. One retained by test, others inside an autoreleasepool so they are released when we exit the pool's scope
        let retainedElement = UIView()
        weak var nonRetainedElement1: UIView?
        weak var nonRetainedElement2: UIView?
        autoreleasepool {
            //
            let addedElements = [UIView(), retainedElement, UIView()]
            nonRetainedElement1 = addedElements[0]
            nonRetainedElement2 = addedElements[2]
            references.add(addedElements[0])
            references.add(addedElements[1])
            references.add(addedElements[2])
            
            // Check that the sequence can properly iterate over its elements
            var visitedElements: [UIView] = []
            for element in references {
                XCTAssertTrue(addedElements.contains(element))
                XCTAssertFalse(visitedElements.contains(element))
                visitedElements.append(element)
            }
            XCTAssertEqual(visitedElements.count, addedElements.count)
        }
        
        // Check that the elements were not retained by the sequence
        XCTAssertNil(nonRetainedElement1)
        XCTAssertNil(nonRetainedElement2)
        
        // Check that the sequence can properly iterate over its elements, now only 1
        var visitedElements: [UIView] = []
        for element in references {
            XCTAssertIdentical(element, retainedElement)
            visitedElements.append(element)
        }
        XCTAssertEqual(visitedElements.count, 1)
    }
}
