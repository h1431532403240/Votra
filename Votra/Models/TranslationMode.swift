//
//  TranslationMode.swift
//  Votra
//
//  Translation modes that determine audio sources and translation direction.
//

import Foundation

/// Translation modes that control how audio is captured and translated
enum TranslationMode: String, CaseIterable, Identifiable, Sendable {
    /// Subtitle mode: Only system audio, translates from source to target language.
    /// Ideal for watching foreign language videos or media.
    case subtitle

    /// Conversation mode: Bidirectional translation.
    /// - Microphone input: translates from source to target language
    /// - System audio: translates from target to source language
    /// Ideal for real-time bilingual conversations.
    case conversation

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .subtitle:
            return String(localized: "Subtitle Mode")
        case .conversation:
            return String(localized: "Conversation Mode")
        }
    }

    var localizedDescription: String {
        switch self {
        case .subtitle:
            return String(localized: "Translates system audio only. Ideal for watching foreign language content.")
        case .conversation:
            return String(localized: "Bidirectional translation for conversations. Your voice and system audio are both translated.")
        }
    }

    var systemImage: String {
        switch self {
        case .subtitle:
            return "captions.bubble"
        case .conversation:
            return "person.2.wave.2"
        }
    }

    /// Whether this mode uses microphone input
    var usesMicrophone: Bool {
        switch self {
        case .subtitle:
            return false
        case .conversation:
            return true
        }
    }

    /// Whether this mode uses system audio
    var usesSystemAudio: Bool {
        // Both modes use system audio
        true
    }
}
