// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// And observer to visibility changes on a view
protocol ViewVisibilityObserver {
    /// Called when the visibility state of the view changes.
    func viewVisibilityDidChange(on view: UIView, to visible: Bool)
}
