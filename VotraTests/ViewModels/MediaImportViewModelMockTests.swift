//
//  MediaImportViewModelMockTests.swift
//  VotraTests
//
//  Unit tests for MediaImportViewModel using mock service implementations.
//

@preconcurrency import AVFoundation
import Foundation
import Testing
@testable import Votra

// MARK: - Mock Speech Recognition Service

@MainActor
final class MockSpeechRecognitionServiceForMediaImport: SpeechRecognitionServiceProtocol, @unchecked Sendable {
    // MARK: - Protocol Properties

    var state: SpeechRecognitionState = .idle
    var sourceLocale: Locale = .current

    // MARK: - Call Tracking

    private(set) var startRecognitionCallCount = 0
    private(set) var startRecognitionLocales: [Locale] = []
    private(set) var startRecognitionAccurateModes: [Bool] = []

    private(set) var stopRecognitionCallCount = 0

    private(set) var processAudioCallCount = 0
    private(set) var processedBuffers: [AVAudioPCMBuffer] = []

    private(set) var isLanguageAvailableCallCount = 0
    private(set) var checkedLocales: [Locale] = []

    private(set) var downloadLanguageCallCount = 0
    private(set) var downloadedLocales: [Locale] = []

    private(set) var supportedLanguagesCallCount = 0

    // MARK: - Stub Configuration

    var startRecognitionResult: AsyncStream<TranscriptionResult> = AsyncStream { $0.finish() }
    var startRecognitionError: Error?

    var isLanguageAvailableResult: LanguageAvailability = .available

    var downloadLanguageResult: AsyncStream<DownloadProgress> = AsyncStream { $0.finish() }
    var downloadLanguageError: Error?

    var supportedLanguagesResult: [Locale] = [Locale(identifier: "en"), Locale(identifier: "zh-Hans")]

    // MARK: - Protocol Methods

    func startRecognition(locale: Locale, accurateMode: Bool) async throws -> AsyncStream<TranscriptionResult> {
        startRecognitionCallCount += 1
        startRecognitionLocales.append(locale)
        startRecognitionAccurateModes.append(accurateMode)
        sourceLocale = locale

        if let error = startRecognitionError {
            throw error
        }

        state = .listening
        return startRecognitionResult
    }

    func stopRecognition() async {
        stopRecognitionCallCount += 1
        state = .idle
    }

    func processAudio(_ buffer: AVAudioPCMBuffer) async throws {
        processAudioCallCount += 1
        processedBuffers.append(buffer)
    }

    func isLanguageAvailable(_ locale: Locale) async -> LanguageAvailability {
        isLanguageAvailableCallCount += 1
        checkedLocales.append(locale)
        return isLanguageAvailableResult
    }

    func downloadLanguage(_ locale: Locale) async throws -> AsyncStream<DownloadProgress> {
        downloadLanguageCallCount += 1
        downloadedLocales.append(locale)

        if let error = downloadLanguageError {
            throw error
        }

        return downloadLanguageResult
    }

    func supportedLanguages() async -> [Locale] {
        supportedLanguagesCallCount += 1
        return supportedLanguagesResult
    }

    // MARK: - Test Helpers

    func reset() {
        state = .idle
        sourceLocale = .current
        startRecognitionCallCount = 0
        startRecognitionLocales = []
        startRecognitionAccurateModes = []
        stopRecognitionCallCount = 0
        processAudioCallCount = 0
        processedBuffers = []
        isLanguageAvailableCallCount = 0
        checkedLocales = []
        downloadLanguageCallCount = 0
        downloadedLocales = []
        supportedLanguagesCallCount = 0
        startRecognitionResult = AsyncStream { $0.finish() }
        startRecognitionError = nil
        isLanguageAvailableResult = .available
        downloadLanguageResult = AsyncStream { $0.finish() }
        downloadLanguageError = nil
        supportedLanguagesResult = [Locale(identifier: "en"), Locale(identifier: "zh-Hans")]
    }
}

