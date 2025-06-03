// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class JSONTests: ChartboostMediationTestCase {

    // MARK: - Decoding Tests

    func testIntegerDecoding() throws {
        let data = try encode("1")
        
        let json = try decode(JSON<Int>.self, from: data)
        
        XCTAssertEqual(json.value, 1)
    }

    func testDecimalDecoding() throws {
        let data = try encode("1.2")

        let json = try decode(JSON<Decimal>.self, from: data)

        XCTAssertEqual(json.value, 1.2)
    }
    
    func testStringDecoding() throws {
        let data = try encode(#""some string""#)
        
        let json = try decode(JSON<String>.self, from: data)
        
        XCTAssertEqual(json.value, "some string")
    }
    
    func testBoolDecoding() throws {
        let data = try encode("false")
        
        let json = try decode(JSON<Bool>.self, from: data)
        
        XCTAssertFalse(json.value)
    }
    
    func testArrayOfStringsDecoding() throws {
        let data = try encode(#"["a", "b", "c"]"#)
        
        let json = try decode(JSON<[String]>.self, from: data)
        
        XCTAssertEqual(json.value, ["a", "b", "c"])
    }
    
    func testArrayOfAnyDecoding() throws {
        let data = try encode(#"["a", 23, 2.3, false, ["23"], {"hello": "a", "bye": "b"}]"#)

        let json = try decode(JSON<[Any]>.self, from: data)
        
        XCTAssertJSONEqual(json.value, [
            "a",
            23,
            2.3 as Decimal,
            false,
            ["23"],
            ["hello": "a", "bye": "b"]
        ] as [Any])
    }
    
    func testObjectOfStringsDecoding() throws {
        let data = try encode(#"{"a": "1", "b": "2"}"#)
        
        let json = try decode(JSON<[String: String]>.self, from: data)
        
        XCTAssertEqual(json.value, ["a": "1", "b": "2"])
    }
    
    func testObjectOfAnyDecoding() throws {
        let data = try encode(#"{"key1": 23, "key2": false, "key3": ["23"], "key4": {"hello": "a", "bye": "b", "23": [{"1": "2"}, {"1": "2"}]}, "key5": 1.3}"#)

        let json = try decode(JSON<[String: Any]>.self, from: data)
        
        XCTAssertJSONEqual(json.value, [
            "key1": 23,
            "key2": false,
            "key3": ["23"],
            "key4": ["hello": "a", "bye": "b", "23": [["1": "2"], ["1": "2"]]] as [String : Any],
            "key5": 1.3 as Decimal
        ] as [String: Any])
    }

    func testNullDecoding() throws {
        let data = try encode("null")
        let json = try decode(JSON<Any?>.self, from: data)
        XCTAssertNil(json.value)
    }

    func testDecodingInvalidJSONThrowsError() {
        let invalidJSON = #"{"key": {"nested": "value"}, "array": 123}"# // Incorrect structure
        let data = invalidJSON.data(using: .utf8)!

        XCTAssertThrowsError(try decode(JSON<[String: Int]>.self, from: data), "Expected type mismatch error") { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError but got \(error)")
        }
    }

    // MARK: - Encoding Tests

    func testIntegerEncoding() throws {
        let json = JSON<Int>(value: 42)
        let encodedData = try JSONEncoder().encode(json)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertEqual(jsonString, "42")
    }

    func testDecimalEncoding() throws {
        let decimalValue: Decimal = 3.14
        let json = JSON<Decimal>(value: decimalValue)
        let encodedData = try JSONEncoder().encode(json)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertEqual(jsonString, "3.14")
    }

    func testStringEncoding() throws {
        let json = JSON<String>(value: "hello")
        let encodedData = try JSONEncoder().encode(json)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertEqual(jsonString, "\"hello\"")
    }

    func testBoolEncoding() throws {
        let json = JSON<Bool>(value: true)
        let encodedData = try JSONEncoder().encode(json)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertEqual(jsonString, "true")
    }

    func testArrayEncoding() throws {
        let json = JSON<[Any]>(value: ["a", 1, false])
        let encodedData = try JSONEncoder().encode(json)
        // Use JSONSerialization to convert encoded data into a structure we can compare
        let jsonObject = try JSONSerialization.jsonObject(with: encodedData, options: [])
        guard let array = jsonObject as? [Any] else {
            XCTFail("Encoded data is not an array")
            return
        }
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0] as? String, "a")
        XCTAssertEqual(array[1] as? Int, 1)
        XCTAssertEqual(array[2] as? Bool, false)
    }

    func testObjectEncoding() throws {
        let original: [String: Any] = ["key": "value", "num": 10]
        let json = JSON<[String: Any]>(value: original)
        let encodedData = try JSONEncoder().encode(json)
        let jsonObject = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any]
        XCTAssertEqual(jsonObject as NSDictionary?, original as NSDictionary?)
    }

    func testNullEncoding() throws {
        let json = JSON<Any?>(value: nil)
        let encodedData = try JSONEncoder().encode(json)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertEqual(jsonString, "null")
    }

    // MARK: - Unsupported Type Test

    func testUnsupportedTypeThrowsError() throws {
        struct UnsupportedType {}
        let json = JSON<Any>(value: UnsupportedType())
        XCTAssertThrowsError(try JSONEncoder().encode(json))
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
