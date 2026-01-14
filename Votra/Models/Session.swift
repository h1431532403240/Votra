//
//  Session.swift
//  Votra
//
//  Session model representing an active or completed translation session.
//

import Foundation
import SwiftData

@Model
final class Session {
    // No @Attribute(.unique) - CloudKit incompatible
    var id = UUID()

    var startTime = Date()
    var endTime: Date?

    var sourceLocaleIdentifier: String = "en-US"
    var targetLocaleIdentifier: String = "zh-Hant"

    /// Whether the session should persist after app quit
    /// Only true when user explicitly records/exports
    var isPersisted: Bool = false

    // All relationships MUST be optional for CloudKit compatibility
    @Relationship(deleteRule: .cascade, inverse: \Segment.session)
    var segments: [Segment]?

    @Relationship var speakers: [Speaker]?

    @Relationship(deleteRule: .cascade, inverse: \Recording.session)
    var recording: Recording?

    @Relationship(deleteRule: .cascade, inverse: \MeetingSummary.session)
    var summary: MeetingSummary?

    // MARK: - Computed Properties

    var sourceLocale: Locale {
        get { Locale(identifier: sourceLocaleIdentifier) }
        set { sourceLocaleIdentifier = newValue.identifier }
    }

    var targetLocale: Locale {
        get { Locale(identifier: targetLocaleIdentifier) }
        set { targetLocaleIdentifier = newValue.identifier }
    }

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var isActive: Bool {
        endTime == nil
    }

    var segmentCount: Int {
        segments?.count ?? 0
    }

    var sortedSegments: [Segment] {
        (segments ?? []).sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        sourceLocale: Locale = Locale(identifier: "en-US"),
        targetLocale: Locale = Locale(identifier: "zh-Hant")
    ) {
        self.id = id
        self.startTime = startTime
        self.sourceLocaleIdentifier = sourceLocale.identifier
        self.targetLocaleIdentifier = targetLocale.identifier
    }

    // MARK: - Methods

    func addSegment(_ segment: Segment) {
        if segments == nil {
            segments = []
        }
        segments?.append(segment)
        segment.session = self
    }

    func addSpeaker(_ speaker: Speaker) {
        var currentSpeakers = speakers ?? []
        guard !currentSpeakers.contains(where: { $0.id == speaker.id }) else { return }
        currentSpeakers.append(speaker)
        speakers = currentSpeakers
    }

    func end() {
        endTime = Date()
    }
}
