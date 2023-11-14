// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class HeliumKeywordsTests: ChartboostMediationTestCase {
    // MARK: - Properties
    
    let keywords = HeliumKeywords()
    
    // MARK: - Tests
    
    func testEmptyByDefault() throws {
        XCTAssertNotNil(keywords.dictionary)
        XCTAssertTrue(keywords.dictionary.count == 0)
    }

    func testSetAllOK() throws {
        XCTAssertTrue(keywords.set(keyword: "foo", value: "bar"))
        XCTAssertTrue(keywords.set(keyword: "abc", value: "123"))
        XCTAssertTrue(keywords.set(keyword: "123", value: "null"))
        XCTAssertTrue(keywords.dictionary.count == 3)
        
        // key length = 64
        XCTAssertTrue(keywords.set(keyword: "abcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdef", value: "123"))

        // value length = 256
        XCTAssertTrue(keywords.set(keyword: "xyz", value: "abcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdef"))

        // value length = 0
        XCTAssertTrue(keywords.set(keyword: "helium", value: ""))
        
        let dictionary = keywords.dictionary
        XCTAssertNotNil(dictionary)
        XCTAssertTrue(dictionary.count == 6)

        XCTAssertEqual("bar", dictionary["foo"])
        XCTAssertEqual("123", dictionary["abc"])
        XCTAssertEqual("null", dictionary["123"])
    }

    func testSetInvalidKeywords() throws {
        // key length = 0
        XCTAssertFalse(keywords.set(keyword: "", value: "bar"))

        // key length > 64
        XCTAssertFalse(keywords.set(keyword: "abcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefg", value: "123"))

        // value length > 256
        XCTAssertFalse(keywords.set(keyword: "xyz", value: "abcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefabcdefghijklmnopqrstuvwxyzabcdefg"))

        XCTAssertTrue(keywords.dictionary.count == 0)
    }

    func testReplace() throws {
        XCTAssertTrue(keywords.set(keyword: "foo", value: "bar"))
        XCTAssertTrue(keywords.set(keyword: "abc", value: "123"))
        XCTAssertTrue(keywords.set(keyword: "123", value: "null"))
        
        XCTAssertTrue(keywords.set(keyword: "foo", value: "rab"))
        XCTAssertTrue(keywords.set(keyword: "abc", value: "321"))
        XCTAssertTrue(keywords.set(keyword: "123", value: "llun"))

        let dictionary = keywords.dictionary
        XCTAssertNotNil(dictionary)
        XCTAssertTrue(dictionary.count == 3)

        XCTAssertEqual("rab", dictionary["foo"])
        XCTAssertEqual("321", dictionary["abc"])
        XCTAssertEqual("llun", dictionary["123"])
    }

    func testRemove() throws {
        XCTAssertTrue(keywords.set(keyword: "foo", value: "bar"))
        XCTAssertTrue(keywords.set(keyword: "abc", value: "123"))
        XCTAssertTrue(keywords.set(keyword: "123", value: "null"))
        XCTAssertTrue(keywords.dictionary.count == 3)

        XCTAssertEqual("123", keywords.remove(keyword: "abc"))
        XCTAssertNotNil(keywords.dictionary)
        XCTAssertNil(keywords.dictionary["abc"])
        XCTAssertTrue(keywords.dictionary.count == 2)
        
        XCTAssertEqual("bar", keywords.remove(keyword: "foo"))
        XCTAssertNotNil(keywords.dictionary)
        XCTAssertNil(keywords.dictionary["foo"])
        XCTAssertTrue(keywords.dictionary.count == 1)

        XCTAssertEqual("null", keywords.remove(keyword: "123"))
        XCTAssertNotNil(keywords.dictionary)
        XCTAssertNil(keywords.dictionary["123"])
        XCTAssertTrue(keywords.dictionary.count == 0)

        // try to remove one of the already removed
        XCTAssertNil(keywords.remove(keyword: "foo"))
        XCTAssertNotNil(keywords.dictionary)
        XCTAssertTrue(keywords.dictionary.count == 0)
    }
    
    func testImmutableDictionary() throws {
        var dictionary = keywords.dictionary
        dictionary["abc"] = "123"
        XCTAssertTrue(keywords.dictionary.count == 0)
    }
}
