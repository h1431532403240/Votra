//
//  SRTFormatterTests.swift
//  VotraTests
//
//  Tests for SRT subtitle formatter with timestamp accuracy verification (SC-005).
//

import Foundation
import SwiftData
import Testing
@testable import Votra

@Suite("SRT Formatter Tests")
@MainActor
struct SRTFormatterTests {

    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    // MARK: - Timestamp Formatting Tests

    @Test("Format timestamp at zero")
    func timestampAtZero() {
        let result = SRTFormatter.formatTimestamp(0)
        #expect(result == "00:00:00,000")
    }

    @Test("Format timestamp with milliseconds")
    func timestampWithMilliseconds() {
        let result = SRTFormatter.formatTimestamp(1.234)
        #expect(result == "00:00:01,234")
    }

    @Test("Format timestamp with minutes")
    func timestampWithMinutes() {
        let result = SRTFormatter.formatTimestamp(65.5)
        #expect(result == "00:01:05,500")
    }

    @Test("Format timestamp with hours")
    func timestampWithHours() {
        let result = SRTFormatter.formatTimestamp(3661.123)
        #expect(result == "01:01:01,123")
    }

    @Test("Format negative timestamp clamps to zero")
    func negativeTimestamp() {
        let result = SRTFormatter.formatTimestamp(-5.0)
        #expect(result == "00:00:00,000")
    }

    @Test("Format timestamp at exact second boundary")
    func timestampAtExactSecond() {
        let result = SRTFormatter.formatTimestamp(30.0)
        #expect(result == "00:00:30,000")
    }

    // MARK: - Timestamp Parsing Tests

    @Test("Parse valid timestamp")
    func parseValidTimestamp() {
        let result = SRTFormatter.parseTimestamp("00:01:05,500")
        #expect(result != nil)
        #expect(abs((result ?? 0) - 65.5) < 0.001)
    }

    @Test("Parse timestamp with hours")
    func parseTimestampWithHours() {
        let result = SRTFormatter.parseTimestamp("01:01:01,123")
        #expect(result != nil)
        #expect(abs((result ?? 0) - 3661.123) < 0.001)
    }

    @Test("Parse invalid timestamp returns nil")
    func parseInvalidTimestamp() {
        #expect(SRTFormatter.parseTimestamp("invalid") == nil)
        #expect(SRTFormatter.parseTimestamp("00:00:00") == nil) // Missing milliseconds
        #expect(SRTFormatter.parseTimestamp("0:0:0,0") == nil) // Wrong format
    }

    // MARK: - Timestamp Accuracy Tests (SC-005: ±0.5s)

    @Test("Timestamp roundtrip accuracy within 0.5s")
    func timestampRoundtripAccuracy() {
        let testTimes: [TimeInterval] = [0, 0.5, 1.0, 30.0, 60.0, 3600.0, 7200.5]

        for originalTime in testTimes {
            let formatted = SRTFormatter.formatTimestamp(originalTime)
            let parsed = SRTFormatter.parseTimestamp(formatted)

            #expect(parsed != nil)
            let difference = abs((parsed ?? 0) - originalTime)
            #expect(difference < 0.5, "Timestamp accuracy for \(originalTime) was \(difference)s, expected < 0.5s")
        }
    }

    @Test("Millisecond precision maintained")
    func millisecondPrecision() {
        let time: TimeInterval = 123.456
        let formatted = SRTFormatter.formatTimestamp(time)
        let parsed = SRTFormatter.parseTimestamp(formatted)

        #expect(parsed != nil)
        let difference = abs((parsed ?? 0) - time)
        #expect(difference < 0.001, "Millisecond precision lost: difference was \(difference)")
    }

    // MARK: - Edge Cases

    @Test("Very short segment handling")
    func veryShortSegment() {
        // Segments < 0.5s should still be processed
        let result = SRTFormatter.formatTimestamp(0.1)
        #expect(result == "00:00:00,100")
    }

