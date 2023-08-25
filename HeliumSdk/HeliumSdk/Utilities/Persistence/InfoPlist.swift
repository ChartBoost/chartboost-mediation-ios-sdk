// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol InfoPlistProviding {
    var appVersion: String? { get }
    var skAdNetworkIDs: [String] { get }
}

struct InfoPlist: InfoPlistProviding {
    struct BadURLError: Error, CustomStringConvertible {
        var description: String {
            "Failed to create a valid URL for Info.plist"
        }
    }

    var appVersion: String? {
        do {
            return try asDictionary["CFBundleShortVersionString"] as? String
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }

    /// Obtain SKAN (SKAdNetwork) ID's from the Info.plist file.
    var skAdNetworkIDs: [String] {
        do {
            guard let skAdNetworkItems = try asDictionary["SKAdNetworkItems"] else {
                assertionFailure("'SKAdNetworkItems' does not exist in Info.plist")
                return []
            }

            guard let skAdNetworkItemsArray = skAdNetworkItems as? [[String: String]] else {
                assertionFailure("Info.plist 'SKAdNetworkItems' value is not an array of [String: String]")
                return []
            }

            let skanIDs = skAdNetworkItemsArray.compactMap { $0["SKAdNetworkIdentifier"] }
            assert(skanIDs.count == skAdNetworkItemsArray.count, "SKAN ID's [\(skanIDs.count)] are less then SKAN item dictionaries [\(skAdNetworkItemsArray.count)]")
            return skanIDs
        } catch {
            assertionFailure(error.localizedDescription)
            return []
        }
    }

    private var asDictionary: NSDictionary {
        get throws {
            @Injected(\.bundleInfo) var bundleInfo
            guard let url = bundleInfo.mainBundle.url(forResource: "Info", withExtension: "plist") else {
                throw BadURLError()
            }
            return try NSDictionary(contentsOf: url, error: ())
        }
    }
}
