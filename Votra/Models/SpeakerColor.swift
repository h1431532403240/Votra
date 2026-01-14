//
//  SpeakerColor.swift
//  Votra
//
//  Speaker color enumeration for visual differentiation of speakers.
//

import SwiftUI

/// Available colors for speaker identification in the UI
nonisolated enum SpeakerColor: String, Codable, Equatable, CaseIterable, Sendable {
    case blue
    case green
    case orange
    case purple
    case pink
    case teal

    var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .teal: return .teal
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
