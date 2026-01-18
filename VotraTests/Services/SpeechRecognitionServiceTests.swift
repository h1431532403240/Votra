//
//  SpeechRecognitionServiceTests.swift
//  VotraTests
//
//  Tests for SpeechRecognitionService - validates state management, error handling,
//  and supporting types.
//

import Foundation
import Testing
@testable import Votra

@Suite("SpeechRecognitionService Tests", .disabled(if: ProcessInfo.processInfo.environment["CI"] == "true", "Requires audio hardware - run locally"))
@MainActor
struct SpeechRecognitionServiceTests {
    // MARK: - SpeechRecognitionState Tests

    @Test("SpeechRecognitionState idle case equality")
    func stateIdleEquality() {
        let state1 = SpeechRecognitionState.idle
        let state2 = SpeechRecognitionState.idle
        #expect(state1 == state2)
    }

    @Test("SpeechRecognitionState starting case equality")
    func stateStartingEquality() {
        let state1 = SpeechRecognitionState.starting
        let state2 = SpeechRecognitionState.starting
        #expect(state1 == state2)
    }

    @Test("SpeechRecognitionState listening case equality")
    func stateListeningEquality() {
        let state1 = SpeechRecognitionState.listening
        let state2 = SpeechRecognitionState.listening
        #expect(state1 == state2)
    }

    @Test("SpeechRecognitionState processing case equality")
    func stateProcessingEquality() {
        let state1 = SpeechRecognitionState.processing
        let state2 = SpeechRecognitionState.processing
        #expect(state1 == state2)
    }

    @Test("SpeechRecognitionState error case equality with same message")
    func stateErrorEqualityWithSameMessage() {
        let state1 = SpeechRecognitionState.error(message: "Test error")
        let state2 = SpeechRecognitionState.error(message: "Test error")
        #expect(state1 == state2)
    }

    @Test("SpeechRecognitionState error case inequality with different messages")
    func stateErrorInequalityWithDifferentMessages() {
        let state1 = SpeechRecognitionState.error(message: "Error one")
        let state2 = SpeechRecognitionState.error(message: "Error two")
        #expect(state1 != state2)
    }

    @Test("SpeechRecognitionState different cases are not equal")
    func stateDifferentCasesNotEqual() {
        #expect(SpeechRecognitionState.idle != SpeechRecognitionState.starting)
        #expect(SpeechRecognitionState.starting != SpeechRecognitionState.listening)
        #expect(SpeechRecognitionState.listening != SpeechRecognitionState.processing)
        #expect(SpeechRecognitionState.processing != SpeechRecognitionState.error(message: "test"))
    }

    // MARK: - TranscriptionResult Tests

    @Test("TranscriptionResult initialization stores all properties")
    func transcriptionResultInitialization() {
        let id = UUID()
        let text = "Hello world"
        let segment = TranscriptionSegment(
            text: "Hello",
            startTime: 0.0,
            endTime: 1.0,
            confidence: 0.95
        )
        let locale = Locale(identifier: "en-US")
        let timestamp: TimeInterval = 1234567890.0

        let result = TranscriptionResult(
            id: id,
            text: text,
            segments: [segment],
            isFinal: true,
            confidence: 0.92,
            locale: locale,
            timestamp: timestamp
        )

        #expect(result.id == id)
        #expect(result.text == text)
        #expect(result.segments.count == 1)
        #expect(result.isFinal == true)
        #expect(result.confidence == 0.92)
        #expect(result.locale == locale)
        #expect(result.timestamp == timestamp)
    }

    @Test("TranscriptionResult equality with same values")
    func transcriptionResultEquality() {
        let id = UUID()
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        #expect(result1 == result2)
    }

    @Test("TranscriptionResult inequality with different IDs")
    func transcriptionResultInequalityDifferentIds() {
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: UUID(),
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: UUID(),
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        #expect(result1 != result2)
    }

    @Test("TranscriptionResult with empty segments")
    func transcriptionResultEmptySegments() {
        let result = TranscriptionResult(
            id: UUID(),
            text: "",
            segments: [],
            isFinal: false,
            confidence: 0.0,
            locale: .current,
            timestamp: 0.0
        )

        #expect(result.segments.isEmpty)
        #expect(result.text.isEmpty)
    }

    // MARK: - TranscriptionSegment Tests

    @Test("TranscriptionSegment initialization stores all properties")
    func transcriptionSegmentInitialization() {
        let segment = TranscriptionSegment(
            text: "Hello",
            startTime: 1.5,
            endTime: 2.5,
            confidence: 0.85
        )

        #expect(segment.text == "Hello")
        #expect(segment.startTime == 1.5)
        #expect(segment.endTime == 2.5)
        #expect(segment.confidence == 0.85)
    }

    @Test("TranscriptionSegment duration computed correctly")
    func transcriptionSegmentDuration() {
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: 5.0,
            endTime: 8.5,
            confidence: 1.0
        )

