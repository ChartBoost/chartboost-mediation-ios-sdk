// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol UserSettingsProviding {
    var inputLanguages: [String] { get }
    var isBoldTextEnabled: Bool { get }
    var languageCode: String? { get }
    var textSize: Double { get }
}

final class UserSettingsProvider: UserSettingsProviding {

    /// A stand alone `taskDispatcher` is needed here because `inputLanguages` needs to make a `sync`
    /// call, and we want to avoid being called on the same background queue and causes dead lock.
    private lazy var taskDispatcher = GCDTaskDispatcher.serialBackgroundQueue(name: "user-settings")

    var inputLanguages: [String] {
        // HB-4356 revealed that multiple threads using the `inputLanguages` getter resulted in crashes.
        // To alleviate the crash, always access `activeInputModes` in the same serial queue.
        taskDispatcher.sync(on: .background) {
            UITextInputMode.activeInputModes.compactMap(\.primaryLanguage)
        }
    }

    var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    var languageCode: String? {
        if #available(iOS 16.0, *) {
            if let languageCode = Locale.current.language.languageCode?.identifier {
                return languageCode
            }
        } else {
            if let languageCode = Locale.current.languageCode {
                return languageCode
            }
        }

        return Locale.preferredLanguages.first
    }

    var textSize: Double {
        Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
    }
}