// MARK: - Mock Translation Service

@MainActor
final class MockTranslationServiceForMediaImport: TranslationServiceProtocol, @unchecked Sendable {
    // MARK: - Protocol Properties

    var state: TranslationServiceState = .idle
    var hasSession: Bool = false

    // MARK: - Call Tracking

    private(set) var translateCallCount = 0
    private(set) var translateTexts: [String] = []
    private(set) var translateSourceLocales: [Locale] = []
    private(set) var translateTargetLocales: [Locale] = []

    private(set) var translateBatchCallCount = 0
    private(set) var translateBatchTexts: [[String]] = []

    private(set) var isLanguagePairSupportedCallCount = 0
    private(set) var checkedLanguagePairs: [(source: Locale, target: Locale)] = []

    private(set) var supportedLanguagePairsCallCount = 0

    private(set) var languageStatusCallCount = 0
    private(set) var checkedLanguageStatuses: [Locale] = []

    private(set) var prepareLanguagesCallCount = 0

    private(set) var setSessionCallCount = 0
    private(set) var setSessions: [Any] = []

    // MARK: - Stub Configuration

    var translateResult: String = "Translated text"
    var translateError: Error?

    var translateBatchResult: [String] = []
    var translateBatchError: Error?

    var isLanguagePairSupportedResult: Bool = true

    var supportedLanguagePairsResult: [LanguagePair] = []

    var languageStatusResult: LanguageDownloadStatus = .installed

    var prepareLanguagesError: Error?

    // MARK: - Protocol Methods

    func translate(_ text: String, from sourceLocale: Locale, to targetLocale: Locale) async throws -> String {
        translateCallCount += 1
        translateTexts.append(text)
        translateSourceLocales.append(sourceLocale)
        translateTargetLocales.append(targetLocale)

        if let error = translateError {
            throw error
        }

        return translateResult
    }

    func translateBatch(_ texts: [String], from sourceLocale: Locale, to targetLocale: Locale) async throws -> [String] {
        translateBatchCallCount += 1
        translateBatchTexts.append(texts)

        if let error = translateBatchError {
            throw error
        }

        return translateBatchResult.isEmpty ? texts.map { _ in translateResult } : translateBatchResult
    }

    func isLanguagePairSupported(source: Locale, target: Locale) async -> Bool {
        isLanguagePairSupportedCallCount += 1
        checkedLanguagePairs.append((source: source, target: target))
        return isLanguagePairSupportedResult
    }

    func supportedLanguagePairs() async -> [LanguagePair] {
        supportedLanguagePairsCallCount += 1
        return supportedLanguagePairsResult
    }

    func languageStatus(for locale: Locale) async -> LanguageDownloadStatus {
        languageStatusCallCount += 1
        checkedLanguageStatuses.append(locale)
        return languageStatusResult
    }

    func prepareLanguages(source: Locale, target: Locale) async throws {
        prepareLanguagesCallCount += 1

        if let error = prepareLanguagesError {
            throw error
        }
    }

    func setSession(_ session: Any) async {
        setSessionCallCount += 1
        setSessions.append(session)
        hasSession = true
        state = .ready
    }

    // MARK: - Test Helpers

    func reset() {
        state = .idle
        hasSession = false
        translateCallCount = 0
        translateTexts = []
        translateSourceLocales = []
        translateTargetLocales = []
        translateBatchCallCount = 0
        translateBatchTexts = []
        isLanguagePairSupportedCallCount = 0
        checkedLanguagePairs = []
        supportedLanguagePairsCallCount = 0
        languageStatusCallCount = 0
        checkedLanguageStatuses = []
        prepareLanguagesCallCount = 0
        setSessionCallCount = 0
        setSessions = []
        translateResult = "Translated text"
        translateError = nil
        translateBatchResult = []
        translateBatchError = nil
        isLanguagePairSupportedResult = true
        supportedLanguagePairsResult = []
        languageStatusResult = .installed
        prepareLanguagesError = nil
    }
}

