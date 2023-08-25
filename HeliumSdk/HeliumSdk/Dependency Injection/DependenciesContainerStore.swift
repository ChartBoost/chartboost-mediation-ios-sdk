// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A global namespace for the shared dependencies container.
enum DependenciesContainerStore {
    /// The shared dependencies container that holds references to all the Helium SDK objects.
    /// It is used by `Injected` property wrappers to access container properties.
    /// - note: Injected properties can be mocked in tests by setting `DependenciesContainerStore.container` to a mock value.
    static var container: DependenciesContainer = HeliumDependenciesContainer()
}
