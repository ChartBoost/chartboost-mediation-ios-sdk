// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class LoggerTests: ChartboostMediationTestCase {

    let capture = LogCaptureHandler()

    override func setUp() {
        super.setUp()
        Logger.attachHandler(capture)
    }

    override func tearDown() {
        super.tearDown()
        Logger.detachHandler(capture)
        capture.didReceiveEntry = nil
        capture.clear()
    }

    // Tests that all log levels can be properly exercises through the `Logger.log()` method.
    func testDefaultLogger() throws {
        let logger = Logger.default
        LogLevel.all.forEach { level in
            let message = "testDefaultLogger-\(level.asString)"

            let expectation = expectation(description: message)
            capture.didReceiveEntry = { lastEntry in
                expectation.fulfill()

                guard let entry = lastEntry else {
                    return XCTFail("lastEntry was unexpectedly nil")
                }

                XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
                XCTAssertEqual("Chartboost Mediation", entry.category)
                XCTAssertEqual(message, entry.message)
                XCTAssertEqual(level, entry.logLevel)
            }

            logger.log(message, level: level)
            wait(for: [expectation], timeout: 1)
        }
    }

    // Tests that the trace log level is properly exercised through the `Logger.verbose()` method.
    func testDefaultLoggerVerbose() throws {
        let logger = Logger.default
        let message = "testDefaultLogger-verbose"

        let expectation = expectation(description: message)
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()

            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.verbose, entry.logLevel)
        }

        logger.verbose(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests that the trace log level is properly exercised through the `Logger.trace()` method.
    func testDefaultLoggerTrace() throws {
        let logger = Logger.default
        let message = "testDefaultLogger-trace"

        let expectation = expectation(description: message)
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()

            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.verbose, entry.logLevel)
        }

        logger.verbose(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests that the debug log level is properly exercised through the `Logger.debug()` method.
    func testDefaultLoggerDebug() throws {
        let logger = Logger.default
        let message = "testDefaultLogger-debug"

        let expectation = expectation(description: message)
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()

            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.debug, entry.logLevel)
        }

        logger.debug(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests that the info log level is properly exercised through the `Logger.info()` method.
    func testDefaultLoggerInfo() throws {
        let logger = Logger.default
        let message = "testDefaultLogger-info"

        let expectation = expectation(description: message)
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()
            
            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.info, entry.logLevel)
        }

        logger.info(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests that the warning log level is properly exercised through the `Logger.warning()` method.
    func testDefaultLoggerWarning() throws {
        let logger = Logger.default
        let message = "testDefaultLogger-warning"

        let expectation = expectation(description: message)
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()

            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.warning, entry.logLevel)
        }

        logger.warning(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests that the error log level is properly exercised through the `Logger.error()` method.
    func testDefaultLoggerError() throws {
        let logger = Logger.default
        let message = "testDefaultLogger-error"

        let expectation = expectation(description: message)
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()

            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.error, entry.logLevel)
        }

        logger.error(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests that attachmenet of the same handler instance is not possible.
    func testAttachExisting() throws {
        Logger.attachHandler(capture) // attaching it again
        Logger.attachHandler(capture) // attaching it again
        Logger.attachHandler(capture) // attaching it again

        // should only ouput once
        let message = "testAttachExisting"
        let expectation = expectation(description: message)
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        capture.didReceiveEntry = { lastEntry in
            expectation.fulfill()

            guard let entry = lastEntry else {
                return XCTFail("lastEntry was unexpectedly nil")
            }

            XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
            XCTAssertEqual("Chartboost Mediation", entry.category)
            XCTAssertEqual(message, entry.message)
            XCTAssertEqual(.info, entry.logLevel)
        }

        logger.info(message)
        wait(for: [expectation], timeout: 1)
    }

    // Tests a non-default logger and that all log levels can be properly exercises through the `Logger.log()` method.
    func testNonDefaultlLogger() throws {
        let logger = Logger(subsystem: "com.chartboost.mediation.sdk.tests", category: "unit-tests")
        LogLevel.all.forEach { level in
            let message = "testNonDefaultlLogger-\(level.asString)"

            let expectation = expectation(description: message)
            capture.didReceiveEntry = { lastEntry in
                expectation.fulfill()

                guard let entry = lastEntry else {
                    return XCTFail("lastEntry was unexpectedly nil")
                }

                XCTAssertEqual("com.chartboost.mediation.sdk.tests", entry.subsystem)
                XCTAssertEqual("Chartboost Mediation - unit-tests", entry.category)
                XCTAssertEqual(message, entry.message)
                XCTAssertEqual(level, entry.logLevel)
            }

            logger.log(message, level: level)
            wait(for: [expectation], timeout: 1)
        }
    }

    // Tests multiple handlers.
    func testMultipleHandlers() throws {
        class AnotherLogCaptureHandler: LogCaptureHandler {}
        let anotherCapture = AnotherLogCaptureHandler()
        Logger.attachHandler(anotherCapture)
        defer {
            anotherCapture.didReceiveEntry = nil
            Logger.detachHandler(anotherCapture)
        }

        let logger = Logger.default
        try LogLevel.all.forEach { level in
            let message = "testMultipleHandlers-\(level.asString)"

            let expectation1 = expectation(description: "Primary: \(message)")
            let expectation2 = expectation(description: "Secondary: \(message)")
            var date1: Date?
            var date2: Date?

            capture.didReceiveEntry = { lastEntry in
                expectation1.fulfill()

                guard let entry = lastEntry else {
                    return XCTFail("lastEntry was unexpectedly nil")
                }

                XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
                XCTAssertEqual("Chartboost Mediation", entry.category)
                XCTAssertEqual(message, entry.message)
                XCTAssertEqual(level, entry.logLevel)
                date1 = entry.date
            }
            anotherCapture.didReceiveEntry = { lastEntry in
                expectation2.fulfill()

                guard let entry = lastEntry else {
                    return XCTFail("lastEntry was unexpectedly nil")
                }

                XCTAssertEqual("com.chartboost.mediation.sdk", entry.subsystem)
                XCTAssertEqual("Chartboost Mediation", entry.category)
                XCTAssertEqual(message, entry.message)
                XCTAssertEqual(level, entry.logLevel)
                date2 = entry.date
            }

            logger.log(message, level: level)
            wait(for: [expectation1, expectation2], timeout: 1)

            // The dates of the two log capture handlers must be identical
            date1 = try XCTUnwrap(date1)
            date2 = try XCTUnwrap(date2)
            XCTAssertEqual(date1, date2)
        }
    }
}

extension LogLevel {
    static let all: [LogLevel] = [
        .none, .error, .warning, .info, .debug, .trace, .verbose
    ]

    var asString: String {
        switch self {
        case .none:
            return "none"
        case .error:
            return "error"
        case .warning:
            return "warning"
        case .info:
            return "info"
        case .debug:
            return "debug"
        case .trace:
            return "trace"
        case .verbose:
            return "verbose"
        }
    }
}
