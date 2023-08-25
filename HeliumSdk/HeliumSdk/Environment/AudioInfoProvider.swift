// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AVFoundation

protocol AudioInfoProviding {
    var audioInputTypes: [String] { get }
    var audioOutputTypes: [String] { get }
    var audioVolume: Double { get }
}

struct AudioInfoProvider: AudioInfoProviding {
    private var audioSession: AVAudioSession {
        .sharedInstance()
    }

    var audioInputTypes: [String] {
        audioSession.currentRoute.inputs.map { $0.portType.rawValue }
    }

    var audioOutputTypes: [String] {
        audioSession.currentRoute.outputs.map { $0.portType.rawValue }
    }

    var audioVolume: Double {
        Double(audioSession.outputVolume)
    }
}
