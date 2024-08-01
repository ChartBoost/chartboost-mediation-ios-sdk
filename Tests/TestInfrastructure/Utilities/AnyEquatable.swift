// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

// MARK: - Protocol Definition

// Type-erased Equatable protocol that allows to compare objects for which their concrete type is not known.
protocol AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool
}

// MARK: - Default Implementations

extension AnyEquatable where Self: Equatable {
    
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

extension AnyEquatable where Self: AnyObject {

    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self === other
    }
}

extension NSObject: AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool {
        isEqual(other)
    }
}

// MARK: - Type conformances

extension Bool: AnyEquatable {}
extension Int: AnyEquatable {}
extension Double: AnyEquatable {}
extension Decimal: AnyEquatable {}
extension String: AnyEquatable {}
extension Set: AnyEquatable {}
extension BannerController: AnyEquatable {}
extension BannerSwapController: AnyEquatable {}

extension PartnerConfiguration: AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return JSONObject(self.credentials) == JSONObject(other.credentials)
        && self.consents == other.consents
        && self.isUserUnderage == other.isUserUnderage
    }
}

extension PartnerAdapterController: AnyEquatable {}
extension PartnerAdLoadRequest: AnyEquatable {}
extension PartnerAdPreBidRequest: AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self.format == other.format
        && self.bannerSize == other.bannerSize
        && self.mediationPlacement == other.mediationPlacement
        && self.loadID == other.loadID
        && JSONObject(self.partnerSettings) == JSONObject(other.partnerSettings)
    }
}
extension SingleAdStorageAdController: AnyEquatable {}

extension Dictionary: AnyEquatable {
    // Two dictionaries are equal conforming to AnyEquatable if
    // a) they are both equal JSON-compatible dictionaries
    // b) all their elements are equal conforming to AnyEquatable
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        if JSONObject(self) == JSONObject(other) {
            return true
        }
        if count != other.count {
            return false
        }
        return self.allSatisfy { key, value in
            guard let first = value as? AnyEquatable, let second = other[key] as? AnyEquatable else {
                return false
            }
            return first.isEqual(to: second)
        }
    }
}

extension Array: AnyEquatable {
    // Two arrays are equal conforming to AnyEquatable if all their elements are equal conforming to AnyEquatable
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        if count != other.count {
            return false
        }
        return zip(self, other).allSatisfy { (first, second) in
            guard let first = first as? AnyEquatable, let second = second as? AnyEquatable else {
                return false
            }
            return first.isEqual(to: second)
        }
    }
}

extension Optional: AnyEquatable where Wrapped: AnyEquatable {
    
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        if let self = self {
            if let other = other {
                return self.isEqual(to: other)
            } else {
                return false
            }
        } else {
            return other == nil
        }
    }
}

extension Result: AnyEquatable where Success: AnyEquatable, Failure: AnyEquatable {
    
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        if let success1 = try? self.get(), let success2 = try? other.get() {
            return success1.isEqual(to: success2)
        } else if let failure1 = self.error, let failure2 = other.error {
            return failure1.isEqual(to: failure2)
        } else {
            return false
        }
    }
}

extension LoadedAd: AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return (self.ilrd.map { $0.isEqual(to: other.ilrd) } ?? (other.ilrd == nil))
        && self.request.isEqual(to: other.request)
        && self.partnerAd === other.partnerAd
        && self.bidInfo.isEqual(to: other.bidInfo)
        && (self.rewardedCallback.map { $0.isEqual(to: other.rewardedCallback) } ?? (other.rewardedCallback == nil))
    }
}

extension InternalAdLoadResult: AnyEquatable {
    
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self.result.isEqual(to: other.result) && self.metrics.isEqual(to: other.metrics)
    }
}

extension InternalAdShowResult: AnyEquatable {
    
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self.error.isEqual(to: other.error) && self.metrics.isEqual(to: other.metrics)
    }
}

extension OpenRTB.BidResponse.Extension.RewardedCallbackData: AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self.url == other.url
        && self.method == other.method
        && self.max_retries == other.max_retries
        && self.retry_delay == other.retry_delay
        && self.body == other.body
    }
}

extension Bid: AnyEquatable {

    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self.identifier == other.identifier
        && self.partnerID == other.partnerID
        && self.adm == other.adm
        && JSONObject(self.partnerDetails ?? [:]) == JSONObject(other.partnerDetails ?? [:])
        && self.lineItemIdentifier == other.lineItemIdentifier
        && JSONObject(self.ilrd ?? [:]) == JSONObject(other.ilrd ?? [:])
        && self.cpmPrice == other.cpmPrice
        && self.adRevenue == other.adRevenue
        && self.auctionID == other.auctionID
        && self.isProgrammatic == other.isProgrammatic
        && self.rewardedCallback.isEqual(to: other.rewardedCallback)
        && self.clearingPrice == other.clearingPrice
        && self.winURL == other.winURL
        && self.lossURL == other.lossURL
    }
}

extension InternalAdLoadRequest: AnyEquatable {
    func isEqual(to other: AnyEquatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self.loadID == other.loadID
        && self.adSize == other.adSize
        && self.adFormat == other.adFormat
        && self.keywords == other.keywords
        && self.mediationPlacement == other.mediationPlacement
        && JSONObject(self.partnerSettings) == JSONObject(other.partnerSettings)
        && self.queueID == other.queueID
    }
}

extension RewardedCallback: AnyEquatable {}
extension AdFormat: AnyEquatable {}
extension URL: AnyEquatable {}
extension URLRequest: AnyEquatable {}
extension Data: AnyEquatable {}
extension CGSize: AnyEquatable {}

// We should add here any conformance for new types that need it.