    @Test("Segment at exact second mark boundary")
    func segmentAtExactSecondMark() {
        // Test at common boundary points
        let boundaries: [TimeInterval] = [1.0, 10.0, 30.0, 60.0, 90.0, 120.0]

        for boundary in boundaries {
            let formatted = SRTFormatter.formatTimestamp(boundary)
            let parsed = SRTFormatter.parseTimestamp(formatted)
            #expect(parsed == boundary, "Boundary \(boundary) not preserved: got \(parsed ?? -1)")
        }
    }

    @Test("Large timestamp values")
    func largeTimestampValues() {
        // 10 hours
        let result = SRTFormatter.formatTimestamp(36000.0)
        #expect(result == "10:00:00,000")

        let parsed = SRTFormatter.parseTimestamp(result)
        #expect(parsed == 36000.0)
    }

    // MARK: - SRT Entry Formatting Tests

    @Test("SRT entry formatted correctly")
    func srtEntryFormatted() {
        let entry = SRTEntry(
            id: 1,
            startTime: 0,
            endTime: 2.5,
            text: "Hello world"
        )

        let formatted = entry.formatted()
        #expect(formatted.contains("1"))
        #expect(formatted.contains("00:00:00,000 --> 00:00:02,500"))
        #expect(formatted.contains("Hello world"))
    }

    @Test("SRT entry with multiline text")
    func srtEntryMultiline() {
        let entry = SRTEntry(
            id: 1,
            startTime: 0,
            endTime: 3.0,
            text: "Line one\nLine two"
        )

        let formatted = entry.formatted()
        #expect(formatted.contains("Line one\nLine two"))
    }

    @Test("SRT entry duration calculated correctly")
    func srtEntryDuration() {
        let entry = SRTEntry(
            id: 1,
            startTime: 5.0,
            endTime: 10.5,
            text: "Test"
        )

        #expect(entry.duration == 5.5)
    }

    @Test("SRT entry equality")
    func srtEntryEquality() {
        let entry1 = SRTEntry(id: 1, startTime: 0, endTime: 2.5, text: "Text")
        let entry2 = SRTEntry(id: 1, startTime: 0, endTime: 2.5, text: "Text")
        let entry3 = SRTEntry(id: 2, startTime: 0, endTime: 2.5, text: "Text")

        #expect(entry1 == entry2)
        #expect(entry1 != entry3)
    }

    // MARK: - Parse SRT Content Tests

    @Test("Parse simple SRT content")
    func parseSimpleSRT() {
        // Use explicit newlines to avoid multiline string parsing issues
        let content = "1\n00:00:00,000 --> 00:00:02,500\nHello world\n\n2\n00:00:03,000 --> 00:00:05,000\nGoodbye world"

        let entries = SRTFormatter.parse(content)
        #expect(entries.count == 2)
        #expect(entries[0].id == 1)
        #expect(entries[0].text == "Hello world")
        #expect(entries[1].id == 2)
        #expect(entries[1].text == "Goodbye world")
    }

    @Test("Parse SRT with multiline text")
    func parseSRTMultiline() {
        // Use explicit newlines
        let content = "1\n00:00:00,000 --> 00:00:02,500\nLine one\nLine two"

        let entries = SRTFormatter.parse(content)
        #expect(entries.count == 1)
        #expect(entries[0].text == "Line one\nLine two")
    }

    @Test("Parse empty SRT content")
    func parseEmptySRT() {
        let entries = SRTFormatter.parse("")
        #expect(entries.isEmpty)
    }

    @Test("Parse malformed SRT content gracefully")
    func parseMalformedSRT() {
        // Use explicit newlines
        let content = "not a number\ninvalid timestamp\nSome text"

        let entries = SRTFormatter.parse(content)
        #expect(entries.isEmpty) // Should skip invalid entries
    }

    @Test("Parse SRT with missing timestamp arrow")
    func parseSRTMissingArrow() {
        let content = "1\n00:00:00,000 00:00:02,500\nSome text"
        let entries = SRTFormatter.parse(content)
        #expect(entries.isEmpty)
    }

    @Test("Parse SRT with only two lines (missing text)")
    func parseSRTMissingText() {
        let content = "1\n00:00:00,000 --> 00:00:02,500"
        let entries = SRTFormatter.parse(content)
        #expect(entries.isEmpty)
    }

