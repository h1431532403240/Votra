//
//  Segment.swift
//  Votra
//
//  Segment model representing a single speech segment with transcription and translation.
//

import Foundation
import SwiftData

@Model
final class Segment {
    // No @Attribute(.unique) - CloudKit incompatible
    var id = UUID()

    /// Time offset from session start (seconds)
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0

    var originalText: String = ""
    var translatedText: String?

    var sourceLocaleIdentifier: String = "en-US"
    var targetLocaleIdentifier: String?

    /// Recognition confidence (0.0 - 1.0)
    var confidence: Float = 1.0

    /// Whether transcription is finalized
    var isFinal: Bool = false

    // Optional relationships for CloudKit
    @Relationship var session: Session?

    @Relationship var speaker: Speaker?

    // MARK: - Computed Properties

    var sourceLocale: Locale {
        Locale(identifier: sourceLocaleIdentifier)
    }

    var targetLocale: Locale? {
        targetLocaleIdentifier.map { Locale(identifier: $0) }
    }

    var duration: TimeInterval {
        endTime - startTime
    }

    var hasTranslation: Bool {
        guard let text = translatedText else { return false }
        return !text.isEmpty
    }

    var displayText: String {
        translatedText ?? originalText
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        startTime: TimeInterval = 0,
        endTime: TimeInterval = 0,
        originalText: String = "",
        translatedText: String? = nil,
        sourceLocale: Locale = Locale(identifier: "en-US"),
        targetLocale: Locale? = nil,
        confidence: Float = 1.0,
        isFinal: Bool = false,
        speaker: Speaker? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLocaleIdentifier = sourceLocale.identifier
        self.targetLocaleIdentifier = targetLocale?.identifier
        self.confidence = confidence
        self.isFinal = isFinal
        self.speaker = speaker
    }
}
