// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class UpdatableApplicationConfigurationTests: ChartboostMediationTestCase {

    lazy var configuration = UpdatableApplicationConfiguration()
    
    // MARK: - ApplicationConfiguration
    
    /// Validates that the configuration updates its values with valid encoded data.
    func testUpdateWithFullValidData() throws {
        // Load the full init response
        let data = JSONLoader.loadData("full_sdk_init_response")
        
        // Update configuration
        try configuration.update(with: data)

        // Check that values are properly updated
        assertValues(in: configuration, match: fullValues)
    }
    
    /// Validates that the configuration updates its values with valid encoded data that is missing some optional values.
    func testUpdateWithPartialValidData() throws {
        // Load the partial init response
        let data = JSONLoader.loadData("partial_sdk_init_response")
        
        // Update configuration
        try configuration.update(with: data)

        // Check that values are properly updated
        assertValues(in: configuration, match: partialValues)
    }
    
    /// Validates that the configuration fails to update with invalid data.
    func testUpdateWithInvalidData() throws {
        // Update configuration
        let invalidData = "some data which is not a RawValues encoded data".data(using: .utf8)!
        XCTAssertThrowsError(try configuration.update(with: invalidData))

        // Check that values are the default
        assertValues(in: configuration, match: nil)
    }
    
    /// Validates that the configuration fails to update with invalid credentials data.
    func testUpdateWithInvalidCredentials() throws {
        // Setup: credentials data is invalid
        guard let data = #"{ "credentials": { "2", "4" } }"#.data(using: .utf8) else {
            throw NSError.test()
        }
        
        // Update configuration
        XCTAssertThrowsError(try configuration.update(with: data))

        // Check that values are the default
        assertValues(in: configuration, match: nil)
    }
    
    /// Validates the initial default values before any update.
    func testDefaultValues() {
        // Check that values are the default
        assertValues(in: configuration, match: nil)
    }
    
    /// Validates that the previous configuration values are not overwritten or reset by a bad update.
    func testPreviousValuesRemainIfAnUpdateFails() throws {
        // Setup: update config with full values
        try testUpdateWithFullValidData()
        
        // Update configuration with invalid data
        let invalidData = "some data which is not a RawValues encoded data".data(using: .utf8)!
        XCTAssertThrowsError(try configuration.update(with: invalidData))

        // Check that values match the full values set at the beginning
        assertValues(in: configuration, match: fullValues)
    }
    
    /// Validates that an update fails gracefully with some encoded data that matches the expected keys but has invalid value types.
    func testUpdateWithDataWithInvalidTypes() throws {
        // Setup: data has invalid types
        guard let data = #"{ "banner_load_timeout": "this should not be a string", "credentials": 123 }"#.data(using: .utf8) else {
            throw NSError.test()
        }
        
        // Update configuration with invalid types
        XCTAssertThrowsError(try configuration.update(with: data))

        // Check that values are the default
        assertValues(in: configuration, match: nil)
    }
    
    /// Validates that an update succeeds ignored extra parameters in an otherwise valid data.
    func testUpdateWithDataWithExtraParameters() throws {
        // Load the full init response
        var response = JSONLoader.loadDictionary("partial_sdk_init_response")
        response["some_extra_param"] = 234
        response["some_extra_param2"] = ["a", "b"]
        let data = try JSONSerialization.data(withJSONObject: response)
        
        try configuration.update(with: data)

        // Check that values are properly updated
        assertValues(in: configuration, match: partialValues)
    }
	
	/// Validates that an AdFormat instance is properly retrieved and decoded from the configuration raw values when matched with a placement.
	func testAdFormatForPlacement() throws {
		// Load the response with placement data
		var response = JSONLoader.loadDictionary("partial_sdk_init_response")
		response["placements"] = [
			["chartboost_placement": "placement1", "format": "rewarded_interstitial"],
			["chartboost_placement": "placement2", "format": "interstitial"],
			["chartboost_placement": "placement3", "format": "rewarded"],
			["chartboost_placement": "placement4", "format": "banner"],
			["chartboost_placement": "placement5", "format": "unknown"]
		]
		let data = try JSONSerialization.data(withJSONObject: response)
		
		// Update the configuration
		try configuration.update(with: data)
		
		// Check the ad formats are found and decoded when available
		XCTAssertEqual(configuration.adFormat(forPlacement: "placement1"), .rewardedInterstitial)
		XCTAssertEqual(configuration.adFormat(forPlacement: "placement2"), .interstitial)
		XCTAssertEqual(configuration.adFormat(forPlacement: "placement3"), .rewarded)
		XCTAssertEqual(configuration.adFormat(forPlacement: "placement4"), .banner)
		XCTAssertNil(configuration.adFormat(forPlacement: "placement5"))
	}
    
    /// Validates that banner autorefresh rate is properly retrieved when matched with a placement.
    func testBannerAutoRefreshRate() throws {
        // Load the response with placement data
        var response = JSONLoader.loadDictionary("partial_sdk_init_response")
        response["placements"] = [
            ["chartboost_placement": "placement1", "format": "banner"],
            ["chartboost_placement": "placement2", "format": "banner", "auto_refresh_rate": -4],
            ["chartboost_placement": "placement3", "format": "banner", "auto_refresh_rate": 0],
            ["chartboost_placement": "placement4", "format": "banner", "auto_refresh_rate": 9],
            ["chartboost_placement": "placement5", "format": "banner", "auto_refresh_rate": 25],
            ["chartboost_placement": "placement6", "format": "banner", "auto_refresh_rate": 260]
        ] as [[String: Any]]
        let data = try JSONSerialization.data(withJSONObject: response)
        
        // Update the configuration
        try configuration.update(with: data)
        
        // Check the autorefresh rate values
        XCTAssertEqual(configuration.autoRefreshRate(forPlacement: "placement1"), 30)
        XCTAssertEqual(configuration.autoRefreshRate(forPlacement: "placement2"), 0)
        XCTAssertEqual(configuration.autoRefreshRate(forPlacement: "placement3"), 0)
        XCTAssertEqual(configuration.autoRefreshRate(forPlacement: "placement4"), 0)
        XCTAssertEqual(configuration.autoRefreshRate(forPlacement: "placement5"), 25)
        XCTAssertEqual(configuration.autoRefreshRate(forPlacement: "placement6"), 240)
        
        // Check the load retry rate values
        XCTAssertEqual(configuration.normalLoadRetryRate(forPlacement: "placement1"), 30)
        XCTAssertEqual(configuration.normalLoadRetryRate(forPlacement: "placement2"), 30)
        XCTAssertEqual(configuration.normalLoadRetryRate(forPlacement: "placement3"), 30)
        XCTAssertEqual(configuration.normalLoadRetryRate(forPlacement: "placement4"), 30)
        XCTAssertEqual(configuration.normalLoadRetryRate(forPlacement: "placement5"), 25)
        XCTAssertEqual(configuration.normalLoadRetryRate(forPlacement: "placement6"), 240)
        
        // Check constant banner values
        XCTAssertEqual(configuration.penaltyLoadRetryRate, 240)
        XCTAssertEqual(configuration.penaltyLoadRetryCount, 4)
    }

    func testBannerSizeEventDelay() throws {
        var response = JSONLoader.loadDictionary("full_sdk_init_response")
        response["banner_size_event_delay_ms"] = 2000
        let data = try JSONSerialization.data(withJSONObject: response)

        // Update the configuration
        try configuration.update(with: data)

        XCTAssertEqual(configuration.bannerSizeEventDelay, 2.0, accuracy: 0.001)
    }

    func testBannerSizeEventDelayUsesDefaultValueWhenMissing() throws {
        let response = JSONLoader.loadDictionary("partial_sdk_init_response")
        let data = try JSONSerialization.data(withJSONObject: response)

        // Update the configuration
        try configuration.update(with: data)

        XCTAssertEqual(configuration.bannerSizeEventDelay, 1.0, accuracy: 0.001)
    }
    
    /// Checks that the configuration returns proper values for all its protocol conformances.
    private func assertValues(in configuration: UpdatableApplicationConfiguration, match values: UpdatableApplicationConfiguration.RawValues?) {
        XCTAssertEqual(configuration.prebidFetchTimeout, TimeInterval(values?.prebidFetchTimeout ?? 5))
        XCTAssertEqual(configuration.fullscreenLoadTimeout, TimeInterval(values?.fullscreenLoadTimeout ?? 30))
        XCTAssertEqual(configuration.bannerLoadTimeout, TimeInterval(values?.bannerLoadTimeout ?? 15))
        XCTAssertEqual(configuration.country, values?.country)
        XCTAssertEqual(configuration.testIdentifier, values?.internalTestId)
        XCTAssertEqual(configuration.partnerAdapterClassNames, Set(values?.adapterClasses ?? []))
        XCTAssertJSONEqual(configuration.partnerCredentials, values?.credentials.value ?? ["reference": [:]]) // TODO: Remove this reference adapter hack in HB-4504
        XCTAssertEqual(configuration.minimumVisiblePoints, CGFloat(values?.bannerImpressionMinVisibleDips ?? 1))
        XCTAssertEqual(configuration.pollInterval, TimeInterval(values?.visibilityTrackerPollIntervalMs ?? 100) / 1000)
        XCTAssertEqual(configuration.minimumVisibleSeconds, TimeInterval(values?.bannerImpressionMinVisibleDurationMs ?? 0) / 1000)
        XCTAssertEqual(configuration.traversalLimit, values?.visibilityTrackerTraversalLimit ?? 25)
        XCTAssertEqual(configuration.showTimeout, TimeInterval(values?.showTimeout ?? 5))
        XCTAssertEqual(configuration.maxQueueSize, Int(values?.maxQueueSize ?? 5))
        XCTAssertEqual(configuration.defaultQueueSize, Int(values?.defaultQueueSize ?? 1))
        XCTAssertEqual(configuration.queuedAdTtl, TimeInterval(values?.queuedAdTtl ?? 3600))
    }
    
    /// The expected config values when parsing the response "full_sdk_init_response.json" that contains all the possible fields.
    private var fullValues: UpdatableApplicationConfiguration.RawValues {
        .init(
            fullscreenLoadTimeout: 22,
            bannerLoadTimeout: 10,
            showTimeout: 2,
            country: "some country",
            internalTestId: "some test id",
            prebidFetchTimeout: 111,
            bannerImpressionMinVisibleDips: 3,
            bannerImpressionMinVisibleDurationMs: 4,
            bannerSizeEventDelayMs: 1000,
            visibilityTrackerPollIntervalMs: 5,
            visibilityTrackerTraversalLimit: 6,
            adapterClasses: ["ONE", "two", "three"],
            credentials: .init(value: [
                "adcolony": [
                    "adc_app_id": "app4a5d0480628d4fe0b2"
                ],
                "admob": [
                    "admob_app_id": "ca-app-pub-6548817822928201~9620807135"
                ],
                "amazon_aps": [
                    "application_id": "b242e84190ef4240a39858d5d75a5d4e",
                    "prebids": [[
                        "height": 50,
                        "helium_placement": "AllNetworkBanner",
                        "partner_placement": "5ee565ed-15c5-4053-bfe6-52afe4443776",
                        "type": "banner",
                        "width": 320
                    ], [
                        "helium_placement": "AllNetworkInterstitial",
                        "partner_placement": "39a5105a-8c16-4417-acb8-1c152c7db5b1",
                        "type": "interstitial"
                    ], [
                        "height": 50,
                        "helium_placement": "AllProBanner",
                        "partner_placement": "5ee565ed-15c5-4053-bfe6-52afe4443776",
                        "type": "banner",
                        "width": 320
                    ], [
                        "helium_placement": "AllProInterstitial",
                        "partner_placement": "39a5105a-8c16-4417-acb8-1c152c7db5b1",
                        "type": "interstitial"
                    ], [
                        "height": 90,
                        "helium_placement": "APSBannerLeaderboard",
                        "partner_placement": "8c7eff7b-35e9-4762-8f02-440b0ac8ee28",
                        "type": "banner",
                        "width": 728
                    ], [
                        "height": 250,
                        "helium_placement": "APSBannerMedium",
                        "partner_placement": "75a66d2d-416b-4601-9d18-fea363bfb7ae",
                        "type": "banner",
                        "width": 300
                    ], [
                        "height": 50,
                        "helium_placement": "APSBannerStandard",
                        "partner_placement": "5ee565ed-15c5-4053-bfe6-52afe4443776",
                        "type": "banner",
                        "width": 320
                    ], [
                        "helium_placement": "APSInterstitial",
                        "partner_placement": "39a5105a-8c16-4417-acb8-1c152c7db5b1",
                        "type": "interstitial"
                    ], [
                        "height": 50,
                        "helium_placement": "APSTestBanner",
                        "partner_placement": "a56d59d3-1dd1-4c27-896d-c2e39f14b106",
                        "type": "banner",
                        "width": 320
                    ]] as [[String: Any]]
                ],
                "applovin": [
                    "package_name": "com.applovin.enterprise.apps.demoapp.test",
                    "sdk_key": "wy1dIpr2F2-9fqTT2ihBprfAvPyfd6qm_81WkbsZC6Fl31vaW4aiDFxR52R89x98WWNfPmTIGMInIvffFTOxLz"
                ],
                "chartboost": [
                    "app_id": "59c04299d989d60fc5d2c782",
                    "app_signature": "6deb8e06616569af9306393f2ce1c9f8eefb405c"
                ],
                "facebook": [
                    "applicationid": "428939561173260"
                ],
                "fyber": [
                    "fyber_app_id": "126907"
                ],
                "google_googlebidding": [
                    "google_googlebidding_app_id": "ca-app-pub-6548817822928201~9620807135"
                ],
                "inmobi": [
                    "account_id": "1eec80192d354cedb466065f40fdd088"
                ],
                "ironsource": [
                    "app_key": "52216cb5"
                ],
                "mintegral": [
                    "app_key": "4ccdac5a4a32b28e5a88404ebf566475",
                    "mintegral_app_id": "155101"
                ],
                "pangle": [
                    "application_id": "8025569"
                ],
                "tapjoy": [
                    "sdk_key": "wcyoj4ZIRuKI0KSIxtuSwAEBtpbz8Ol3jnxsSCQjcEkIqyYGyeFbX8itGWtx"
                ],
                "unity": [
                    "game_id": "3690830",
                    "org_core_id": "20066366404150"
                ],
                "vungle": [
                    "vungle_app_id": "5dcde5072aa70a0017bcc85c"
                ],
                // TODO: Remove this reference adapter hack in HB-4504
                "reference": [:]
            ] as [String: [String: Any]]),
            metricsEvents: nil,
            initTimeout: 1,
            initMetricsPostTimeout: 5,
            placements: [
                .init(chartboostPlacement: "Placement1", format: "interstitial", autoRefreshRate: nil),
                .init(chartboostPlacement: "Placement2", format: "rewarded", autoRefreshRate: nil),
                .init(chartboostPlacement: "Placement3", format: "banner", autoRefreshRate: nil),
                .init(chartboostPlacement: "Placement4", format: "rewarded_interstitial", autoRefreshRate: nil),
                .init(chartboostPlacement: "Placement5", format: "unknown", autoRefreshRate: nil),
                .init(chartboostPlacement: "Placement6", format: "banner", autoRefreshRate: 35)
			],
            logLevel: nil,
            privacyBanList: PrivacyBanListCandidate.allCases.map { $0.rawValue },
            maxQueueSize: 5,
            defaultQueueSize: 3,
            queuedAdTtl: 3600
        )
    }
    
    /// The expected config values when parsing the response "partial_sdk_init_response.json" that ommits most of the required fields.
    private var partialValues: UpdatableApplicationConfiguration.RawValues {
        .init(
            fullscreenLoadTimeout: nil,
            bannerLoadTimeout: nil,
            showTimeout: nil,
            country: nil,
            internalTestId: nil,
            prebidFetchTimeout: nil,
            bannerImpressionMinVisibleDips: nil,
            bannerImpressionMinVisibleDurationMs: nil,
            bannerSizeEventDelayMs: nil,
            visibilityTrackerPollIntervalMs: nil,
            visibilityTrackerTraversalLimit: nil,
            adapterClasses: nil,
            credentials: .init(value: [
                "adcolony": [
                    "adc_app_id": "app4a5d0480628d4fe0b2"
                ],
                // TODO: Remove this reference adapter hack in HB-4504
                "reference": [:]
            ]),
            metricsEvents: nil,
            initTimeout: nil,
            initMetricsPostTimeout: nil,
            placements: [],
            logLevel: nil,
            privacyBanList: [],
            maxQueueSize: nil,
            defaultQueueSize: nil,
            queuedAdTtl: nil
        )
    }
}