// MARK: - Mock Subtitle Export Service

@MainActor
final class MockSubtitleExportServiceForMediaImport: SubtitleExportServiceProtocol {
    // MARK: - Call Tracking

    private(set) var exportSegmentsCallCount = 0
    private(set) var exportedSegments: [[Segment]] = []
    private(set) var exportSegmentsOptions: [SubtitleExportOptions] = []

    private(set) var exportMessagesCallCount = 0
    private(set) var exportedMessages: [[ConversationMessage]] = []
    private(set) var exportMessagesSessionStartTimes: [Date] = []
    private(set) var exportMessagesOptions: [SubtitleExportOptions] = []

    private(set) var generateContentFromSegmentsCallCount = 0
    private(set) var generatedContentSegments: [[Segment]] = []

    private(set) var generateContentFromMessagesCallCount = 0
    private(set) var generatedContentMessages: [[ConversationMessage]] = []

    // MARK: - Stub Configuration

    var exportSegmentsResult = URL.temporaryDirectory.appending(path: "test.srt")
    var exportSegmentsError: Error?

    var exportMessagesResult = URL.temporaryDirectory.appending(path: "test.srt")
    var exportMessagesError: Error?

    var generateContentFromSegmentsResult: String = "1\n00:00:00,000 --> 00:00:05,000\nTest subtitle"

    var generateContentFromMessagesResult: String = "1\n00:00:00,000 --> 00:00:05,000\nTest message"

    // MARK: - Protocol Methods

    func export(
        segments: [Segment],
        options: SubtitleExportOptions
    ) async throws -> URL {
        exportSegmentsCallCount += 1
        exportedSegments.append(segments)
        exportSegmentsOptions.append(options)

        if let error = exportSegmentsError {
            throw error
        }

        return exportSegmentsResult
    }

    func export(
        messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) async throws -> URL {
        exportMessagesCallCount += 1
        exportedMessages.append(messages)
        exportMessagesSessionStartTimes.append(sessionStartTime)
        exportMessagesOptions.append(options)

        if let error = exportMessagesError {
            throw error
        }

        return exportMessagesResult
    }

    func generateContent(
        from segments: [Segment],
        options: SubtitleExportOptions
    ) -> String {
        generateContentFromSegmentsCallCount += 1
        generatedContentSegments.append(segments)
        return generateContentFromSegmentsResult
    }

    func generateContent(
        from messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) -> String {
        generateContentFromMessagesCallCount += 1
        generatedContentMessages.append(messages)
        return generateContentFromMessagesResult
    }

    // MARK: - Test Helpers

    func reset() {
        exportSegmentsCallCount = 0
        exportedSegments = []
        exportSegmentsOptions = []
        exportMessagesCallCount = 0
        exportedMessages = []
        exportMessagesSessionStartTimes = []
        exportMessagesOptions = []
        generateContentFromSegmentsCallCount = 0
        generatedContentSegments = []
        generateContentFromMessagesCallCount = 0
        generatedContentMessages = []
        exportSegmentsResult = URL.temporaryDirectory.appending(path: "test.srt")
        exportSegmentsError = nil
        exportMessagesResult = URL.temporaryDirectory.appending(path: "test.srt")
        exportMessagesError = nil
        generateContentFromSegmentsResult = "1\n00:00:00,000 --> 00:00:05,000\nTest subtitle"
        generateContentFromMessagesResult = "1\n00:00:00,000 --> 00:00:05,000\nTest message"
    }
}

// MARK: - Mock Intelligent Segmentation Service

@MainActor
final class MockIntelligentSegmentationServiceForMediaImport: IntelligentSegmentationServiceProtocol {
    // MARK: - Call Tracking

    private(set) var segmentTranscriptCallCount = 0
    private(set) var segmentTranscriptTexts: [String] = []
    private(set) var segmentTranscriptWordTimings: [[WordTimingInfo]] = []
    private(set) var segmentTranscriptSourceLocales: [Locale] = []
    private(set) var segmentTranscriptMaxChars: [Int?] = []

