// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

typealias SDKInitHash = String

/// If this is not nil, then it represents success with HTTP status code 200. This typically
/// represents the first successful SDK init. The SDK is supposed to store `sdkInitHash` and `data`
/// for future SDK init. Backend might intentionally nil out the SDK init hash for force a fresh fetch.
///
/// If this is nil, then it represents success with HTTP status code 204 (No Content). This means
/// SDK init was successful previously, and a valid SDK init hash was provided in the HTTP header
/// of this fetch. App config data is not provided because it's supposed to be stored after the first successful SDK init.
typealias SDKInitSuccessUpdate = (sdkInitHash: SDKInitHash?, data: Data)?

typealias FetchAppConfigurationCompletion = (_ result: Result<SDKInitSuccessUpdate, ChartboostMediationError>) -> Void

/// A service that provides an app configuration.
protocol AppConfigurationServiceProtocol {
    /// Obtains new configuration data.
    func fetchAppConfiguration(sdkInitHash: SDKInitHash?, completion: @escaping FetchAppConfigurationCompletion)
}

final class AppConfigurationService: AppConfigurationServiceProtocol {

    @Injected(\.networkManager) private var networkManager
    @Injected(\.environment) private var environment

    func fetchAppConfiguration(sdkInitHash: SDKInitHash?, completion: @escaping FetchAppConfigurationCompletion) {
        logger.debug("Sending SDK init request")
        
        guard let appID = environment.app.appID else {
            let error = ChartboostMediationError(
                code: .initializationFailureInvalidAppConfig,
                description: "Cannot send /sdk_init request because app ID is nil."
            )
            logger.error("Failed to send SDK init request with error: \(error)")
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
        
        networkManager.send(request) { result in
            switch result {
            case .success(let response):
                guard response.httpURLResponse.statusCode != 204 else {
                    logger.debug("SDK init request succeeded with no new data")
                    completion(.success(nil))
                    return
                }

                guard let data = response.rawData else {
                    let error = ChartboostMediationError(
                        code: .initializationFailureInvalidAppConfig,
                        description: "Response data is nil."
                    )
                    logger.error("SDK init request failed with error: \(error)")
                    completion(.failure(error))
                    return
                }
                
                logger.info("SDK init request succeeded")
                completion(.success((response.httpURLResponse.sdkInitHash, data)))

            case .failure(let requestError):
                let httpStatusCode = requestError.httpURLResponse.map { "\($0.statusCode)" } ?? "n/a"
                let error = ChartboostMediationError(
                    code: requestError.asCMErrorCode,
                    description: "Failed to fetch app configuration. HTTP status code: \(httpStatusCode)",
                    error: requestError
                )
                logger.error("SDK init request failed with error: \(error)")
                completion(.failure(error))
            }
        }
    }
}

extension NetworkManager.RequestError {
    fileprivate var asCMErrorCode: ChartboostMediationError.Code {
        switch self {
        case .nilNetworkManagerBeforeSendError,
             .sdkNotInitialized, // this should be an impossible case
             .urlRequestCreationError,
             .jsonDecodeError,
             .nilNetworkManagerBeforeRetryError:
            return .initializationFailureInternalError

        case .dataTaskError,
             .notHTTPURLResponseError:
            return .initializationFailureNetworkingError

        case .responseStatusCodeOutOfRangeError,
             .responseWithEmptyDataError:
            return .initializationFailureServerError
        }
    }
}

extension HTTPURLResponse {
    fileprivate var sdkInitHash: SDKInitHash? {
        allHeaderFields[HTTP.HeaderKey.sdkInitHash.rawValue] as? SDKInitHash
    }
}