    @Test("Parse SRT with whitespace in lines")
    func parseSRTWithWhitespace() {
        let content = "1\n  00:00:00,000 --> 00:00:02,500  \n  Some text  "
        let entries = SRTFormatter.parse(content)
        #expect(entries.count == 1)
        #expect(entries[0].text == "Some text")
    }

    // MARK: - Content Option Tests

    @Test("Content option localized names exist")
    func contentOptionLocalizedNames() {
        for option in SubtitleContentOption.allCases {
            #expect(!option.localizedName.isEmpty)
        }
    }

    @Test("Content option raw values")
    func contentOptionRawValues() {
        #expect(SubtitleContentOption.originalOnly.rawValue == "original")
        #expect(SubtitleContentOption.translationOnly.rawValue == "translation")
        #expect(SubtitleContentOption.both.rawValue == "both")
    }

    @Test("Content option all cases count")
    func contentOptionAllCases() {
        #expect(SubtitleContentOption.allCases.count == 3)
    }

    // MARK: - BilingualTextOrder Tests

    @Test("Bilingual text order localized names exist")
    func bilingualTextOrderLocalizedNames() {
        for order in BilingualTextOrder.allCases {
            #expect(!order.localizedName.isEmpty)
        }
    }

    @Test("Bilingual text order raw values")
    func bilingualTextOrderRawValues() {
        #expect(BilingualTextOrder.translationFirst.rawValue == "translationFirst")
        #expect(BilingualTextOrder.originalFirst.rawValue == "originalFirst")
    }

    @Test("Bilingual text order all cases count")
    func bilingualTextOrderAllCases() {
        #expect(BilingualTextOrder.allCases.count == 2)
    }

    // MARK: - Generate from Segments Tests

    @Test("Generate SRT from empty segments array")
    func generateFromEmptySegments() {
        let segments: [Segment] = []
        let result = SRTFormatter.generate(from: segments)
        #expect(result.isEmpty)
    }

