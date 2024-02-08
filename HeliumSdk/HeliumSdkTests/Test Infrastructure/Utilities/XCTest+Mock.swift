// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest

// MARK: - Types

/// A placeholder for a parameter which we do not care to validate.
/// When passed in a call to XCTAssertMethodCalls() the parameter at that position is ignored.
///
/// Example where we want to check the first parameter in a method call but we don't care about the second:
/// ```
/// XCTAssertMethodCalls(mock, .someMethod, parameters: [false, XCTMethodIgnoredParameter()])
/// ```
struct XCTMethodIgnoredParameter {}

/// A placeholder for a parameter which we cannot compare using AnyEquatable.
/// This may be because infering the values for all the properties in the expected object is too difficult or undesirable.
/// When passed in a call to XCTAssertMethodCalls() the associated closure is executed with the parameter at that position as an argument.
///
/// Example where a notification center mock has a `postNotification(_ notification: Notification)` method where we cannot compare the notification
/// parameter to an expected object but we still want to validate its name and object:
/// ```
/// XCTAssertMethodCalls(notificationCenterMock, .postNotification, parameters: [
///     XCTMethodSomeParameter<Notification> { notification in
///         XCTAssertEqual(notification.name, "expected notification name")
///         XCTAssertEqual(notification.object as? SomeCustomObject, expectedObject)
///     }
/// ])
/// ```
struct XCTMethodSomeParameter<T>: AnyXCTMethodSomeParameter {
    fileprivate let parameterCheck: (Any?) -> Bool
    /// - parameter closure: A closure to be executed with the recorded parameter when comparing parameters in a call to XCTAssertMethodCalls().
    init(_ closure: @escaping (T) -> Void) {
        parameterCheck = { (parameter: Any?) in
            if let parameter = parameter as? T {
                closure(parameter)
                return true
            } else {
                return false
            }
        }
    }
}

/// A placeholder for a parameter which we want to capture.
/// This may be used to keep a reference to a completion handler to be executed later.
///
/// Example where we capture a completion handler pass to a mocked method and then call it:
/// ```
/// var completion: ((Bool) -> Void)?
/// XCTAssertMethodCalls(mock, .methodWithCompletion, parameters: [
///     XCTMethodCaptureParameter { completion = $0 }
/// ])
/// completion?(true)
/// ```
typealias XCTMethodCaptureParameter = XCTMethodSomeParameter

private protocol AnyXCTMethodSomeParameter {
    var parameterCheck: (Any?) -> Bool { get }
}

// MARK: - XCTAssert Methods

/// Asserts all the method calls and parameters passed to the given mock.
/// Note that the `parameters` parameter is optional. It is possible to check only for method calls regardless of the parameters passed.
///
/// Example where we check that `someMethod()` is called twice, first with `false` and `"hello"` as parameters, then with `true` and `"bye"`:
/// ```
/// XCTAssertMethodCalls(mock, .someMethod, .someMethod, parameters: [false, "hello"], [true, "bye"])
/// ```
func XCTAssertMethodCalls<Method>(_ mock: Mock<Method>, _ methods: Method..., parameters: [Any?]..., file: StaticString = #file, line: UInt = #line) {
    // Remove mock records so on next calls to XCTAssertMethodCalls() we validate only the method calls made after this point.
    defer {
        mock.removeAllRecords()
    }
    // Check that the number of recorded and expected method calls matches.
    guard mock.recordedMethods == methods else {
        XCTFail("Expected \(methods) but got \(mock.recordedMethods)", file: file, line: line)
        return
    }
    
    // Finish if the expected parameters list is empty, which means we don't want to do any parameter check.
    guard !parameters.isEmpty else {
        return  // no parameters check
    }
    
    // Check that the number of recorded and expected parameters matches. This should always be the case unless a Mock subclass has a faulty implementation.
    guard mock.recordedParameters.count == parameters.count else {
        XCTFail("Expected \(parameters.count) method calls but got \(mock.recordedParameters.count)", file: file, line: line)
        return
    }
    
    // For each method call, validate its recorded parameters.
    for (recorded, expected) in zip(mock.recordedParameters, parameters) {
        assertParametersEqual(recorded: recorded, expected: expected, file: file, line: line)
    }
}

/// Asserts that the method call and parameters are at the top of the given mocks recorded method/parameter stack.
/// Note that the `parameters` parameter is optional. It is possible to check only for method calls regardless of the parameters passed.
///
/// Example where we check that `someMethod()` is called, with `false` and `"hello"` as parameters:
/// ```
/// XCTAssertMethodCallPop(mock, .someMethod, parameters: [false, "hello"])
/// ```
func XCTAssertMethodCallPop<Method>(_ mock: Mock<Method>, _ method: Method, parameters: [Any?], file: StaticString = #file, line: UInt = #line) {
    // Remove mock records so on next calls to XCTAssertMethodCallPop() we validate only the method calls made after this point.
    defer {
        mock.popRecord()
    }

    // Ensure a method call was made.
    guard let recordedMethod = mock.recordedMethods.first else {
        XCTFail("Expected \(method) but no method calls were made", file: file, line: line)
        return
    }

    // Check that the method call matches.
    guard recordedMethod == method else {
        XCTFail("Expected \(method) but got \(recordedMethod)", file: file, line: line)
        return
    }

    // Finish if the expected parameters list is empty, which means we don't want to do any parameter check.
    guard !parameters.isEmpty else {
        return  // no parameters check
    }

    assertParametersEqual(recorded: mock.recordedParameters.first ?? [], expected: parameters, file: file, line: line)
}

