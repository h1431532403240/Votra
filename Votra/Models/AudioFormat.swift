//
//  AudioFormat.swift
//  Votra
//
//  Audio format enumeration for recording and export.
//

import Foundation

/// Supported audio file formats for recording
nonisolated enum AudioFormat: String, Codable, Equatable, Sendable, CaseIterable {
    case m4a
    case wav
    case mp3

    var fileExtension: String { rawValue }

    var mimeType: String {
        switch self {
        case .m4a: return "audio/mp4"
        case .wav: return "audio/wav"
        case .mp3: return "audio/mpeg"
        }
    }

    var displayName: String {
        rawValue.uppercased()
    }
}
