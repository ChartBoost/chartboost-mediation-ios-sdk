// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

class DataLoader {
    
    static func load(_ name: String, type: String?) -> Data {
        let bundle = Bundle(for: DataLoader.self)
        let filePath = bundle.path(forResource: name, ofType: type)!
        let url = URL(fileURLWithPath: filePath)
        let data = try! Data(contentsOf: url)
        return data
    }
}
