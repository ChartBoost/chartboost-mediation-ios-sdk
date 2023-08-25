// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostMediationErrorTests: XCTestCase {

    typealias Code = ChartboostMediationError.Code

    enum CustomError: Error, LocalizedError, CaseIterable {
        case foo
        case bar

        var errorDescription: String? {
            switch self {
            case .foo: return "got the foo"
            case .bar: return "jumped the bar"
            }
        }
    }

    func testBasic() {
        let code = Code.allCases.randomElement()!
        let error = ChartboostMediationError(code: code)
        XCTAssertEqual("com.chartboost.mediation", error.domain)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, code.message)
        let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertNil(underlyingError)
        if #available(iOS 14.5, *) {
            XCTAssertTrue(error.underlyingErrors.isEmpty)
        }
        let errorCode = Code(rawValue: error.code)
        XCTAssertNotNil(errorCode)
        XCTAssertEqual(code, errorCode)
        XCTAssertEqual(code, error.chartboostMediationCode)
    }

    func testWithDescription() {
        let code = Code.allCases.randomElement()!
        let error = ChartboostMediationError(code: code, description: "cannot compute!")
        XCTAssertEqual("com.chartboost.mediation", error.domain)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, code.message)
        XCTAssertEqual(error.userInfo[NSLocalizedFailureErrorKey] as? String, "cannot compute!")
        let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertNil(underlyingError)
        if #available(iOS 14.5, *) {
            XCTAssertTrue(error.underlyingErrors.isEmpty)
        }
        let errorCode = Code(rawValue: error.code)
        XCTAssertNotNil(errorCode)
        XCTAssertEqual(code, errorCode)
        XCTAssertEqual(code, error.chartboostMediationCode)
    }

    func testWithError() {
        CustomError.allCases.forEach { customError in
            let code = Code.allCases.randomElement()!
            let error = ChartboostMediationError(code: code, error: customError)
            XCTAssertEqual("com.chartboost.mediation", error.domain)
            XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, code.message)
            let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
            if let underlyingError = underlyingError {
                XCTAssertEqual(customError.errorDescription, underlyingError.localizedDescription)
            }
            else {
                XCTFail()
            }
            if #available(iOS 14.5, *) {
                XCTAssertEqual(1, error.underlyingErrors.count)
            }
            let errorCode = Code(rawValue: error.code)
            XCTAssertNotNil(errorCode)
            XCTAssertEqual(code, errorCode)
            XCTAssertEqual(code, error.chartboostMediationCode)
        }
    }

    func testWithErrorAndDescription() {
        CustomError.allCases.forEach { customError in
            let code = Code.allCases.randomElement()!
            let error = ChartboostMediationError(code: code, description: "cannot compute!", error: customError)
            XCTAssertEqual("com.chartboost.mediation", error.domain)
            XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, code.message)
            let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
            if let underlyingError = underlyingError {
                XCTAssertEqual(customError.errorDescription, underlyingError.localizedDescription)
            }
            else {
                XCTFail()
            }
            if #available(iOS 14.5, *) {
                XCTAssertEqual(1, error.underlyingErrors.count)
            }
            let errorCode = Code(rawValue: error.code)
            XCTAssertNotNil(errorCode)
            XCTAssertEqual(code, errorCode)
            XCTAssertEqual(code, error.chartboostMediationCode)
        }
    }

    func testWithMultipleErrors() {
        let code = Code.allCases.randomElement()!
        let error = ChartboostMediationError(code: code, errors: [CustomError.foo, CustomError.bar])
        let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertNil(underlyingError)
        if #available(iOS 14.5, *) {
            XCTAssertEqual(error.underlyingErrors as? [CustomError], [.foo, .bar])
        }
        let errorCode = Code(rawValue: error.code)
        XCTAssertNotNil(errorCode)
        XCTAssertEqual(code, errorCode)
        XCTAssertEqual(code, error.chartboostMediationCode)
    }

    func testLocalizedDescription() {
        for (code, expected) in Code.rawExpectedData {
            let error = ChartboostMediationError(code: code)
            XCTAssertEqual(error.localizedDescription, "\(expected.constant) (\(expected.codeString)). Cause: \(expected.cause) Resolution: \(expected.resolution)")
        }
    }
}
