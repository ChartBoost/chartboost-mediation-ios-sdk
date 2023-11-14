// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class JSONTests: ChartboostMediationTestCase {

    func testInteger() throws {
        let data = try encode("1")
        
        let json = try decode(JSON<Int>.self, from: data)
        
        XCTAssertEqual(json.value, 1)
    }
    
    func testDouble() throws {
        let data = try encode("1.2")
        
        let json = try decode(JSON<Double>.self, from: data)
        
        XCTAssertEqual(json.value, 1.2)
    }
    
    func testString() throws {
        let data = try encode(#""some string""#)
        
        let json = try decode(JSON<String>.self, from: data)
        
        XCTAssertEqual(json.value, "some string")
    }
    
    func testBool() throws {
        let data = try encode("false")
        
        let json = try decode(JSON<Bool>.self, from: data)
        
        XCTAssertEqual(json.value, false)
    }
    
    func testArrayOfStrings() throws {
        let data = try encode(#"["a", "b", "c"]"#)
        
        let json = try decode(JSON<[String]>.self, from: data)
        
        XCTAssertEqual(json.value, ["a", "b", "c"])
    }
    
    func testArrayOfAny() throws {
        let data = try encode(#"["a", 23, false, ["23"], {"hello": "a", "bye": "b"}]"#)
        
        let json = try decode(JSON<[Any]>.self, from: data)
        
        XCTAssertJSONEqual(json.value, [
            "a",
            23,
            false,
            ["23"],
            ["hello": "a", "bye": "b"]
        ] as [Any])
    }
    
    func testObjectOfStrings() throws {
        let data = try encode(#"{"a": "1", "b": "2"}"#)
        
        let json = try decode(JSON<[String: String]>.self, from: data)
        
        XCTAssertEqual(json.value, ["a": "1", "b": "2"])
    }
    
    func testObjectOfAny() throws {
        let data = try encode(#"{"key1": 23, "key2": false, "key3": ["23"], "key4": {"hello": "a", "bye": "b", "23": [{"1": "2"}, {"1": "2"}]}}"#)
        
        let json = try decode(JSON<[String: Any]>.self, from: data)
        
        XCTAssertJSONEqual(json.value, [
            "key1": 23,
            "key2": false,
            "key3": ["23"],
            "key4": ["hello": "a", "bye": "b", "23": [["1": "2"], ["1": "2"]]] as [String : Any]
        ] as [String: Any])
    }
}

// MARK: - Helpers

extension JSONTests {
    
    private func encode(_ value: String) throws  -> Data {
        if let data = value.data(using: .utf8) {
            return data
        } else {
            throw NSError(domain: "tests", code: 0)
        }
    }
    
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}
