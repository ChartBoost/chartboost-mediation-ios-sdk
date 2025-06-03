// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK

/// An internal Core module which can be instiantiated by reflection only.
/// - warning: Chartboost Core may instantiate this class several times during initialization.
/// It's important to keep it stateless to make no assumptions about which particular instance
/// will be the one kept alive by Chartboost Core.
final class CoreModule: Module {
    @Injected(\.environment) private var environment
    @Injected(\.sdkInitializer) private var sdkInitializer
    @Injected(\.consentSettings) private var consentSettings

    let moduleID = ChartboostMediation.coreModuleID
    var moduleVersion: String { environment.sdk.sdkVersion }

    init(credentials: [String: Any]?) {
        // We currently don't expect any configuration data to come from Core backend.
    }

    func initialize(configuration: ModuleConfiguration, completion: @escaping (Error?) -> Void) {
        // Initialize the SDK through the initializer.
        // It will take care of edge cases like SDK already initialized or initializing.
        sdkInitializer.initialize(appIdentifier: configuration.chartboostAppID) { cmError in
            completion(cmError)
        }
    }
}

extension CoreModule: ConsentObserver {
    func onConsentModuleReady(initialConsents: [ConsentKey: ConsentValue]) {
        // We indicate all the initial keys as modified keys, since Mediation and its adapters doesn't
        // really care if the new consent info comes from a new user interaction or if it's just being
        // restored from a previous session.
        consentSettings.setConsents(initialConsents, modifiedKeys: Set(initialConsents.keys))
    }

    func onConsentChange(fullConsents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        consentSettings.setConsents(fullConsents, modifiedKeys: modifiedKeys)
    }
}

extension CoreModule: EnvironmentObserver {
    func onChange(_ property: ObservableEnvironmentProperty) {
        if property == .isUserUnderage {
            consentSettings.setIsUserUnderage(ChartboostCore.analyticsEnvironment.isUserUnderage)
        }
    }
}
