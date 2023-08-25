// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// OpenRTB 2.5 spec: https://www.iab.com/wp-content/uploads/2016/03/OpenRTB-API-Specification-Version-2-5-FINAL.pdf

import Foundation

extension OpenRTB {

    // An OpenRTB bid request is supposed to include an `id` but the ChartboostMedicationSDK does not.
    struct BidRequest: Encodable {
        /// Array of `Impression` objects representing the impressions offered. At least 1 `Impression` object is required.
        let imp: [Impression]

        /// Details about the publisher’s app (i.e., non-browser applications). Only applicable and recommended for apps.
        let app: App?

        /// Details about the user’s device to which the impression will be delivered.
        let device: Device?

        /// Details about the human user of the device; the advertising audience.
        let user: User?

        /// An object that specifies any industry, legal, or governmental regulations in force for this request.
        let regs: Regulations?

        /// Extension (implementation-specific) data
        let ext: Extension?

        /// Custom - indicates test mode enabled
        let test: Int?
    }

    struct Impression: Encodable {
        /// Name of ad mediation partner, SDK technology, or player responsible for rendering ad (typically video or mobile).
        /// Used by some ad servers to customize ad code by partner. Recommended for video and/or apps.
        let displaymanager: String?

        /// Version of ad mediation partner, SDK technology, or player responsible for rendering ad (typically video or mobile).
        /// Used by some ad servers to customize ad code by partner. Recommended for video and/or apps.
        let displaymanagerver: String?

        /// 1 = the ad is interstitial or full screen, 0 = not interstitial.
        /// Default value is 0
        let instl: Int?

        /// Identifier for specific ad placement or ad tag that was used to initiate the auction.
        /// This can be useful for debugging of any issues, or for optimization by the buyer.
        let tagid: String?

        /// Flag to indicate if the impression requires secure HTTPS URL creative assets and markup,
        /// where 0 = non-secure, 1 = secure. If omitted, the secure state is unknown, but non-secure HTTP support can be assumed.
        let secure: Int?

        /// A `Video` object; required if this impression is offered as a video ad opportunity.
        let video: Video?

        /// A `Banner` object; required if this impression is offered as a banner ad opportunity.
        let banner: Banner?

        struct Video: Encodable {
            /// Content MIME types supported (e.g., “video/x-ms-wmv”, “video/mp4”).
            let mimes: [String]

            /// Width of the video player in device independent pixels (DIPS).
            let w: Int?

            /// Height of the video player in device independent pixels (DIPS).
            let h: Int?

            /// Placement type for the impression.
            let placement: VideoPlacementType?

            /// Ad position on screen.
            let pos: OpenRTB.AdPosition?

            /// Supported VAST companion ad types. Refer to List 5.14. Recommended if companion `Banner` objects are included via
            /// the `companionad` array. If one of these banners will be rendered as an end-card, this can be specified using the `vcm` attribute
            /// with the particular banner.
            let companiontype: [CompanionType]?

            /// Extension (implementation-specific) data
            let ext: Extension?
        }

        struct Banner: Encodable {
            /// Exact width in device independent pixels (DIPS); recommended if no `format` objects are specified.
            let w: Int?

            /// Exact height in device independent pixels (DIPS); recommended if no `format` objects are specified.
            let h: Int?

            /// Ad position on screen.
            let pos: OpenRTB.AdPosition?

            /// Indicates if the banner is in the top frame as opposed to an iframe, where 0 = no, 1 = yes.
            let topframe: Int?

            /// Extension (implementation-specific) data
            let ext: Extension?
        }
    }

    struct App: Encodable {
        /// Exchange-specific app ID.
        let id: String?

        /// A platform-specific application identifier intended to be unique to the app and independent of the exchange.
        /// On Android, this should be a bundle or package name (e.g., com.foo.mygame). On iOS, it is typically a numeric ID.
        let bundle: String?

        /// Application version.
        let ver: String?

        /// Extension (implementation-specific) data
        let ext: Extension?
    }

    struct Device: Encodable {
        /// Browser user agent string.
        let ua: String?

        /// “Limit Ad Tracking” signal commercially endorsed (e.g., iOS, Android), where 0 = tracking is unrestricted, 1 = tracking must
        /// be limited per commercial guidelines.
        let lmt: Int?

        /// The general type of device.
        let devicetype: DeviceType?

        /// Device make (e.g., “Apple”).
        let make: String?

        /// Device model (e.g., “iPhone”).
        let model: String?

        /// Device operating system (e.g., “iOS”).
        let os: String?

        /// Device operating system version (e.g., “3.1.2”).
        let osv: String?

        /// Physical height of the screen in pixels.
        let h: Int?

        /// Physical width of the screen in pixels.
        let w: Int?

        /// The ratio of physical pixels to device independent pixels.
        let pxratio: Double?

        /// Browser language using ISO-639-1-alpha-2.
        let language: String?

        /// Carrier or ISP (e.g., “VERIZON”) using exchange curated string names which should be published to bidders a priori.
        let carrier: String?

        /// Mobile carrier as the concatenated MCC-MNC code (e.g., “310-005” identifies Verizon Wireless CDMA in the USA).
        /// Refer to https://en.wikipedia.org/wiki/Mobile_country_code for further examples.
        /// Note that the dash between the MCC and MNC parts is required to remove parsing ambiguity.
        let mccmnc: String?

        /// Network connection type.
        let connectiontype: ConnectionType?

        /// ID sanctioned for advertiser use in the clear (i.e., not hashed).
        let ifa: String?

