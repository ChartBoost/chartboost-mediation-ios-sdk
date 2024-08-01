// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A property wrapper that can be used to declare that a property is atomic.
@propertyWrapper
class Atomic<Value> {
    private let queue = DispatchQueue(label: "com.chartboost.mediation.sdk.atomic")
    private var value: Value

    /// Initializer that can be used in order to declare any variable as atomic.
    /// Example:
    /// let one = Atomic(wrappedValue: 1)
    /// one.mutate { $0 += 1 }
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    /// The value that is managed by the wrapper. Access to it is gated by a serial queue.
    var wrappedValue: Value {
        get {
            queue.sync { value }
        }
        set {
            queue.sync { value = newValue }
        }
    }

    /// Allows for multi-step operations to be atomic. Properties' `get` and `set` are individually
    /// atomic but the combination of both are not, such as incrementing an integer.
    func mutate(_ mutation: (inout Value) -> Void) {
        queue.sync {
            mutation(&value)
        }
    }

    /// Provide a projection to allow for custom/multi-step mutation.
    var projectedValue: Atomic<Value> {
        return self
    }
}
