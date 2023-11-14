// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Serializes dictionaries into JSON data, and deserializes JSON data into dictionaries.
protocol JSONSerializer {
    
    /// Converts a JSON-compatible dictionary into JSON data.
    func serialize(_ value: [String: Any], options: JSONSerialization.WritingOptions) throws -> Data
    
    /// Converts JSON data into a JSON-compatible value.
    func deserialize<Value>(_ data: Data) throws -> Value
}

extension JSONSerializer {
    
    /// Converts a JSON-compatible dictionary into JSON data, with a default set of options.
    func serialize(_ value: [String: Any]) throws -> Data {
        try serialize(value, options: [.sortedKeys])
    }
    
    /// Converts JSON data into another JSON data with the same content but with the specified serialization options.
    func reserialize(_ data: Data, options: JSONSerialization.WritingOptions) throws -> Data {
        try serialize(deserialize(data), options: options)
    }
}

/// A JSONSerialization wrapper that handles some of its edge cases that might lead to crashes.
struct SafeJSONSerializer: JSONSerializer {
    
    enum JSONSerializationError: Error {
        case invalidJSONObject
        case serializedJSONNotADictionary
    }
    
    func serialize(_ value: [String: Any], options: JSONSerialization.WritingOptions) throws -> Data {
        // Validate that the value can be transformed into JSON.
        // Without this step `JSONSerialization.data(withJSONObject:)` might throw an exception (not an error) and crash the app.
        guard JSONSerialization.isValidJSONObject(value) else {
            logger.error("JSON serialization error: not a json dictionary \(value)")
            throw JSONSerializationError.invalidJSONObject
        }
        // Serialize
        do {
            // this is just to facilitate testing, to get always the same string back from the same input
            return try JSONSerialization.data(withJSONObject: value, options: options)
        } catch {
            logger.error("JSON serialization error: \(error)")
            throw error
        }
    }
    
    func deserialize<Value>(_ data: Data) throws -> Value {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        guard let dictionary = object as? Value else {
            logger.error("JSON deserialization error: wrong type \(type(of: object))")
            throw JSONSerializationError.serializedJSONNotADictionary
        }
        return dictionary
    }
}
