// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A property wrapper that exposes a property value from the shared dependencies container.
/// - note: Injected properties can be mocked in tests by setting `DependenciesContainerStore.container` to a mock value.
@propertyWrapper
struct Injected<Value> {
    
    /// The key path to the dependencies container property.
    private let keyPath: KeyPath<DependenciesContainer, Value>
    
    var wrappedValue: Value {
        DependenciesContainerStore.container[keyPath: keyPath]
    }
    
    init(_ keyPath: KeyPath<DependenciesContainer, Value>) {
        self.keyPath = keyPath
    }
}
