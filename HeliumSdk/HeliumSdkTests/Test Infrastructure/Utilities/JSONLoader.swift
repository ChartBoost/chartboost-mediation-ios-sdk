// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest

class JSONLoader {
    /// The raw value is the JSON file name.
    enum JSONFile: String {
        case BidResponseILRD
        case BidResponseILRDNullValues
        case BidResponseNoBaseILRD
        case BidResponseNoBidderILRD
        case BidResponseNoILRD
        case BidResponseRewardedCallbackMalformed
        case BidResponseRewardedCallbackNullGET
        case BidResponseRewardedCallbackNullPOST
        case BidResponseRewardedCallbackPOST
        case BidResponseRewardedCallbackSparse
        case Test_BidResp_Only1NonProg
        case Test_BidResp_OnlyProg
        case Test_BidResp_OnlyTJProg
        case Test_BidResp_Order
        case bid_response_banner_real
        case bid_response_interstitial_real
        case bid_response_rewarded_real
        case full_sdk_init_response
    }

    static func loadData(_ jsonFile: JSONFile) -> Data {
        DataLoader.load(jsonFile.rawValue, type: "json")
    }
    
    static func loadData(_ name: String) -> Data {
        DataLoader.load(name, type: "json")
    }
    
    static func loadObject(_ name: String) -> Any {
        return try! JSONSerialization.jsonObject(with: loadData(name), options: .mutableContainers)
    }
    
    static func loadDictionary(_ name: String) -> [AnyHashable: Any] {
        return loadObject(name) as! [AnyHashable: Any]
    }
    
    static func loadArray(_ name: String) -> [Any] {
        return loadObject(name) as! [Any]
    }
    
    static func loadString(_ name: String) -> String {
        let object = loadObject(name)
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return String(data: data, encoding: .utf8)!
    }
}
