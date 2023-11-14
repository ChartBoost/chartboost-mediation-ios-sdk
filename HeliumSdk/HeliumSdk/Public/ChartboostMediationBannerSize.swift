// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The size of a banner ad.
///
/// This size is used in ``ChartboostMediationBannerLoadRequest`` as the maximum size of a requested banner, and is
/// available as a property on ``ChartboostMediationBannerView`` with the actual size of the displayed banner.
@objc
public final class ChartboostMediationBannerSize: NSObject {
    /// A size object for a fixed size 320x50 standard banner.
    @objc public static let standard = ChartboostMediationBannerSize(
        size: CGSize(width: 320, height: 50),
        type: .fixed
    )

    /// A size object for a fixed size 300x250 medium banner.
    @objc public static let medium = ChartboostMediationBannerSize(
        size: CGSize(width: 300, height: 250),
        type: .fixed
    )

    /// A size object for a fixed size 728x90 leaderboard banner.
    @objc public static let leaderboard = ChartboostMediationBannerSize(
        size: CGSize(width: 728, height: 90),
        type: .fixed
    )

    /// Returns a size for an adaptive banner with the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// This will generally be used when requesting an inline ad that can be of any height. To request an adaptive size banner with
    /// a maximum height, use ``ChartboostMediationBannerSize/adaptive(width:maxHeight:)`` instead.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive(width: CGFloat) -> ChartboostMediationBannerSize {
        return .init(
            size: CGSize(width: width, height: 0),
            type: .adaptive
        )
    }

    /// Returns a size for an adaptive banner with the specified `width` and `maxHeight`.
    /// - Parameter width: The maximum width for the banner.
    /// - Parameter height: The maximum height for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// This will generally be used when requesting an anchored adaptive banner, or when requesting an inline adaptive banner where
    /// the maximum height should be constained. To request an adaptive size banner without a `maxHeight`, use
    /// ``ChartboostMediationBannerSize/adaptive(width:)`` instead.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive(
        width: CGFloat,
        maxHeight: CGFloat
    ) -> ChartboostMediationBannerSize {
        return .init(
            size: CGSize(width: width, height: maxHeight),
            type: .adaptive
        )
    }

    // MARK: - IAB Aspect Ratio Conveniences

    // MARK: Horizontal
    /// Convenience that returns a 2:1 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive2x1(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width / 2.0)
    }

    /// Convenience that returns a 4:1 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive4x1(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width / 4.0)
    }

    /// Convenience that returns a 6:1 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive6x1(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width / 6.0)
    }

    /// Convenience that returns a 8:1 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive8x1(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width / 8.0)
    }

    /// Convenience that returns a 10:1 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive10x1(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width / 10.0)
    }

    // MARK: Vertical
    /// Convenience that returns a 1:2 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive1x2(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width * 2.0)
    }

    /// Convenience that returns a 1:3 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive1x3(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width * 3.0)
    }

    /// Convenience that returns a 1:4 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive1x4(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width * 4.0)
    }

    /// Convenience that returns a 9:16 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive9x16(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: (width * 16.0) / 9.0)
    }

    // MARK: Tiles and Other
    /// Convenience that returns a 1:1 `ChartboostMediationBannerSize` for the specified `width`.
    /// - Parameter width: The maximum width for the banner.
    /// - Returns: A `ChartboostMediationBannerSize` that can be used to load a banner.
    ///
    /// - Note: This is only a maximum banner size. Depending on how your waterfall is configured, smaller or different aspect ratio
    /// ads may be served.
    @objc public static func adaptive1x1(width: CGFloat) -> ChartboostMediationBannerSize {
        return adaptive(width: width, maxHeight: width)
    }

    /// The underlying `CGSize`.
    @objc public let size: CGSize

    /// The banner type.
    @objc public let type: ChartboostMediationBannerType

    /// The aspect ratio of ``size``.
    ///
    /// Returns `0` if either the width or height are negative or `0`.
    @objc public var aspectRatio: CGFloat {
        guard size.width > 0 && size.height > 0 else {
            return 0
        }

        return size.width / size.height
    }

    var isValid: Bool {
        let isValidWidth = Constants.validBannerSizeRange.contains(size.width)
        let isValidHeight = size.height == 0 || Constants.validBannerSizeRange.contains(size.height)
        return isValidWidth && isValidHeight
    }

    init(size: CGSize, type: ChartboostMediationBannerType) {
        self.size = size
        self.type = type
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ChartboostMediationBannerSize else {
            return false
        }

        return (
            size == other.size &&
            type == other.type
        )
    }
}

extension ChartboostMediationBannerSize {
    private enum Constants {
        // Min/max banner dimensions as per the IAB spec.
        static let minimumBannerDimension = 50.0
        static let maximumBannerDimension = 1800.0
        static let validBannerSizeRange = minimumBannerDimension...maximumBannerDimension
    }
}