/// Asserts the call count for a specific method in a given mock.
///
/// Example where we check that `someMethod()` is called 3 times, regardless if other methods where called too:
/// ```
/// XCTAssertMethodCallCount(mock, .someMethod, calls: 3)
/// ```
func XCTAssertMethodCallCount<Method>(_ mock: Mock<Method>, _ method: Method, calls: Int, file: StaticString = #file, line: UInt = #line) {
    let methods = mock.recordedMethods.filter { $0 == method }
    if methods.count != calls {
         XCTFail("\(mock) calls \(method) \(methods.count) times but \(calls) was expected", file: file, line: line)
    }
}

/// Asserts one single method was called at least once and validates the parameters passed in that call, for a given mock.
///
/// Example where we check that `someMethod()` is called with `false` and `"hello"` as parameters, regardless if further calls to this or
/// other methods where made too:
/// ```
/// XCTAssertMethodCallsContains(mock, .someMethod, parameters: [false, "hello"])
/// ```
func XCTAssertMethodCallsContains<Method>(_ mock: Mock<Method>, _ method: Method, parameters: [Any?], file: StaticString = #file, line: UInt = #line) {
    guard let methodIndex = mock.recordedMethods.firstIndex(of: method) else {
        XCTFail("\(mock) does not have a record of a call to \(method))", file: file, line: line)
        return
    }
    assertParametersEqual(recorded: mock.recordedParameters[methodIndex], expected: parameters, file: file, line: line)
}

/// Asserts no calls were made for any method for a given mock.
///
/// Example where we check no calls were made to `mock`:
/// ```
/// XCTAssertNoMethodCalls(mock)
/// ```
func XCTAssertNoMethodCalls<Method>(_ mock: Mock<Method>, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(mock.recordedMethods, [], file: file, line: line)
}

/// Asserts no calls were made to a specific method for a given mock.
///
/// Example where we check no calls were made to `someMethod()`, regardless if calls to other methods were made:
/// ```
/// XCTAssertNoMethodCall(mock, to: .someMethod)
/// ```
func XCTAssertNoMethodCall<Method>(_ mock: Mock<Method>, to method: Method, file: StaticString = #file, line: UInt = #line) {
    if mock.recordedMethods.contains(method) {
        XCTFail("\(mock.recordedMethods) contains \(method)", file: file, line: line)
    }
}

/// Validates the recorded parameters list for one method call, comparing them to a list of expected parameter values.
private func assertParametersEqual(recorded: [Any?], expected: [Any?], file: StaticString, line: UInt) {
    // Check that the number of recorded and expected parameters matches.
    guard recorded.count == expected.count else {
        XCTFail("Expected \(recorded.count) parameters but got \(expected.count)", file: file, line: line)
        return
    }
    // Iterate over each individual parameter
    for (param1, param2) in zip(recorded, expected) {
        // Ignore XCTMethodIgnoredParameter parameters
        if param2 is XCTMethodIgnoredParameter {
            continue
        }
        // Do custom parameter check for XCTMethodSomeParameter parameters
        else if let param2 = param2 as? AnyXCTMethodSomeParameter {
            if !param2.parameterCheck(param1) {
                XCTFail("Parameter \(param1 ?? "nil") is not of the expected type", file: file, line: line)
            }
        }
        // Compare nil parameters
        else if param1 == nil && param2 == nil {
            continue
        }
        // Compare AnyEquatable parameters. See AnyEquatable.swift for more info.
        else if let param1 = param1 as? AnyEquatable, let param2 = param2 as? AnyEquatable {
            XCTAssertAnyEqual(param1, param2, file: file, line: line)
        }
        // Closure types are not comparable.
        else if let param1 = param1, "\(param1)" == "(Function)",
                let param2 = param2, "\(param2)" == "(Function)" {
            XCTFail("Use `XCTMethodCaptureParameter` or `XCTMethodIgnoredParameter` instead of testing against closures directly.")
        }
        // Failure: parameters could not be compared. See AnyEquatable.swift to add conformance for the parameter type to AnyEquatable.
        else {
            XCTFail("Parameters of \(String(describing: param1)) and \(String(describing: param2)) cannot be compared. Add conformance to the AnyEquatable protocol in AnyEquatable.swift", file: file, line: line)
        }
    }
}