    @Test("Generate SRT from single segment with original only")
    func generateFromSingleSegmentOriginalOnly() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "Test text",
            translatedText: "Translated text"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment], contentOption: .originalOnly)
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text == "Test text")
        #expect(!entries[0].text.contains("Translated"))
    }

    @Test("Generate SRT from single segment with translation only")
    func generateFromSingleSegmentTranslationOnly() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "Test text",
            translatedText: "Translated text"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment], contentOption: .translationOnly)
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text == "Translated text")
    }

    @Test("Generate SRT from segment with translation only but nil translation")
    func generateFromSegmentWithNilTranslation() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "Test text",
            translatedText: nil
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment], contentOption: .translationOnly)
        let entries = SRTFormatter.parse(result)

        // Should fall back to original text
        #expect(entries.count == 1)
        #expect(entries[0].text == "Test text")
    }

    @Test("Generate SRT from segment with both - translation first")
    func generateFromSegmentBothTranslationFirst() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "Original",
            translatedText: "Translation"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(
            from: [segment],
            contentOption: .both,
            bilingualOrder: .translationFirst
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        // Translation should come first
        #expect(entries[0].text.hasPrefix("Translation"))
        #expect(entries[0].text.contains("Original"))
    }

    @Test("Generate SRT from segment with both - original first")
    func generateFromSegmentBothOriginalFirst() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "Original",
            translatedText: "Translation"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(
            from: [segment],
            contentOption: .both,
            bilingualOrder: .originalFirst
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        // Original should come first
        #expect(entries[0].text.hasPrefix("Original"))
        #expect(entries[0].text.contains("Translation"))
    }

    @Test("Generate SRT from segment with both but empty translation")
    func generateFromSegmentBothEmptyTranslation() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "Original text only",
            translatedText: ""
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment], contentOption: .both)
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        // Should only have original text since translation is empty
        #expect(entries[0].text == "Original text only")
    }

    @Test("Generate SRT skips segments with negative start time")
    func generateSkipsNegativeStartTime() {
        let context = container.mainContext
        let segment = Segment(
            startTime: -1.0,
            endTime: 2.5,
            originalText: "Should be skipped"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment])
        #expect(result.isEmpty)
    }

    @Test("Generate SRT skips segments with very short duration")
    func generateSkipsVeryShortDuration() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 0.05, // Less than 0.1s
            originalText: "Too short"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment])
        #expect(result.isEmpty)
    }

    @Test("Generate SRT skips segments with empty text")
    func generateSkipsEmptyText() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "   " // Whitespace only
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment])
        #expect(result.isEmpty)
    }

    @Test("Generate SRT estimates end time when invalid")
    func generateEstimatesEndTimeWhenInvalid() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 5.0,
            endTime: 3.0, // End before start - invalid
            originalText: "Test text for estimation"
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment])
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].startTime == 5.0)
        // End time should be estimated (greater than start time)
        #expect(entries[0].endTime > entries[0].startTime)
    }

    @Test("Generate SRT with multiple segments assigns sequential IDs")
    func generateWithMultipleSegmentsSequentialIDs() {
        let context = container.mainContext
        let segment1 = Segment(startTime: 0, endTime: 2.0, originalText: "First")
        let segment2 = Segment(startTime: 3.0, endTime: 5.0, originalText: "Second")
        let segment3 = Segment(startTime: 6.0, endTime: 8.0, originalText: "Third")
        context.insert(segment1)
        context.insert(segment2)
        context.insert(segment3)

        let result = SRTFormatter.generate(from: [segment1, segment2, segment3])
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 3)
        #expect(entries[0].id == 1)
        #expect(entries[1].id == 2)
        #expect(entries[2].id == 3)
    }

    @Test("Generate SRT trims whitespace from text")
    func generateTrimsWhitespace() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.5,
            originalText: "  Text with whitespace  "
        )
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment], contentOption: .originalOnly)
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text == "Text with whitespace")
    }

    // MARK: - Generate from Messages Tests

    @Test("Generate SRT from empty messages array")
    func generateFromEmptyMessages() {
        let messages: [ConversationMessage] = []
        let sessionStart = Date()
        let result = SRTFormatter.generate(from: messages, sessionStartTime: sessionStart)
        #expect(result.isEmpty)
    }

    @Test("Generate SRT from single message original only")
    func generateFromSingleMessageOriginalOnly() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "Original message",
            translatedText: "Translated message",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(1.0),
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message],
            contentOption: .originalOnly,
            sessionStartTime: sessionStart
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text == "Original message")
    }

    @Test("Generate SRT from single message translation only")
    func generateFromSingleMessageTranslationOnly() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "Original message",
            translatedText: "Translated message",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(1.0),
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message],
            contentOption: .translationOnly,
            sessionStartTime: sessionStart
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text == "Translated message")
    }

    @Test("Generate SRT from message with both - translation first")
    func generateFromMessageBothTranslationFirst() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "Original",
            translatedText: "Translation",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(1.0),
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message],
            contentOption: .both,
            sessionStartTime: sessionStart,
            bilingualOrder: .translationFirst
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text.hasPrefix("Translation"))
        #expect(entries[0].text.contains("Original"))
    }

    @Test("Generate SRT from message with both - original first")
    func generateFromMessageBothOriginalFirst() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "Original",
            translatedText: "Translation",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(1.0),
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message],
            contentOption: .both,
            sessionStartTime: sessionStart,
            bilingualOrder: .originalFirst
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].text.hasPrefix("Original"))
        #expect(entries[0].text.contains("Translation"))
    }

    @Test("Generate SRT from multiple messages calculates end times correctly")
    func generateFromMultipleMessagesEndTimes() {
        let sessionStart = Date()
        let message1 = ConversationMessage(
            originalText: "First message",
            translatedText: "Primera",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(0),
            isFinal: true
        )
        let message2 = ConversationMessage(
            originalText: "Second message",
            translatedText: "Segunda",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .systemAudio,
            timestamp: sessionStart.addingTimeInterval(5.0),
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message1, message2],
            contentOption: .originalOnly,
            sessionStartTime: sessionStart
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 2)
        // First entry should end before second starts
        #expect(entries[0].endTime < entries[1].startTime)
    }

    @Test("Generate SRT skips messages with empty text")
    func generateFromMessagesSkipsEmptyText() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "   ",
            translatedText: "   ",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(1.0),
            isFinal: true
        )

        let result = SRTFormatter.generate(from: [message], sessionStartTime: sessionStart)
        #expect(result.isEmpty)
    }

    @Test("Generate SRT from messages ensures minimum duration")
    func generateFromMessagesMinimumDuration() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "Short",
            translatedText: "Corto",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart,
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message],
            contentOption: .originalOnly,
            sessionStartTime: sessionStart
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        // Minimum duration should be at least 0.5s
        #expect(entries[0].duration >= 0.5)
    }

    @Test("Generate SRT from messages uses timestamp offsets from session start")
    func generateFromMessagesTimestampOffsets() {
        let sessionStart = Date()
        let message = ConversationMessage(
            originalText: "Test message",
            translatedText: "Mensaje de prueba",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStart.addingTimeInterval(10.5),
            isFinal: true
        )

        let result = SRTFormatter.generate(
            from: [message],
            contentOption: .originalOnly,
            sessionStartTime: sessionStart
        )
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(abs(entries[0].startTime - 10.5) < 0.001)
    }

    // MARK: - Resolve Overlaps Tests

    @Test("Overlapping segments are resolved")
    func overlappingSegmentsResolved() {
        let context = container.mainContext
        // Create overlapping segments
        let segment1 = Segment(startTime: 0, endTime: 5.0, originalText: "First")
        let segment2 = Segment(startTime: 3.0, endTime: 8.0, originalText: "Second")
        context.insert(segment1)
        context.insert(segment2)

        let result = SRTFormatter.generate(from: [segment1, segment2])
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 2)
        // First entry end time should be adjusted to not overlap with second
        #expect(entries[0].endTime < entries[1].startTime)
    }

    @Test("Non-overlapping segments are unchanged")
    func nonOverlappingSegmentsUnchanged() {
        let context = container.mainContext
        let segment1 = Segment(startTime: 0, endTime: 2.0, originalText: "First")
        let segment2 = Segment(startTime: 5.0, endTime: 7.0, originalText: "Second")
        context.insert(segment1)
        context.insert(segment2)

        let result = SRTFormatter.generate(from: [segment1, segment2])
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 2)
        #expect(entries[0].endTime == 2.0)
        #expect(entries[1].startTime == 5.0)
    }

    @Test("Single segment overlap resolution does nothing")
    func singleSegmentNoOverlapResolution() {
        let context = container.mainContext
        let segment = Segment(startTime: 0, endTime: 5.0, originalText: "Only one")
        context.insert(segment)

        let result = SRTFormatter.generate(from: [segment])
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 1)
        #expect(entries[0].endTime == 5.0)
    }

    @Test("Multiple consecutive overlaps resolved correctly")
    func multipleConsecutiveOverlaps() {
        let context = container.mainContext
        let segment1 = Segment(startTime: 0, endTime: 3.0, originalText: "A")
        let segment2 = Segment(startTime: 2.0, endTime: 5.0, originalText: "B")
        let segment3 = Segment(startTime: 4.0, endTime: 7.0, originalText: "C")
        context.insert(segment1)
        context.insert(segment2)
        context.insert(segment3)

        let result = SRTFormatter.generate(from: [segment1, segment2, segment3])
        let entries = SRTFormatter.parse(result)

        #expect(entries.count == 3)
        // Each entry's end time should be before next entry's start time
        #expect(entries[0].endTime < entries[1].startTime)
        #expect(entries[1].endTime < entries[2].startTime)
    }

    // MARK: - Split Into Lines Tests

    @Test("Split into lines trims whitespace")
    func splitIntoLinesTrimsWhitespace() {
        let text = "  Hello world  "
        let result = SRTFormatter.splitIntoLines(text)
        #expect(result == "Hello world")
    }

    @Test("Split into lines handles newlines")
    func splitIntoLinesHandlesNewlines() {
        let text = "\nLine one\nLine two\n"
        let result = SRTFormatter.splitIntoLines(text)
        #expect(result == "Line one\nLine two")
    }

    // MARK: - Format Bilingual Text Tests

    @Test("Format bilingual text creates two lines")
    func formatBilingualTextTwoLines() {
        let result = SRTFormatter.formatBilingualText(line1: "First line", line2: "Second line")
        let lines = result.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[0] == "First line")
        #expect(lines[1] == "Second line")
    }

    @Test("Format bilingual text trims whitespace")
    func formatBilingualTextTrimsWhitespace() {
        let result = SRTFormatter.formatBilingualText(line1: "  First  ", line2: "  Second  ")
        let lines = result.components(separatedBy: "\n")
        #expect(lines[0] == "First")
        #expect(lines[1] == "Second")
    }

    // MARK: - Roundtrip Tests

    @Test("SRT generation and parsing roundtrip preserves data")
    func srtRoundtripPreservesData() {
        let context = container.mainContext
        let segment1 = Segment(startTime: 0, endTime: 2.5, originalText: "First subtitle")
        let segment2 = Segment(startTime: 3.0, endTime: 5.5, originalText: "Second subtitle")
        context.insert(segment1)
        context.insert(segment2)

        let generated = SRTFormatter.generate(from: [segment1, segment2], contentOption: .originalOnly)
        let parsed = SRTFormatter.parse(generated)

        #expect(parsed.count == 2)
        #expect(parsed[0].text == "First subtitle")
        #expect(parsed[1].text == "Second subtitle")
        #expect(abs(parsed[0].startTime - 0) < 0.001)
        #expect(abs(parsed[0].endTime - 2.5) < 0.001)
        #expect(abs(parsed[1].startTime - 3.0) < 0.001)
        #expect(abs(parsed[1].endTime - 5.5) < 0.001)
    }

    @Test("SRT with bilingual text roundtrip")
    func srtBilingualRoundtrip() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 3.0,
            originalText: "Hello",
            translatedText: "Hola"
        )
        context.insert(segment)

        let generated = SRTFormatter.generate(
            from: [segment],
            contentOption: .both,
            bilingualOrder: .translationFirst
        )
        let parsed = SRTFormatter.parse(generated)

        #expect(parsed.count == 1)
        #expect(parsed[0].text.contains("Hello"))
        #expect(parsed[0].text.contains("Hola"))
    }

    // MARK: - Edge Cases Additional

    @Test("Parse SRT with extra blank lines")
    func parseSRTExtraBlankLines() {
        let content = "1\n00:00:00,000 --> 00:00:02,500\nText\n\n\n\n2\n00:00:03,000 --> 00:00:05,000\nMore text"
        let entries = SRTFormatter.parse(content)
        #expect(entries.count == 2)
    }

    @Test("Timestamp at exact minute boundary")
    func timestampExactMinuteBoundary() {
        let result = SRTFormatter.formatTimestamp(60.0)
        #expect(result == "00:01:00,000")

        let parsed = SRTFormatter.parseTimestamp(result)
        #expect(parsed == 60.0)
    }

    @Test("Timestamp at exact hour boundary")
    func timestampExactHourBoundary() {
        let result = SRTFormatter.formatTimestamp(3600.0)
        #expect(result == "01:00:00,000")

        let parsed = SRTFormatter.parseTimestamp(result)
        #expect(parsed == 3600.0)
    }

    @Test("Very long duration timestamp")
    func veryLongDurationTimestamp() {
        // 99 hours, 59 minutes, 59 seconds, 999 milliseconds
        let hours: TimeInterval = 99 * 3600
        let minutes: TimeInterval = 59 * 60
        let seconds: TimeInterval = 59
        let milliseconds: TimeInterval = 0.999
        let time: TimeInterval = hours + minutes + seconds + milliseconds
        let formatted = SRTFormatter.formatTimestamp(time)
        let parsed = SRTFormatter.parseTimestamp(formatted)

        #expect(parsed != nil)
        #expect(abs((parsed ?? 0) - time) < 0.001)
    }
}
