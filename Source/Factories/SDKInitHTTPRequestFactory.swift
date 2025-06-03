// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Factory to create a ``SDKInitHTTPRequest`` model using the information provided by
/// the publisher, partners, and the current environment.
protocol SDKInitHTTPRequestFactory {
    /// Generates the request in a thread-safe manner.
    /// - parameter sdkInitHash: The persisted init hash obtained from a previous API response.
    /// - parameter completion: The handler that takes in the generated request.
    func makeRequest(
        sdkInitHash: SDKInitHash?,
        completion: @escaping (Result<SDKInitHTTPRequest, ChartboostMediationError>) -> Void
    )
}

/// Mediation's concrete implementation of ``SDKInitHTTPRequestFactory``.
struct MediationSDKInitHTTPRequestFactory: SDKInitHTTPRequestFactory {
    @Injected(\.environment) private var environment
    @Injected(\.taskDispatcher) private var taskDispatcher

    func makeRequest(
        sdkInitHash: SDKInitHash?,
        completion: @escaping (Result<SDKInitHTTPRequest, ChartboostMediationError>) -> Void
    ) {
        taskDispatcher.async(on: .main) {   // execute on main to prevent issues when accessing UIKit APIs via the environment
            guard let appID = environment.app.chartboostAppID else {
                let error = ChartboostMediationError(
                    code: .initializationFailureInvalidAppConfig,
                    description: "Cannot send /sdk_init request because app ID is nil."
                )
                completion(.failure(error))
                return
            }
            let request = SDKInitHTTPRequest(
                appID: appID,
                deviceOSName: environment.device.osName,
                deviceOSVersion: environment.device.osVersion,
                sdkInitHash: sdkInitHash,
                sdkVersion: environment.sdk.sdkVersion
            )
            completion(.success(request))
        }
    }
}
