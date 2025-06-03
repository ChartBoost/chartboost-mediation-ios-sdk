// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostIDProviderTests: ChartboostMediationTestCase {

    func testSharedChartboostID() throws {
        let chartboostIDProvider = ChartboostIDProvider()
        let fileSystemStorage = FileSystemStorage()
        let fileURL = try fileSystemStorage.urlForChartboostIDFile

        try fileSystemStorage.write(try XCTUnwrap("sharedChartboostID".data(using: .utf8)), to: fileURL)
        XCTAssertEqual(chartboostIDProvider.chartboostID, "sharedChartboostID")

        try fileSystemStorage.removeFile(at: fileURL)
        XCTAssertNil(chartboostIDProvider.chartboostID)

        try "".write(to: fileURL, atomically: false, encoding: .utf8)
        XCTAssertEqual(chartboostIDProvider.chartboostID, "")
    }
}
