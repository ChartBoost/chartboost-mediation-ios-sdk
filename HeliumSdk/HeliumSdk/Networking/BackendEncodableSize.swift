// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// Size that is appropriate for encoding and sending to the backend.
struct BackendEncodableSize: Encodable {
    enum CodingKeys: String, CodingKey {
        case width = "w"
        case height = "h"
    }

    let width: Int
    let height: Int

    init(cgSize: CGSize) {
        self.width = Int(ceil(cgSize.width))
        self.height = Int(ceil(cgSize.height))
    }
}

extension CGSize {
    /// Convenience to create a `BackendEncodableSize` from this `CGSize`.
    var backendEncodableSize: BackendEncodableSize {
        BackendEncodableSize(cgSize: self)
    }
}
