// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class SafeJSONSerializerTests: ChartboostMediationTestCase {
    
    let serializer = SafeJSONSerializer()

    func testSerializeEmptyDictionary() throws {
        let data = try serializer.serialize([:])
        
        XCTAssertEqual(String(data: data, encoding: .utf8), "{}")
    }
    
    func testSerializeValidDictionary() throws {
        let data = try serializer.serialize(["a": 3, "bc": "123"])
        
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"a":3,"bc":"123"}"#)
    }
    
    func testSerializeInvalidDictionary() {
        XCTAssertThrowsError(
            try serializer.serialize(["a": Date()])
        )
    }

    func testSerializePrettyPrinted() throws {
        let data = try serializer.serialize(["a": 3, "bc": "123"], options: [.prettyPrinted, .sortedKeys])
        
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            """
            {
              "a" : 3,
              "bc" : "123"
            }
            """
        )
    }
    
    func testDeserializeEmptyData() throws {
        XCTAssertThrowsError(
            try serializer.deserialize(Data()) as [String: Any]
        )
    }
    
    func testDeserializeValidData() throws {
        let data = try XCTUnwrap(#"{"a":3,"bc":"123"}"#.data(using: .utf8))
        let object = try serializer.deserialize(data) as [String: Any]
        
        XCTAssertAnyEqual(object, ["a": 3, "bc": "123"] as [String: Any])
    }
    
    func testDeserializeWrongValueData() throws {
        let data = try XCTUnwrap(#"{"a":3,"bc":"123"}"#.data(using: .utf8))
        
        XCTAssertThrowsError(
            try serializer.deserialize(data) as [String]
        )
    }
    
    func testReserialize() throws {
        let data = try XCTUnwrap(#"{"a":3,"bc":"123"}"#.data(using: .utf8))
        
        let reserializedData = try serializer.reserialize(data, options: [.prettyPrinted, .sortedKeys])
        
        XCTAssertEqual(
            String(data: reserializedData, encoding: .utf8),
            """
            {
              "a" : 3,
              "bc" : "123"
            }
            """
        )
    }
}