    // MARK: - Stub Configuration

    var segmentTranscriptResult: [TimedSegment] = []
    var segmentTranscriptError: Error?

    // MARK: - Protocol Methods

    func segmentTranscript(
        text: String,
        wordTimings: [WordTimingInfo],
        sourceLocale: Locale,
        maxCharsPerSegment: Int?
    ) async throws -> [TimedSegment] {
        segmentTranscriptCallCount += 1
        segmentTranscriptTexts.append(text)
        segmentTranscriptWordTimings.append(wordTimings)
        segmentTranscriptSourceLocales.append(sourceLocale)
        segmentTranscriptMaxChars.append(maxCharsPerSegment)

        if let error = segmentTranscriptError {
            throw error
        }

        // Default: return single segment with the full text if no result configured
        if segmentTranscriptResult.isEmpty {
            return [TimedSegment(text: text, startTime: 0, endTime: 5.0)]
        }

        return segmentTranscriptResult
    }

    // MARK: - Test Helpers

    func reset() {
        segmentTranscriptCallCount = 0
        segmentTranscriptTexts = []
        segmentTranscriptWordTimings = []
        segmentTranscriptSourceLocales = []
        segmentTranscriptMaxChars = []
        segmentTranscriptResult = []
        segmentTranscriptError = nil
    }
}

// MARK: - MediaImportViewModel Mock Tests

@Suite("MediaImportViewModel Mock Tests")
@MainActor
struct MediaImportViewModelMockTests {
    // MARK: - Test Fixtures

    let mockSpeechRecognitionService = MockSpeechRecognitionServiceForMediaImport()
    let mockTranslationService = MockTranslationServiceForMediaImport()
    let mockSubtitleExportService = MockSubtitleExportServiceForMediaImport()
    let mockIntelligentSegmentationService = MockIntelligentSegmentationServiceForMediaImport()

    func createViewModel() -> MediaImportViewModel {
        MediaImportViewModel(
            speechRecognitionService: mockSpeechRecognitionService,
            translationService: mockTranslationService,
            subtitleExportService: mockSubtitleExportService,
            intelligentSegmentationService: mockIntelligentSegmentationService
        )
    }

    // MARK: - Cancel Processing Tests

    @Test("cancelProcessing sets state to cancelled")
    func cancelProcessingSetsStateToCancelled() {
        let viewModel = createViewModel()

        // Initial state should be idle
        #expect(viewModel.batchState == .idle)

        // Cancel processing
        viewModel.cancelProcessing()

        // State should be cancelled
        #expect(viewModel.batchState == .cancelled)
    }

    @Test("cancelProcessing from idle state")
    func cancelProcessingFromIdleState() {
        let viewModel = createViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("cancelProcessing can be called multiple times")
    func cancelProcessingMultipleTimes() {
        let viewModel = createViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)
    }

    // MARK: - Clear Queue Tests

