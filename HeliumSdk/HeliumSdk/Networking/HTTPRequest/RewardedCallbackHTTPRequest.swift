// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

private enum Constant {
    /// The maximum number of characters allows for the custom data property.
    /// Note that UTF characters might be 1-4 bytes long.
    static let customDataMaxLength = 1000
    static let nullString = "null"
}

private enum Macro {
    /// Double or Null value type.
    case adRevenue

    /// Double or Null value type.
    case cpmPrice

    /// String value type. Also known as "partner identifier".
    case networkName

    /// String or Null value type.
    case customData

    /// 64-bit Integer value type that reprecents the number of seconds since 1970.
    case sdkTimestamp

    /// A "%%" enclosed string.
    var string: String {
        "%%\(rawValue)%%"
    }

    /// A "%25%25" enclosed string.
    var encodedString: String {
        "%25%25\(rawValue)%25%25"
    }

    /// Making `rawValue` private so that this enum is not accidentally misused.
    private var rawValue: String {
        switch self {
        case .adRevenue: return "AD_REVENUE"
        case .cpmPrice: return "CPM_PRICE"
        case .networkName: return "NETWORK_NAME"
        case .customData: return "CUSTOM_DATA"
        case .sdkTimestamp: return "SDK_TIMESTAMP"
        }
    }
}

/// This represents a rewarded callback HTTP request sends back to publisher.
struct RewardedCallbackHTTPRequest: HTTPRequestWithRawDataResponse {
    typealias CustomData = String

    let url: URL
    let method: HTTP.Method
    let customHeaders: HTTP.Headers
    let bodyData: Data?
    let maxRetries: Int
    let retryDelay: TimeInterval
    let shouldIncludeSessionID = false
    let shouldIncludeIDFV = false

    init?(
        rewardedCallback: RewardedCallback,
        customData: CustomData?,
        timestampMs: Int = Int(Date().timeIntervalSince1970 * 1000)
    ) {
        let sanitizedCustomData = customData?.sanitized()
        guard let callbackURL = rewardedCallback.url(customData: sanitizedCustomData, timestampMs: timestampMs) else {
            return nil
        }
        let data = rewardedCallback.bodyData(customData: sanitizedCustomData, timestampMs: timestampMs)

        url = callbackURL
        method = rewardedCallback.method
        customHeaders = data.map { [HTTP.HeaderKey.contentLength.rawValue: "\($0.count)"] } ?? [:]
        bodyData = data
        maxRetries = rewardedCallback.maxRetries
        retryDelay = rewardedCallback.retryDelay
    }
}

private extension RewardedCallbackHTTPRequest.CustomData {
    func sanitized(maxLength: Int = Constant.customDataMaxLength) -> RewardedCallbackHTTPRequest.CustomData? {
        // Validate that the incoming custom data string is less than maximum allowed length.
        guard count <= maxLength else {
            logger.error("Failed to set custom data because it exceeds the maximum allowed \(Constant.customDataMaxLength) characters. Setting custom data to nil.")
            return nil
        }
        return self
    }
}

private extension RewardedCallback {
    func url(customData: String?, timestampMs: Int) -> URL? {
        var urlString = urlString
        urlString = urlString.replacingAdRevenue(adRevenue, defaultValue: "")
        urlString = urlString.replacingCPMPrice(cpmPrice, defaultValue: "")
        urlString = urlString.replacingCustomData(customData ?? "", uriEncode: true)
        urlString = urlString.replacingNetworkName(partnerIdentifier, uriEncode: true)
        urlString = urlString.replacingSDKTimestamp(timestampMs)
        return URL(string: urlString)
    }

    func bodyData(customData: String?, timestampMs: Int) -> Data? {
        guard method == .post, var bodyString = body else { return nil }
        bodyString = bodyString.replacingAdRevenue(adRevenue, defaultValue: Constant.nullString)
        bodyString = bodyString.replacingCPMPrice(cpmPrice, defaultValue: Constant.nullString)
        bodyString = bodyString.replacingCustomData(customData ?? "", uriEncode: false)
        bodyString = bodyString.replacingNetworkName(partnerIdentifier, uriEncode: false)
        bodyString = bodyString.replacingSDKTimestamp(timestampMs)
        guard let jsonData = bodyString.data(using: .utf8) else { return nil }

        // Transform the string into a JSON dictionary so we can scrub out JSON null values.
        @Injected(\.jsonSerializer) var jsonSerializer
        if let json = try? jsonSerializer.deserialize(jsonData) as [String: Any?] {
            let jsonWithNoNulls = json.compactMapValues { $0 }
            return try? jsonSerializer.serialize(jsonWithNoNulls)
        } else {
            return jsonData
        }
    }
}

private extension String {
    private var uriEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    /// Search and replace the macro and its encoded version.
    private func replacing(macro: Macro, with string: String) -> String {
        // First pass will try to find the macro as unencoded.
        // The second pass will attempt to find the URI encoded version of the macro.
        let firstPass = replacingOccurrences(of: macro.string, with: string)
        let secondPass = firstPass.replacingOccurrences(of: macro.encodedString, with: string)
        return secondPass
    }

    func replacingAdRevenue(_ adRevenue: Double?, defaultValue: String) -> String {
        replacing(macro: .adRevenue, with: adRevenue.map { "\($0)" } ?? defaultValue)
    }

    func replacingCPMPrice(_ cpmPrice: Double?, defaultValue: String) -> String {
        replacing(macro: .cpmPrice, with: cpmPrice.map { "\($0)" } ?? defaultValue)
    }

    func replacingCustomData(_ customData: String, uriEncode: Bool) -> String {
        replacing(macro: .customData, with: uriEncode ? customData.uriEncoded : customData)
    }

    func replacingNetworkName(_ networkName: String, uriEncode: Bool) -> String {
        replacing(macro: .networkName, with: uriEncode ? networkName.uriEncoded : networkName)
    }

    func replacingSDKTimestamp(_ timestampMs: Int) -> String {
        replacing(macro: .sdkTimestamp, with: "\(timestampMs)")
    }
}
