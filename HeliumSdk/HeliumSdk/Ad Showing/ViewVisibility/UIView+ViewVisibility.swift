// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// Provides extensions to the `UIView` relating to view visibility.
extension UIView {
    private static let defaultMaximumDepth: UInt = 25

    /// Determines if this view is visible with the specified minimum number of device independent pixels.
    ///
    /// To be considered visible, a view must:
    /// * Not be hidden, or a descendent of a hidden view.
    /// * Intersect the frame of its parent window, even if that intersection has zero area.
    ///
    /// - Parameter minimumVisiblePoints: The minimum number of device independent pixels the `view` is required to be visible on screen.
    /// - Returns `true` if this view is currently visible, or `false` if not.
    /// - Note: This function does not check whether any part of the view is obscured by another view.
    func isVisible(minimumVisiblePoints: CGFloat, maximumDepth: UInt = defaultMaximumDepth) -> Bool {
        // There must be a visible portion of the view to proceed.
        guard let intersection = visibleRect(maximumDepth: maximumDepth) else { return false }

        // Determine if the visible area meets or exceeds the minimum visible points.
        let clampedPoints = max(0, minimumVisiblePoints)
        let intersectionArea = intersection.width * intersection.height
        return intersectionArea >= clampedPoints
    }

    /// Indicates if the view is visible.
    ///
    /// To be considered visible, a view must:
    /// * Not be hidden, or a descendent of a hidden view.
    /// * Intersect the frame of its parent window, even if that intersection has zero area.
    /// - Note: This property does not check whether any part of the view is obscured by another view.
    var isVisible: Bool {
        return visibleRect(maximumDepth: Self.defaultMaximumDepth) != nil
    }

    /// A `CGRect` that is the visible portion of this view's frame that intersects with its parent window, in the
    /// window's coordinate system, or `nil` if the view is not visible.
    private func visibleRect(maximumDepth: UInt) -> CGRect? {
        // Not in a view hierarchy.
        guard let superview else { return nil }

        // Not attached to a window.
        guard let window else { return nil }

        // Ensure that both self and all of our ancestors are not hidden.
        var ancestor: UIView? = self

        var depth = 0
        while let view = ancestor, depth < maximumDepth {
            if view.isHidden {
                 return nil
            }
            ancestor = view.superview
            depth += 1
        }

        // We need to call `convert` on this view's superview rather than on this view itself.
        let viewFrameInWindowCoordinates = superview.convert(frame, to: window)

        // Ensure that the view intersects the window. Since we're looking
        // from the reference point of the window, we must use the window's
        // bounds.
        guard viewFrameInWindowCoordinates.intersects(window.bounds) else {
            return nil
        }

        return viewFrameInWindowCoordinates.intersection(window.bounds)
    }
}
