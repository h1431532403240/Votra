//
//  TranslationSessionTests.swift
//  VotraTests
//
//  Comprehensive unit tests for the Session model (translation session).
//

import Testing
import Foundation
import SwiftData
@testable import Votra

@Suite("Session Model Tests")
@MainActor
struct TranslationSessionTests {
    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    // MARK: - Default Initialization Tests

    @Test("Default initializer creates valid session with UUID")
    func defaultInitializerCreatesValidSession() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.id != UUID())
    }

    @Test("Default initializer sets startTime to now")
    func defaultInitializerSetsStartTime() {
        let context = container.mainContext
        let beforeCreation = Date()
        let session = Session()
        context.insert(session)
        let afterCreation = Date()

        #expect(session.startTime >= beforeCreation)
        #expect(session.startTime <= afterCreation)
    }

    @Test("Default initializer leaves endTime nil")
    func defaultInitializerLeavesEndTimeNil() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.endTime == nil)
    }

    @Test("Default initializer uses English-US as source locale")
    func defaultSourceLocaleIsEnglishUS() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.sourceLocaleIdentifier == "en-US")
        #expect(session.sourceLocale.identifier == "en-US")
    }

    @Test("Default initializer uses Traditional Chinese as target locale")
    func defaultTargetLocaleIsTraditionalChinese() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.targetLocaleIdentifier == "zh-Hant")
        #expect(session.targetLocale.identifier == "zh-Hant")
    }

    @Test("Default initializer sets isPersisted to false")
    func defaultIsPersistedIsFalse() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.isPersisted == false)
    }

    @Test("Default initializer leaves relationships nil")
    func defaultRelationshipsAreNil() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.segments == nil)
        #expect(session.speakers == nil)
        #expect(session.recording == nil)
        #expect(session.summary == nil)
    }

    // MARK: - Custom Initialization Tests

    @Test("Initializer with custom UUID preserves the ID")
    func customUUIDIsPreserved() {
        let context = container.mainContext
        let customID = UUID()
        let session = Session(id: customID)
        context.insert(session)

        #expect(session.id == customID)
    }

    @Test("Initializer with custom startTime preserves the time")
    func customStartTimeIsPreserved() {
        let context = container.mainContext
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let session = Session(startTime: customDate)
        context.insert(session)

        #expect(session.startTime == customDate)
    }

    @Test("Initializer with custom source locale preserves identifier")
    func customSourceLocaleIsPreserved() {
        let context = container.mainContext
        let session = Session(sourceLocale: Locale(identifier: "ja-JP"))
        context.insert(session)

        #expect(session.sourceLocaleIdentifier == "ja-JP")
        #expect(session.sourceLocale.identifier == "ja-JP")
    }

    @Test("Initializer with custom target locale preserves identifier")
    func customTargetLocaleIsPreserved() {
        let context = container.mainContext
        let session = Session(targetLocale: Locale(identifier: "ko-KR"))
        context.insert(session)

        #expect(session.targetLocaleIdentifier == "ko-KR")
        #expect(session.targetLocale.identifier == "ko-KR")
    }

    @Test("Initializer with all custom parameters preserves all values")
    func allCustomParametersPreserved() {
        let context = container.mainContext
        let customID = UUID()
        let customDate = Date(timeIntervalSince1970: 500_000)
        let sourceLocale = Locale(identifier: "fr-FR")
        let targetLocale = Locale(identifier: "de-DE")

        let session = Session(
            id: customID,
            startTime: customDate,
            sourceLocale: sourceLocale,
            targetLocale: targetLocale
        )
        context.insert(session)

        #expect(session.id == customID)
        #expect(session.startTime == customDate)
        #expect(session.sourceLocaleIdentifier == "fr-FR")
        #expect(session.targetLocaleIdentifier == "de-DE")
    }

    @Test("Initializer accepts various locale formats")
    func acceptsVariousLocaleFormats() {
        let context = container.mainContext

        // Simple language code
        let session1 = Session(sourceLocale: Locale(identifier: "en"))
        context.insert(session1)
        #expect(session1.sourceLocaleIdentifier == "en")

        // Language with region
        let session2 = Session(sourceLocale: Locale(identifier: "pt-BR"))
        context.insert(session2)
        #expect(session2.sourceLocaleIdentifier == "pt-BR")

        // Language with script
        let session3 = Session(sourceLocale: Locale(identifier: "zh-Hans"))
        context.insert(session3)
        #expect(session3.sourceLocaleIdentifier == "zh-Hans")
    }

    // MARK: - Computed Properties Tests

    @Test("sourceLocale getter returns correct Locale")
    func sourceLocaleGetterReturnsCorrectLocale() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.sourceLocaleIdentifier = "es-MX"

        let locale = session.sourceLocale
        #expect(locale.identifier == "es-MX")
    }

    @Test("sourceLocale setter updates identifier")
    func sourceLocaleSetterUpdatesIdentifier() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.sourceLocale = Locale(identifier: "it-IT")

        #expect(session.sourceLocaleIdentifier == "it-IT")
    }

    @Test("targetLocale getter returns correct Locale")
    func targetLocaleGetterReturnsCorrectLocale() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.targetLocaleIdentifier = "ru-RU"

        let locale = session.targetLocale
        #expect(locale.identifier == "ru-RU")
    }

    @Test("targetLocale setter updates identifier")
    func targetLocaleSetterUpdatesIdentifier() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.targetLocale = Locale(identifier: "ar-SA")

        #expect(session.targetLocaleIdentifier == "ar-SA")
    }

    @Test("isActive is true when endTime is nil")
    func isActiveTrueWhenEndTimeNil() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.endTime == nil)
        #expect(session.isActive == true)
    }

    @Test("isActive is false when endTime is set")
    func isActiveFalseWhenEndTimeSet() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.endTime = Date()

        #expect(session.isActive == false)
    }

    @Test("segmentCount is 0 when segments is nil")
    func segmentCountZeroWhenSegmentsNil() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.segments == nil)
        #expect(session.segmentCount == 0)
    }

    @Test("segmentCount is 0 when segments is empty array")
    func segmentCountZeroWhenSegmentsEmpty() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.segments = []

        #expect(session.segmentCount == 0)
    }

    @Test("segmentCount reflects actual segment count")
    func segmentCountReflectsActualCount() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment1 = Segment(startTime: 0, endTime: 5, originalText: "First")
        let segment2 = Segment(startTime: 5, endTime: 10, originalText: "Second")
        context.insert(segment1)
        context.insert(segment2)

        session.addSegment(segment1)
        session.addSegment(segment2)

        #expect(session.segmentCount == 2)
    }

    @Test("sortedSegments returns empty array when segments is nil")
    func sortedSegmentsEmptyWhenNil() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.segments == nil)
        #expect(session.sortedSegments.isEmpty)
    }

    @Test("sortedSegments returns segments sorted by startTime")
    func sortedSegmentsOrderedByStartTime() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Add segments in non-chronological order
        let segment1 = Segment(startTime: 10, endTime: 15, originalText: "Third")
        let segment2 = Segment(startTime: 0, endTime: 5, originalText: "First")
        let segment3 = Segment(startTime: 5, endTime: 10, originalText: "Second")

        context.insert(segment1)
        context.insert(segment2)
        context.insert(segment3)

        session.addSegment(segment1)
        session.addSegment(segment2)
        session.addSegment(segment3)

        let sorted = session.sortedSegments
        #expect(sorted.count == 3)
        #expect(sorted[0].originalText == "First")
        #expect(sorted[1].originalText == "Second")
        #expect(sorted[2].originalText == "Third")
    }

    // MARK: - Duration Tests

    @Test("Duration calculates from startTime to now when active")
    func durationCalculatesToNowWhenActive() async throws {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        try await Task.sleep(for: .milliseconds(50))

        let duration = session.duration
        #expect(duration >= 0.05)
        #expect(session.isActive == true)
    }

    @Test("Duration calculates from startTime to endTime when ended")
    func durationCalculatesToEndTimeWhenEnded() {
        let context = container.mainContext
        let startTime = Date(timeIntervalSince1970: 1000)
        let endTime = Date(timeIntervalSince1970: 1060) // 60 seconds later

        let session = Session(startTime: startTime)
        context.insert(session)
        session.endTime = endTime

        let duration = session.duration
        #expect(abs(duration - 60.0) < 0.001)
    }

    @Test("Duration is zero when startTime equals endTime")
    func durationZeroWhenTimesEqual() {
        let context = container.mainContext
        let sameTime = Date()

        let session = Session(startTime: sameTime)
        context.insert(session)
        session.endTime = sameTime

        #expect(abs(session.duration) < 0.001)
    }

    @Test("Duration handles long sessions correctly")
    func durationHandlesLongSessions() {
        let context = container.mainContext
        let startTime = Date(timeIntervalSince1970: 0)
        let endTime = Date(timeIntervalSince1970: 7200) // 2 hours

        let session = Session(startTime: startTime)
        context.insert(session)
        session.endTime = endTime

        let duration = session.duration
        #expect(abs(duration - 7200.0) < 0.001)
    }

    @Test("Duration stays fixed after session ends")
    func durationStaysFixedAfterEnd() async throws {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        try await Task.sleep(for: .milliseconds(50))
        session.end()

        let durationAtEnd = session.duration

        try await Task.sleep(for: .milliseconds(50))

        let durationLater = session.duration
        #expect(abs(durationAtEnd - durationLater) < 0.001)
    }

    // MARK: - End Session Tests

    @Test("End sets endTime to current date")
    func endSetsEndTime() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let beforeEnd = Date()
        session.end()
        let afterEnd = Date()

        #expect(session.endTime != nil)
        if let endTime = session.endTime {
            #expect(endTime >= beforeEnd)
            #expect(endTime <= afterEnd)
        }
    }

    @Test("End changes isActive to false")
    func endChangesIsActiveToFalse() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.isActive == true)

        session.end()

        #expect(session.isActive == false)
    }

    @Test("End called multiple times updates endTime each time")
    func endCalledMultipleTimesUpdatesEndTime() async throws {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.end()
        let firstEndTime = session.endTime

        try await Task.sleep(for: .milliseconds(50))

        session.end()
        let secondEndTime = session.endTime

        #expect(firstEndTime != nil)
        #expect(secondEndTime != nil)
        if let first = firstEndTime, let second = secondEndTime {
            #expect(second >= first)
        }
    }

    @Test("EndTime is always after or equal to startTime")
    func endTimeIsAfterStartTime() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.end()

        if let endTime = session.endTime {
            #expect(endTime >= session.startTime)
        }
    }

    // MARK: - Add Segment Tests

    @Test("addSegment initializes segments array if nil")
    func addSegmentInitializesArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.segments == nil)

        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        context.insert(segment)

        session.addSegment(segment)

        #expect(session.segments != nil)
        #expect(session.segmentCount == 1)
    }

    @Test("addSegment appends segment to array")
    func addSegmentAppendsToArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment1 = Segment(startTime: 0, endTime: 5, originalText: "First")
        let segment2 = Segment(startTime: 5, endTime: 10, originalText: "Second")
        context.insert(segment1)
        context.insert(segment2)

        session.addSegment(segment1)
        session.addSegment(segment2)

        #expect(session.segmentCount == 2)
    }

    @Test("addSegment sets inverse relationship on segment")
    func addSegmentSetsInverseRelationship() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        context.insert(segment)

        #expect(segment.session == nil)

        session.addSegment(segment)

        #expect(segment.session === session)
    }

    @Test("addSegment preserves segment data")
    func addSegmentPreservesData() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment = Segment(
            startTime: 10.5,
            endTime: 15.3,
            originalText: "Hello World",
            translatedText: "Bonjour le Monde",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "fr-FR"),
            confidence: 0.95,
            isFinal: true
        )
        context.insert(segment)

        session.addSegment(segment)

        let addedSegment = session.segments?.first
        #expect(addedSegment?.startTime == 10.5)
        #expect(addedSegment?.endTime == 15.3)
        #expect(addedSegment?.originalText == "Hello World")
        #expect(addedSegment?.translatedText == "Bonjour le Monde")
        #expect(addedSegment?.confidence == 0.95)
        #expect(addedSegment?.isFinal == true)
    }

    @Test("addSegment allows adding many segments")
    func addSegmentAllowsManySegments() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        for i in 0..<100 {
            let segment = Segment(
                startTime: Double(i),
                endTime: Double(i + 1),
                originalText: "Segment \(i)"
            )
            context.insert(segment)
            session.addSegment(segment)
        }

        #expect(session.segmentCount == 100)
    }

    // MARK: - Add Speaker Tests

    @Test("addSpeaker initializes speakers array if nil")
    func addSpeakerInitializesArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.speakers == nil)

        let speaker = Speaker.createMe()
        context.insert(speaker)

        session.addSpeaker(speaker)

        #expect(session.speakers != nil)
        #expect(session.speakers?.count == 1)
    }

    @Test("addSpeaker appends speaker to array")
    func addSpeakerAppendsToArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker1 = Speaker.createMe()
        let speaker2 = Speaker.createRemote()
        context.insert(speaker1)
        context.insert(speaker2)

        session.addSpeaker(speaker1)
        session.addSpeaker(speaker2)

        #expect(session.speakers?.count == 2)
    }

    @Test("addSpeaker prevents duplicate speakers by ID")
    func addSpeakerPreventsDuplicates() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker = Speaker.createMe()
        context.insert(speaker)

        session.addSpeaker(speaker)
        session.addSpeaker(speaker)
        session.addSpeaker(speaker)

        #expect(session.speakers?.count == 1)
    }

    @Test("addSpeaker allows speakers with different IDs")
    func addSpeakerAllowsDifferentIDs() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker1 = Speaker(displayName: "Speaker 1", source: .microphone)
        let speaker2 = Speaker(displayName: "Speaker 2", source: .systemAudio)
        context.insert(speaker1)
        context.insert(speaker2)

        session.addSpeaker(speaker1)
        session.addSpeaker(speaker2)

        #expect(session.speakers?.count == 2)
    }

    @Test("addSpeaker preserves speaker properties")
    func addSpeakerPreservesProperties() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker = Speaker(
            displayName: "John Doe",
            source: .microphone,
            color: .orange
        )
        context.insert(speaker)

        session.addSpeaker(speaker)

        let addedSpeaker = session.speakers?.first
        #expect(addedSpeaker?.displayName == "John Doe")
        #expect(addedSpeaker?.source == .microphone)
        #expect(addedSpeaker?.color == .orange)
    }

    // MARK: - Relationship Tests

    @Test("Recording relationship can be set")
    func recordingRelationshipCanBeSet() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let recording = Recording(duration: 120.0)
        context.insert(recording)

        session.recording = recording

        #expect(session.recording != nil)
        #expect(session.recording?.duration == 120.0)
    }

    @Test("Recording inverse relationship is set automatically")
    func recordingInverseRelationshipIsSet() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let recording = Recording()
        context.insert(recording)

        session.recording = recording

        #expect(recording.session === session)
    }

    @Test("Summary relationship can be set")
    func summaryRelationshipCanBeSet() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let summary = MeetingSummary(
            summaryText: "Test summary",
            keyPoints: ["Point 1", "Point 2"],
            actionItems: ["Action 1"]
        )
        context.insert(summary)

        session.summary = summary

        #expect(session.summary != nil)
        #expect(session.summary?.summaryText == "Test summary")
    }

    @Test("Summary inverse relationship is set automatically")
    func summaryInverseRelationshipIsSet() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let summary = MeetingSummary()
        context.insert(summary)

        session.summary = summary

        #expect(summary.session === session)
    }

    @Test("isPersisted can be toggled")
    func isPersistedCanBeToggled() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.isPersisted == false)

        session.isPersisted = true

        #expect(session.isPersisted == true)

        session.isPersisted = false

        #expect(session.isPersisted == false)
    }

    // MARK: - State Transition Tests

    @Test("New session is active")
    func newSessionIsActive() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.isActive == true)
        #expect(session.endTime == nil)
    }

    @Test("Session can transition from active to ended")
    func sessionTransitionsFromActiveToEnded() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.isActive == true)

        session.end()

        #expect(session.isActive == false)
        #expect(session.endTime != nil)
    }

    @Test("Ended session can have endTime updated")
    func endedSessionCanHaveEndTimeUpdated() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.end()
        let firstEndTime = session.endTime

        session.endTime = Date(timeIntervalSinceNow: 3600)
        let newEndTime = session.endTime

        #expect(newEndTime != firstEndTime)
    }

    @Test("Session can be reactivated by clearing endTime")
    func sessionCanBeReactivated() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.end()
        #expect(session.isActive == false)

        session.endTime = nil
        #expect(session.isActive == true)
    }

    // MARK: - Edge Case Tests

    @Test("Empty locale identifier is accepted")
    func emptyLocaleIdentifierAccepted() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.sourceLocaleIdentifier = ""
        session.targetLocaleIdentifier = ""

        #expect(session.sourceLocaleIdentifier.isEmpty)
        #expect(session.targetLocaleIdentifier.isEmpty)
    }

    @Test("Very old startTime is accepted")
    func veryOldStartTimeAccepted() {
        let context = container.mainContext
        let veryOldDate = Date(timeIntervalSince1970: 0)
        let session = Session(startTime: veryOldDate)
        context.insert(session)

        #expect(session.startTime == veryOldDate)
    }

    @Test("Future startTime is accepted")
    func futureStartTimeAccepted() {
        let context = container.mainContext
        let futureDate = Date(timeIntervalSinceNow: 86400 * 365) // 1 year from now
        let session = Session(startTime: futureDate)
        context.insert(session)

        #expect(session.startTime == futureDate)
    }

    @Test("Session with same source and target locale is valid")
    func sameSourceAndTargetLocaleIsValid() {
        let context = container.mainContext
        let session = Session(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "en-US")
        )
        context.insert(session)

        #expect(session.sourceLocaleIdentifier == session.targetLocaleIdentifier)
    }

    @Test("Segments can have overlapping times")
    func segmentsCanOverlap() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment1 = Segment(startTime: 0, endTime: 10, originalText: "First")
        let segment2 = Segment(startTime: 5, endTime: 15, originalText: "Overlapping")
        context.insert(segment1)
        context.insert(segment2)

        session.addSegment(segment1)
        session.addSegment(segment2)

        #expect(session.segmentCount == 2)
    }

    @Test("sortedSegments handles segments with same startTime")
    func sortedSegmentsHandlesSameStartTime() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment1 = Segment(startTime: 5, endTime: 10, originalText: "A")
        let segment2 = Segment(startTime: 5, endTime: 10, originalText: "B")
        context.insert(segment1)
        context.insert(segment2)

        session.addSegment(segment1)
        session.addSegment(segment2)

        let sorted = session.sortedSegments
        #expect(sorted.count == 2)
        // Both should be present, order between equal times is unspecified
        let texts = sorted.map { $0.originalText }
        #expect(texts.contains("A"))
        #expect(texts.contains("B"))
    }

    @Test("Multiple sessions can exist independently")
    func multipleSessionsExistIndependently() {
        let context = container.mainContext

        let session1 = Session(sourceLocale: Locale(identifier: "en-US"))
        let session2 = Session(sourceLocale: Locale(identifier: "ja-JP"))
        let session3 = Session(sourceLocale: Locale(identifier: "de-DE"))

        context.insert(session1)
        context.insert(session2)
        context.insert(session3)

        #expect(session1.sourceLocaleIdentifier == "en-US")
        #expect(session2.sourceLocaleIdentifier == "ja-JP")
        #expect(session3.sourceLocaleIdentifier == "de-DE")
    }

    // MARK: - Persistence Tests

    @Test("Session persists to context")
    func sessionPersistsToContext() throws {
        let context = container.mainContext

        let sessionID = UUID()
        let session = Session(id: sessionID)
        context.insert(session)

        try context.save()

        let descriptor = FetchDescriptor<Session>()
        let fetchedSessions = try context.fetch(descriptor)

        #expect(fetchedSessions.contains { $0.id == sessionID })
    }

    @Test("Session with relationships persists")
    func sessionWithRelationshipsPersists() throws {
        let context = container.mainContext

        let session = Session()
        context.insert(session)

        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        context.insert(segment)
        session.addSegment(segment)

        let speaker = Speaker.createMe()
        context.insert(speaker)
        session.addSpeaker(speaker)

        try context.save()

        let descriptor = FetchDescriptor<Session>()
        let fetchedSessions = try context.fetch(descriptor)
        let fetchedSession = fetchedSessions.first { $0.id == session.id }

        #expect(fetchedSession?.segmentCount == 1)
        #expect(fetchedSession?.speakers?.count == 1)
    }

    // MARK: - Locale Handling Tests

    @Test("Common language locales are supported")
    func commonLanguageLocalesSupported() {
        let context = container.mainContext

        let locales = [
            "en-US", "en-GB", "zh-Hans", "zh-Hant",
            "ja-JP", "ko-KR", "es-ES", "es-MX",
            "fr-FR", "de-DE", "it-IT", "pt-BR",
            "ru-RU", "ar-SA", "hi-IN", "th-TH"
        ]

        for identifier in locales {
            let session = Session(sourceLocale: Locale(identifier: identifier))
            context.insert(session)
            #expect(session.sourceLocaleIdentifier == identifier)
        }
    }

    @Test("Locale changes are reflected in computed properties")
    func localeChangesReflected() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Initial values
        #expect(session.sourceLocale.identifier == "en-US")

        // Change via identifier
        session.sourceLocaleIdentifier = "fr-FR"
        #expect(session.sourceLocale.identifier == "fr-FR")

        // Change via computed property
        session.sourceLocale = Locale(identifier: "de-DE")
        #expect(session.sourceLocaleIdentifier == "de-DE")
    }

    // MARK: - Complex Scenario Tests

    @Test("Full session lifecycle with all relationships")
    func fullSessionLifecycle() throws {
        let context = container.mainContext

        // Create session
        let session = Session(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "ja-JP")
        )
        context.insert(session)

        // Add speakers
        let meSpeaker = Speaker.createMe()
        let remoteSpeaker = Speaker.createRemote()
        context.insert(meSpeaker)
        context.insert(remoteSpeaker)
        session.addSpeaker(meSpeaker)
        session.addSpeaker(remoteSpeaker)

        // Add segments
        let segment1 = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello",
            translatedText: "Konnichiwa",
            isFinal: true,
            speaker: meSpeaker
        )
        let segment2 = Segment(
            startTime: 5,
            endTime: 10,
            originalText: "How are you?",
            translatedText: "Ogenki desu ka?",
            isFinal: true,
            speaker: remoteSpeaker
        )
        context.insert(segment1)
        context.insert(segment2)
        session.addSegment(segment1)
        session.addSegment(segment2)

        // Add recording
        let recording = Recording(duration: 10.0)
        context.insert(recording)
        session.recording = recording

        // Add summary
        let summary = MeetingSummary(
            summaryText: "A brief greeting exchange",
            keyPoints: ["Greeting", "Inquiry about wellbeing"],
            actionItems: []
        )
        context.insert(summary)
        session.summary = summary

        // End session
        session.isPersisted = true
        session.end()

        // Save
        try context.save()

        // Verify all relationships
        #expect(session.speakers?.count == 2)
        #expect(session.segmentCount == 2)
        #expect(session.recording != nil)
        #expect(session.summary != nil)
        #expect(session.isActive == false)
        #expect(session.isPersisted == true)
        #expect(session.duration >= 0)

        // Verify sorted segments
        let sorted = session.sortedSegments
        #expect(sorted[0].originalText == "Hello")
        #expect(sorted[1].originalText == "How are you?")
    }

    @Test("Session can be cleared and reused")
    func sessionCanBeClearedAndReused() {
        let context = container.mainContext

        let session = Session()
        context.insert(session)

        // Add some data
        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        context.insert(segment)
        session.addSegment(segment)

        let speaker = Speaker.createMe()
        context.insert(speaker)
        session.addSpeaker(speaker)

        // Clear relationships by setting to empty arrays
        // (SwiftData may retain relationship arrays even when set to nil)
        session.segments = []
        session.speakers = []
        session.recording = nil
        session.summary = nil
        session.endTime = nil

        // Verify cleared
        #expect(session.segmentCount == 0)
        #expect(session.speakers?.count ?? 0 == 0)
        #expect(session.recording == nil)
        #expect(session.summary == nil)
        #expect(session.isActive == true)

        // Can add new data
        let newSegment = Segment(startTime: 0, endTime: 3, originalText: "New")
        context.insert(newSegment)
        session.addSegment(newSegment)

        #expect(session.segmentCount == 1)
        #expect(session.segments?.first?.originalText == "New")
    }

    @Test("Session handles rapid segment additions")
    func sessionHandlesRapidSegmentAdditions() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Simulate rapid segment additions
        for i in 0..<50 {
            let segment = Segment(
                startTime: Double(i) * 0.5,
                endTime: Double(i) * 0.5 + 0.5,
                originalText: "Segment \(i)",
                isFinal: i.isMultiple(of: 2)
            )
            context.insert(segment)
            session.addSegment(segment)
        }

        #expect(session.segmentCount == 50)

        let sorted = session.sortedSegments
        #expect(sorted.first?.startTime == 0)
        #expect(sorted.last?.startTime == 24.5)
    }

    @Test("Session locale swapping works correctly")
    func sessionLocaleSwappingWorks() {
        let context = container.mainContext
        let session = Session(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "ja-JP")
        )
        context.insert(session)

        // Swap locales
        let tempSource = session.sourceLocale
        session.sourceLocale = session.targetLocale
        session.targetLocale = tempSource

        #expect(session.sourceLocaleIdentifier == "ja-JP")
        #expect(session.targetLocaleIdentifier == "en-US")
    }

    // MARK: - Additional Coverage Tests

    @Test("addSegment appends when segments is already empty array")
    func addSegmentAppendsToEmptyArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Pre-initialize segments as empty array (not nil)
        session.segments = []
        #expect(session.segments != nil)
        #expect(session.segmentCount == 0)

        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        context.insert(segment)

        session.addSegment(segment)

        #expect(session.segmentCount == 1)
        #expect(segment.session === session)
    }

    @Test("addSpeaker appends when speakers is already empty array")
    func addSpeakerAppendsToEmptyArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Pre-initialize speakers as empty array (not nil)
        session.speakers = []
        #expect(session.speakers != nil)
        #expect(session.speakers?.isEmpty == true)

        let speaker = Speaker.createMe()
        context.insert(speaker)

        session.addSpeaker(speaker)

        #expect(session.speakers?.count == 1)
    }

    @Test("addSpeaker guard returns early when speaker exists in non-empty array")
    func addSpeakerReturnsEarlyForExistingInNonEmptyArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker1 = Speaker(displayName: "First", source: .microphone)
        let speaker2 = Speaker(displayName: "Second", source: .systemAudio)
        context.insert(speaker1)
        context.insert(speaker2)

        // Add both speakers
        session.addSpeaker(speaker1)
        session.addSpeaker(speaker2)
        #expect(session.speakers?.count == 2)

        // Try to add speaker1 again - should hit the guard and return early
        session.addSpeaker(speaker1)
        #expect(session.speakers?.count == 2)

        // Try to add speaker2 again - should also hit guard
        session.addSpeaker(speaker2)
        #expect(session.speakers?.count == 2)
    }

    @Test("addSpeaker contains check executes for each speaker in array")
    func addSpeakerContainsCheckExecutesForMultipleSpeakers() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Create multiple speakers with distinct IDs
        let speaker1 = Speaker(displayName: "Alice", source: .microphone)
        let speaker2 = Speaker(displayName: "Bob", source: .systemAudio)
        let speaker3 = Speaker(displayName: "Charlie", source: .microphone)
        context.insert(speaker1)
        context.insert(speaker2)
        context.insert(speaker3)

        // Add all three speakers
        session.addSpeaker(speaker1)
        session.addSpeaker(speaker2)
        session.addSpeaker(speaker3)
        #expect(session.speakers?.count == 3)

        // Verify IDs are all different
        let speakerIDs = session.speakers?.map(\.id) ?? []
        #expect(speakerIDs.count == 3)
        #expect(Set(speakerIDs).count == 3) // All unique

        // Now try adding speaker2 again - the contains closure must check against
        // speaker1 and speaker2 (and find speaker2)
        session.addSpeaker(speaker2)
        #expect(session.speakers?.count == 3)

        // Add a new speaker to verify it still works after duplicate rejection
        let speaker4 = Speaker(displayName: "Diana", source: .systemAudio)
        context.insert(speaker4)
        session.addSpeaker(speaker4)
        #expect(session.speakers?.count == 4)
    }

    @Test("sortedSegments returns empty array when segments is empty array")
    func sortedSegmentsEmptyWhenEmptyArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Set segments to empty array (not nil)
        session.segments = []

        #expect(session.segments != nil)
        #expect(session.sortedSegments.isEmpty)
    }

    @Test("segmentCount returns correct count with pre-initialized empty array")
    func segmentCountWithPreInitializedEmptyArray() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Pre-initialize to empty array
        session.segments = []
        #expect(session.segmentCount == 0)

        // Add a segment
        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        context.insert(segment)
        session.addSegment(segment)

        #expect(session.segmentCount == 1)
    }

    @Test("duration uses current date when endTime is nil")
    func durationUsesCurrentDateWhenEndTimeNil() {
        let context = container.mainContext
        // Use a fixed start time in the past
        let startTime = Date(timeIntervalSinceNow: -10)
        let session = Session(startTime: startTime)
        context.insert(session)

        #expect(session.endTime == nil)

        let duration = session.duration
        // Duration should be approximately 10 seconds (or slightly more)
        #expect(duration >= 10.0)
        #expect(duration < 15.0)
    }
}
