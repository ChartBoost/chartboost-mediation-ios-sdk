// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A sequence that holds **unordered** weak references to objects.
/// Basically a Swifty wrapper over NSHashTable.
/// - warning: Elements must be reference types (objects, not structs or enums).
/// Unfortunately this requirement cannot be specified in the type definition, since `Value: AnyObject` would restrict `Value` to be a
/// class type and not a protocol that requires conformant types to be classes, which is a common use case.
struct WeakReferences<Value>: Sequence {
    /// List of elements. We use NSHashTable to avoid holding strong references to them.
    /// - note: We use AnyObject because NSMapTable requires values to be class types.
    private var rawObjects = NSHashTable<AnyObject>.weakObjects()

    /// Cast NSMapTable's values to a nicely typed Swift array.
    private var typedObjects: [Value] {
        rawObjects.allObjects as? [Value] ?? []
    }

    /// Addds a new element to the sequence.
    func add(_ value: Value) {
        rawObjects.add(value as AnyObject)
    }

    // Required by Sequence.
    func makeIterator() -> Iterator {
        Iterator(elements: typedObjects)
    }
}

extension WeakReferences {
    /// Required by Sequence. Provides logic on how to iterate over its elements.
    struct Iterator: IteratorProtocol {
        let elements: [Value]
        var position: Array<Value>.Index

        init(elements: [Value]) {
            self.elements = elements
            self.position = elements.startIndex
        }

        mutating func next() -> Value? {
            // If we passed the last element position we return nil
            guard position < elements.endIndex else {
                return nil
            }
            // Otherwise return element and increase position for the next one
            let element = elements[position]
            position += 1
            return element
        }
    }
}