    @Test("clearQueue clears files when idle")
    func clearQueueClearsFilesWhenIdle() async {
        let viewModel = createViewModel()

        // Manually add a file to the queue (simulating the internal state)
        // Since we cannot directly add files without a real URL, we test the empty case
        #expect(viewModel.files.isEmpty)

        viewModel.clearQueue()

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)
    }

    @Test("clearQueue clears files when cancelled")
    func clearQueueClearsFilesWhenCancelled() {
        let viewModel = createViewModel()

        // Set state to cancelled
        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        // Clear should work when cancelled
        viewModel.clearQueue()

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)
    }

    @Test("clearQueue resets batchState to idle")
    func clearQueueResetsBatchStateToIdle() {
        let viewModel = createViewModel()

        // Cancel first to change state
        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        // Clear queue
        viewModel.clearQueue()

        #expect(viewModel.batchState == .idle)
    }

    // MARK: - Set Translation Session Tests

    @Test("setTranslationSession passes session to translation service")
    func setTranslationSessionPassesToService() async {
        let viewModel = createViewModel()
        let mockSession = "MockTranslationSession"

        await viewModel.setTranslationSession(mockSession)

        #expect(mockTranslationService.setSessionCallCount == 1)
        #expect(mockTranslationService.setSessions.count == 1)
    }

    @Test("setTranslationSession updates service state")
    func setTranslationSessionUpdatesServiceState() async {
        let viewModel = createViewModel()

        #expect(mockTranslationService.hasSession == false)
        #expect(mockTranslationService.state == .idle)

        await viewModel.setTranslationSession("session")

        #expect(mockTranslationService.hasSession == true)
        #expect(mockTranslationService.state == .ready)
    }

    @Test("setTranslationSession can be called multiple times")
    func setTranslationSessionMultipleTimes() async {
        let viewModel = createViewModel()

        await viewModel.setTranslationSession("session1")
        await viewModel.setTranslationSession("session2")
        await viewModel.setTranslationSession("session3")

        #expect(mockTranslationService.setSessionCallCount == 3)
        #expect(mockTranslationService.setSessions.count == 3)
    }

    // MARK: - Computed Properties Tests

    @Test("isCompleted returns false when idle")
    func isCompletedReturnsFalseWhenIdle() {
        let viewModel = createViewModel()

        #expect(viewModel.isCompleted == false)
    }

    @Test("isCompleted returns false when cancelled")
    func isCompletedReturnsFalseWhenCancelled() {
        let viewModel = createViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.isCompleted == false)
    }

    @Test("isProcessing returns false when idle")
    func isProcessingReturnsFalseWhenIdle() {
        let viewModel = createViewModel()

        #expect(viewModel.isProcessing == false)
    }

    @Test("isProcessing returns false when cancelled")
    func isProcessingReturnsFalseWhenCancelled() {
        let viewModel = createViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.isProcessing == false)
    }

    @Test("totalFiles returns zero initially")
    func totalFilesReturnsZeroInitially() {
        let viewModel = createViewModel()

        #expect(viewModel.totalFiles == 0)
    }

    @Test("completedFiles returns zero initially")
    func completedFilesReturnsZeroInitially() {
        let viewModel = createViewModel()

        #expect(viewModel.completedFiles == 0)
    }

    @Test("failedFiles returns zero initially")
    func failedFilesReturnsZeroInitially() {
        let viewModel = createViewModel()

        #expect(viewModel.failedFiles == 0)
    }

    @Test("overallProgress returns zero when no files")
    func overallProgressReturnsZeroWhenNoFiles() {
        let viewModel = createViewModel()

        #expect(viewModel.overallProgress == 0)
    }

    // MARK: - Configuration Update Tests

    @Test("sourceLocale can be updated")
    func sourceLocaleCanBeUpdated() {
        let viewModel = createViewModel()

        #expect(viewModel.sourceLocale.identifier == "en")

        viewModel.sourceLocale = Locale(identifier: "ja")

        #expect(viewModel.sourceLocale.identifier == "ja")
    }

    @Test("targetLocale can be updated")
    func targetLocaleCanBeUpdated() {
        let viewModel = createViewModel()

        #expect(viewModel.targetLocale.identifier == "zh-Hans")

        viewModel.targetLocale = Locale(identifier: "fr")

        #expect(viewModel.targetLocale.identifier == "fr")
    }

    @Test("exportOptions can be updated")
    func exportOptionsCanBeUpdated() {
        let viewModel = createViewModel()

        let newOptions = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )
        viewModel.exportOptions = newOptions

        #expect(viewModel.exportOptions.format == .vtt)
        #expect(viewModel.exportOptions.contentOption == .originalOnly)
        #expect(viewModel.exportOptions.includeTimestamps == false)
        #expect(viewModel.exportOptions.bilingualOrder == .originalFirst)
    }

    @Test("outputDirectory can be updated")
    func outputDirectoryCanBeUpdated() {
        let viewModel = createViewModel()

        let originalDirectory = viewModel.outputDirectory
        let newDirectory = URL.temporaryDirectory.appending(path: "custom_output")
        viewModel.outputDirectory = newDirectory

        #expect(viewModel.outputDirectory == newDirectory)
        #expect(viewModel.outputDirectory != originalDirectory)
    }

    @Test("exportOptions format defaults to SRT")
    func exportOptionsFormatDefaultsToSRT() {
        let viewModel = createViewModel()

        #expect(viewModel.exportOptions.format == .srt)
    }

    @Test("exportOptions contentOption defaults to both")
    func exportOptionsContentOptionDefaultsToBoth() {
        let viewModel = createViewModel()

        #expect(viewModel.exportOptions.contentOption == .both)
    }

    @Test("exportOptions includeTimestamps defaults to true")
    func exportOptionsIncludeTimestampsDefaultsToTrue() {
        let viewModel = createViewModel()

        #expect(viewModel.exportOptions.includeTimestamps == true)
    }

    @Test("exportOptions bilingualOrder defaults to translationFirst")
    func exportOptionsBilingualOrderDefaultsToTranslationFirst() {
        let viewModel = createViewModel()

        #expect(viewModel.exportOptions.bilingualOrder == .translationFirst)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let viewModel = createViewModel()

        #expect(viewModel.batchState == .idle)
        #expect(viewModel.files.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Initial configuration uses default values")
    func initialConfigurationUsesDefaultValues() {
        let viewModel = createViewModel()

        #expect(viewModel.sourceLocale.identifier == "en")
        #expect(viewModel.targetLocale.identifier == "zh-Hans")
        #expect(viewModel.outputDirectory == StoragePaths.exports)
    }

    // MARK: - State Transition Tests

    @Test("State transitions from idle to cancelled")
    func stateTransitionsFromIdleToCancelled() {
        let viewModel = createViewModel()

        #expect(viewModel.batchState == .idle)

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("State resets to idle after clear queue")
    func stateResetsToIdleAfterClearQueue() {
        let viewModel = createViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.clearQueue()
        #expect(viewModel.batchState == .idle)
    }

    // MARK: - Mock Service Verification Tests

    @Test("Translation service mock tracks setSession calls correctly")
    func translationServiceMockTracksSetSessionCalls() async {
        let viewModel = createViewModel()

        #expect(mockTranslationService.setSessionCallCount == 0)

        await viewModel.setTranslationSession("test-session-1")
        #expect(mockTranslationService.setSessionCallCount == 1)

        await viewModel.setTranslationSession("test-session-2")
        #expect(mockTranslationService.setSessionCallCount == 2)
    }

    @Test("Mock services can be reset")
    func mockServicesCanBeReset() async {
        let viewModel = createViewModel()

        await viewModel.setTranslationSession("session")
        #expect(mockTranslationService.setSessionCallCount == 1)

        mockTranslationService.reset()
        #expect(mockTranslationService.setSessionCallCount == 0)
        #expect(mockTranslationService.hasSession == false)
        #expect(mockTranslationService.state == .idle)
    }
}

// MARK: - MediaFile State Computation Tests

@Suite("MediaFile State Computation Tests")
@MainActor
struct MediaFileStateComputationTests {
    @Test("MediaFile queued state")
    func mediaFileQueuedState() {
        let file = MediaFile(
            url: URL.temporaryDirectory.appending(path: "test.mp4"),
            fileName: "test.mp4",
            fileSize: 1024,
            duration: 60.0,
            mediaType: .video,
            state: .queued
        )

        #expect(file.state == .queued)
    }

    @Test("MediaFile processing state with progress")
    func mediaFileProcessingStateWithProgress() {
        let file = MediaFile(
            url: URL.temporaryDirectory.appending(path: "test.mp4"),
            fileName: "test.mp4",
            fileSize: 1024,
            duration: 60.0,
            mediaType: .video,
            state: .processing(progress: 0.5)
        )

        if case .processing(let progress) = file.state {
            #expect(progress == 0.5)
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("MediaFile completed state")
    func mediaFileCompletedState() {
        let file = MediaFile(
            url: URL.temporaryDirectory.appending(path: "test.mp4"),
            fileName: "test.mp4",
            fileSize: 1024,
            duration: 60.0,
            mediaType: .video,
            state: .completed
        )

        #expect(file.state == .completed)
    }

    @Test("MediaFile failed state with error message")
    func mediaFileFailedStateWithError() {
        let file = MediaFile(
            url: URL.temporaryDirectory.appending(path: "test.mp4"),
            fileName: "test.mp4",
            fileSize: 1024,
            duration: 60.0,
            mediaType: .video,
            state: .failed(error: "Test error message")
        )

        if case .failed(let error) = file.state {
            #expect(error == "Test error message")
        } else {
            Issue.record("Expected failed state")
        }
    }

    @Test("MediaFile formattedDuration for short duration")
    func mediaFileFormattedDurationShort() {
        let file = MediaFile(
            url: URL.temporaryDirectory.appending(path: "test.mp4"),
            fileName: "test.mp4",
            fileSize: 1024,
            duration: 65.0, // 1:05
            mediaType: .video
        )

        #expect(file.formattedDuration == "1:05")
    }

    @Test("MediaFile formattedDuration for long duration")
    func mediaFileFormattedDurationLong() {
        let file = MediaFile(
            url: URL.temporaryDirectory.appending(path: "test.mp4"),
            fileName: "test.mp4",
            fileSize: 1024,
            duration: 3665.0, // 1:01:05
            mediaType: .video
        )

        #expect(file.formattedDuration == "1:01:05")
    }
}

// MARK: - Batch Processing State Tests

@Suite("Batch Processing State Mock Tests")
@MainActor
struct BatchProcessingStateMockTests {
    @Test("Idle state equality")
    func idleStateEquality() {
        let state1 = BatchProcessingState.idle
        let state2 = BatchProcessingState.idle

        #expect(state1 == state2)
    }

    @Test("Processing state equality with same values")
    func processingStateEqualitySameValues() {
        let state1 = BatchProcessingState.processing(current: 1, total: 5)
        let state2 = BatchProcessingState.processing(current: 1, total: 5)

        #expect(state1 == state2)
    }

    @Test("Processing state inequality with different values")
    func processingStateInequalityDifferentValues() {
        let state1 = BatchProcessingState.processing(current: 1, total: 5)
        let state2 = BatchProcessingState.processing(current: 2, total: 5)

        #expect(state1 != state2)
    }

    @Test("Completed state equality with same counts")
    func completedStateEqualitySameCounts() {
        let state1 = BatchProcessingState.completed(successful: 3, failed: 2)
        let state2 = BatchProcessingState.completed(successful: 3, failed: 2)

        #expect(state1 == state2)
    }

    @Test("Completed state inequality with different counts")
    func completedStateInequalityDifferentCounts() {
        let state1 = BatchProcessingState.completed(successful: 3, failed: 2)
        let state2 = BatchProcessingState.completed(successful: 4, failed: 1)

        #expect(state1 != state2)
    }

    @Test("Cancelled state equality")
    func cancelledStateEquality() {
        let state1 = BatchProcessingState.cancelled
        let state2 = BatchProcessingState.cancelled

        #expect(state1 == state2)
    }

    @Test("Different states are not equal")
    func differentStatesNotEqual() {
        let idle = BatchProcessingState.idle
        let cancelled = BatchProcessingState.cancelled
        let processing = BatchProcessingState.processing(current: 1, total: 2)
        let completed = BatchProcessingState.completed(successful: 1, failed: 0)

        #expect(idle != cancelled)
        #expect(idle != processing)
        #expect(idle != completed)
        #expect(cancelled != processing)
        #expect(cancelled != completed)
        #expect(processing != completed)
    }
}

// MARK: - Mock Service Call Verification Tests

@Suite("Mock Service Call Verification Tests")
@MainActor
struct MockServiceCallVerificationTests {
    @Test("Speech recognition mock initial state")
    func speechRecognitionMockInitialState() {
        let mock = MockSpeechRecognitionServiceForMediaImport()

        #expect(mock.state == .idle)
        #expect(mock.startRecognitionCallCount == 0)
        #expect(mock.stopRecognitionCallCount == 0)
        #expect(mock.processAudioCallCount == 0)
    }

    @Test("Translation mock initial state")
    func translationMockInitialState() {
        let mock = MockTranslationServiceForMediaImport()

        #expect(mock.state == .idle)
        #expect(mock.hasSession == false)
        #expect(mock.translateCallCount == 0)
        #expect(mock.setSessionCallCount == 0)
    }

    @Test("Subtitle export mock initial state")
    func subtitleExportMockInitialState() {
        let mock = MockSubtitleExportServiceForMediaImport()

        #expect(mock.exportSegmentsCallCount == 0)
        #expect(mock.exportMessagesCallCount == 0)
        #expect(mock.generateContentFromSegmentsCallCount == 0)
    }

    @Test("Intelligent segmentation mock initial state")
    func intelligentSegmentationMockInitialState() {
        let mock = MockIntelligentSegmentationServiceForMediaImport()

        #expect(mock.segmentTranscriptCallCount == 0)
        #expect(mock.segmentTranscriptTexts.isEmpty)
    }

    @Test("Translation mock setSession tracks call")
    func translationMockSetSessionTracksCall() async {
        let mock = MockTranslationServiceForMediaImport()

        await mock.setSession("test-session")

        #expect(mock.setSessionCallCount == 1)
        #expect(mock.hasSession == true)
        #expect(mock.state == .ready)
    }

    @Test("Translation mock translate tracks parameters")
    func translationMockTranslateTracksParameters() async throws {
        let mock = MockTranslationServiceForMediaImport()
        let sourceLocale = Locale(identifier: "en")
        let targetLocale = Locale(identifier: "ja")

        _ = try await mock.translate("Hello", from: sourceLocale, to: targetLocale)

        #expect(mock.translateCallCount == 1)
        #expect(mock.translateTexts == ["Hello"])
        #expect(mock.translateSourceLocales.first?.identifier == "en")
        #expect(mock.translateTargetLocales.first?.identifier == "ja")
    }

    @Test("Intelligent segmentation mock returns default segment")
    func intelligentSegmentationMockReturnsDefaultSegment() async throws {
        let mock = MockIntelligentSegmentationServiceForMediaImport()

        let result = try await mock.segmentTranscript(
            text: "Test text",
            wordTimings: [],
            sourceLocale: Locale(identifier: "en"),
            maxCharsPerSegment: 42
        )

        #expect(mock.segmentTranscriptCallCount == 1)
        #expect(result.count == 1)
        #expect(result.first?.text == "Test text")
    }

    @Test("Intelligent segmentation mock can be configured with custom result")
    func intelligentSegmentationMockCanBeConfiguredWithCustomResult() async throws {
        let mock = MockIntelligentSegmentationServiceForMediaImport()
        mock.segmentTranscriptResult = [
            TimedSegment(text: "Segment 1", startTime: 0, endTime: 2),
            TimedSegment(text: "Segment 2", startTime: 2, endTime: 4)
        ]

        let result = try await mock.segmentTranscript(
            text: "Segment 1 Segment 2",
            wordTimings: [],
            sourceLocale: Locale(identifier: "en"),
            maxCharsPerSegment: nil
        )

        #expect(result.count == 2)
        #expect(result[0].text == "Segment 1")
        #expect(result[1].text == "Segment 2")
    }
}
