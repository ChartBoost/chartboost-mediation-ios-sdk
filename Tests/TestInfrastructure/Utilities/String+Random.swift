// Copyright 2024-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension String {
    static func random(length: Int = Int.random(in: 1...20), includeNumbers: Bool = true) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" + (includeNumbers ? "0123456789" : "")
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    static func randomArray(maxSize: Int = 5, length: Int = Int.random(in: 1...20), includeNumbers: Bool = true) -> [String] {
        let count = Int.random(in: 0...maxSize)
        guard count > 0 else { return [] }
        var arr = [String]()
        for _ in 0..<count {
            arr.append(String.random(length: length, includeNumbers: includeNumbers))
        }
        return arr
    }
}
