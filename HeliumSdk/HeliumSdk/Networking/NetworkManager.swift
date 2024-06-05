// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This is a protocol of the network manager.
///
/// Note: Do not define a `sendHTTPRequest()` function that accepts a `HTTPRequest`, otherwise
/// all request objects comforming to a `HTTPRequest` descendant protocol will be treated as a
/// `HTTPRequest` instead of the specific descendant protocol.
protocol NetworkManagerProtocol {
    func send(
        _ httpRequest: HTTPRequestWithRawDataResponse,
        maxRetries: Int,
        retryDelay: TimeInterval,
        completion: @escaping NetworkManager.RequestCompletionWithRawDataResponse
    )

    func send<T: HTTPRequestWithDecodableResponse>(
        _ httpRequest: T,
        maxRetries: Int,
        retryDelay: TimeInterval,
        completion: @escaping NetworkManager.RequestCompletionWithJSONResponse<T.DecodableResponse>
    )
}

extension NetworkManagerProtocol {
    func send(
        _ httpRequest: HTTPRequestWithRawDataResponse,
        completion: @escaping NetworkManager.RequestCompletionWithRawDataResponse
    ) {
        send(httpRequest, maxRetries: 0, retryDelay: 0, completion: completion)
    }

    func send<T: HTTPRequestWithDecodableResponse>(
        _ httpRequest: T,
        completion: @escaping NetworkManager.RequestCompletionWithJSONResponse<T.DecodableResponse>
    ) {
        send(httpRequest, maxRetries: 0, retryDelay: 0, completion: completion)
    }
}

// MARK: - NetworkManager

final class NetworkManager: NSObject {
    typealias RequestCompletionWithRawDataResponse = (_ result: Result<RawDataResponse, RequestError>) -> Void
    typealias RequestCompletionWithJSONResponse<T> = (_ result: Result<JSONResponse<T>, RequestError>) -> Void

    struct RawDataResponse {
        let httpURLResponse: HTTPURLResponse
        let rawData: Data?
    }

    struct JSONResponse<T> {
        struct ResponseData {
            let rawData: Data
            let decodedData: T
        }

        let httpURLResponse: HTTPURLResponse
        let responseData: ResponseData? // some API might return empty data as success, such as /sdk_init
    }

    @Injected(\.initializationStatusProvider) private var initializationStatusProvider
    @OptionalInjected(\.customTaskDispatcher, default: .serialBackgroundQueue(name: "network-manager")) private var taskDispatcher

    private let logger = Logger(category: "network")

    private static var defaultURLSessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }()

    private let urlSessionConfig: URLSessionConfiguration

    private lazy var urlSession: URLSession = {
        let queue = OperationQueue()
        queue.name = "com.chartboost.sdk.url_session_delegate_queue"
        return URLSession(configuration: urlSessionConfig, delegate: self, delegateQueue: queue)
    }()

    init(urlSessionConfig: URLSessionConfiguration = NetworkManager.defaultURLSessionConfig) {
        self.urlSessionConfig = urlSessionConfig
        super.init()
    }
}

// MARK: - NetworkManager.RequestError

extension NetworkManager {
    enum RequestError: Error {
        case nilNetworkManagerBeforeSendError(httpRequest: HTTPRequest, maxRetries: Int)
        case sdkNotInitialized(httpRequest: HTTPRequest)
        case urlRequestCreationError(httpRequest: HTTPRequest, originalError: Error)
        case dataTaskError(httpRequest: HTTPRequest, httpURLResponse: HTTPURLResponse?, originalError: Error)
        case notHTTPURLResponseError(httpRequest: HTTPRequest)
        case responseStatusCodeOutOfRangeError(httpRequest: HTTPRequest, httpURLResponse: HTTPURLResponse, maxRetries: Int)
        case responseWithEmptyDataError(httpRequest: HTTPRequest, httpURLResponse: HTTPURLResponse)
        case jsonDecodeError(httpRequest: HTTPRequest, httpURLResponse: HTTPURLResponse, data: Data, originalError: Error)
        case nilNetworkManagerBeforeRetryError(httpRequest: HTTPRequest, httpURLResponse: HTTPURLResponse, maxRetries: Int)