        /// Location of the device assumed to be the user’s current location.
        let geo: Geo?

        /// Extension (implementation-specific) data
        let ext: Extension?

        struct Geo: Encodable {
            /// Local time as the number +/- of minutes from UTC.
            let utcoffset: Int?
        }
    }

    struct User: Encodable {
        /// Exchange-specific ID for the user. At least one of `id` or `buyeruid` is recommended.
        let id: String?

        /// The GDPR TCFv2 consent value
        let consent: String?

        /// Extension (implementation-specific) data
        let ext: Extension?
    }

    struct Regulations: Encodable {
        /// Flag indicating if this request is subject to the COPPA regulations established by the USA FTC, where 0 = no, 1 = yes.
        let coppa: Int?

        /// Extension (implementation-specific) data
        let ext: Extension?
    }
}

extension OpenRTB.Impression.Video {
    /// The following enumeration lists the various types of video placements derived largely from the IAB Digital Video Guidelines.
    /// - Note: Conforms to OpenRTB 2.5 specification 5.9
    enum VideoPlacementType: Int, Codable {
        /// Played before, during or after the streaming video content that the consumer has requested (e.g., Pre-roll, Mid-roll, Post-roll).
        case inStream = 1

        /// Exists within a web banner that leverages the banner space to deliver a video experience as opposed to another static or rich media format.
        /// The format relies on the existence of display ad inventory on the page for its delivery.
        case inBanner = 2

        /// Loads and plays dynamically between paragraphs of editorial content; existing as a standalone branded message.
        case inArticle = 3

        /// Found in content, social, or product feeds.
        case inFeed = 4

        /// Covers the entire or a portion of screen area, but is always on screen while displayed (i.e. cannot be scrolled out of view).
        /// Note that a full-screen interstitial (e.g., in mobile) can be distinguished from a floating/slider unit by the `imp.instl` field.
        case interstitialSliderOrFloating = 5
    }

    /// The following enumeration lists the options to indicate markup types allowed for companion ads that apply to video and audio ads.
    /// This table is derived from VAST 2.0+ and DAAST 1.0 specifications. Refer to www.iab.com/guidelines/digital-video-suite for more information.
    /// - Note: Conforms to OpenRTB 2.5 specification 5.14
    enum CompanionType: Int, Codable {
        /// Static Resource
        case staticResource = 1

        /// HTML Resource
        case htmlResource = 2

        /// iframe Resource
        case iframeResource = 3
    }
}

extension OpenRTB.Device {
    /// The following table lists the type of device from which the impression originated.
    /// OpenRTB version 2.2 of the specification added distinct values for Mobile and Tablet.
    /// It is recommended that any bidder adding support for 2.2 treat a value of 1 as an acceptable alias of 4 & 5.
    /// This OpenRTB enumeration has values derived from the Inventory Quality Guidelines (IQG). Practitioners should keep in sync with updates to the IQG values.
    /// - Note: Conforms to OpenRTB 2.5 specification 5.21
    enum DeviceType: Int, Codable {
        case mobileOrTablet = 1
        case personalComputer = 2
        case connectedTV = 3
        case phone = 4
        case tablet = 5
        case connectedDevice = 6
        case setTopBox = 7
    }

    /// The following enumeration lists the various options for the type of device connectivity.
    /// - Note: Conforms to OpenRTB 2.5 specification 5.22
    enum ConnectionType: Int, Codable {
        case unknown = 0
        case ethernet = 1
        case wifi = 2
        case cellularNetwork = 3
        case cellularNetwork2G = 4
        case cellularNetwork3G = 5
        case cellularNetwork4G = 6
        case cellularNetwork5G = 7
    }
}

// Extra (implementation-specific) data

extension OpenRTB.BidRequest {
    struct Extension: Encodable {
        let bidders: [String: [String: String]]?
        let helium_sdk_request_id: String?
        let skadn: StoreKitAdNetworks?
    }

    struct StoreKitAdNetworks: Encodable {
        let version: String
        let skadnetids: [String]
    }
}

extension OpenRTB.Impression.Video {
    struct Extension: Encodable {
        let placementtype: String
    }
}

extension OpenRTB.Impression.Banner {
    struct Extension: Encodable {
        let placementtype: String
    }
}

extension OpenRTB.App {
    struct Extension: Encodable {
        /// app.ext.game_engine_name
        let game_engine_name: String?

        /// app.ext.game_engine_version
        let game_engine_version: String?
    }
}

extension OpenRTB.Device {
    struct Extension: Encodable {
        let ifv: String?
        let atts: UInt?
        let inputLanguage: [String] // Note: This field intentionally has a capital L
        let networktype: [String]
        let audiooutputtype: [String]
        let audioinputtype: [String]
        let audiovolume: Double
        let screenbright: Double
        let batterylevel: Double
        let charging: Int
        let darkmode: Int
        let totaldisk: UInt
        let diskspace: UInt
        let textsize: Double
        let boldtext: Int
    }
}

extension OpenRTB.User {
    struct Extension: Encodable {
        let consent: String?
        let sessionduration: UInt
        let impdepth: UInt
        let keywords: [String: String]?

        /// Optional user identifier specified by the publisher.
        /// This generally represents the user in the publisher's ecosystem.
        let publisher_user_id: String?
    }
}

extension OpenRTB.Regulations {
    struct Extension: Encodable {
        let gdpr: Int

        /// CCPA consent value
        let us_privacy: String?
    }
}
