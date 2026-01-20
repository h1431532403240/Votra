//
//  FloatingPanelDisplayMode.swift
//  Votra
//
//  Display modes for the floating translation panel.
//

import Foundation

/// Display modes for the floating translation panel
enum FloatingPanelDisplayMode: String, CaseIterable, Identifiable {
    /// Compact subtitle mode - shows only current translation like video subtitles
    case subtitle

    /// Conversation mode - shows recent messages in a horizontal layout
    case conversation

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .subtitle:
            return String(localized: "Subtitle")
        case .conversation:
            return String(localized: "Conversation")
        }
    }

    var systemImage: String {
        switch self {
        case .subtitle:
            return "text.bubble"
        case .conversation:
            return "bubble.left.and.bubble.right"
        }
    }

    /// Recommended panel size for this mode
    var recommendedSize: CGSize {
        switch self {
        case .subtitle:
            return CGSize(width: 500, height: 120)
        case .conversation:
            return CGSize(width: 600, height: 220)
        }
    }

    /// Minimum panel size for this mode
    var minimumSize: CGSize {
        switch self {
        case .subtitle:
            return CGSize(width: 400, height: 80)
        case .conversation:
            return CGSize(width: 500, height: 160)
        }
    }
}
