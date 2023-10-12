// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK

/// This is just a simple data mock, thus no need to inherit `Mock`.
final class PrivacyConfigurationDependencyMock: PrivacyConfiguration {
    var privacyBanList: [PrivacyBanListCandidate] = []
}