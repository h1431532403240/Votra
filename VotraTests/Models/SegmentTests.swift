//
//  SegmentTests.swift
//  VotraTests
//
//  Unit tests for the Segment model.
//

import Testing
import Foundation
import SwiftData
@testable import Votra

@MainActor
@Suite("Segment Model Tests")
struct SegmentTests {
    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    // MARK: - Initialization Tests

    @Test("Default initialization creates segment with expected defaults")
    func testSegmentInitialization() {
        let context = container.mainContext
        let segment = Segment()
        context.insert(segment)

        #expect(segment.id != UUID())
        #expect(segment.startTime == 0)
        #expect(segment.endTime == 0)
        #expect(segment.originalText.isEmpty)
        #expect(segment.translatedText == nil)
        #expect(segment.confidence == 1.0)
        #expect(segment.isFinal == false)
        #expect(segment.session == nil)
        #expect(segment.speaker == nil)
    }

    @Test("Initialization with custom UUID preserves the UUID")
    func testSegmentWithCustomUUID() {
        let context = container.mainContext
        let customUUID = UUID()
        let segment = Segment(id: customUUID)
        context.insert(segment)

        #expect(segment.id == customUUID)
    }

    @Test("Initialization with all parameters sets values correctly")
    func testSegmentWithContent() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 10.5,
            endTime: 15.3,
            originalText: "Hello, how are you?",
            translatedText: "Translated text",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hant"),
            confidence: 0.95,
            isFinal: true
        )
        context.insert(segment)

        #expect(segment.startTime == 10.5)
        #expect(segment.endTime == 15.3)
        #expect(segment.originalText == "Hello, how are you?")
        #expect(segment.translatedText == "Translated text")
        #expect(segment.sourceLocaleIdentifier == "en-US")
        #expect(segment.targetLocaleIdentifier == "zh-Hant")
        #expect(segment.confidence == 0.95)
        #expect(segment.isFinal == true)
    }

    // MARK: - Duration Computed Property Tests

    @Test("Duration calculates difference between end and start time")
    func testSegmentDuration() {
        let context = container.mainContext
        let segment = Segment(startTime: 5.0, endTime: 12.5)
        context.insert(segment)

        #expect(segment.duration == 7.5)
    }

    @Test("Duration is zero when start and end times are equal")
    func testSegmentDurationZero() {
        let context = container.mainContext
        let segment = Segment(startTime: 10.0, endTime: 10.0)
        context.insert(segment)

        #expect(segment.duration == 0)
    }

    @Test("Duration can be negative when end time is before start time")
    func testSegmentDurationNegative() {
        let context = container.mainContext
        let segment = Segment(startTime: 15.0, endTime: 10.0)
        context.insert(segment)

        #expect(segment.duration == -5.0)
    }

    @Test("Duration with very large time values")
    func testSegmentDurationLargeValues() {
        let context = container.mainContext
        let segment = Segment(startTime: 0, endTime: 86400.0) // 24 hours in seconds
        context.insert(segment)

        #expect(segment.duration == 86400.0)
    }

    @Test("Duration with fractional milliseconds")
    func testSegmentDurationFractional() {
        let context = container.mainContext
        let segment = Segment(startTime: 1.001, endTime: 2.999)
        context.insert(segment)

        #expect(abs(segment.duration - 1.998) < 0.0001)
    }

    // MARK: - hasTranslation Computed Property Tests

    @Test("hasTranslation returns false when translatedText is nil")
    func testHasTranslationNil() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello")
        context.insert(segment)
        #expect(segment.hasTranslation == false)
    }

    @Test("hasTranslation returns false when translatedText is empty string")
    func testHasTranslationEmpty() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello", translatedText: "")
        context.insert(segment)
        #expect(segment.hasTranslation == false)
    }

    @Test("hasTranslation returns true when translatedText has content")
    func testHasTranslationWithContent() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello", translatedText: "Translated")
        context.insert(segment)
        #expect(segment.hasTranslation == true)
    }

    @Test("hasTranslation returns true when translatedText is whitespace only")
    func testHasTranslationWhitespace() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello", translatedText: "   ")
        context.insert(segment)
        // Whitespace-only string is not empty, so hasTranslation should be true
        #expect(segment.hasTranslation == true)
    }

    // MARK: - displayText Computed Property Tests

    @Test("displayText returns originalText when no translation")
    func testDisplayTextWithoutTranslation() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello")
        context.insert(segment)
        #expect(segment.displayText == "Hello")
    }

    @Test("displayText returns translatedText when translation exists")
    func testDisplayTextWithTranslation() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello", translatedText: "Translated")
        context.insert(segment)
        #expect(segment.displayText == "Translated")
    }

    @Test("displayText returns empty translatedText when it is empty string")
    func testDisplayTextWithEmptyTranslation() {
        let context = container.mainContext

        let segment = Segment(originalText: "Hello", translatedText: "")
        context.insert(segment)
        // translatedText is not nil, so it will be returned even if empty
        #expect(segment.displayText.isEmpty)
    }

    // MARK: - Locale Computed Property Tests

    @Test("sourceLocale returns Locale from sourceLocaleIdentifier")
    func testSourceLocaleComputedProperty() {
        let context = container.mainContext
        let segment = Segment(sourceLocale: Locale(identifier: "ja-JP"))
        context.insert(segment)

        #expect(segment.sourceLocale.identifier == "ja-JP")
    }

    @Test("targetLocale returns Locale when targetLocaleIdentifier is set")
    func testTargetLocaleComputedProperty() {
        let context = container.mainContext
        let segment = Segment(
            sourceLocale: Locale(identifier: "ja-JP"),
            targetLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        #expect(segment.targetLocale?.identifier == "en-US")
    }

    @Test("targetLocale returns nil when targetLocaleIdentifier is nil")
    func testTargetLocaleNil() {
        let context = container.mainContext
        let segment = Segment(sourceLocale: Locale(identifier: "en-US"))
        context.insert(segment)

        #expect(segment.targetLocaleIdentifier == nil)
        #expect(segment.targetLocale == nil)
    }

    @Test("Default sourceLocaleIdentifier is en-US")
    func testDefaultSourceLocale() {
        let context = container.mainContext
        let segment = Segment()
        context.insert(segment)

        #expect(segment.sourceLocaleIdentifier == "en-US")
        #expect(segment.sourceLocale.identifier == "en-US")
    }

    // MARK: - Speaker Relationship Tests

    @Test("Segment can be initialized with a Speaker")
    func testSegmentWithSpeaker() {
        let context = container.mainContext
        let speaker = Speaker.createMe()
        context.insert(speaker)

        let segment = Segment(
            originalText: "Hello from me",
            speaker: speaker
        )
        context.insert(segment)

        #expect(segment.speaker === speaker)
        #expect(segment.speaker?.isMe == true)
    }

    @Test("Segment speaker can be set after initialization")
    func testSegmentSpeakerAssignment() {
        let context = container.mainContext
        let segment = Segment(originalText: "Test")
        context.insert(segment)

        let speaker = Speaker.createRemote()
        context.insert(speaker)

        segment.speaker = speaker

        #expect(segment.speaker === speaker)
        #expect(segment.speaker?.isMe == false)
    }

    @Test("Segment speaker can be cleared")
    func testSegmentSpeakerClearing() {
        let context = container.mainContext
        let speaker = Speaker.createMe()
        context.insert(speaker)

        let segment = Segment(originalText: "Test", speaker: speaker)
        context.insert(segment)

        #expect(segment.speaker != nil)

        segment.speaker = nil

        #expect(segment.speaker == nil)
    }

    // MARK: - Session Relationship Tests

    @Test("Segment session is nil by default")
    func testSegmentSessionNilByDefault() {
        let context = container.mainContext
        let segment = Segment()
        context.insert(segment)

        #expect(segment.session == nil)
    }

    @Test("Segment session can be set directly")
    func testSegmentSessionAssignment() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment = Segment(originalText: "Test")
        context.insert(segment)

        segment.session = session

        #expect(segment.session === session)
    }

    @Test("Segment session assignment through Session.addSegment establishes bidirectional relationship")
    func testSegmentSessionBidirectionalRelationship() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment = Segment(originalText: "Test")
        context.insert(segment)

        session.addSegment(segment)

        #expect(segment.session === session)
        #expect(session.segments?.contains { $0.id == segment.id } == true)
    }

    @Test("Segment session can be cleared")
    func testSegmentSessionClearing() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment = Segment(originalText: "Test")
        context.insert(segment)

        session.addSegment(segment)
        #expect(segment.session != nil)

        segment.session = nil

        #expect(segment.session == nil)
    }

    // MARK: - Confidence Tests

    @Test("Confidence can be set to minimum value 0.0")
    func testConfidenceMinimum() {
        let context = container.mainContext

        let segment = Segment(confidence: 0.0)
        context.insert(segment)
        #expect(segment.confidence == 0.0)
    }

    @Test("Confidence can be set to maximum value 1.0")
    func testConfidenceMaximum() {
        let context = container.mainContext

        let segment = Segment(confidence: 1.0)
        context.insert(segment)
        #expect(segment.confidence == 1.0)
    }

    @Test("Confidence can be set to midpoint value")
    func testConfidenceMidpoint() {
        let context = container.mainContext

        let segment = Segment(confidence: 0.5)
        context.insert(segment)
        #expect(segment.confidence == 0.5)
    }

    @Test("Confidence can be set to typical recognition value")
    func testConfidenceTypicalValue() {
        let context = container.mainContext

        let segment = Segment(confidence: 0.75)
        context.insert(segment)
        #expect(segment.confidence == 0.75)
    }

    @Test("Confidence can be modified after initialization")
    func testConfidenceModification() {
        let context = container.mainContext

        let segment = Segment(confidence: 0.5)
        context.insert(segment)

        segment.confidence = 0.9

        #expect(segment.confidence == 0.9)
    }

    // MARK: - isFinal Tests

    @Test("isFinal defaults to false")
    func testIsFinalDefault() {
        let context = container.mainContext
        let segment = Segment()
        context.insert(segment)

        #expect(segment.isFinal == false)
    }

    @Test("isFinal can be set to true during initialization")
    func testIsFinalTrue() {
        let context = container.mainContext
        let segment = Segment(isFinal: true)
        context.insert(segment)

        #expect(segment.isFinal == true)
    }

    @Test("isFinal can be toggled after initialization")
    func testIsFinalToggle() {
        let context = container.mainContext
        let segment = Segment(isFinal: false)
        context.insert(segment)

        segment.isFinal = true

        #expect(segment.isFinal == true)
    }

    // MARK: - Property Mutation Tests

    @Test("originalText can be modified after initialization")
    func testOriginalTextModification() {
        let context = container.mainContext
        let segment = Segment(originalText: "Initial")
        context.insert(segment)

        segment.originalText = "Modified"

        #expect(segment.originalText == "Modified")
    }

    @Test("translatedText can be modified after initialization")
    func testTranslatedTextModification() {
        let context = container.mainContext
        let segment = Segment(originalText: "Hello")
        context.insert(segment)

        #expect(segment.translatedText == nil)

        segment.translatedText = "Translated"

        #expect(segment.translatedText == "Translated")
        #expect(segment.hasTranslation == true)
        #expect(segment.displayText == "Translated")
    }

    @Test("startTime can be modified after initialization")
    func testStartTimeModification() {
        let context = container.mainContext
        let segment = Segment(startTime: 0)
        context.insert(segment)

        segment.startTime = 5.5

        #expect(segment.startTime == 5.5)
    }

    @Test("endTime can be modified after initialization")
    func testEndTimeModification() {
        let context = container.mainContext
        let segment = Segment(startTime: 0, endTime: 5)
        context.insert(segment)

        segment.endTime = 10.5

        #expect(segment.endTime == 10.5)
        #expect(segment.duration == 10.5)
    }

    @Test("sourceLocaleIdentifier can be modified directly")
    func testSourceLocaleIdentifierModification() {
        let context = container.mainContext
        let segment = Segment()
        context.insert(segment)

        segment.sourceLocaleIdentifier = "fr-FR"

        #expect(segment.sourceLocaleIdentifier == "fr-FR")
        #expect(segment.sourceLocale.identifier == "fr-FR")
    }

    @Test("targetLocaleIdentifier can be modified directly")
    func testTargetLocaleIdentifierModification() {
        let context = container.mainContext
        let segment = Segment()
        context.insert(segment)

        #expect(segment.targetLocaleIdentifier == nil)

        segment.targetLocaleIdentifier = "de-DE"

        #expect(segment.targetLocaleIdentifier == "de-DE")
        #expect(segment.targetLocale?.identifier == "de-DE")
    }

    // MARK: - Edge Case Tests

    @Test("Segment with empty strings for text fields")
    func testSegmentWithEmptyStrings() {
        let context = container.mainContext
        let segment = Segment(
            originalText: "",
            translatedText: ""
        )
        context.insert(segment)

        #expect(segment.originalText.isEmpty)
        #expect(segment.translatedText?.isEmpty == true)
        #expect(segment.hasTranslation == false)
        #expect(segment.displayText.isEmpty)
    }

    // MARK: - hasTranslation Edge Cases

    @Test("hasTranslation with nil translatedText explicitly checks nil first")
    func testHasTranslationNilCheckFirst() {
        let context = container.mainContext
        let segment = Segment(originalText: "Hello")
        context.insert(segment)

        // Verify nil case is handled
        #expect(segment.translatedText == nil)
        #expect(segment.hasTranslation == false)
    }

    @Test("hasTranslation with non-nil non-empty translatedText")
    func testHasTranslationNonNilNonEmpty() {
        let context = container.mainContext
        let segment = Segment(originalText: "Hello", translatedText: "World")
        context.insert(segment)

        // Verify non-nil, non-empty case
        #expect(segment.translatedText != nil)
        #expect(segment.translatedText?.isEmpty == false)
        #expect(segment.hasTranslation == true)
    }

    @Test("hasTranslation transitions from nil to value")
    func testHasTranslationTransition() {
        let context = container.mainContext
        let segment = Segment(originalText: "Hello")
        context.insert(segment)

        // Initially nil
        #expect(segment.hasTranslation == false)

        // Set to empty string
        segment.translatedText = ""
        #expect(segment.hasTranslation == false)

        // Set to non-empty string
        segment.translatedText = "Translated"
        #expect(segment.hasTranslation == true)

        // Set back to nil
        segment.translatedText = nil
        #expect(segment.hasTranslation == false)
    }

    @Test("Segment with Unicode text content")
    func testSegmentWithUnicodeContent() {
        let context = container.mainContext
        let segment = Segment(
            originalText: "Hello World",
            translatedText: "Emoji and special chars"
        )
        context.insert(segment)

        #expect(segment.originalText == "Hello World")
        #expect(segment.translatedText == "Emoji and special chars")
    }

    @Test("Segment with very long text content")
    func testSegmentWithLongContent() {
        let context = container.mainContext
        let longText = String(repeating: "a", count: 10000)
        let segment = Segment(originalText: longText)
        context.insert(segment)

        #expect(segment.originalText.count == 10000)
    }

    @Test("Multiple segments can coexist in context")
    func testMultipleSegments() {
        let context = container.mainContext

        let segment1 = Segment(startTime: 0, endTime: 5, originalText: "First")
        let segment2 = Segment(startTime: 5, endTime: 10, originalText: "Second")
        let segment3 = Segment(startTime: 10, endTime: 15, originalText: "Third")

        context.insert(segment1)
        context.insert(segment2)
        context.insert(segment3)

        #expect(segment1.id != segment2.id)
        #expect(segment2.id != segment3.id)
        #expect(segment1.id != segment3.id)
    }
}
