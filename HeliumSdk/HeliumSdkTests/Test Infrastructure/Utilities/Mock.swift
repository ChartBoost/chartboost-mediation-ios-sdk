// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A base class from which all mocks should inherit from.
/// It allows us to create new mocks that can record method calls and their parameters with minimal boilerplate.
/// In conjunction with the methods defined in XCTest+Mock it allows us to validate the behavior of other types that interact with the mock.
///
/// Here is an example of a Mock subclass that conforms to a protocol called `YourProtocol`:
/// ```
/// // Note Mock is a generic class that requires passing a Method type when subclassed.
/// class YourProtocolMock: Mock<YourProtocolMock.Method>, YourProtocol {
///
///     // Method is just an enum that lists all the YourProtocol methods that you want to record calls of.
///     enum Method {
///         case protocolMethodWithParameters
///         case protocolMethodWithReturnValue
///         case protocolMethodThatThrows
///     }
///
///     // This is the default values to be returned by methods with a return value. In our case, protocolMethodWithReturnValue() and
///     protocolMethodThatThrows(parameter1:), the last one not because it can return but because it can throw an error.
///     override var defaultReturnValues: [Method: Any?] {
///         [.protocolMethodWithReturnValue: true,
///          .protocolMethodThatThrows: NSError(domain: "", code: 0, userInfo: nil)]
///     }
///
///     // Here we implement YourProtocol methods. The only thing needed to record a method call is to call one of the record methods.
///
///     func protocolMethodWithParameters(parameter1: String, parameter2: Int) {
///         record(.protocolMethodWithParameters, parameters: [parameter1, parameter2])
///     }
///
///     func protocolMethodWithReturnValue() -> Bool {
///         record(.protocolMethodWithReturnValue)
///     }
///
///     func protocolMethodThatThrows(parameter1: NSObject) throws {
///         throwingRecord(.protocolMethodThatThrows, parameters: [parameter1])
///     }
/// }
/// ```
///
/// Of course a mock can be as simple as the protocol you are mocking. Here is a more concise example:
/// ```
/// class SingleMethodProtocolMock: Mock<SingleMethodProtocolMock.Method>, SingleMethodProtocol {
///     enum Method {
///         case singleMethod
///     }
///     func singleMethod() {
///         record(.singleMethod)
///     }
/// }
/// ```
///
/// Creating a Mock subclass is the first step. In order to use it in your tests you will need to follow these steps:
/// - 1: Inject the mock as a dependency into the class under test. Hopefully this will be as easy as passing the mock object in the class' init.
/// - 2: Optionally, do some mock setup using the `setReturnValue(_:for:)` method to change the mock's return values.
/// - 3: Perform whatever action you want to test on your class under test.
/// - 4: Validate that as result of that action, the class under test called the appropriate mock methods passing the expected parameters.
///      You will do this using the custom XCTAssert methods defined in XCTest+Mock.swift.
///      See example below:
///
/// ```
/// func test_A_calls_SingleMethod_if_protocolMethodWithReturnValue_returns_false() {
///     // Step 1
///     let singleMethodProtocolMock = SingleMethodProtocolMock()
///     let yourProtocolMock = YourProtocolMock()
///     let a = A(singleMethodProtocolMock: singleMethodProtocolMock, yourProtocolMock: yourProtocolMock)
///
///     // Step 2
///     yourProtocolMock.setReturnValue(false, for: .protocolMethodWithReturnValue)
///
///     // Step 3
///     a.someAction()
///
///     // Step 4
///     XCTAssertMethodCalls(singleMethodProtocolMock, .singleMethod)
/// }
/// ```
/// See XCTest+Mock.swift for more info on method call validation methods.
class Mock<Method: Equatable & Hashable>: NSObject {
    /// List of recorded method calls. Should not be accessed directly. In order to validate which methods were called you should use the
    /// methods defined in XCTest+Mock.swift instead like XCTAssertMethodCalls().
    private(set) var recordedMethods: [Method] = []
    /// List of recorded method call parameters. Should not be accessed directly. In order to validate which methods were called you should
    /// use the methods defined in XCTest+Mock.swift instead like XCTAssertMethodCalls().
    private(set) var recordedParameters: [[Any?]] = []
    /// Values to return whenever a the corresponding method is called. Applies only to mocked methods with return values.
    /// Empy by default. Subclasses can override `defaultReturnValues` to provide custom default values.
    private lazy var returnValues: [Method : Any?] = defaultReturnValues
    
    /// To be overriden by subclasses so they can provide their own default return values.
    /// These values can be changed during test execution by using the `setReturnValue(_:for:)` method.
    var defaultReturnValues: [Method : Any?] { [:] }
    
    // MARK: - Spy
    
    /// Records a method call and parameters.
    /// Should be called by subclasses in their implementation of mocked protocol methods that do not return a value.
    func record(_ method: Method, parameters: [Any?] = []) {
        recordedMethods.append(method)
        recordedParameters.append(parameters)
    }
    
    /// Removes all recorded method calls and parameters.
    /// Generally you should not need to call this directly, since XCTAssertMethodCalls() takes care of that after validating method calls.
    /// You may use it though to clean the mock's records at some point during your test if you don't care about what happened previous to
    /// that point.
    func removeAllRecords() {
        recordedMethods.removeAll()
        recordedParameters.removeAll()
    }
    
    // MARK: - Stub
    
    /// The value to be returned by the mock when the indicated method is called.
    func returnValue<T>(for method: Method) -> T {
        returnValues[method] as! T
    }
    
    /// Sets the value to be returned by the mock when the indicated method is called.
    func setReturnValue(_ value: Any?, for method: Method) {
        returnValues.updateValue(value, forKey: method) // updateValue sets a `nil` value for the given key if value is `nil`, unlike the default setter which removes the entry
    }
    
    /// Like returnValue(for:), but it the return value is an Error it throws it instead of returning it.
    private func throwingReturnValue<T>(for method: Method) throws -> T {
        if let error = returnValues[method] as? Error {
            throw error
        } else {
            return returnValues[method] as! T
        }
    }

    // MARK: - Mock
    
    /// Records a method call and parameters, and returns a return value.
    /// Should be called by subclasses in their implementation of mocked protocol methods that return a value.
    func record<T>(_ method: Method, parameters: [Any?] = []) -> T {
        record(method, parameters: parameters)
        return returnValue(for: method)
    }
    
    /// Records a method call and parameters, and returns a return value or throws an error.
    /// Should be called by subclasses in their implementation of mocked protocol methods that return a value and can throw.
    func throwingRecord<T>(_ method: Method, parameters: [Any?] = []) throws -> T {
        record(method, parameters: parameters)
        return try throwingReturnValue(for: method)
    }
    
    /// Records a method call and parameters, possibly throwing an error.
    /// Should be called by subclasses in their implementation of mocked protocol methods that can throw.
    func throwingRecord(_ method: Method, parameters: [Any?] = []) throws {
        record(method, parameters: parameters)
        if let error = returnValues[method] as? Error {
            throw error
        }
    }
}