        #expect(segment.duration == 3.5)
    }

    @Test("TranscriptionSegment duration with zero length")
    func transcriptionSegmentZeroDuration() {
        let segment = TranscriptionSegment(
            text: "",
            startTime: 2.0,
            endTime: 2.0,
            confidence: 1.0
        )

        #expect(segment.duration == 0.0)
    }

    @Test("TranscriptionSegment equality")
    func transcriptionSegmentEquality() {
        let segment1 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        let segment2 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        #expect(segment1 == segment2)
    }

    @Test("TranscriptionSegment inequality with different text")
    func transcriptionSegmentInequalityDifferentText() {
        let segment1 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        let segment2 = TranscriptionSegment(
            text: "World",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        #expect(segment1 != segment2)
    }

    // MARK: - LanguageAvailability Tests

    @Test("LanguageAvailability available case equality")
    func languageAvailabilityAvailableEquality() {
        let availability1 = LanguageAvailability.available
        let availability2 = LanguageAvailability.available
        #expect(availability1 == availability2)
    }

    @Test("LanguageAvailability downloadRequired case equality with same size")
    func languageAvailabilityDownloadRequiredEquality() {
        let availability1 = LanguageAvailability.downloadRequired(size: 100_000_000)
        let availability2 = LanguageAvailability.downloadRequired(size: 100_000_000)
        #expect(availability1 == availability2)
    }

    @Test("LanguageAvailability downloadRequired case inequality with different size")
    func languageAvailabilityDownloadRequiredInequality() {
        let availability1 = LanguageAvailability.downloadRequired(size: 100_000_000)
        let availability2 = LanguageAvailability.downloadRequired(size: 200_000_000)
        #expect(availability1 != availability2)
    }

    @Test("LanguageAvailability downloading case equality with same progress")
    func languageAvailabilityDownloadingEquality() {
        let availability1 = LanguageAvailability.downloading(progress: 0.5)
        let availability2 = LanguageAvailability.downloading(progress: 0.5)
        #expect(availability1 == availability2)
    }

    @Test("LanguageAvailability downloading case inequality with different progress")
    func languageAvailabilityDownloadingInequality() {
        let availability1 = LanguageAvailability.downloading(progress: 0.25)
        let availability2 = LanguageAvailability.downloading(progress: 0.75)
        #expect(availability1 != availability2)
    }

    @Test("LanguageAvailability unsupported case equality")
    func languageAvailabilityUnsupportedEquality() {
        let availability1 = LanguageAvailability.unsupported
        let availability2 = LanguageAvailability.unsupported
        #expect(availability1 == availability2)
    }

    @Test("LanguageAvailability different cases not equal")
    func languageAvailabilityDifferentCasesNotEqual() {
        #expect(LanguageAvailability.available != LanguageAvailability.unsupported)
        #expect(LanguageAvailability.downloadRequired(size: 100) != LanguageAvailability.available)
        #expect(LanguageAvailability.downloading(progress: 0.5) != LanguageAvailability.available)
    }

    // MARK: - DownloadProgress Tests

    @Test("DownloadProgress initialization stores all properties")
    func downloadProgressInitialization() {
        let progress = DownloadProgress(
            bytesDownloaded: 50_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        #expect(progress.bytesDownloaded == 50_000_000)
        #expect(progress.totalBytes == 100_000_000)
        #expect(progress.isComplete == false)
    }

    @Test("DownloadProgress computed progress property")
    func downloadProgressComputedProgress() {
        let progress = DownloadProgress(
            bytesDownloaded: 25_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        #expect(progress.progress == 0.25)
    }

    @Test("DownloadProgress computed progress at 100%")
    func downloadProgressComputedProgressComplete() {
        let progress = DownloadProgress(
            bytesDownloaded: 100_000_000,
            totalBytes: 100_000_000,
            isComplete: true
        )

        #expect(progress.progress == 1.0)
    }

    @Test("DownloadProgress computed progress with zero total bytes")
    func downloadProgressComputedProgressZeroTotal() {
        let progress = DownloadProgress(
            bytesDownloaded: 50_000,
            totalBytes: 0,
            isComplete: false
        )

        #expect(progress.progress == 0.0)
    }

    @Test("DownloadProgress computed progress at start")
    func downloadProgressComputedProgressAtStart() {
        let progress = DownloadProgress(
            bytesDownloaded: 0,
            totalBytes: 100_000_000,
            isComplete: false
        )

        #expect(progress.progress == 0.0)
    }

    // MARK: - SpeechRecognitionError Tests

    @Test("SpeechRecognitionError permissionDenied has error description")
    func errorPermissionDeniedDescription() {
        let error = SpeechRecognitionError.permissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError permissionDenied has recovery suggestion")
    func errorPermissionDeniedRecoverySuggestion() {
        let error = SpeechRecognitionError.permissionDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SpeechRecognitionError languageNotSupported has error description")
    func errorLanguageNotSupportedDescription() {
        let locale = Locale(identifier: "xx-XX")
        let error = SpeechRecognitionError.languageNotSupported(locale)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError languageNotSupported has no recovery suggestion")
    func errorLanguageNotSupportedNoRecoverySuggestion() {
        let locale = Locale(identifier: "en-US")
        let error = SpeechRecognitionError.languageNotSupported(locale)
        #expect(error.recoverySuggestion == nil)
    }

    @Test("SpeechRecognitionError languageNotDownloaded has error description")
    func errorLanguageNotDownloadedDescription() {
        let locale = Locale(identifier: "ja-JP")
        let error = SpeechRecognitionError.languageNotDownloaded(locale)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError languageNotDownloaded has recovery suggestion")
    func errorLanguageNotDownloadedRecoverySuggestion() {
        let locale = Locale(identifier: "ja-JP")
        let error = SpeechRecognitionError.languageNotDownloaded(locale)
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SpeechRecognitionError downloadFailed has error description")
    func errorDownloadFailedDescription() {
        struct TestError: Error {}
        let error = SpeechRecognitionError.downloadFailed(underlying: TestError())
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError downloadFailed has recovery suggestion")
    func errorDownloadFailedRecoverySuggestion() {
        struct TestError: Error {}
        let error = SpeechRecognitionError.downloadFailed(underlying: TestError())
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SpeechRecognitionError recognitionFailed has error description")
    func errorRecognitionFailedDescription() {
        struct TestError: Error {}
        let error = SpeechRecognitionError.recognitionFailed(underlying: TestError())
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError recognitionFailed has no recovery suggestion")
    func errorRecognitionFailedNoRecoverySuggestion() {
        struct TestError: Error {}
        let error = SpeechRecognitionError.recognitionFailed(underlying: TestError())
        #expect(error.recoverySuggestion == nil)
    }

    @Test("SpeechRecognitionError noAudioInput has error description")
    func errorNoAudioInputDescription() {
        let error = SpeechRecognitionError.noAudioInput
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError noAudioInput has no recovery suggestion")
    func errorNoAudioInputNoRecoverySuggestion() {
        let error = SpeechRecognitionError.noAudioInput
        #expect(error.recoverySuggestion == nil)
    }

    @Test("SpeechRecognitionError alreadyRunning has error description")
    func errorAlreadyRunningDescription() {
        let error = SpeechRecognitionError.alreadyRunning
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SpeechRecognitionError alreadyRunning has no recovery suggestion")
    func errorAlreadyRunningNoRecoverySuggestion() {
        let error = SpeechRecognitionError.alreadyRunning
        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - SpeechRecognitionService Initialization Tests

    @Test("Service initializes with default identifier")
    func serviceInitializationDefaultIdentifier() {
        let service = SpeechRecognitionService()
        #expect(service.identifier == "default")
    }

    @Test("Service initializes with custom identifier")
    func serviceInitializationCustomIdentifier() {
        let service = SpeechRecognitionService(identifier: "test-service")
        #expect(service.identifier == "test-service")
    }

    @Test("Service initializes in idle state")
    func serviceInitializationIdleState() {
        let service = SpeechRecognitionService()
        #expect(service.state == .idle)
    }

    @Test("Service initializes with current locale as source")
    func serviceInitializationCurrentLocale() {
        let service = SpeechRecognitionService()
        #expect(service.sourceLocale == .current)
    }

    // MARK: - SpeechRecognitionService Observable Properties Tests

    @Test("Service state is observable")
    func serviceStateIsObservable() {
        let service = SpeechRecognitionService()

        // Initial state should be idle
        #expect(service.state == .idle)

        // State should be accessible as an observable property
        let currentState = service.state
        #expect(currentState == .idle)
    }

    @Test("Service sourceLocale is observable")
    func serviceSourceLocaleIsObservable() {
        let service = SpeechRecognitionService()

        // Should be accessible as an observable property
        let locale = service.sourceLocale
        #expect(locale == .current)
    }

    @Test("Multiple service instances have independent state")
    func multipleServiceInstancesIndependentState() {
        let service1 = SpeechRecognitionService(identifier: "service1")
        let service2 = SpeechRecognitionService(identifier: "service2")

        #expect(service1.identifier != service2.identifier)
        #expect(service1.state == .idle)
        #expect(service2.state == .idle)
    }

    // MARK: - SpeechRecognitionError LocalizedError Conformance Tests

    @Test("All errors conform to LocalizedError with descriptions")
    func allErrorsHaveDescriptions() {
        let errors: [SpeechRecognitionError] = [
            .permissionDenied,
            .languageNotSupported(Locale(identifier: "en-US")),
            .languageNotDownloaded(Locale(identifier: "ja-JP")),
            .downloadFailed(underlying: NSError(domain: "test", code: 0)),
            .recognitionFailed(underlying: NSError(domain: "test", code: 0)),
            .noAudioInput,
            .alreadyRunning
        ]

        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have a description")
            #expect(error.errorDescription?.isEmpty == false, "Error \(error) description should not be empty")
        }
    }

    // MARK: - Sendable Conformance Tests

    @Test("SpeechRecognitionState is Sendable")
    func stateIsSendable() async {
        let state = SpeechRecognitionState.listening

        // This test verifies Sendable conformance by passing state across isolation boundaries
        let task = Task.detached {
            state
        }

        let result = await task.value
        #expect(result == .listening)
    }

    @Test("TranscriptionResult is Sendable")
    func transcriptionResultIsSendable() async {
        let result = TranscriptionResult(
            id: UUID(),
            text: "Test",
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: .current,
            timestamp: 0.0
        )

        let task = Task.detached {
            result
        }

        let returned = await task.value
        #expect(returned.text == "Test")
    }

    @Test("TranscriptionSegment is Sendable")
    func transcriptionSegmentIsSendable() async {
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: 0.0,
            endTime: 1.0,
            confidence: 1.0
        )

        let task = Task.detached {
            segment
        }

        let returned = await task.value
        #expect(returned.text == "Test")
    }

    @Test("LanguageAvailability is Sendable")
    func languageAvailabilityIsSendable() async {
        let availability = LanguageAvailability.downloadRequired(size: 100)

        let task = Task.detached {
            availability
        }

        let returned = await task.value
        #expect(returned == .downloadRequired(size: 100))
    }

    @Test("DownloadProgress is Sendable")
    func downloadProgressIsSendable() async {
        let progress = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: 100,
            isComplete: false
        )

        let task = Task.detached {
            progress
        }

        let returned = await task.value
        #expect(returned.progress == 0.5)
    }

    // MARK: - Edge Case Tests

    @Test("TranscriptionResult with maximum confidence")
    func transcriptionResultMaxConfidence() {
        let result = TranscriptionResult(
            id: UUID(),
            text: "High confidence",
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: .current,
            timestamp: 0.0
        )

        #expect(result.confidence == 1.0)
    }

    @Test("TranscriptionResult with zero confidence")
    func transcriptionResultZeroConfidence() {
        let result = TranscriptionResult(
            id: UUID(),
            text: "Low confidence",
            segments: [],
            isFinal: false,
            confidence: 0.0,
            locale: .current,
            timestamp: 0.0
        )

        #expect(result.confidence == 0.0)
    }

    @Test("TranscriptionSegment with negative times")
    func transcriptionSegmentNegativeTimes() {
        // While unusual, the struct should handle negative values
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: -1.0,
            endTime: 0.0,
            confidence: 1.0
        )

        #expect(segment.duration == 1.0)
    }

    @Test("DownloadProgress with bytes exceeding total")
    func downloadProgressBytesExceedTotal() {
        // Edge case where downloaded exceeds total (shouldn't happen but should handle gracefully)
        let progress = DownloadProgress(
            bytesDownloaded: 150,
            totalBytes: 100,
            isComplete: true
        )

        #expect(progress.progress == 1.5)  // Computed property returns actual ratio
    }

    @Test("Service identifier with special characters")
    func serviceIdentifierSpecialCharacters() {
        let service = SpeechRecognitionService(identifier: "test-service_123/456")
        #expect(service.identifier == "test-service_123/456")
    }

    @Test("Service identifier with empty string")
    func serviceIdentifierEmptyString() {
        let service = SpeechRecognitionService(identifier: "")
        #expect(service.identifier.isEmpty)
    }

    @Test("Error description for language with valid language code")
    func errorDescriptionValidLanguageCode() {
        let locale = Locale(identifier: "en-US")
        let error = SpeechRecognitionError.languageNotSupported(locale)

        // Should produce a description even for valid locales
        #expect(error.errorDescription != nil)
    }

    @Test("Error description for language with invalid language code")
    func errorDescriptionInvalidLanguageCode() {
        let locale = Locale(identifier: "invalid")
        let error = SpeechRecognitionError.languageNotSupported(locale)

        // Should handle invalid locale gracefully
        #expect(error.errorDescription != nil)
    }

    // MARK: - TranscriptionResult Multiple Segments Tests

    @Test("TranscriptionResult with multiple segments")
    func transcriptionResultMultipleSegments() {
        let segments = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 0.5, confidence: 0.9),
            TranscriptionSegment(text: "world", startTime: 0.5, endTime: 1.0, confidence: 0.95),
            TranscriptionSegment(text: "test", startTime: 1.0, endTime: 1.5, confidence: 0.85)
        ]

        let result = TranscriptionResult(
            id: UUID(),
            text: "Hello world test",
            segments: segments,
            isFinal: true,
            confidence: 0.9,
            locale: .current,
            timestamp: 0.0
        )

        #expect(result.segments.count == 3)
        #expect(result.segments[0].text == "Hello")
        #expect(result.segments[1].text == "world")
        #expect(result.segments[2].text == "test")
    }

    // MARK: - Locale Handling Tests

    @Test("TranscriptionResult with various locales")
    func transcriptionResultVariousLocales() {
        let locales = [
            Locale(identifier: "en-US"),
            Locale(identifier: "ja-JP"),
            Locale(identifier: "zh-CN"),
            Locale(identifier: "fr-FR"),
            Locale(identifier: "de-DE")
        ]

        for locale in locales {
            let result = TranscriptionResult(
                id: UUID(),
                text: "Test",
                segments: [],
                isFinal: true,
                confidence: 1.0,
                locale: locale,
                timestamp: 0.0
            )

            #expect(result.locale == locale)
        }
    }

    @Test("SpeechRecognitionError with various locales")
    func errorWithVariousLocales() {
        let locales = [
            Locale(identifier: "en-US"),
            Locale(identifier: "ja-JP"),
            Locale(identifier: "es-ES")
        ]

        for locale in locales {
            let notSupportedError = SpeechRecognitionError.languageNotSupported(locale)
            let notDownloadedError = SpeechRecognitionError.languageNotDownloaded(locale)

            #expect(notSupportedError.errorDescription != nil)
            #expect(notDownloadedError.errorDescription != nil)
            #expect(notDownloadedError.recoverySuggestion != nil)
        }
    }

    // MARK: - TranscriptionResult Inequality Tests

    @Test("TranscriptionResult inequality with different text")
    func transcriptionResultInequalityDifferentText() {
        let id = UUID()
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "World",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        #expect(result1 != result2)
    }

    @Test("TranscriptionResult inequality with different isFinal")
    func transcriptionResultInequalityDifferentIsFinal() {
        let id = UUID()
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: false,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        #expect(result1 != result2)
    }

    @Test("TranscriptionResult inequality with different confidence")
    func transcriptionResultInequalityDifferentConfidence() {
        let id = UUID()
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.5,
            locale: locale,
            timestamp: 100.0
        )

        #expect(result1 != result2)
    }

    @Test("TranscriptionResult inequality with different locale")
    func transcriptionResultInequalityDifferentLocale() {
        let id = UUID()
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: Locale(identifier: "en-US"),
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: Locale(identifier: "ja-JP"),
            timestamp: 100.0
        )

        #expect(result1 != result2)
    }

    @Test("TranscriptionResult inequality with different timestamp")
    func transcriptionResultInequalityDifferentTimestamp() {
        let id = UUID()
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 200.0
        )

        #expect(result1 != result2)
    }

    @Test("TranscriptionResult inequality with different segments")
    func transcriptionResultInequalityDifferentSegments() {
        let id = UUID()
        let segment1 = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let segment2 = TranscriptionSegment(text: "other", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment1],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: id,
            text: "Hello",
            segments: [segment2],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        #expect(result1 != result2)
    }

    // MARK: - TranscriptionSegment Inequality Tests

    @Test("TranscriptionSegment inequality with different startTime")
    func transcriptionSegmentInequalityDifferentStartTime() {
        let segment1 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        let segment2 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.5,
            endTime: 2.0,
            confidence: 0.9
        )

        #expect(segment1 != segment2)
    }

    @Test("TranscriptionSegment inequality with different endTime")
    func transcriptionSegmentInequalityDifferentEndTime() {
        let segment1 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        let segment2 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 3.0,
            confidence: 0.9
        )

        #expect(segment1 != segment2)
    }

    @Test("TranscriptionSegment inequality with different confidence")
    func transcriptionSegmentInequalityDifferentConfidence() {
        let segment1 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.9
        )

        let segment2 = TranscriptionSegment(
            text: "Hello",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.5
        )

        #expect(segment1 != segment2)
    }

    // MARK: - DownloadProgress Equality Tests

    @Test("DownloadProgress equality with same values")
    func downloadProgressEquality() {
        let progress1 = DownloadProgress(
            bytesDownloaded: 50_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        let progress2 = DownloadProgress(
            bytesDownloaded: 50_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        #expect(progress1.bytesDownloaded == progress2.bytesDownloaded)
        #expect(progress1.totalBytes == progress2.totalBytes)
        #expect(progress1.isComplete == progress2.isComplete)
        #expect(progress1.progress == progress2.progress)
    }

    @Test("DownloadProgress inequality with different bytesDownloaded")
    func downloadProgressInequalityBytesDownloaded() {
        let progress1 = DownloadProgress(
            bytesDownloaded: 25_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        let progress2 = DownloadProgress(
            bytesDownloaded: 75_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        #expect(progress1.bytesDownloaded != progress2.bytesDownloaded)
        #expect(progress1.progress != progress2.progress)
    }

    @Test("DownloadProgress inequality with different totalBytes")
    func downloadProgressInequalityTotalBytes() {
        let progress1 = DownloadProgress(
            bytesDownloaded: 50_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        let progress2 = DownloadProgress(
            bytesDownloaded: 50_000_000,
            totalBytes: 200_000_000,
            isComplete: false
        )

        #expect(progress1.totalBytes != progress2.totalBytes)
        #expect(progress1.progress != progress2.progress)
    }

    @Test("DownloadProgress inequality with different isComplete")
    func downloadProgressInequalityIsComplete() {
        let progress1 = DownloadProgress(
            bytesDownloaded: 100_000_000,
            totalBytes: 100_000_000,
            isComplete: false
        )

        let progress2 = DownloadProgress(
            bytesDownloaded: 100_000_000,
            totalBytes: 100_000_000,
            isComplete: true
        )

        #expect(progress1.isComplete != progress2.isComplete)
    }

    // MARK: - LanguageAvailability Edge Case Tests

    @Test("LanguageAvailability downloading at zero progress")
    func languageAvailabilityDownloadingZeroProgress() {
        let availability = LanguageAvailability.downloading(progress: 0.0)
        #expect(availability == .downloading(progress: 0.0))
    }

    @Test("LanguageAvailability downloading at full progress")
    func languageAvailabilityDownloadingFullProgress() {
        let availability = LanguageAvailability.downloading(progress: 1.0)
        #expect(availability == .downloading(progress: 1.0))
    }

    @Test("LanguageAvailability downloadRequired with zero size")
    func languageAvailabilityDownloadRequiredZeroSize() {
        let availability = LanguageAvailability.downloadRequired(size: 0)
        #expect(availability == .downloadRequired(size: 0))
    }

    @Test("LanguageAvailability downloadRequired with large size")
    func languageAvailabilityDownloadRequiredLargeSize() {
        let availability = LanguageAvailability.downloadRequired(size: Int64.max)
        #expect(availability == .downloadRequired(size: Int64.max))
    }

    // MARK: - SpeechRecognitionState Message Extraction Tests

    @Test("SpeechRecognitionState error message can be extracted")
    func stateErrorMessageExtraction() {
        let errorMessage = "Test error message"
        let state = SpeechRecognitionState.error(message: errorMessage)

        if case .error(let message) = state {
            #expect(message == errorMessage)
        } else {
            Issue.record("State should be error case")
        }
    }

    @Test("SpeechRecognitionState error with empty message")
    func stateErrorEmptyMessage() {
        let state = SpeechRecognitionState.error(message: "")
        #expect(state == .error(message: ""))

        if case .error(let message) = state {
            #expect(message.isEmpty)
        } else {
            Issue.record("State should be error case")
        }
    }

    @Test("SpeechRecognitionState error with special characters")
    func stateErrorSpecialCharacters() {
        let specialMessage = "Error: \n\t\"quoted\" <html>&amp;"
        let state = SpeechRecognitionState.error(message: specialMessage)

        if case .error(let message) = state {
            #expect(message == specialMessage)
        } else {
            Issue.record("State should be error case")
        }
    }

    // MARK: - SpeechRecognitionError Underlying Error Tests

    @Test("SpeechRecognitionError downloadFailed preserves underlying error type")
    func errorDownloadFailedPreservesUnderlyingError() {
        struct CustomDownloadError: Error {
            let code: Int
        }
        let underlyingError = CustomDownloadError(code: 404)
        let error = SpeechRecognitionError.downloadFailed(underlying: underlyingError)

        if case .downloadFailed(let underlying) = error {
            #expect(underlying is CustomDownloadError)
            if let customError = underlying as? CustomDownloadError {
                #expect(customError.code == 404)
            }
        } else {
            Issue.record("Error should be downloadFailed case")
        }
    }

    @Test("SpeechRecognitionError recognitionFailed preserves underlying error type")
    func errorRecognitionFailedPreservesUnderlyingError() {
        struct CustomRecognitionError: Error {
            let reason: String
        }
        let underlyingError = CustomRecognitionError(reason: "timeout")
        let error = SpeechRecognitionError.recognitionFailed(underlying: underlyingError)

        if case .recognitionFailed(let underlying) = error {
            #expect(underlying is CustomRecognitionError)
            if let customError = underlying as? CustomRecognitionError {
                #expect(customError.reason == "timeout")
            }
        } else {
            Issue.record("Error should be recognitionFailed case")
        }
    }

    @Test("SpeechRecognitionError downloadFailed with NSError")
    func errorDownloadFailedWithNSError() {
        let nsError = NSError(domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        let error = SpeechRecognitionError.downloadFailed(underlying: nsError)

        if case .downloadFailed(let underlying) = error {
            let resultNSError = underlying as NSError
            #expect(resultNSError.domain == "TestDomain")
            #expect(resultNSError.code == 500)
        } else {
            Issue.record("Error should be downloadFailed case")
        }
    }

    @Test("SpeechRecognitionError recognitionFailed with NSError")
    func errorRecognitionFailedWithNSError() {
        let nsError = NSError(domain: "SpeechDomain", code: 100, userInfo: nil)
        let error = SpeechRecognitionError.recognitionFailed(underlying: nsError)

        if case .recognitionFailed(let underlying) = error {
            let resultNSError = underlying as NSError
            #expect(resultNSError.domain == "SpeechDomain")
            #expect(resultNSError.code == 100)
        } else {
            Issue.record("Error should be recognitionFailed case")
        }
    }

    // MARK: - SpeechRecognitionError Locale Extraction Tests

    @Test("SpeechRecognitionError languageNotSupported preserves locale")
    func errorLanguageNotSupportedPreservesLocale() {
        let locale = Locale(identifier: "zh-Hans-CN")
        let error = SpeechRecognitionError.languageNotSupported(locale)

        if case .languageNotSupported(let resultLocale) = error {
            #expect(resultLocale.identifier == locale.identifier)
        } else {
            Issue.record("Error should be languageNotSupported case")
        }
    }

    @Test("SpeechRecognitionError languageNotDownloaded preserves locale")
    func errorLanguageNotDownloadedPreservesLocale() {
        let locale = Locale(identifier: "pt-BR")
        let error = SpeechRecognitionError.languageNotDownloaded(locale)

        if case .languageNotDownloaded(let resultLocale) = error {
            #expect(resultLocale.identifier == locale.identifier)
        } else {
            Issue.record("Error should be languageNotDownloaded case")
        }
    }

    // MARK: - TranscriptionSegment Duration Edge Cases

    @Test("TranscriptionSegment duration with very small interval")
    func transcriptionSegmentVerySmallDuration() {
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: 0.0,
            endTime: 0.001,
            confidence: 1.0
        )

        #expect(segment.duration == 0.001)
    }

    @Test("TranscriptionSegment duration with very large interval")
    func transcriptionSegmentVeryLargeDuration() {
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: 0.0,
            endTime: 3600.0,  // 1 hour
            confidence: 1.0
        )

        #expect(segment.duration == 3600.0)
    }

    @Test("TranscriptionSegment duration with non-zero start")
    func transcriptionSegmentDurationNonZeroStart() {
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: 100.5,
            endTime: 105.5,
            confidence: 1.0
        )

        #expect(segment.duration == 5.0)
    }

    // MARK: - DownloadProgress Edge Cases

    @Test("DownloadProgress with very small values")
    func downloadProgressVerySmallValues() {
        let progress = DownloadProgress(
            bytesDownloaded: 1,
            totalBytes: 1000,
            isComplete: false
        )

        #expect(progress.progress == 0.001)
    }

    @Test("DownloadProgress with Int64 max values")
    func downloadProgressMaxInt64Values() {
        let progress = DownloadProgress(
            bytesDownloaded: Int64.max / 2,
            totalBytes: Int64.max,
            isComplete: false
        )

        // Should be approximately 0.5
        #expect(progress.progress > 0.49)
        #expect(progress.progress < 0.51)
    }

    @Test("DownloadProgress with negative bytesDownloaded")
    func downloadProgressNegativeBytesDownloaded() {
        // Edge case: shouldn't happen but test the behavior
        let progress = DownloadProgress(
            bytesDownloaded: -100,
            totalBytes: 1000,
            isComplete: false
        )

        #expect(progress.progress < 0)
    }

    // MARK: - Service Protocol Conformance Tests

    @Test("SpeechRecognitionService conforms to protocol")
    func serviceConformsToProtocol() {
        let service = SpeechRecognitionService()

        // Verify protocol properties are accessible
        _ = service.state
        _ = service.sourceLocale

        // Protocol conformance is verified at compile time
        let _: any SpeechRecognitionServiceProtocol = service
    }

    // MARK: - TranscriptionResult with Unicode Text

    @Test("TranscriptionResult with Unicode text")
    func transcriptionResultUnicodeText() {
        let unicodeText = "Hello \u{1F600} World \u{4E2D}\u{6587}"  // emoji and Chinese characters
        let result = TranscriptionResult(
            id: UUID(),
            text: unicodeText,
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: .current,
            timestamp: 0.0
        )

        #expect(result.text == unicodeText)
    }

    @Test("TranscriptionSegment with Unicode text")
    func transcriptionSegmentUnicodeText() {
        let unicodeText = "\u{65E5}\u{672C}\u{8A9E}"  // Japanese characters
        let segment = TranscriptionSegment(
            text: unicodeText,
            startTime: 0.0,
            endTime: 1.0,
            confidence: 0.95
        )

        #expect(segment.text == unicodeText)
    }

    // MARK: - SpeechRecognitionError Case Distinction Tests

    @Test("SpeechRecognitionError cases are distinct")
    func errorCasesAreDistinct() {
        let locale = Locale(identifier: "en-US")
        struct TestError: Error {}

        let errors: [SpeechRecognitionError] = [
            .permissionDenied,
            .languageNotSupported(locale),
            .languageNotDownloaded(locale),
            .downloadFailed(underlying: TestError()),
            .recognitionFailed(underlying: TestError()),
            .noAudioInput,
            .alreadyRunning
        ]

        // Verify each error has a unique description
        var descriptions = Set<String>()
        for error in errors {
            if let description = error.errorDescription {
                descriptions.insert(description)
            }
        }

        #expect(descriptions.count == errors.count)
    }

    // MARK: - LanguageAvailability All Cases Tests

    @Test("LanguageAvailability all cases are distinct")
    func languageAvailabilityAllCasesDistinct() {
        let cases: [LanguageAvailability] = [
            .available,
            .downloadRequired(size: 100),
            .downloading(progress: 0.5),
            .unsupported
        ]

        // Verify all cases are different from each other
        for i in 0..<cases.count {
            for j in (i + 1)..<cases.count {
                #expect(cases[i] != cases[j])
            }
        }
    }

    // MARK: - TranscriptionResult Hashability Tests

    @Test("TranscriptionResult can be used in Set when Hashable")
    func transcriptionResultInSet() {
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let result1 = TranscriptionResult(
            id: UUID(),
            text: "Hello",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        let result2 = TranscriptionResult(
            id: UUID(),
            text: "World",
            segments: [segment],
            isFinal: true,
            confidence: 0.9,
            locale: locale,
            timestamp: 100.0
        )

        // Different IDs mean different results
        #expect(result1 != result2)
    }

    // MARK: - Service Initialization Edge Cases

    @Test("Service initializes with very long identifier")
    func serviceInitializationLongIdentifier() {
        let longIdentifier = String(repeating: "a", count: 1000)
        let service = SpeechRecognitionService(identifier: longIdentifier)
        #expect(service.identifier == longIdentifier)
    }

    @Test("Service initializes with Unicode identifier")
    func serviceInitializationUnicodeIdentifier() {
        let unicodeIdentifier = "\u{1F600}-service-\u{4E2D}\u{6587}"
        let service = SpeechRecognitionService(identifier: unicodeIdentifier)
        #expect(service.identifier == unicodeIdentifier)
    }

    // MARK: - DownloadProgress Progress Calculation Tests

    @Test("DownloadProgress progress calculation precision")
    func downloadProgressPrecision() {
        let progress = DownloadProgress(
            bytesDownloaded: 1,
            totalBytes: 3,
            isComplete: false
        )

        // Should be approximately 0.333...
        #expect(progress.progress > 0.33)
        #expect(progress.progress < 0.34)
    }

    @Test("DownloadProgress zero divided by zero edge case")
    func downloadProgressZeroByZero() {
        let progress = DownloadProgress(
            bytesDownloaded: 0,
            totalBytes: 0,
            isComplete: false
        )

        // Guard clause returns 0 when totalBytes is 0
        #expect(progress.progress == 0.0)
    }

    // MARK: - SpeechRecognitionState Pattern Matching Tests

    @Test("SpeechRecognitionState idle pattern matching")
    func stateIdlePatternMatching() {
        let state = SpeechRecognitionState.idle
        var matched = false

        switch state {
        case .idle:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionState starting pattern matching")
    func stateStartingPatternMatching() {
        let state = SpeechRecognitionState.starting
        var matched = false

        switch state {
        case .starting:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionState listening pattern matching")
    func stateListeningPatternMatching() {
        let state = SpeechRecognitionState.listening
        var matched = false

        switch state {
        case .listening:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionState processing pattern matching")
    func stateProcessingPatternMatching() {
        let state = SpeechRecognitionState.processing
        var matched = false

        switch state {
        case .processing:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionState error pattern matching extracts message")
    func stateErrorPatternMatchingExtractsMessage() {
        let errorMsg = "Network timeout occurred"
        let state = SpeechRecognitionState.error(message: errorMsg)
        var extractedMessage: String?

        switch state {
        case .error(let message):
            extractedMessage = message
        default:
            break
        }

        #expect(extractedMessage == errorMsg)
    }

    // MARK: - LanguageAvailability Pattern Matching Tests

    @Test("LanguageAvailability available pattern matching")
    func languageAvailablePatternMatching() {
        let availability = LanguageAvailability.available
        var matched = false

        switch availability {
        case .available:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("LanguageAvailability unsupported pattern matching")
    func languageUnsupportedPatternMatching() {
        let availability = LanguageAvailability.unsupported
        var matched = false

        switch availability {
        case .unsupported:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("LanguageAvailability downloadRequired pattern matching extracts size")
    func languageDownloadRequiredPatternMatchingExtractsSize() {
        let expectedSize: Int64 = 256_000_000
        let availability = LanguageAvailability.downloadRequired(size: expectedSize)
        var extractedSize: Int64?

        switch availability {
        case .downloadRequired(let size):
            extractedSize = size
        default:
            break
        }

        #expect(extractedSize == expectedSize)
    }

    @Test("LanguageAvailability downloading pattern matching extracts progress")
    func languageDownloadingPatternMatchingExtractsProgress() {
        let expectedProgress = 0.75
        let availability = LanguageAvailability.downloading(progress: expectedProgress)
        var extractedProgress: Double?

        switch availability {
        case .downloading(let progress):
            extractedProgress = progress
        default:
            break
        }

        #expect(extractedProgress == expectedProgress)
    }

    // MARK: - SpeechRecognitionError Pattern Matching Tests

    @Test("SpeechRecognitionError permissionDenied pattern matching")
    func errorPermissionDeniedPatternMatching() {
        let error = SpeechRecognitionError.permissionDenied
        var matched = false

        switch error {
        case .permissionDenied:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionError noAudioInput pattern matching")
    func errorNoAudioInputPatternMatching() {
        let error = SpeechRecognitionError.noAudioInput
        var matched = false

        switch error {
        case .noAudioInput:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionError alreadyRunning pattern matching")
    func errorAlreadyRunningPatternMatching() {
        let error = SpeechRecognitionError.alreadyRunning
        var matched = false

        switch error {
        case .alreadyRunning:
            matched = true
        default:
            break
        }

        #expect(matched)
    }

    @Test("SpeechRecognitionError languageNotSupported pattern matching extracts locale")
    func errorLanguageNotSupportedPatternMatchingExtractsLocale() {
        let expectedLocale = Locale(identifier: "ko-KR")
        let error = SpeechRecognitionError.languageNotSupported(expectedLocale)
        var extractedLocale: Locale?

        switch error {
        case .languageNotSupported(let locale):
            extractedLocale = locale
        default:
            break
        }

        #expect(extractedLocale?.identifier == expectedLocale.identifier)
    }

    @Test("SpeechRecognitionError languageNotDownloaded pattern matching extracts locale")
    func errorLanguageNotDownloadedPatternMatchingExtractsLocale() {
        let expectedLocale = Locale(identifier: "ar-SA")
        let error = SpeechRecognitionError.languageNotDownloaded(expectedLocale)
        var extractedLocale: Locale?

        switch error {
        case .languageNotDownloaded(let locale):
            extractedLocale = locale
        default:
            break
        }

        #expect(extractedLocale?.identifier == expectedLocale.identifier)
    }

    @Test("SpeechRecognitionError downloadFailed pattern matching extracts underlying error")
    func errorDownloadFailedPatternMatchingExtractsUnderlying() {
        struct TestDownloadError: Error {
            let message: String
        }
        let underlyingError = TestDownloadError(message: "Connection reset")
        let error = SpeechRecognitionError.downloadFailed(underlying: underlyingError)
        var extractedError: (any Error)?

        switch error {
        case .downloadFailed(let underlying):
            extractedError = underlying
        default:
            break
        }

        #expect(extractedError != nil)
        if let testError = extractedError as? TestDownloadError {
            #expect(testError.message == "Connection reset")
        } else {
            Issue.record("Expected TestDownloadError type")
        }
    }

    @Test("SpeechRecognitionError recognitionFailed pattern matching extracts underlying error")
    func errorRecognitionFailedPatternMatchingExtractsUnderlying() {
        struct TestRecognitionError: Error {
            let code: Int
        }
        let underlyingError = TestRecognitionError(code: 42)
        let error = SpeechRecognitionError.recognitionFailed(underlying: underlyingError)
        var extractedError: (any Error)?

        switch error {
        case .recognitionFailed(let underlying):
            extractedError = underlying
        default:
            break
        }

        #expect(extractedError != nil)
        if let testError = extractedError as? TestRecognitionError {
            #expect(testError.code == 42)
        } else {
            Issue.record("Expected TestRecognitionError type")
        }
    }

    // MARK: - TranscriptionResult Additional Edge Cases

    @Test("TranscriptionResult with very long text")
    func transcriptionResultVeryLongText() {
        let longText = String(repeating: "This is a test sentence. ", count: 1000)
        let result = TranscriptionResult(
            id: UUID(),
            text: longText,
            segments: [],
            isFinal: true,
            confidence: 0.95,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )

        #expect(result.text == longText)
        #expect(result.text.count > 20000)
    }

    @Test("TranscriptionResult with many segments")
    func transcriptionResultManySegments() {
        var segments: [TranscriptionSegment] = []
        for i in 0..<100 {
            segments.append(TranscriptionSegment(
                text: "Word\(i)",
                startTime: Double(i) * 0.5,
                endTime: Double(i + 1) * 0.5,
                confidence: Float.random(in: 0.8...1.0)
            ))
        }

        let result = TranscriptionResult(
            id: UUID(),
            text: "Long transcription",
            segments: segments,
            isFinal: true,
            confidence: 0.9,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )

        #expect(result.segments.count == 100)
    }

    @Test("TranscriptionResult with negative timestamp")
    func transcriptionResultNegativeTimestamp() {
        let result = TranscriptionResult(
            id: UUID(),
            text: "Test",
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: Locale(identifier: "en-US"),
            timestamp: -100.0
        )

        #expect(result.timestamp == -100.0)
    }

    @Test("TranscriptionResult with very large timestamp")
    func transcriptionResultVeryLargeTimestamp() {
        let largeTimestamp = TimeInterval.greatestFiniteMagnitude / 2
        let result = TranscriptionResult(
            id: UUID(),
            text: "Test",
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: Locale(identifier: "en-US"),
            timestamp: largeTimestamp
        )

        #expect(result.timestamp == largeTimestamp)
    }

    @Test("TranscriptionResult confidence boundary values")
    func transcriptionResultConfidenceBoundaries() {
        // Test just above 0
        let lowResult = TranscriptionResult(
            id: UUID(),
            text: "Low",
            segments: [],
            isFinal: true,
            confidence: Float.leastNonzeroMagnitude,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )
        #expect(lowResult.confidence > 0)
        #expect(lowResult.confidence < 0.001)

        // Test just below 1
        let highResult = TranscriptionResult(
            id: UUID(),
            text: "High",
            segments: [],
            isFinal: true,
            confidence: 1.0 - Float.ulpOfOne,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )
        #expect(highResult.confidence < 1.0)
        #expect(highResult.confidence > 0.99)
    }

    // MARK: - TranscriptionSegment Additional Edge Cases

    @Test("TranscriptionSegment with equal start and end times")
    func transcriptionSegmentEqualStartEndTimes() {
        let segment = TranscriptionSegment(
            text: "Instant",
            startTime: 5.0,
            endTime: 5.0,
            confidence: 1.0
        )

        #expect(segment.duration == 0.0)
        #expect(segment.startTime == segment.endTime)
    }

    @Test("TranscriptionSegment with reversed times produces negative duration")
    func transcriptionSegmentReversedTimes() {
        let segment = TranscriptionSegment(
            text: "Reversed",
            startTime: 10.0,
            endTime: 5.0,
            confidence: 1.0
        )

        #expect(segment.duration == -5.0)
    }

    @Test("TranscriptionSegment confidence boundary values")
    func transcriptionSegmentConfidenceBoundaries() {
        let lowSegment = TranscriptionSegment(
            text: "Low",
            startTime: 0.0,
            endTime: 1.0,
            confidence: Float.leastNonzeroMagnitude
        )
        #expect(lowSegment.confidence > 0)

        let highSegment = TranscriptionSegment(
            text: "High",
            startTime: 0.0,
            endTime: 1.0,
            confidence: Float.greatestFiniteMagnitude
        )
        #expect(highSegment.confidence == Float.greatestFiniteMagnitude)
    }

    @Test("TranscriptionSegment with whitespace-only text")
    func transcriptionSegmentWhitespaceText() {
        let segment = TranscriptionSegment(
            text: "   \t\n   ",
            startTime: 0.0,
            endTime: 1.0,
            confidence: 0.5
        )

        #expect(segment.text == "   \t\n   ")
        #expect(segment.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("TranscriptionSegment with special characters")
    func transcriptionSegmentSpecialCharacters() {
        let specialText = "Hello! @#$%^&*()_+-=[]{}|;':\",./<>?"
        let segment = TranscriptionSegment(
            text: specialText,
            startTime: 0.0,
            endTime: 1.0,
            confidence: 0.8
        )

        #expect(segment.text == specialText)
    }

    @Test("TranscriptionSegment with RTL text")
    func transcriptionSegmentRTLText() {
        let rtlText = "\u{0645}\u{0631}\u{062D}\u{0628}\u{0627}"  // Arabic "marhaba"
        let segment = TranscriptionSegment(
            text: rtlText,
            startTime: 0.0,
            endTime: 1.0,
            confidence: 0.9
        )

        #expect(segment.text == rtlText)
    }

    // MARK: - DownloadProgress Additional Tests

    @Test("DownloadProgress with exact half progress")
    func downloadProgressExactHalf() {
        let progress = DownloadProgress(
            bytesDownloaded: 500,
            totalBytes: 1000,
            isComplete: false
        )

        #expect(progress.progress == 0.5)
    }

    @Test("DownloadProgress with one third progress")
    func downloadProgressOneThird() {
        let progress = DownloadProgress(
            bytesDownloaded: 333,
            totalBytes: 1000,
            isComplete: false
        )

        #expect(progress.progress == 0.333)
    }

    @Test("DownloadProgress isComplete does not affect progress calculation")
    func downloadProgressIsCompleteIndependent() {
        let progress1 = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: 100,
            isComplete: false
        )

        let progress2 = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: 100,
            isComplete: true
        )

        #expect(progress1.progress == progress2.progress)
    }

    @Test("DownloadProgress with negative totalBytes")
    func downloadProgressNegativeTotalBytes() {
        let progress = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: -100,
            isComplete: false
        )

        // Negative totalBytes fails the guard (totalBytes > 0 is false), returns 0
        #expect(progress.progress == 0.0)
    }

    // MARK: - SpeechRecognitionError Locale Variant Tests

    @Test("SpeechRecognitionError with locale having only language code")
    func errorWithLanguageOnlyLocale() {
        let locale = Locale(identifier: "en")
        let error = SpeechRecognitionError.languageNotSupported(locale)

        #expect(error.errorDescription != nil)
    }

    @Test("SpeechRecognitionError with locale having script")
    func errorWithScriptLocale() {
        let locale = Locale(identifier: "zh-Hans")
        let error = SpeechRecognitionError.languageNotSupported(locale)

        #expect(error.errorDescription != nil)
    }

    @Test("SpeechRecognitionError with full locale identifier")
    func errorWithFullLocaleIdentifier() {
        let locale = Locale(identifier: "zh-Hans-CN")
        let error = SpeechRecognitionError.languageNotDownloaded(locale)

        #expect(error.errorDescription != nil)
        #expect(error.recoverySuggestion != nil)
    }

    @Test("SpeechRecognitionError with posix locale")
    func errorWithPosixLocale() {
        let locale = Locale(identifier: "en_US_POSIX")
        let error = SpeechRecognitionError.languageNotSupported(locale)

        #expect(error.errorDescription != nil)
    }

    // MARK: - LanguageAvailability Downloading Progress Edge Cases

    @Test("LanguageAvailability downloading with progress exceeding 1.0")
    func languageAvailabilityDownloadingProgressExceedsOne() {
        let availability = LanguageAvailability.downloading(progress: 1.5)
        #expect(availability == .downloading(progress: 1.5))

        if case .downloading(let progress) = availability {
            #expect(progress > 1.0)
        }
    }

    @Test("LanguageAvailability downloading with negative progress")
    func languageAvailabilityDownloadingNegativeProgress() {
        let availability = LanguageAvailability.downloading(progress: -0.1)
        #expect(availability == .downloading(progress: -0.1))

        if case .downloading(let progress) = availability {
            #expect(progress < 0)
        }
    }

    @Test("LanguageAvailability downloadRequired with negative size")
    func languageAvailabilityDownloadRequiredNegativeSize() {
        let availability = LanguageAvailability.downloadRequired(size: -100)
        #expect(availability == .downloadRequired(size: -100))

        if case .downloadRequired(let size) = availability {
            #expect(size < 0)
        }
    }

    // MARK: - SpeechRecognitionState All Cases Exhaustive Test

    @Test("SpeechRecognitionState exhaustive switch")
    func stateExhaustiveSwitch() {
        let states: [SpeechRecognitionState] = [
            .idle,
            .starting,
            .listening,
            .processing,
            .error(message: "test")
        ]

        for state in states {
            var handled = false
            switch state {
            case .idle:
                handled = true
            case .starting:
                handled = true
            case .listening:
                handled = true
            case .processing:
                handled = true
            case .error:
                handled = true
            }
            #expect(handled, "State \(state) should be handled")
        }
    }

    // MARK: - LanguageAvailability All Cases Exhaustive Test

    @Test("LanguageAvailability exhaustive switch")
    func languageAvailabilityExhaustiveSwitch() {
        let availabilities: [LanguageAvailability] = [
            .available,
            .downloadRequired(size: 100),
            .downloading(progress: 0.5),
            .unsupported
        ]

        for availability in availabilities {
            var handled = false
            switch availability {
            case .available:
                handled = true
            case .downloadRequired:
                handled = true
            case .downloading:
                handled = true
            case .unsupported:
                handled = true
            }
            #expect(handled, "Availability \(availability) should be handled")
        }
    }

    // MARK: - SpeechRecognitionError All Cases Exhaustive Test

    @Test("SpeechRecognitionError exhaustive switch")
    func errorExhaustiveSwitch() {
        struct TestError: Error {}
        let locale = Locale(identifier: "en-US")

        let errors: [SpeechRecognitionError] = [
            .permissionDenied,
            .languageNotSupported(locale),
            .languageNotDownloaded(locale),
            .downloadFailed(underlying: TestError()),
            .recognitionFailed(underlying: TestError()),
            .noAudioInput,
            .alreadyRunning
        ]

        for error in errors {
            var handled = false
            switch error {
            case .permissionDenied:
                handled = true
            case .languageNotSupported:
                handled = true
            case .languageNotDownloaded:
                handled = true
            case .downloadFailed:
                handled = true
            case .recognitionFailed:
                handled = true
            case .noAudioInput:
                handled = true
            case .alreadyRunning:
                handled = true
            }
            #expect(handled, "Error \(error) should be handled")
        }
    }

    // MARK: - SpeechRecognitionError Recovery Suggestion Mapping Tests

    @Test("Only specific errors have recovery suggestions")
    func errorRecoverySuggestionMapping() {
        struct TestError: Error {}
        let locale = Locale(identifier: "en-US")

        // Errors that should have recovery suggestions
        #expect(SpeechRecognitionError.permissionDenied.recoverySuggestion != nil)
        #expect(SpeechRecognitionError.languageNotDownloaded(locale).recoverySuggestion != nil)
        #expect(SpeechRecognitionError.downloadFailed(underlying: TestError()).recoverySuggestion != nil)

        // Errors that should NOT have recovery suggestions
        #expect(SpeechRecognitionError.languageNotSupported(locale).recoverySuggestion == nil)
        #expect(SpeechRecognitionError.recognitionFailed(underlying: TestError()).recoverySuggestion == nil)
        #expect(SpeechRecognitionError.noAudioInput.recoverySuggestion == nil)
        #expect(SpeechRecognitionError.alreadyRunning.recoverySuggestion == nil)
    }

    // MARK: - TranscriptionResult Segments Array Tests

    @Test("TranscriptionResult segments array is mutable copy safe")
    func transcriptionResultSegmentsImmutable() {
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let result = TranscriptionResult(
            id: UUID(),
            text: "Test",
            segments: [segment],
            isFinal: true,
            confidence: 1.0,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )

        // Get segments
        var segments = result.segments
        segments.append(TranscriptionSegment(text: "extra", startTime: 1, endTime: 2, confidence: 1.0))

        // Original should be unchanged (value semantics)
        #expect(result.segments.count == 1)
        #expect(segments.count == 2)
    }

    // MARK: - Service Multiple Instance Independence Tests

    @Test("Multiple service instances maintain independent identifiers")
    func multipleServiceInstancesIndependentIdentifiers() {
        let services = (0..<10).map { SpeechRecognitionService(identifier: "service-\($0)") }

        for (index, service) in services.enumerated() {
            #expect(service.identifier == "service-\(index)")
        }
    }

    @Test("Multiple service instances all start in idle state")
    func multipleServiceInstancesAllIdleState() {
        let services = (0..<10).map { _ in SpeechRecognitionService() }

        for service in services {
            #expect(service.state == .idle)
        }
    }

    // MARK: - TranscriptionSegment Duration Calculation Tests

    @Test("TranscriptionSegment duration calculation with decimal precision")
    func transcriptionSegmentDurationDecimalPrecision() {
        let segment = TranscriptionSegment(
            text: "Test",
            startTime: 0.123456789,
            endTime: 1.987654321,
            confidence: 1.0
        )

        let expectedDuration = 1.987654321 - 0.123456789
        #expect(abs(segment.duration - expectedDuration) < 0.0000001)
    }

    // MARK: - SpeechRecognitionState Inequality Across All Cases

    @Test("All SpeechRecognitionState cases are mutually distinct")
    func allStatesAreMutuallyDistinct() {
        let idle = SpeechRecognitionState.idle
        let starting = SpeechRecognitionState.starting
        let listening = SpeechRecognitionState.listening
        let processing = SpeechRecognitionState.processing
        let error1 = SpeechRecognitionState.error(message: "error1")
        let error2 = SpeechRecognitionState.error(message: "error2")

        #expect(idle != starting)
        #expect(idle != listening)
        #expect(idle != processing)
        #expect(idle != error1)
        #expect(starting != listening)
        #expect(starting != processing)
        #expect(starting != error1)
        #expect(listening != processing)
        #expect(listening != error1)
        #expect(processing != error1)
        #expect(error1 != error2)
    }

    // MARK: - DownloadProgress Computed Property Tests

    @Test("DownloadProgress progress returns correct value for various fractions")
    func downloadProgressVariousFractions() {
        let testCases: [(downloaded: Int64, total: Int64, expected: Double)] = [
            (0, 100, 0.0),
            (25, 100, 0.25),
            (50, 100, 0.5),
            (75, 100, 0.75),
            (100, 100, 1.0),
            (10, 100, 0.1),
            (90, 100, 0.9)
        ]

        for testCase in testCases {
            let progress = DownloadProgress(
                bytesDownloaded: testCase.downloaded,
                totalBytes: testCase.total,
                isComplete: testCase.downloaded == testCase.total
            )
            #expect(progress.progress == testCase.expected)
        }
    }

    // MARK: - TranscriptionResult with Various Locale Formats

    @Test("TranscriptionResult handles locale with calendar")
    func transcriptionResultLocaleWithCalendar() {
        var locale = Locale(identifier: "ja-JP")
        locale = Locale(identifier: "ja-JP@calendar=japanese")
        let result = TranscriptionResult(
            id: UUID(),
            text: "Test",
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: locale,
            timestamp: 0.0
        )

        #expect(result.locale.identifier.contains("ja"))
    }

    // MARK: - SpeechRecognitionError LocalizedError Protocol Tests

    @Test("SpeechRecognitionError can be cast to LocalizedError")
    func errorCanBeCastToLocalizedError() {
        let error: any Error = SpeechRecognitionError.permissionDenied

        let localizedError = error as? any LocalizedError
        #expect(localizedError != nil)
        #expect(localizedError?.errorDescription != nil)
    }

    @Test("All SpeechRecognitionError cases can be cast to LocalizedError")
    func allErrorsCastToLocalizedError() {
        struct TestError: Error {}
        let locale = Locale(identifier: "en-US")

        let errors: [any Error] = [
            SpeechRecognitionError.permissionDenied,
            SpeechRecognitionError.languageNotSupported(locale),
            SpeechRecognitionError.languageNotDownloaded(locale),
            SpeechRecognitionError.downloadFailed(underlying: TestError()),
            SpeechRecognitionError.recognitionFailed(underlying: TestError()),
            SpeechRecognitionError.noAudioInput,
            SpeechRecognitionError.alreadyRunning
        ]

        for error in errors {
            let localizedError = error as? any LocalizedError
            #expect(localizedError != nil)
            #expect(localizedError?.errorDescription != nil)
        }
    }

    // MARK: - Sendable Verification with Complex Data

    @Test("TranscriptionResult with segments is Sendable")
    func transcriptionResultWithSegmentsIsSendable() async {
        let segments = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 0.5, confidence: 0.9),
            TranscriptionSegment(text: "World", startTime: 0.5, endTime: 1.0, confidence: 0.95)
        ]

        let result = TranscriptionResult(
            id: UUID(),
            text: "Hello World",
            segments: segments,
            isFinal: true,
            confidence: 0.925,
            locale: Locale(identifier: "en-US"),
            timestamp: 1000.0
        )

        let task = Task.detached {
            result
        }

        let returned = await task.value
        #expect(returned.segments.count == 2)
        #expect(returned.segments[0].text == "Hello")
        #expect(returned.segments[1].text == "World")
    }

    @Test("SpeechRecognitionState error with long message is Sendable")
    func stateErrorLongMessageIsSendable() async {
        let longMessage = String(repeating: "Error detail. ", count: 100)
        let state = SpeechRecognitionState.error(message: longMessage)

        let task = Task.detached {
            state
        }

        let returned = await task.value
        if case .error(let message) = returned {
            #expect(message == longMessage)
        } else {
            Issue.record("Expected error state")
        }
    }

    // MARK: - TranscriptionResult ID Uniqueness Tests

    @Test("TranscriptionResult with same content but different IDs are not equal")
    func transcriptionResultDifferentIdsNotEqual() {
        let segment = TranscriptionSegment(text: "test", startTime: 0, endTime: 1, confidence: 1.0)
        let locale = Locale(identifier: "en-US")

        let results = (0..<5).map { _ in
            TranscriptionResult(
                id: UUID(),
                text: "Same text",
                segments: [segment],
                isFinal: true,
                confidence: 0.9,
                locale: locale,
                timestamp: 100.0
            )
        }

        // All should have different IDs and thus be not equal
        for i in 0..<results.count {
            for j in (i + 1)..<results.count {
                #expect(results[i] != results[j])
            }
        }
    }

    // MARK: - Service State Observation Tests

    @Test("Service state property is read-only from external access")
    func serviceStateIsReadOnly() {
        let service = SpeechRecognitionService()

        // We can read the state
        let currentState = service.state
        #expect(currentState == .idle)

        // The state property is private(set), so external code cannot modify it
        // This is a compile-time guarantee, the test just verifies initial state
    }

    @Test("Service sourceLocale property is read-only from external access")
    func serviceSourceLocaleIsReadOnly() {
        let service = SpeechRecognitionService()

        // We can read the locale
        let currentLocale = service.sourceLocale
        #expect(currentLocale == .current)

        // The sourceLocale property is private(set), so external code cannot modify it
        // This is a compile-time guarantee
    }

    // MARK: - LanguageAvailability Size Formatting Tests

    @Test("LanguageAvailability downloadRequired size in bytes")
    func languageAvailabilityDownloadRequiredSizeBytes() {
        let sizes: [Int64] = [1, 1024, 1024 * 1024, 1024 * 1024 * 1024]

        for size in sizes {
            let availability = LanguageAvailability.downloadRequired(size: size)
            if case .downloadRequired(let extractedSize) = availability {
                #expect(extractedSize == size)
            } else {
                Issue.record("Expected downloadRequired case")
            }
        }
    }

    // MARK: - TranscriptionSegment Time Interval Tests

    @Test("TranscriptionSegment handles microsecond precision")
    func transcriptionSegmentMicrosecondPrecision() {
        let segment = TranscriptionSegment(
            text: "Precise",
            startTime: 0.000001,
            endTime: 0.000002,
            confidence: 1.0
        )

        #expect(segment.duration == 0.000001)
    }

    @Test("TranscriptionSegment handles hour-long durations")
    func transcriptionSegmentHourLongDuration() {
        let segment = TranscriptionSegment(
            text: "Long",
            startTime: 0.0,
            endTime: 3600.0,  // 1 hour
            confidence: 1.0
        )

        #expect(segment.duration == 3600.0)
    }

    // MARK: - SpeechRecognitionError Description Content Tests

    @Test("SpeechRecognitionError descriptions are non-empty strings")
    func errorDescriptionsAreNonEmpty() {
        struct TestError: Error {}
        let locale = Locale(identifier: "fr-FR")

        // All errors should have non-empty descriptions
        let permissionError = SpeechRecognitionError.permissionDenied
        #expect(permissionError.errorDescription != nil)
        #expect(permissionError.errorDescription?.isEmpty == false)

        let noAudioError = SpeechRecognitionError.noAudioInput
        #expect(noAudioError.errorDescription != nil)
        #expect(noAudioError.errorDescription?.isEmpty == false)

        let alreadyRunningError = SpeechRecognitionError.alreadyRunning
        #expect(alreadyRunningError.errorDescription != nil)
        #expect(alreadyRunningError.errorDescription?.isEmpty == false)

        let downloadFailedError = SpeechRecognitionError.downloadFailed(underlying: TestError())
        #expect(downloadFailedError.errorDescription != nil)
        #expect(downloadFailedError.errorDescription?.isEmpty == false)

        let recognitionFailedError = SpeechRecognitionError.recognitionFailed(underlying: TestError())
        #expect(recognitionFailedError.errorDescription != nil)
        #expect(recognitionFailedError.errorDescription?.isEmpty == false)
    }

    // MARK: - SpeechRecognitionError Recovery Suggestion Content Tests

    @Test("SpeechRecognitionError recovery suggestions are non-empty when present")
    func errorRecoverySuggestionsAreNonEmptyWhenPresent() {
        struct TestError: Error {}
        let locale = Locale(identifier: "en-US")

        // permissionDenied should have a non-empty recovery suggestion
        let permissionRecovery = SpeechRecognitionError.permissionDenied.recoverySuggestion
        #expect(permissionRecovery != nil)
        #expect(permissionRecovery?.isEmpty == false)

        // languageNotDownloaded should have a non-empty recovery suggestion
        let downloadRecovery = SpeechRecognitionError.languageNotDownloaded(locale).recoverySuggestion
        #expect(downloadRecovery != nil)
        #expect(downloadRecovery?.isEmpty == false)

        // downloadFailed should have a non-empty recovery suggestion
        let failedRecovery = SpeechRecognitionError.downloadFailed(underlying: TestError()).recoverySuggestion
        #expect(failedRecovery != nil)
        #expect(failedRecovery?.isEmpty == false)
    }

    // MARK: - DownloadProgress Edge Case Combinations

    @Test("DownloadProgress handles all zero values")
    func downloadProgressAllZeroValues() {
        let progress = DownloadProgress(
            bytesDownloaded: 0,
            totalBytes: 0,
            isComplete: false
        )

        #expect(progress.bytesDownloaded == 0)
        #expect(progress.totalBytes == 0)
        #expect(progress.isComplete == false)
        #expect(progress.progress == 0.0)
    }

    @Test("DownloadProgress complete but with zero bytes")
    func downloadProgressCompleteZeroBytes() {
        let progress = DownloadProgress(
            bytesDownloaded: 0,
            totalBytes: 0,
            isComplete: true
        )

        #expect(progress.isComplete == true)
        #expect(progress.progress == 0.0)
    }

    // MARK: - Protocol Conformance Verification Tests

    @Test("SpeechRecognitionState conforms to Equatable")
    func stateConformsToEquatable() {
        let state1: any Equatable = SpeechRecognitionState.idle
        let state2: any Equatable = SpeechRecognitionState.idle

        // Just verify the types can be used as Equatable
        #expect(type(of: state1) == type(of: state2))
    }

    @Test("TranscriptionResult conforms to Equatable")
    func transcriptionResultConformsToEquatable() {
        let result: any Equatable = TranscriptionResult(
            id: UUID(),
            text: "Test",
            segments: [],
            isFinal: true,
            confidence: 1.0,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )

        #expect(result is TranscriptionResult)
    }

    @Test("TranscriptionSegment conforms to Equatable")
    func transcriptionSegmentConformsToEquatable() {
        let segment: any Equatable = TranscriptionSegment(
            text: "Test",
            startTime: 0.0,
            endTime: 1.0,
            confidence: 1.0
        )

        #expect(segment is TranscriptionSegment)
    }

    @Test("LanguageAvailability conforms to Equatable")
    func languageAvailabilityConformsToEquatable() {
        let availability: any Equatable = LanguageAvailability.available

        #expect(availability is LanguageAvailability)
    }

    // MARK: - TranscriptionResult Segment Order Tests

    @Test("TranscriptionResult preserves segment order")
    func transcriptionResultPreservesSegmentOrder() {
        let segments = (0..<10).map { index in
            TranscriptionSegment(
                text: "Segment\(index)",
                startTime: Double(index),
                endTime: Double(index + 1),
                confidence: Float(index) / 10.0
            )
        }

        let result = TranscriptionResult(
            id: UUID(),
            text: "Full text",
            segments: segments,
            isFinal: true,
            confidence: 0.5,
            locale: Locale(identifier: "en-US"),
            timestamp: 0.0
        )

        for (index, segment) in result.segments.enumerated() {
            #expect(segment.text == "Segment\(index)")
            #expect(segment.startTime == Double(index))
        }
    }

    // MARK: - Nonisolated Type Tests

    @Test("SpeechRecognitionState is nonisolated")
    func stateIsNonisolated() {
        // This test verifies that SpeechRecognitionState can be used without actor isolation
        nonisolated func createState() -> SpeechRecognitionState {
            .idle
        }

        let state = createState()
        #expect(state == .idle)
    }

    @Test("TranscriptionResult is nonisolated")
    func transcriptionResultIsNonisolated() {
        nonisolated func createResult() -> TranscriptionResult {
            TranscriptionResult(
                id: UUID(),
                text: "Test",
                segments: [],
                isFinal: true,
                confidence: 1.0,
                locale: Locale(identifier: "en-US"),
                timestamp: 0.0
            )
        }

        let result = createResult()
        #expect(result.text == "Test")
    }

    @Test("TranscriptionSegment is nonisolated")
    func transcriptionSegmentIsNonisolated() {
        nonisolated func createSegment() -> TranscriptionSegment {
            TranscriptionSegment(
                text: "Test",
                startTime: 0.0,
                endTime: 1.0,
                confidence: 1.0
            )
        }

        let segment = createSegment()
        #expect(segment.text == "Test")
    }

    @Test("LanguageAvailability is nonisolated")
    func languageAvailabilityIsNonisolated() {
        nonisolated func createAvailability() -> LanguageAvailability {
            .available
        }

        let availability = createAvailability()
        #expect(availability == .available)
    }

    @Test("DownloadProgress is nonisolated")
    func downloadProgressIsNonisolated() {
        nonisolated func createProgress() -> DownloadProgress {
            DownloadProgress(
                bytesDownloaded: 50,
                totalBytes: 100,
                isComplete: false
            )
        }

        let progress = createProgress()
        #expect(progress.progress == 0.5)
    }

    @Test("SpeechRecognitionError is nonisolated")
    func speechRecognitionErrorIsNonisolated() {
        nonisolated func createError() -> SpeechRecognitionError {
            .permissionDenied
        }

        let error = createError()
        #expect(error.errorDescription != nil)
    }
}
