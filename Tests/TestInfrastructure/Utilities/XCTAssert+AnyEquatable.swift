// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest

/// Same as the standard `XCTAssertEqual` but for non-Equatable, AnyEquatable types.
func XCTAssertAnyEqual(_ first: AnyEquatable, _ second: AnyEquatable, file: StaticString = #file, line: UInt = #line) {
    XCTAssert(first.isEqual(to: second), "\(String(describing: first)) is not equal to \(String(describing: second))", file: file, line: line)
}

/// Same as the standard `XCTAssertNotEqual` but for non-Equatable, AnyEquatable types.
func XCTAssertAnyNotEqual(_ first: AnyEquatable, _ second: AnyEquatable, file: StaticString = #file, line: UInt = #line) {
    XCTAssert(!first.isEqual(to: second), "\(String(describing: first)) is equal to \(String(describing: second))", file: file, line: line)
}
