//
//  MusicControlButton.swift
//  boringNotch
//
//  Created by Alexander on 2025-11-16.
//

import Defaults

enum MusicControlButton: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case previous
    case playPause
    case next
    case goBackward
    case goForward
    case mute
    case none

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = MusicControlButton(rawValue: raw) ?? .none
    }

    static let defaultLayout: [MusicControlButton] = [
        .goBackward,
        .previous,
        .playPause,
        .next,
        .goForward
    ]

    static let minSlotCount: Int = 3
    static let maxSlotCount: Int = 5

    static let pickerOptions: [MusicControlButton] = [
        .previous,
        .playPause,
        .next,
        .goBackward,
        .goForward
    ]

    var label: String {
        switch self {
        case .previous:
            return "Previous"
        case .playPause:
            return "Play/Pause"
        case .next:
            return "Next"
        case .goBackward:
            return "Backward 15s"
        case .goForward:
            return "Forward 15s"
        case .mute:
            return "Mute/Unmute"
        case .none:
            return "Empty slot"
        }
    }

    var iconName: String {
        switch self {
        case .previous:
            return "backward.fill"
        case .playPause:
            return "playpause"
        case .next:
            return "forward.fill"
        case .goBackward:
            return "gobackward.15"
        case .goForward:
            return "goforward.15"
        case .mute:
            return "speaker.slash.fill"
        case .none:
            return ""
        }
    }

    var prefersLargeScale: Bool {
        self == .playPause
    }
}
