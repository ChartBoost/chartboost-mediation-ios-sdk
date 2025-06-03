// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

typealias ChartboostID = String

/// Provide the Chartboost ID stored a file (/Library/Chartboost/chartboost_identifier).
protocol ChartboostIDProviding {
    var chartboostID: ChartboostID? { get }
}

final class ChartboostIDProvider: ChartboostIDProviding {
    @Injected(\.fileStorage) private var fileStorage

    var chartboostID: ChartboostID? {
        do {
            let fileURL = try fileStorage.urlForChartboostIDFile
            return String(data: try Data(contentsOf: fileURL, options: .mappedIfSafe), encoding: .utf8)
        } catch {
            logger.error("Failed to obtain chartboostID with error: \(error)")
            return nil
        }
    }
}
