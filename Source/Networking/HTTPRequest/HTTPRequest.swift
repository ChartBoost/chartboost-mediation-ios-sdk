// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

enum HTTPRequestError: LocalizedError {
    case createURLWithComponentsError(urlComponents: URLComponents)

    var errorDescription: String? {
        switch self {
        case .createURLWithComponentsError(let urlComponents):
            return "Failed to create a `URL` with `URLComponents`: \(urlComponents)"
        }
    }
}

/// A basic representation of a HTTP request.
protocol HTTPRequest: CustomStringConvertible {
    /// The URL.
    var url: URL { get throws }

    /// The HTTP method such as "GET" and "POST".
    var method: HTTP.Method { get }

    /// A dictionary of custom HTTP headers.
    var customHeaders: HTTP.Headers { get }

    /// The optional `Data` representation of the request body.
    var bodyData: Data? { get throws }

    /// Intended to prevent us from sending requests before initialization due to a malicious use of bug.
    /// Default to `true` except for `/sdk_init` and `/event/initialization`.
    var isSDKInitializationRequired: Bool { get }

    /// Indicates if mediation headers should be included in the request.
    /// Generally we want this to happen for all requests that hit our own backend.
    var shouldIncludeMediationHeaders: Bool { get }
}

extension HTTPRequest {
    var description: String {
        "\(method): \((try? url)?.absoluteString ?? "bad URL")"
    }

    var customHeaders: HTTP.Headers {
        [:]
    }

    var bodyData: Data? {
        nil
    }

    var isSDKInitializationRequired: Bool {
        true
    }

    var shouldIncludeMediationHeaders: Bool {
        true
    }

    func makeURL(endpoint: BackendAPI.Endpoint, extraPathComponents: [String] = []) throws -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        urlComponents.path = ([endpoint.basePath] + extraPathComponents).joined(separator: "/")

        guard let url = urlComponents.url else {
            throw HTTPRequestError.createURLWithComponentsError(urlComponents: urlComponents)
        }
        return url
    }

    func makeURLRequest() throws -> URLRequest {
        var headers = [
            HTTP.HeaderKey.accept.rawValue: HTTP.HeaderValue.applicationJSON_chartsetUTF8,
            HTTP.HeaderKey.contentType.rawValue: HTTP.HeaderValue.applicationJSON_chartsetUTF8,
        ].merging(customHeaders) { _, new in new } // `customHeaders` overrides the default headers

        if shouldIncludeMediationHeaders {
            addMediationHeaders(to: &headers)
        }

        var urlRequest = URLRequest(url: try url)
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = try bodyData
        return urlRequest
    }

    private func addMediationHeaders(to headers: inout [String: String]) {
        @Injected(\.environment) var environment: Environment

        headers[HTTP.HeaderKey.appID.rawValue] = environment.app.chartboostAppID
        headers[HTTP.HeaderKey.deviceOS.rawValue] = environment.device.osName
        headers[HTTP.HeaderKey.deviceOSVersion.rawValue] = environment.device.osVersion
        headers[HTTP.HeaderKey.idfv.rawValue] = environment.appTracking.idfv
        headers[HTTP.HeaderKey.sdkVersion.rawValue] = environment.sdk.sdkVersion
        headers[HTTP.HeaderKey.sessionID.rawValue] = environment.session.sessionID

        if environment.testMode.isTestModeEnabled {
            headers[HTTP.HeaderKey.debug.rawValue] = environment.app.chartboostAppID
        }
    }
}
