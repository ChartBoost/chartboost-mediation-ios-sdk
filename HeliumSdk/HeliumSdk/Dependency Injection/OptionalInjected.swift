// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A property wrapper that exposes a property value from the shared dependencies container.
/// It's the same as `Injected`, but properties we don't always want to inject and want to provide a local value instead.
/// This is useful for properties that are not injected in a normal environment, but we still want to mock in our tests.
/// - note: Injected properties can be mocked in tests by setting `DependenciesContainerStore.container` to a mock value.
@propertyWrapper
struct OptionalInjected<Value> {
    /// The key path to the dependencies container property.
    private let keyPath: KeyPath<DependenciesContainer, Value?>
    private let defaultValue: Value

    var wrappedValue: Value {
        DependenciesContainerStore.container[keyPath: keyPath] ?? defaultValue
    }

    init(_ keyPath: KeyPath<DependenciesContainer, Value?>, `default` defaultValue: Value) {
        self.keyPath = keyPath
        self.defaultValue = defaultValue
    }
}
