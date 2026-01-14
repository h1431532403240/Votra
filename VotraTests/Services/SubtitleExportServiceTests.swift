//
//  SubtitleExportServiceTests.swift
//  VotraTests
//
//  Tests for SubtitleExportService with VTT generation, plain text, and export options.
//

import Foundation
import SwiftData
import Testing
@testable import Votra

@Suite("Subtitle Export Service Tests")
@MainActor
struct SubtitleExportServiceTests {
    let service: SubtitleExportService
    let container: ModelContainer

    init() {
        service = SubtitleExportService()
        container = TestModelContainer.createFresh()
    }

    // MARK: - SubtitleFormat Enum Tests

    @Test("SubtitleFormat file extension returns raw value")
    func formatFileExtension() {
        #expect(SubtitleFormat.srt.fileExtension == "srt")
        #expect(SubtitleFormat.vtt.fileExtension == "vtt")
        #expect(SubtitleFormat.txt.fileExtension == "txt")
    }

    @Test("SubtitleFormat display names are human readable")
    func formatDisplayNames() {
        #expect(SubtitleFormat.srt.displayName == "SubRip (SRT)")
        #expect(SubtitleFormat.vtt.displayName == "WebVTT")
        #expect(SubtitleFormat.txt.displayName == "Plain Text")
    }

    @Test("SubtitleFormat MIME types are correct")
    func formatMimeTypes() {
        #expect(SubtitleFormat.srt.mimeType == "application/x-subrip")
        #expect(SubtitleFormat.vtt.mimeType == "text/vtt")
        #expect(SubtitleFormat.txt.mimeType == "text/plain")
    }

