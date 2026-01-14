//
//  ChatMessage.swift
//  Votra
//
//  A chat message model representing a translated conversation message.
//

import Foundation

/// Role of a chat message participant
nonisolated enum ChatMessageRole: String, Codable, Equatable, Sendable, CaseIterable {
    /// Message from the local user (microphone input)
    case user
    /// Message from a remote participant (system audio input)
    case remote
    /// System-generated message (e.g., status updates)
    case system
}

/// A message in a chat conversation with translation support
nonisolated struct ChatMessage: Identifiable, Sendable, Equatable, Hashable {
    // MARK: - Properties

    /// Unique identifier for the message
    let id: UUID

    /// Original text before translation
    let originalText: String

    /// Translated text
    let translatedText: String

    /// Identifier for the source language locale
    let sourceLocaleIdentifier: String

    /// Identifier for the target language locale
    let targetLocaleIdentifier: String

    /// Role of the message sender
    let role: ChatMessageRole

    /// Timestamp when the message was created
    let timestamp: Date

    /// Whether the transcription/translation is final
    let isFinal: Bool

    // MARK: - Computed Properties

    /// Source locale for the original text
    var sourceLocale: Locale {
        Locale(identifier: sourceLocaleIdentifier)
    }

    /// Target locale for the translated text
    var targetLocale: Locale {
        Locale(identifier: targetLocaleIdentifier)
    }

    /// Whether this message is from the local user
    var isFromUser: Bool {
        role == .user
    }

    /// Whether this message is from a remote participant
    var isFromRemote: Bool {
        role == .remote
    }

    /// Whether this message is a system message
    var isSystemMessage: Bool {
        role == .system
    }

    /// Duration since the message was created
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    /// The text to display (translated if available, otherwise original)
    var displayText: String {
        translatedText.isEmpty ? originalText : translatedText
    }

    /// Whether the message has a translation different from the original
    var hasTranslation: Bool {
        !translatedText.isEmpty && translatedText != originalText
    }

    // MARK: - Initialization

    /// Creates a new chat message
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - originalText: Original text before translation
    ///   - translatedText: Translated text
    ///   - sourceLocale: Source language locale
    ///   - targetLocale: Target language locale
    ///   - role: Role of the message sender
    ///   - timestamp: Timestamp when the message was created
    ///   - isFinal: Whether the transcription/translation is final
    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLocale: Locale,
        targetLocale: Locale,
        role: ChatMessageRole,
        timestamp: Date,
        isFinal: Bool
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLocaleIdentifier = sourceLocale.identifier
        self.targetLocaleIdentifier = targetLocale.identifier
        self.role = role
        self.timestamp = timestamp
        self.isFinal = isFinal
    }

    /// Creates a chat message from an audio source
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - originalText: Original text before translation
    ///   - translatedText: Translated text
    ///   - sourceLocale: Source language locale
    ///   - targetLocale: Target language locale
    ///   - source: Audio source (microphone or system audio)
    ///   - timestamp: Timestamp when the message was created
    ///   - isFinal: Whether the transcription/translation is final
    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLocale: Locale,
        targetLocale: Locale,
        source: AudioSource,
        timestamp: Date,
        isFinal: Bool
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLocaleIdentifier = sourceLocale.identifier
        self.targetLocaleIdentifier = targetLocale.identifier
        self.role = source == .microphone ? .user : .remote
        self.timestamp = timestamp
        self.isFinal = isFinal
    }

    // MARK: - Factory Methods

    /// Creates a user message from microphone input
    static func userMessage(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLocale: Locale,
        targetLocale: Locale,
        timestamp: Date = Date(),
        isFinal: Bool = true
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            originalText: originalText,
            translatedText: translatedText,
            sourceLocale: sourceLocale,
            targetLocale: targetLocale,
            role: .user,
            timestamp: timestamp,
            isFinal: isFinal
        )
    }

    /// Creates a remote participant message from system audio
    static func remoteMessage(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLocale: Locale,
        targetLocale: Locale,
        timestamp: Date = Date(),
        isFinal: Bool = true
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            originalText: originalText,
            translatedText: translatedText,
            sourceLocale: sourceLocale,
            targetLocale: targetLocale,
            role: .remote,
            timestamp: timestamp,
            isFinal: isFinal
        )
    }

    /// Creates a system message
    static func systemMessage(
        id: UUID = UUID(),
        text: String,
        locale: Locale,
        timestamp: Date = Date()
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            originalText: text,
            translatedText: text,
            sourceLocale: locale,
            targetLocale: locale,
            role: .system,
            timestamp: timestamp,
            isFinal: true
        )
    }
}

// MARK: - Codable

extension ChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case originalText
        case translatedText
        case sourceLocaleIdentifier
        case targetLocaleIdentifier
        case role
        case timestamp
        case isFinal
    }
}
