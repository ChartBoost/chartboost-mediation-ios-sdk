// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class InstanceIdentifierProviderTests: HeliumTestCase {

    func testWithStandardUserDefaults() throws {
        let provider: InstanceIdentifierProviding = InstanceIdentifierProvider(userDefaults: .standard)
        let id = provider.instanceIdentifier

        // The requirements specify that the id is a UUID;
        // therefore test that this is actually true.
        XCTAssertNotNil(UUID(uuidString: id))

        // Verify that reading it again is still the same value.
        XCTAssertEqual(id, provider.instanceIdentifier)
    }

    func testWithUserDefaults() throws {
        let provider1: InstanceIdentifierProviding = InstanceIdentifierProvider(userDefaults: UserDefaults())
        let id1 = provider1.instanceIdentifier
        XCTAssertNotNil(UUID(uuidString: id1))
        XCTAssertEqual(id1, provider1.instanceIdentifier)

        let provider2: InstanceIdentifierProviding = InstanceIdentifierProvider(userDefaults: UserDefaults())
        let id2 = provider2.instanceIdentifier
        XCTAssertNotNil(UUID(uuidString: id2))
        XCTAssertEqual(id2, provider2.instanceIdentifier)

        XCTAssertEqual(id1, id2)
    }
}