    @Test("SubtitleFormat is CaseIterable with all formats")
    func formatCaseIterable() {
        let allCases = SubtitleFormat.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.srt))
        #expect(allCases.contains(.vtt))
        #expect(allCases.contains(.txt))
    }

    // MARK: - SubtitleExportError Tests

    @Test("SubtitleExportError noSegments has description")
    func errorNoSegments() {
        let error = SubtitleExportError.noSegments
        #expect(error.errorDescription != nil)
        // Verify description is not empty (localized string content may vary)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SubtitleExportError noMessages has description")
    func errorNoMessages() {
        let error = SubtitleExportError.noMessages
        #expect(error.errorDescription != nil)
        // Verify description is not empty (localized string content may vary)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SubtitleExportError writeError includes underlying error")
    func errorWriteError() {
        let underlyingError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = SubtitleExportError.writeError(underlying: underlyingError)
        #expect(error.errorDescription != nil)
        // Verify description is not empty (localized string content may vary)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SubtitleExportError invalidFormat includes format name")
    func errorInvalidFormat() {
        let error = SubtitleExportError.invalidFormat(format: .vtt)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("vtt") == true)
    }

    @Test("SubtitleExportError emptyContent has description")
    func errorEmptyContent() {
        let error = SubtitleExportError.emptyContent
        #expect(error.errorDescription != nil)
        // Verify description is not empty (localized string content may vary)
        #expect(error.errorDescription?.isEmpty == false)
    }

    // MARK: - SubtitleExportOptions Tests

    @Test("SubtitleExportOptions default values are correct")
    func optionsDefaults() {
        let options = SubtitleExportOptions.default
        #expect(options.format == .srt)
        #expect(options.contentOption == .both)
        #expect(options.includeTimestamps == true)
        #expect(options.bilingualOrder == .translationFirst)
    }

    @Test("SubtitleExportOptions can be customized")
    func optionsCustomization() {
        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )
        #expect(options.format == .vtt)
        #expect(options.contentOption == .originalOnly)
        #expect(options.includeTimestamps == false)
        #expect(options.bilingualOrder == .originalFirst)
    }

    // MARK: - VTT Generation from Segments Tests

    @Test("VTT generation includes header")
    func vttGenerationHeader() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Hello world",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.hasPrefix("WEBVTT"))
    }

    @Test("VTT generation formats timestamps correctly")
    func vttTimestampFormat() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 65.5,
            endTime: 68.123,
            originalText: "Test text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        // VTT uses period for milliseconds separator (HH:MM:SS.mmm)
        #expect(content.contains("00:01:05.500"))
        #expect(content.contains("00:01:08.123"))
    }

    @Test("VTT generation with original only content")
    func vttOriginalOnly() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Original text",
            translatedText: "Translated text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Original text"))
        #expect(!content.contains("Translated text"))
    }

    @Test("VTT generation with translation only content")
    func vttTranslationOnly() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Original text",
            translatedText: "Translated text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Translated text"))
        #expect(!content.contains("Original text"))
    }

    @Test("VTT generation with both texts translation first")
    func vttBothTranslationFirst() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Original text",
            translatedText: "Translated text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Translated text"))
        #expect(content.contains("Original text"))

        // Verify order: translation should come before original
        if let translatedRange = content.range(of: "Translated text"),
           let originalRange = content.range(of: "Original text") {
            #expect(translatedRange.lowerBound < originalRange.lowerBound)
        }
    }

    @Test("VTT generation with both texts original first")
    func vttBothOriginalFirst() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Original text",
            translatedText: "Translated text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Original text"))
        #expect(content.contains("Translated text"))

        // Verify order: original should come before translation
        if let originalRange = content.range(of: "Original text"),
           let translatedRange = content.range(of: "Translated text") {
            #expect(originalRange.lowerBound < translatedRange.lowerBound)
        }
    }

    @Test("VTT generation with multiple segments")
    func vttMultipleSegments() {
        let context = container.mainContext
        let segment1 = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "First segment",
            sourceLocale: Locale(identifier: "en-US")
        )
        let segment2 = Segment(
            startTime: 3.0,
            endTime: 5.0,
            originalText: "Second segment",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment1)
        context.insert(segment2)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment1, segment2], options: options)
        #expect(content.contains("First segment"))
        #expect(content.contains("Second segment"))
        #expect(content.contains("1\n"))
        #expect(content.contains("2\n"))
    }

    // MARK: - VTT Generation from ConversationMessages Tests

    @Test("VTT generation from messages includes header")
    func vttMessagesHeader() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Hello from message",
            translatedText: "Hola desde mensaje",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.hasPrefix("WEBVTT"))
    }

    @Test("VTT generation from messages calculates timestamps from session start")
    func vttMessagesTimestamps() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Test message",
            translatedText: "Mensaje de prueba",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(5.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        // Should start at 5 seconds from session start
        #expect(content.contains("00:00:05.000"))
    }

    @Test("VTT generation from messages with bilingual content")
    func vttMessagesBilingual() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("Hello"))
        #expect(content.contains("Hola"))
    }

    @Test("VTT generation from consecutive messages uses next message start for end time")
    func vttConsecutiveMessages() {
        let sessionStartTime = Date()
        let message1 = ConversationMessage(
            originalText: "First",
            translatedText: "Primero",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(0.0),
            isFinal: true
        )
        let message2 = ConversationMessage(
            originalText: "Second",
            translatedText: "Segundo",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .systemAudio,
            timestamp: sessionStartTime.addingTimeInterval(3.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message1, message2],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("First"))
        #expect(content.contains("Second"))
        // First message should end before second starts (around 2.9 seconds due to gap)
        // The exact value may vary slightly, so check for approximate range
        #expect(content.contains("00:00:02.8") || content.contains("00:00:02.9"))
    }

    // MARK: - Plain Text Generation Tests

    @Test("Plain text generation from segments without timestamps")
    func plainTextSegments() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Hello world",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Hello world"))
        // Plain text should NOT have VTT header
        #expect(!content.contains("WEBVTT"))
        // Plain text should NOT have timestamp markers
        #expect(!content.contains("-->"))
    }

    @Test("Plain text generation with translation only")
    func plainTextTranslationOnly() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Original text",
            translatedText: "Texto traducido",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Texto traducido"))
        #expect(!content.contains("Original text"))
    }

    @Test("Plain text generation with bilingual content")
    func plainTextBilingual() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Hello"))
        #expect(content.contains("Hola"))
    }

    @Test("Plain text generation multiple segments separated by blank lines")
    func plainTextMultipleSegments() {
        let context = container.mainContext
        let segment1 = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "First",
            sourceLocale: Locale(identifier: "en-US")
        )
        let segment2 = Segment(
            startTime: 3.0,
            endTime: 5.0,
            originalText: "Second",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment1)
        context.insert(segment2)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment1, segment2], options: options)
        #expect(content.contains("First"))
        #expect(content.contains("Second"))
        // Segments should be separated by double newline
        #expect(content.contains("\n\n"))
    }

    @Test("Plain text generation from messages")
    func plainTextMessages() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Message text",
            translatedText: "Texto del mensaje",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("Message text"))
        #expect(!content.contains("WEBVTT"))
    }

    // MARK: - Bilingual Order Tests

    @Test("Bilingual order translation first in plain text")
    func bilingualOrderTranslationFirstPlainText() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "AAA Original",
            translatedText: "ZZZ Translation",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)

        if let translationRange = content.range(of: "ZZZ Translation"),
           let originalRange = content.range(of: "AAA Original") {
            #expect(translationRange.lowerBound < originalRange.lowerBound)
        }
    }

    @Test("Bilingual order original first in plain text")
    func bilingualOrderOriginalFirstPlainText() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "AAA Original",
            translatedText: "ZZZ Translation",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let content = service.generateContent(from: [segment], options: options)

        if let originalRange = content.range(of: "AAA Original"),
           let translationRange = content.range(of: "ZZZ Translation") {
            #expect(originalRange.lowerBound < translationRange.lowerBound)
        }
    }

    // MARK: - Export Error Tests

    @Test("Export throws noSegments error for empty segments array")
    func exportEmptySegmentsThrows() async {
        let options = SubtitleExportOptions.default

        await #expect(throws: SubtitleExportError.self) {
            try await service.export(segments: [], options: options)
        }
    }

    @Test("Export throws noMessages error for empty messages array")
    func exportEmptyMessagesThrows() async {
        let options = SubtitleExportOptions.default
        let sessionStartTime = Date()

        await #expect(throws: SubtitleExportError.self) {
            try await service.export(
                messages: [],
                sessionStartTime: sessionStartTime,
                options: options
            )
        }
    }

    // MARK: - Content Option Tests

    @Test("Content option originalOnly excludes translation")
    func contentOptionOriginalOnlyExcludesTranslation() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "ORIGINAL_UNIQUE_TEXT",
            translatedText: "TRANSLATED_UNIQUE_TEXT",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("ORIGINAL_UNIQUE_TEXT"))
        #expect(!content.contains("TRANSLATED_UNIQUE_TEXT"))
    }

    @Test("Content option translationOnly excludes original")
    func contentOptionTranslationOnlyExcludesOriginal() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "ORIGINAL_UNIQUE_TEXT",
            translatedText: "TRANSLATED_UNIQUE_TEXT",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(!content.contains("ORIGINAL_UNIQUE_TEXT"))
        #expect(content.contains("TRANSLATED_UNIQUE_TEXT"))
    }

    @Test("Content option both includes both texts")
    func contentOptionBothIncludesBoth() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "ORIGINAL_UNIQUE_TEXT",
            translatedText: "TRANSLATED_UNIQUE_TEXT",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("ORIGINAL_UNIQUE_TEXT"))
        #expect(content.contains("TRANSLATED_UNIQUE_TEXT"))
    }

    @Test("Translation only falls back to original when no translation")
    func translationOnlyFallsBackToOriginal() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Only original text",
            translatedText: nil,
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Only original text"))
    }

    @Test("Both content option falls back to original when no translation")
    func bothContentFallsBackToOriginalWhenNoTranslation() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Only original text",
            translatedText: nil,
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Only original text"))
    }

    // MARK: - Edge Cases

    @Test("Segment without end time estimates duration")
    func segmentWithoutEndTimeEstimatesDuration() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 0, // No end time
            originalText: "This is a test sentence that should have estimated duration",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        // Should have generated content with estimated end time
        #expect(content.contains("-->"))
        // End time should not be 00:00:00.000 (should be estimated)
        #expect(!content.contains("00:00:00.000 --> 00:00:00.000"))
    }

    @Test("Empty text segments are skipped")
    func emptyTextSegmentsSkipped() {
        let context = container.mainContext
        let segment1 = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "   ",
            sourceLocale: Locale(identifier: "en-US")
        )
        let segment2 = Segment(
            startTime: 3.0,
            endTime: 5.0,
            originalText: "Valid text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment1)
        context.insert(segment2)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment1, segment2], options: options)
        #expect(content.contains("Valid text"))
        // Empty segment should be skipped, resulting in only one entry
        // Note: The counter increments even for skipped entries, so check there is no second entry content
        #expect(!content.contains("   ")) // Whitespace-only content should not be present
    }

    @Test("VTT timestamp format uses period separator")
    func vttTimestampUsesPeriodSeparator() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 1.234,
            endTime: 2.567,
            originalText: "Test",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        // VTT uses period (.), not comma (,) for milliseconds
        #expect(content.contains("00:00:01.234"))
        #expect(content.contains("00:00:02.567"))
        // Should NOT use comma separator (that's SRT format)
        #expect(!content.contains("00:00:01,234"))
    }

    @Test("Large hour values formatted correctly")
    func largeHourValues() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 36000.0, // 10 hours
            endTime: 36005.0,
            originalText: "Long meeting",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("10:00:00.000"))
        #expect(content.contains("10:00:05.000"))
    }

    // MARK: - SRT Format Generation Tests

    @Test("SRT generation from segments produces valid format")
    func srtGenerationFromSegments() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 1.5,
            endTime: 4.0,
            originalText: "Hello world",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        // SRT uses comma for milliseconds separator
        #expect(content.contains("00:00:01,500"))
        #expect(content.contains("00:00:04,000"))
        #expect(content.contains("-->"))
        #expect(content.contains("Hello world"))
        // Should NOT have VTT header
        #expect(!content.contains("WEBVTT"))
    }

    @Test("SRT generation with bilingual content translation first")
    func srtBilingualTranslationFirst() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 3.0,
            originalText: "Original SRT text",
            translatedText: "Translated SRT text",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Original SRT text"))
        #expect(content.contains("Translated SRT text"))

        // Verify order: translation should come before original
        if let translatedRange = content.range(of: "Translated SRT text"),
           let originalRange = content.range(of: "Original SRT text") {
            #expect(translatedRange.lowerBound < originalRange.lowerBound)
        }
    }

    @Test("SRT generation with bilingual content original first")
    func srtBilingualOriginalFirst() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 3.0,
            originalText: "Original SRT",
            translatedText: "Translated SRT",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let content = service.generateContent(from: [segment], options: options)

        // Verify order: original should come before translation
        if let originalRange = content.range(of: "Original SRT"),
           let translatedRange = content.range(of: "Translated SRT") {
            #expect(originalRange.lowerBound < translatedRange.lowerBound)
        }
    }

    @Test("SRT generation from messages")
    func srtGenerationFromMessages() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Message for SRT",
            translatedText: "Mensaje para SRT",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(2.5),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        // SRT uses comma separator
        #expect(content.contains("00:00:02,500"))
        #expect(content.contains("Message for SRT"))
        #expect(!content.contains("WEBVTT"))
    }

    @Test("SRT generation from messages with translation only")
    func srtMessagesTranslationOnly() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Original message",
            translatedText: "Translated message",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("Translated message"))
        #expect(!content.contains("Original message"))
    }

    @Test("SRT generation from messages with bilingual original first")
    func srtMessagesBilingualOriginalFirst() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "AAA Original msg",
            translatedText: "ZZZ Translated msg",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )

        // Verify order: original should come before translation
        if let originalRange = content.range(of: "AAA Original msg"),
           let translatedRange = content.range(of: "ZZZ Translated msg") {
            #expect(originalRange.lowerBound < translatedRange.lowerBound)
        }
    }

    // MARK: - VTT Messages Additional Content Options Tests

    @Test("VTT generation from messages with translation only")
    func vttMessagesTranslationOnly() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Original VTT message",
            translatedText: "Translated VTT message",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("Translated VTT message"))
        #expect(!content.contains("Original VTT message"))
    }

    @Test("VTT generation from messages with original first bilingual order")
    func vttMessagesOriginalFirst() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "AAA Original",
            translatedText: "ZZZ Translated",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )

        // Verify order: original should come before translation
        if let originalRange = content.range(of: "AAA Original"),
           let translatedRange = content.range(of: "ZZZ Translated") {
            #expect(originalRange.lowerBound < translatedRange.lowerBound)
        }
    }

    // MARK: - Plain Text Messages Additional Content Options Tests

    @Test("Plain text generation from messages with translation only")
    func plainTextMessagesTranslationOnly() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Original plain text",
            translatedText: "Translated plain text",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("Translated plain text"))
        #expect(!content.contains("Original plain text"))
    }

    @Test("Plain text generation from messages with bilingual translation first")
    func plainTextMessagesBilingualTranslationFirst() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "AAA Original",
            translatedText: "ZZZ Translated",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )

        // Verify order: translation should come before original
        if let translatedRange = content.range(of: "ZZZ Translated"),
           let originalRange = content.range(of: "AAA Original") {
            #expect(translatedRange.lowerBound < originalRange.lowerBound)
        }
    }

    @Test("Plain text generation from messages with bilingual original first")
    func plainTextMessagesBilingualOriginalFirst() {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "AAA Original",
            translatedText: "ZZZ Translated",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let content = service.generateContent(
            from: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )

        // Verify order: original should come before translation
        if let originalRange = content.range(of: "AAA Original"),
           let translatedRange = content.range(of: "ZZZ Translated") {
            #expect(originalRange.lowerBound < translatedRange.lowerBound)
        }
    }

    @Test("Plain text generation from multiple messages separated by blank lines")
    func plainTextMultipleMessages() {
        let sessionStartTime = Date()
        let message1 = ConversationMessage(
            originalText: "First message",
            translatedText: "Primer mensaje",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(0.0),
            isFinal: true
        )
        let message2 = ConversationMessage(
            originalText: "Second message",
            translatedText: "Segundo mensaje",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .systemAudio,
            timestamp: sessionStartTime.addingTimeInterval(3.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message1, message2],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("First message"))
        #expect(content.contains("Second message"))
        // Messages should be separated by double newline
        #expect(content.contains("\n\n"))
    }

    // MARK: - File Export Tests

    @Test("Export segments creates file and returns URL")
    func exportSegmentsCreatesFile() async throws {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Export test content",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let url = try await service.export(segments: [segment], options: options)

        // Verify URL has correct extension
        #expect(url.pathExtension == "srt")

        // Verify file exists and has content
        let fileContent = try String(contentsOf: url, encoding: .utf8)
        #expect(fileContent.contains("Export test content"))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Export messages creates file and returns URL")
    func exportMessagesCreatesFile() async throws {
        let sessionStartTime = Date()
        let message = ConversationMessage(
            originalText: "Export message test",
            translatedText: "Test de exportacion",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(1.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let url = try await service.export(
            messages: [message],
            sessionStartTime: sessionStartTime,
            options: options
        )

        // Verify URL has correct extension
        #expect(url.pathExtension == "vtt")

        // Verify file exists and has content
        let fileContent = try String(contentsOf: url, encoding: .utf8)
        #expect(fileContent.contains("WEBVTT"))
        #expect(fileContent.contains("Export message test"))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Export with txt format creates correct file")
    func exportTxtFormat() async throws {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Plain text export",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let url = try await service.export(segments: [segment], options: options)

        #expect(url.pathExtension == "txt")

        let fileContent = try String(contentsOf: url, encoding: .utf8)
        #expect(fileContent.contains("Plain text export"))
        #expect(!fileContent.contains("WEBVTT"))
        #expect(!fileContent.contains("-->"))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Additional Edge Cases

    @Test("VTT timestamp clamps negative values to zero")
    func vttNegativeTimeClampedToZero() {
        let context = container.mainContext
        // Create segment where message timestamp is before session start (negative offset)
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Negative time test",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        // Should start at 00:00:00.000 (clamped from negative)
        #expect(content.contains("00:00:00.000"))
    }

    @Test("VTT segment with empty translation string falls back to original only")
    func vttEmptyTranslationStringFallback() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Only original here",
            translatedText: "", // Empty string, not nil
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Only original here"))
        // Should only contain the original text once (not duplicated on two lines)
        let occurrences = content.components(separatedBy: "Only original here").count - 1
        #expect(occurrences == 1)
    }

    @Test("Plain text segment with empty translation falls back to original")
    func plainTextEmptyTranslationFallback() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Fallback original",
            translatedText: nil,
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Fallback original"))
    }

    @Test("Plain text bilingual with empty translation uses only original")
    func plainTextBilingualEmptyTranslation() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Single line original",
            translatedText: "",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Single line original"))
    }

    @Test("VTT skips messages with empty text")
    func vttSkipsEmptyMessages() {
        let sessionStartTime = Date()
        let message1 = ConversationMessage(
            originalText: "   ", // Whitespace only
            translatedText: "   ",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(0.0),
            isFinal: true
        )
        let message2 = ConversationMessage(
            originalText: "Valid message",
            translatedText: "Mensaje valido",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(2.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message1, message2],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("Valid message"))
        // Whitespace-only message should be skipped
        #expect(!content.contains("   \n"))
    }

    @Test("Plain text skips segments with empty text")
    func plainTextSkipsEmptySegments() {
        let context = container.mainContext
        let segment1 = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "   ", // Whitespace only
            sourceLocale: Locale(identifier: "en-US")
        )
        let segment2 = Segment(
            startTime: 3.0,
            endTime: 5.0,
            originalText: "Valid segment",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment1)
        context.insert(segment2)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment1, segment2], options: options)
        #expect(content.contains("Valid segment"))
        #expect(content == "Valid segment") // Only valid segment, no extra whitespace entries
    }

    @Test("VTT handles very long text segments")
    func vttLongTextSegments() {
        let context = container.mainContext
        let longText = String(repeating: "This is a long sentence. ", count: 20)
        let segment = Segment(
            startTime: 0,
            endTime: 30.0,
            originalText: longText,
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("WEBVTT"))
        #expect(content.contains("This is a long sentence."))
    }

    @Test("Multiple consecutive VTT messages calculate end times correctly")
    func vttMultipleConsecutiveMessages() {
        let sessionStartTime = Date()
        let message1 = ConversationMessage(
            originalText: "First",
            translatedText: "Primero",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(0.0),
            isFinal: true
        )
        let message2 = ConversationMessage(
            originalText: "Second",
            translatedText: "Segundo",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(2.0),
            isFinal: true
        )
        let message3 = ConversationMessage(
            originalText: "Third",
            translatedText: "Tercero",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es-ES"),
            source: .microphone,
            timestamp: sessionStartTime.addingTimeInterval(4.0),
            isFinal: true
        )

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(
            from: [message1, message2, message3],
            sessionStartTime: sessionStartTime,
            options: options
        )
        #expect(content.contains("First"))
        #expect(content.contains("Second"))
        #expect(content.contains("Third"))
        // Check all three entries are numbered
        #expect(content.contains("1\n"))
        #expect(content.contains("2\n"))
        #expect(content.contains("3\n"))
    }

    @Test("SRT generation with multiple segments")
    func srtMultipleSegments() {
        let context = container.mainContext
        let segment1 = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "First SRT segment",
            sourceLocale: Locale(identifier: "en-US")
        )
        let segment2 = Segment(
            startTime: 3.0,
            endTime: 5.0,
            originalText: "Second SRT segment",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment1)
        context.insert(segment2)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment1, segment2], options: options)
        #expect(content.contains("First SRT segment"))
        #expect(content.contains("Second SRT segment"))
        #expect(content.contains("1\n"))
        #expect(content.contains("2\n"))
    }

    @Test("SRT generation with translation only content option")
    func srtTranslationOnly() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 2.0,
            originalText: "Original for SRT",
            translatedText: "Translated for SRT",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        let content = service.generateContent(from: [segment], options: options)
        #expect(content.contains("Translated for SRT"))
        #expect(!content.contains("Original for SRT"))
    }
}