        var localizedDescription: String {
            switch self {
            case .nilNetworkManagerBeforeSendError(let request, let maxRetries):
                return "[\(request)] Unable to send HTTP request because `NetworkManager` is nil. Max retry attempts for [400, 600) status: \(maxRetries)"

            case .sdkNotInitialized(let request):
                return "[\(request)] The SDK is not initialized yet."

            case .urlRequestCreationError(let request, let originalError):
                return "[\(request)] Failed to create a URL request: \(originalError.localizedDescription)"

            case .dataTaskError(let request, _, let originalError):
                return "[\(request)] Data task error: \(originalError.localizedDescription)"

            case .notHTTPURLResponseError(let request):
                return "[\(request)] `dataTask()` response is not an `HTTPURLResponse`."

            case .responseStatusCodeOutOfRangeError(let request, let response, let maxRetries):
                return "[\(request)] Response status code \(response.statusCode) is out of the [200, 400) range. Max retry attempts for [400, 600) status: \(maxRetries)"

            case .responseWithEmptyDataError(let request, let response):
                return "[\(request)] Response data is nil. Status code: \(response.statusCode)"

            case .jsonDecodeError(let request, _, let data, let originalError):
                return "[\(request)] `JSONDecoder` error: \(originalError.localizedDescription), response body text: \(String(data: data, encoding: .utf8) ?? "")"

            case .nilNetworkManagerBeforeRetryError(let request, let response, let maxRetries):
                return "[\(request)] Unable to retry after receiving status code \(response.statusCode) because `NetworkManager` is nil. Max retry attempts for [400, 600) status: \(maxRetries)"
            }
        }
    }
}

// MARK: - NetworkManager: NetworkManagerProtocol

extension NetworkManager: NetworkManagerProtocol {
    func send(
        _ httpRequest: HTTPRequestWithRawDataResponse,
        maxRetries: Int,
        retryDelay: TimeInterval,
        completion: @escaping RequestCompletionWithRawDataResponse
    ) {
        commonSend(httpRequest, maxRetries: maxRetries, retryDelay: retryDelay) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success((let response, let data)):
                completion(.success(.init(httpURLResponse: response, rawData: data)))
            }
        }
    }

    func send<T: HTTPRequestWithDecodableResponse>(
        _ httpRequest: T,
        maxRetries: Int,
        retryDelay: TimeInterval,
        completion: @escaping RequestCompletionWithJSONResponse<T.DecodableResponse>
    ) {
        commonSend(httpRequest, maxRetries: maxRetries, retryDelay: retryDelay) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success((let response, let data)):
                guard let data, !data.isEmpty else {
                    if response.statusCode == 204 { // HTTP 204 = No Content
                        completion(.success(.init(httpURLResponse: response, responseData: nil)))
                    } else {
                        let error = RequestError.responseWithEmptyDataError(
                            httpRequest: httpRequest,
                            httpURLResponse: response
                        )
                        self.logger.error(error.localizedDescription)
                        completion(.failure(error))
                    }
                    return
                }

                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = httpRequest.responseKeyDecodingStrategy
                    let decodedData = try jsonDecoder.decode(T.DecodableResponse.self, from: data)
                    completion(.success(.init(
                        httpURLResponse: response,
                        responseData: .init(rawData: data, decodedData: decodedData)
                    )))
                } catch {
                    let error = RequestError.jsonDecodeError(
                        httpRequest: httpRequest,
                        httpURLResponse: response,
                        data: data,
                        originalError: error
                    )
                    self.logger.error(error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - NetworkManager: URLSessionTaskDelegate

extension NetworkManager: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let credential: URLCredential?
        let disposition: URLSession.AuthChallengeDisposition

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust,
               serverTrust.evaluateForHost(challenge.protectionSpace.host) {
                credential = URLCredential(trust: serverTrust)
                disposition = credential != nil ? .useCredential : .performDefaultHandling
            } else {
                credential = nil
                disposition = .cancelAuthenticationChallenge
            }
        } else {
            credential = nil
            disposition = .performDefaultHandling
        }

        completionHandler(disposition, credential)
    }
}

// MARK: - NetworkManager.RequestError

extension NetworkManager.RequestError {
    var httpURLResponse: HTTPURLResponse? {
        switch self {
        case .nilNetworkManagerBeforeSendError,
             .sdkNotInitialized,
             .urlRequestCreationError,
             .notHTTPURLResponseError:
            return nil
        case .dataTaskError(_, let httpURLResponse, _): // this `httpURLResponse` is Optional
            return httpURLResponse
        case .responseStatusCodeOutOfRangeError(_, let httpURLResponse, _),
             .responseWithEmptyDataError(_, let httpURLResponse),
             .jsonDecodeError(_, let httpURLResponse, _, _),
             .nilNetworkManagerBeforeRetryError(_, let httpURLResponse, _):
            return httpURLResponse
        }
    }
}

// MARK: - Private NetworkManager

