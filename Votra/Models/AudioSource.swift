//
//  AudioSource.swift
//  Votra
//
//  Audio source enumeration for identifying where audio is captured from.
//

import Foundation

/// Represents the source of audio input
nonisolated enum AudioSource: String, Codable, Equatable, Sendable {
    case microphone
    case systemAudio

    var displayName: String {
        switch self {
        case .microphone: return String(localized: "Microphone")
        case .systemAudio: return String(localized: "System Audio")
        }
    }
}
