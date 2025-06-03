// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The Mediation instance identifier is a String
typealias InstanceIdentifier = String

/// A protocol that defines the contract for a class that is responsbile for providing
/// the value of the Mediation client instance identifier.
protocol InstanceIdentifierProviding {
    var instanceIdentifier: InstanceIdentifier { get }
}

final class InstanceIdentifierProvider: InstanceIdentifierProviding {
    private let userDefaults: UserDefaults

    /// The `UserDefault` storage key to use for the instance identifier. "helium" is the historic name of Mediation.
    private let InstanceIdentifierKey = "com.chartboost.helium.instance-id"

    /// Constructor.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// The getter for the Mediation instance identifier.
    /// If it does not exist, it is created. It cannot ever be modified.
    var instanceIdentifier: InstanceIdentifier {
        userDefaults.string(forKey: InstanceIdentifierKey) ?? createInstanceIdentifier()
    }

    /// Create the initial client identifier.
    private func createInstanceIdentifier() -> InstanceIdentifier {
        let instanceId = UUID().uuidString
        userDefaults.set(instanceId, forKey: InstanceIdentifierKey)
        return instanceId
    }
}
