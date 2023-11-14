// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import XCTest

func XCTAssertJSONEqual(_ first: Any?, _ second: Any?, file: StaticString = #file, line: UInt = #line) {
    JSONObject.xctAssertEqual(first, second, file: file, line: line)
}

struct JSONObject: Equatable {
    
    var value: Any
    
    init?(_ value: Any) {
        guard value is String || value is Bool || value is Int || value is Double || value is Array<Any> || value is Dictionary<AnyHashable, Any> || value is NSNull else {
            return nil
        }
        self.value = value
    }
    
    @discardableResult
    static func xctAssertEqual(_ optionalFirst: Any?, _ optionalSecond: Any?, file: StaticString = #file, line: UInt = #line) -> Bool {
        guard let first = optionalFirst, let second = optionalSecond else {
            let bothNil = optionalFirst == nil && optionalSecond == nil
            XCTAssert(bothNil, file: file, line: line)
            return bothNil
        }
        guard let jsonFirst = JSONObject(first), let jsonSecond = JSONObject(second) else {
            XCTFail("Non-JSON object: \(first) and/or \(second)", file: file, line: line)
            return false
        }
        return jsonFirst.xctAssertEqual(to: jsonSecond, file: file, line: line)
    }
    
    @discardableResult
    static func xctAssertNotEqual(_ optionalFirst: Any?, _ optionalSecond: Any?, file: StaticString = #file, line: UInt = #line) -> Bool {
        guard let first = optionalFirst, let second = optionalSecond else {
            let bothNil = optionalFirst == nil && optionalSecond == nil
            XCTAssert(!bothNil, file: file, line: line)
            return !bothNil
        }
        guard let jsonFirst = JSONObject(first), let jsonSecond = JSONObject(second) else {
            XCTFail("Non-JSON object: \(first) and/or \(second)", file: file, line: line)
            return false
        }
        let equal = jsonFirst == jsonSecond
        XCTAssert(!equal, file: file, line: line)
        return !equal
    }
    
    @discardableResult
    func xctAssertEqual(to object: JSONObject, file: StaticString = #file, line: UInt = #line) -> Bool {
        return JSONObject.equalityCheck(lhs: self, rhs: object, assert: true, key: nil, file: file, line: line)
    }
    
    static func ==(lhs: JSONObject, rhs: JSONObject) -> Bool {
        return JSONObject.equalityCheck(lhs: lhs, rhs: rhs, assert: false, key: nil, file: #file, line: #line)
    }
    
    private static func equalityCheck(lhs: JSONObject, rhs: JSONObject, assert: Bool, key: String?, file: StaticString = #file, line: UInt = #line) -> Bool {
        if let lhs = lhs.value as? String, let rhs = rhs.value as? String {
            if assert { XCTAssert(lhs == rhs, "JSON not equal: \((key != nil) ? "\"" + key! + "\" " : "")\(lhs) and \(rhs)", file: file, line: line) }
            return lhs == rhs
        } else if let lhs = lhs.value as? NSNumber, lhs === kCFBooleanTrue || lhs === kCFBooleanFalse, let rhs = rhs.value as? NSNumber, rhs === kCFBooleanTrue || rhs === kCFBooleanFalse {
            if assert { XCTAssert(lhs == rhs, "JSON not equal: \((key != nil) ? "\"" + key! + "\" " : "")\(lhs) and \(rhs)", file: file, line: line) }
            return lhs == rhs
        } else if let lhs = lhs.value as? NSNumber, lhs !== kCFBooleanTrue && lhs !== kCFBooleanFalse, let rhs = rhs.value as? NSNumber, rhs !== kCFBooleanTrue && rhs !== kCFBooleanFalse {
            if let lhsI = lhs as? Int, let rhsI = rhs as? Int {
                if assert { XCTAssert(lhsI == rhsI, "JSON not equal: \((key != nil) ? "\"" + key! + "\" " : "")\(lhsI) and \(rhsI)", file: file, line: line) }
                return lhsI == rhsI
            }
            else if let lhsI = lhs as? Double, let rhsI = rhs as? Double {
                if assert { XCTAssert(lhsI == rhsI, "JSON not equal: \((key != nil) ? "\"" + key! + "\" " : "")\(lhsI) and \(rhsI)", file: file, line: line) }
                return lhsI == rhsI
            }
        } else if let lhs = lhs.value as? Array<Any>, let rhs = rhs.value as? Array<Any> {
            if lhs.count != rhs.count {
                if assert { XCTFail("JSON not equal (different count): \((key != nil) ? "\"" + key! + "\" " : "")\(lhs) and \(rhs)", file: file, line: line) }
                return false
            }
            for (lhsElement, rhsElement) in zip(lhs, rhs) {
                guard let jsonLhsElement = JSONObject(lhsElement), let jsonRhsElement = JSONObject(rhsElement) else {
                    if assert {
                        XCTFail("JSON object contains non-JSON children: \((key != nil) ? "\"" + key! + "\" " : "")\(lhsElement) and/or \(rhsElement)", file: file, line: line)
                    }
                    return false
                }
                if !JSONObject.equalityCheck(lhs: jsonLhsElement, rhs: jsonRhsElement, assert: assert, key: nil, file: file, line: line) {
                    return false
                }
            }
            return true
        } else if let lhs = lhs.value as? Dictionary<AnyHashable, Any>, let rhs = rhs.value as? Dictionary<AnyHashable, Any> {
            if lhs.count != rhs.count {
                if assert { XCTFail("JSON not equal (different count): \((key != nil) ? "\"" + key! + "\" " : "")\(lhs) and \(rhs)", file: file, line: line) }
                return false
            }
            for (lhsKey, lhsValue) in lhs {
                guard let rhsValue = rhs[lhsKey] else {
                    if assert { XCTFail("JSON not equal (missing key): \((key != nil) ? "\"" + key! + "\" " : "")\(lhsKey) in \(rhs)", file: file, line: line) }
                    return false
                }
                guard let jsonLhsValue = JSONObject(lhsValue), let jsonRhsValue = JSONObject(rhsValue) else {
                    if assert {
                        XCTFail("JSON object contains non-JSON children: \((key != nil) ? "\"" + key! + "\" " : "")\(lhsValue) and/or \(rhsValue)", file: file, line: line)
                    }
                    return false
                }
                if !JSONObject.equalityCheck(lhs: jsonLhsValue, rhs: jsonRhsValue, assert: assert, key: lhsKey as? String, file: file, line: line) {
                    return false
                }
            }
            return true
        } else if lhs.value is NSNull, rhs.value is NSNull {
            return true
        }
        if assert { XCTFail("JSON not equal (different types): \((key != nil) ? "\"" + key! + "\" " : "")\(lhs.value) and \(rhs.value)", file: file, line: line) }
        return false
    }
}