extension NetworkManager {
    private func commonSend(
        _ httpRequest: HTTPRequest,
        maxRetries: Int,
        retryDelay: TimeInterval,
        completion: @escaping (_ result: Result<(HTTPURLResponse, Data?), RequestError>) -> Void
    ) {
        // Put the send logic in a background thread to avoid potential threading issues. For example,
        // When trying to fire `/v1/event/initialization`, `initializationStatusProvider.isInitialized`
        // calls `taskDispatcher.sync(on: .background)` in the same background thread, and then triggers
        // a EXC_BAD_INSTRUCTION crash if this `commonSend` is not in the `NetworkManager` thread.
        taskDispatcher.async(on: .background) { [weak self] in
            guard let self else {
                let error = RequestError.nilNetworkManagerBeforeSendError(httpRequest: httpRequest, maxRetries: maxRetries)
                Logger.default.error(error.localizedDescription)
                completion(.failure(error))
                return // code path 1: report nil manager
            }

            guard !httpRequest.isSDKInitializationRequired || self.initializationStatusProvider.isInitialized else {
                let error = RequestError.sdkNotInitialized(httpRequest: httpRequest)
                self.logger.error(error.localizedDescription)
                completion(.failure(error))
                return // code path 2: report SDK not initialized
            }

            let urlRequest: URLRequest
            do {
                urlRequest = try httpRequest.makeURLRequest()
            } catch {
                let error = error as? RequestError ?? .urlRequestCreationError(httpRequest: httpRequest, originalError: error)
                self.logger.error(error.localizedDescription)
                completion(.failure(error))
                return // code path 3: report URL creation error
            }

            NetworkActivityConsoleLogger.logURLRequest(urlRequest, logger: self.logger)

            let dataTask = self.urlSession.dataTask(with: urlRequest) { [weak self] data, urlResponse, error in
                let logger = self?.logger ?? Logger.default

                if let error {
                    let error = RequestError.dataTaskError(
                        httpRequest: httpRequest,
                        httpURLResponse: urlResponse as? HTTPURLResponse,
                        originalError: error
                    )
                    logger.error(error.localizedDescription)
                    completion(.failure(error))
                    return // code path 4: report data task error
                }

                // Apple doc: "Whenever you make an HTTP request, the URLResponse object you
                // get back is actually an instance of the HTTPURLResponse class."
                // See https://developer.apple.com/documentation/foundation/urlresponse
                guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
                    let error = RequestError.notHTTPURLResponseError(httpRequest: httpRequest)
                    logger.error(error.localizedDescription)
                    completion(.failure(error))
                    return // code path 5: report response error
                }

                NetworkActivityConsoleLogger.logURLResponse(httpURLResponse, data: data, logger: logger)

                let statusCode = httpURLResponse.statusCode
                if statusCode.isSuccess {
                    completion(.success((httpURLResponse, data)))
                    return // code path 6: report response success
                }

                let shouldRetry = (
                    maxRetries > 0 && (
                        statusCode.isRetryable ||
                        Self.isConnectivityError(error)
                    )
                )
                let statusCodeOutOfRangeError = RequestError.responseStatusCodeOutOfRangeError(
                    httpRequest: httpRequest,
                    httpURLResponse: httpURLResponse,
                    maxRetries: maxRetries
                )
                logger.error(statusCodeOutOfRangeError.localizedDescription)

                guard shouldRetry else {
                    completion(.failure(statusCodeOutOfRangeError))
                    return // code path 7: report status code error
                }

                func reportNilNetworkManager() {
                    let nilNetworkManagerBeforeRetryError = RequestError.nilNetworkManagerBeforeRetryError(
                        httpRequest: httpRequest,
                        httpURLResponse: httpURLResponse,
                        maxRetries: maxRetries
                    )
                    logger.error(nilNetworkManagerBeforeRetryError.localizedDescription)
                    completion(.failure(nilNetworkManagerBeforeRetryError))
                }

                guard let self else {
                    reportNilNetworkManager()
                    return // code path 8: report nil network manager
                }

                self.taskDispatcher.async(on: .background, after: retryDelay) { [weak self] in
                    guard let self else {
                        reportNilNetworkManager()
                        return // code path 9: report nil network manager
                    }

                    // code path 10: asynchronously retry
                    self.commonSend(
                        httpRequest,
                        maxRetries: maxRetries - 1,
                        retryDelay: retryDelay,
                        completion: completion
                    )
                }
            }
            dataTask.resume()
        }
    }

    private static func isConnectivityError(_ error: Error?) -> Bool {
        guard
            let error = error as? NSError,
            error.domain == NSURLErrorDomain
        else {
            return false
        }

        switch error.code {
        case
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorTimedOut:
            return true
        default:
            return false
        }
    }
}

extension HTTP.StatusCode {
    fileprivate var isSuccess: Bool {
        200 <= self && self < 400
    }

    fileprivate var isRetryable: Bool {
        400 <= self && self < 600
    }
}
