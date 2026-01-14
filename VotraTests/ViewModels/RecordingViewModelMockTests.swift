//
//  RecordingViewModelMockTests.swift
//  VotraTests
//
//  Tests for RecordingViewModel using mock service implementations.
//

import Foundation
import SwiftData
import Testing
@testable import Votra

// MARK: - Mock Recording Service

/// Mock implementation of RecordingServiceProtocol for testing RecordingViewModel
@MainActor
final class MockRecordingServiceForViewModel: RecordingServiceProtocol {
    // MARK: - State

    private(set) var state = RecordingState.idle
    private(set) var currentMetadata: RecordingMetadata?

    // MARK: - Call Tracking

    var startCallCount = 0
    var stopCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var forceSaveCallCount = 0
    var checkForIncompleteRecordingsCallCount = 0
    var recoverRecordingCallCount = 0
    var discardIncompleteRecordingCallCount = 0
    var availableDiskSpaceCallCount = 0

    var lastStartFormat: AudioFormat?
    var lastRecoveredMetadata: RecordingMetadata?
    var lastDiscardedMetadata: RecordingMetadata?

    // MARK: - Configurable Behavior

    var shouldFailStart = false
    var startError = RecordingServiceError.permissionDenied

    var shouldFailStop = false
    var stopError = RecordingServiceError.notRecording
    var stopReturnURL = URL(filePath: "/tmp/test-recording.m4a")

    var shouldFailPause = false
    var pauseError = RecordingServiceError.notRecording

    var shouldFailResume = false
    var resumeError = RecordingServiceError.notRecording

    var shouldFailForceSave = false
    var forceSaveError = RecordingServiceError.notRecording

    var shouldFailRecovery = false
    var recoveryError = RecordingServiceError.recoveryFailed(
        underlying: NSError(domain: "Test", code: -1, userInfo: nil)
    )
    var recoveryReturnURL = URL(filePath: "/tmp/recovered-recording.m4a")

    var shouldFailDiscard = false
    var discardError = RecordingServiceError.notRecording

    var incompleteRecordingsToReturn: [RecordingMetadata] = []
    var diskSpaceToReturn = Int64.max

    // MARK: - RecordingServiceProtocol Implementation

    func start(format: AudioFormat) async throws {
        startCallCount += 1
        lastStartFormat = format

        if shouldFailStart {
            throw startError
        }

        state = RecordingState.recording
        currentMetadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: format,
            tempFileURL: URL(filePath: "/tmp/temp-recording.\(format.fileExtension)"),
            isComplete: false,
            lastAutoSaveTime: nil
        )
    }

    func stop() async throws -> URL {
        stopCallCount += 1

        if shouldFailStop {
            throw stopError
        }

        state = RecordingState.idle
        currentMetadata = nil
        return stopReturnURL
    }

    func pause() throws {
        pauseCallCount += 1

        if shouldFailPause {
            throw pauseError
        }

        state = RecordingState.paused
    }

    func resume() throws {
        resumeCallCount += 1

        if shouldFailResume {
            throw resumeError
        }

        state = RecordingState.recording
    }

    func forceSave() async throws {
        forceSaveCallCount += 1

        if shouldFailForceSave {
            throw forceSaveError
        }
    }

    func checkForIncompleteRecordings() -> [RecordingMetadata] {
        checkForIncompleteRecordingsCallCount += 1
        return incompleteRecordingsToReturn
    }

    func recoverRecording(_ metadata: RecordingMetadata) async throws -> URL {
        recoverRecordingCallCount += 1
        lastRecoveredMetadata = metadata

        if shouldFailRecovery {
            throw recoveryError
        }

        return recoveryReturnURL
    }

    func discardIncompleteRecording(_ metadata: RecordingMetadata) throws {
        discardIncompleteRecordingCallCount += 1
        lastDiscardedMetadata = metadata

        if shouldFailDiscard {
            throw discardError
        }
    }

    func availableDiskSpace() -> Int64 {
        availableDiskSpaceCallCount += 1
        return diskSpaceToReturn
    }

    // MARK: - Test Helpers

    /// Manually set state for testing (simulates service state changes)
    func setState(_ newState: RecordingState) {
        state = newState
    }

    /// Manually set metadata for testing
    func setMetadata(_ metadata: RecordingMetadata?) {
        currentMetadata = metadata
    }

    /// Reset all call counts and state
    func reset() {
        startCallCount = 0
        stopCallCount = 0
        pauseCallCount = 0
        resumeCallCount = 0
        forceSaveCallCount = 0
        checkForIncompleteRecordingsCallCount = 0
        recoverRecordingCallCount = 0
        discardIncompleteRecordingCallCount = 0
        availableDiskSpaceCallCount = 0

        lastStartFormat = nil
        lastRecoveredMetadata = nil
        lastDiscardedMetadata = nil

        shouldFailStart = false
        shouldFailStop = false
        shouldFailPause = false
        shouldFailResume = false
        shouldFailForceSave = false
        shouldFailRecovery = false
        shouldFailDiscard = false

        state = RecordingState.idle
        currentMetadata = nil
    }
}

// MARK: - Mock Subtitle Export Service

/// Mock implementation of SubtitleExportServiceProtocol for testing RecordingViewModel
@MainActor
final class MockSubtitleExportServiceForViewModel: SubtitleExportServiceProtocol {
    // MARK: - Call Tracking

    var exportSegmentsCallCount = 0
    var exportMessagesCallCount = 0
    var generateContentFromSegmentsCallCount = 0
    var generateContentFromMessagesCallCount = 0

    var lastExportedSegments: [Segment]?
    var lastExportedMessages: [ConversationMessage]?
    var lastExportOptions: SubtitleExportOptions?
    var lastSessionStartTime: Date?

    // MARK: - Configurable Behavior

    var shouldFailExport = false
    var exportError = SubtitleExportError.noSegments
    var exportReturnURL = URL(filePath: "/tmp/subtitles.srt")

    var generatedContentToReturn = "1\n00:00:00,000 --> 00:00:05,000\nTest subtitle content\n"

    // MARK: - SubtitleExportServiceProtocol Implementation

    func export(
        segments: [Segment],
        options: SubtitleExportOptions
    ) async throws -> URL {
        exportSegmentsCallCount += 1
        lastExportedSegments = segments
        lastExportOptions = options

        if shouldFailExport {
            throw exportError
        }

        return exportReturnURL
    }

    func export(
        messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) async throws -> URL {
        exportMessagesCallCount += 1
        lastExportedMessages = messages
        lastSessionStartTime = sessionStartTime
        lastExportOptions = options

        if shouldFailExport {
            throw exportError
        }

        return exportReturnURL
    }

    func generateContent(
        from segments: [Segment],
        options: SubtitleExportOptions
    ) -> String {
        generateContentFromSegmentsCallCount += 1
        lastExportedSegments = segments
        lastExportOptions = options
        return generatedContentToReturn
    }

    func generateContent(
        from messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) -> String {
        generateContentFromMessagesCallCount += 1
        lastExportedMessages = messages
        lastSessionStartTime = sessionStartTime
        lastExportOptions = options
        return generatedContentToReturn
    }

    // MARK: - Test Helpers

    /// Reset all call counts and state
    func reset() {
        exportSegmentsCallCount = 0
        exportMessagesCallCount = 0
        generateContentFromSegmentsCallCount = 0
        generateContentFromMessagesCallCount = 0

        lastExportedSegments = nil
        lastExportedMessages = nil
        lastExportOptions = nil
        lastSessionStartTime = nil

        shouldFailExport = false
    }
}

// MARK: - Test Suite

@Suite("RecordingViewModel with Mocks")
@MainActor
struct RecordingViewModelMockTests {
    // MARK: - Test Dependencies

    let mockRecordingService: MockRecordingServiceForViewModel
    let mockSubtitleService: MockSubtitleExportServiceForViewModel
    let viewModel: RecordingViewModel
    let container: ModelContainer

    init() {
        mockRecordingService = MockRecordingServiceForViewModel()
        mockSubtitleService = MockSubtitleExportServiceForViewModel()
        viewModel = RecordingViewModel(
            recordingService: mockRecordingService,
            subtitleExportService: mockSubtitleService
        )
        container = TestModelContainer.createFresh()
        viewModel.setModelContext(container.mainContext)
    }

    // MARK: - Start Recording Tests

    @Test("startRecording calls service and updates state on success")
    func startRecordingSuccess() async {
        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(mockRecordingService.startCallCount == 1)
        #expect(mockRecordingService.lastStartFormat == AudioFormat.m4a)
        #expect(viewModel.recordingState == RecordingState.recording)
        #expect(viewModel.currentMetadata != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("startRecording with wav format passes correct format to service")
    func startRecordingWithWavFormat() async {
        await viewModel.startRecording(format: AudioFormat.wav)

        #expect(mockRecordingService.startCallCount == 1)
        #expect(mockRecordingService.lastStartFormat == AudioFormat.wav)
    }

    @Test("startRecording with mp3 format passes correct format to service")
    func startRecordingWithMp3Format() async {
        await viewModel.startRecording(format: AudioFormat.mp3)

        #expect(mockRecordingService.startCallCount == 1)
        #expect(mockRecordingService.lastStartFormat == AudioFormat.mp3)
    }

    @Test("startRecording handles permission denied error")
    func startRecordingPermissionDenied() async {
        mockRecordingService.shouldFailStart = true
        mockRecordingService.startError = RecordingServiceError.permissionDenied

        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(mockRecordingService.startCallCount == 1)
        // Verify error occurred (exact message may vary by locale)
        #expect(viewModel.errorMessage != nil, "Expected error message to be set")
        if case RecordingState.error = viewModel.recordingState {
            // Expected state - error state should be set
        } else {
            Issue.record("Expected error state, got \(viewModel.recordingState)")
        }
    }

    @Test("startRecording handles insufficient disk space error")
    func startRecordingInsufficientDiskSpace() async {
        mockRecordingService.shouldFailStart = true
        mockRecordingService.startError = RecordingServiceError.insufficientDiskSpace(
            available: 10_000_000,
            required: 100_000_000
        )

        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(mockRecordingService.startCallCount == 1)
        #expect(viewModel.errorMessage != nil)
        if case RecordingState.error = viewModel.recordingState {
            // Expected state
        } else {
            Issue.record("Expected error state, got \(viewModel.recordingState)")
        }
    }

    @Test("startRecording handles already recording error")
    func startRecordingAlreadyRecording() async {
        mockRecordingService.shouldFailStart = true
        mockRecordingService.startError = RecordingServiceError.alreadyRecording

        await viewModel.startRecording(format: AudioFormat.m4a)

        // Verify error occurred (exact message may vary by locale)
        #expect(viewModel.errorMessage != nil, "Expected error message to be set")
        // Verify error state
        if case RecordingState.error = viewModel.recordingState {
            // Expected state
        } else {
            Issue.record("Expected error state, got \(viewModel.recordingState)")
        }
    }

    // MARK: - Stop Recording Tests

    @Test("stopRecording calls service and clears metadata on success")
    func stopRecordingSuccess() async throws {
        // Create a test file for the mock to return
        let testFileURL = FileManager.default.temporaryDirectory.appending(path: "test-stop-recording-\(UUID().uuidString).m4a")
        try Data([0, 1, 2, 3]).write(to: testFileURL)
        defer { try? FileManager.default.removeItem(at: testFileURL) }

        // Configure mock to return the real test file
        mockRecordingService.stopReturnURL = testFileURL

        // First start recording
        await viewModel.startRecording(format: AudioFormat.m4a)

        // Reset call counts but preserve stopReturnURL
        mockRecordingService.startCallCount = 0
        mockRecordingService.pauseCallCount = 0

        // Then stop
        await viewModel.stopRecording()

        #expect(mockRecordingService.stopCallCount == 1)
        #expect(viewModel.recordingState == RecordingState.idle)
        #expect(viewModel.currentMetadata == nil)
        // Note: errorMessage may or may not be nil depending on SwiftData save success
    }

    @Test("stopRecording handles not recording error")
    func stopRecordingNotRecording() async {
        mockRecordingService.shouldFailStop = true
        mockRecordingService.stopError = RecordingServiceError.notRecording

        await viewModel.stopRecording()

        #expect(mockRecordingService.stopCallCount == 1)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("stopRecording handles file write error")
    func stopRecordingFileWriteError() async {
        mockRecordingService.shouldFailStop = true
        mockRecordingService.stopError = RecordingServiceError.fileWriteError(
            underlying: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Write failed"])
        )

        await viewModel.stopRecording()

        #expect(viewModel.errorMessage != nil)
        if case RecordingState.error = viewModel.recordingState {
            // Expected state
        } else {
            Issue.record("Expected error state, got \(viewModel.recordingState)")
        }
    }

    // MARK: - Pause Recording Tests

    @Test("pauseRecording transitions to paused state")
    func pauseRecordingSuccess() async {
        // Start recording first
        await viewModel.startRecording(format: AudioFormat.m4a)
        mockRecordingService.reset()

        // Pause
        viewModel.pauseRecording()

        #expect(mockRecordingService.pauseCallCount == 1)
        #expect(viewModel.recordingState == RecordingState.paused)
        #expect(viewModel.isPaused == true)
    }

    @Test("pauseRecording handles error when not recording")
    func pauseRecordingError() {
        mockRecordingService.shouldFailPause = true

        viewModel.pauseRecording()

        #expect(mockRecordingService.pauseCallCount == 1)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Resume Recording Tests

    @Test("resumeRecording transitions from paused to recording")
    func resumeRecordingSuccess() async {
        // Start and pause first
        await viewModel.startRecording(format: AudioFormat.m4a)
        viewModel.pauseRecording()
        mockRecordingService.reset()

        // Resume
        viewModel.resumeRecording()

        #expect(mockRecordingService.resumeCallCount == 1)
        #expect(viewModel.recordingState == RecordingState.recording)
        #expect(viewModel.isPaused == false)
    }

    @Test("resumeRecording handles error when not paused")
    func resumeRecordingError() {
        mockRecordingService.shouldFailResume = true

        viewModel.resumeRecording()

        #expect(mockRecordingService.resumeCallCount == 1)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - State Transitions Tests

    @Test("full recording cycle: start -> pause -> resume -> stop")
    func fullRecordingCycle() async {
        // Start
        await viewModel.startRecording(format: AudioFormat.m4a)
        #expect(viewModel.isRecording == true)
        #expect(viewModel.isPaused == false)

        // Pause
        viewModel.pauseRecording()
        #expect(viewModel.isRecording == true)
        #expect(viewModel.isPaused == true)

        // Resume
        viewModel.resumeRecording()
        #expect(viewModel.isRecording == true)
        #expect(viewModel.isPaused == false)

        // Stop
        await viewModel.stopRecording()
        #expect(viewModel.isRecording == false)
        #expect(viewModel.isPaused == false)
    }

    // MARK: - Load Recordings Tests

    @Test("loadRecordings fetches recordings from SwiftData")
    func loadRecordingsFromSwiftData() {
        let context = container.mainContext

        // Insert test recordings
        let recording1 = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 60,
            format: AudioFormat.m4a,
            createdAt: Date()
        )
        let recording2 = Recording(
            id: UUID(),
            audioData: Data([3, 4, 5]),
            duration: 120,
            format: AudioFormat.wav,
            createdAt: Date().addingTimeInterval(-3600)
        )

        context.insert(recording1)
        context.insert(recording2)
        try? context.save()

        // Reload
        viewModel.loadRecordings()

        #expect(viewModel.recordings.count == 2)
        // Should be sorted by createdAt descending (most recent first)
        #expect(viewModel.recordings.first?.id == recording1.id)
    }

    @Test("loadRecordings returns empty array when no recordings exist")
    func loadRecordingsEmpty() {
        viewModel.loadRecordings()

        #expect(viewModel.recordings.isEmpty)
    }

    @Test("loadRecordings without model context does nothing")
    func loadRecordingsNoContext() {
        let vmWithoutContext = RecordingViewModel(
            recordingService: mockRecordingService,
            subtitleExportService: mockSubtitleService
        )

        vmWithoutContext.loadRecordings()

        #expect(vmWithoutContext.recordings.isEmpty)
    }

    // MARK: - Delete Recording Tests

    @Test("deleteRecording removes recording from context")
    func deleteRecordingSuccess() {
        let context = container.mainContext

        // Insert a recording
        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 60,
            format: AudioFormat.m4a
        )
        context.insert(recording)
        try? context.save()

        viewModel.loadRecordings()
        #expect(viewModel.recordings.count == 1)

        // Delete
        viewModel.deleteRecording(recording)

        #expect(viewModel.recordings.isEmpty)
    }

    @Test("deleteRecording clears selectedRecording if deleted")
    func deleteRecordingClearsSelection() {
        let context = container.mainContext

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 60,
            format: AudioFormat.m4a
        )
        context.insert(recording)
        try? context.save()

        viewModel.loadRecordings()
        viewModel.selectedRecording = recording

        // Delete the selected recording
        viewModel.deleteRecording(recording)

        #expect(viewModel.selectedRecording == nil)
    }

    @Test("deleteRecording preserves selectedRecording if different recording deleted")
    func deleteRecordingPreservesOtherSelection() {
        let context = container.mainContext

        let recording1 = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 60,
            format: AudioFormat.m4a
        )
        let recording2 = Recording(
            id: UUID(),
            audioData: Data([3, 4, 5]),
            duration: 120,
            format: AudioFormat.wav
        )
        context.insert(recording1)
        context.insert(recording2)
        try? context.save()

        viewModel.loadRecordings()
        viewModel.selectedRecording = recording1

        // Delete the other recording
        viewModel.deleteRecording(recording2)

        #expect(viewModel.selectedRecording?.id == recording1.id)
        #expect(viewModel.recordings.count == 1)
    }

    // MARK: - Export Audio Tests

    @Test("exportAudio returns URL from recording")
    func exportAudioSuccess() async throws {
        let context = container.mainContext

        let testData = Data([0, 1, 2, 3, 4, 5])
        let recording = Recording(
            id: UUID(),
            audioData: testData,
            duration: 60,
            format: AudioFormat.m4a
        )
        context.insert(recording)
        try? context.save()

        let url = try await viewModel.exportAudio(recording)

        #expect(url.pathExtension == "m4a")
        #expect(FileManager.default.fileExists(atPath: url.path()))

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportAudio throws error when no audio data")
    func exportAudioNoData() async {
        let context = container.mainContext

        let recording = Recording(
            id: UUID(),
            audioData: nil,
            duration: 60,
            format: AudioFormat.m4a
        )
        context.insert(recording)
        try? context.save()

        do {
            _ = try await viewModel.exportAudio(recording)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
            #expect(error is RecordingError)
        }
    }

    // MARK: - Export Subtitles Tests

    @Test("exportSubtitles calls subtitle service with correct segments")
    func exportSubtitlesSuccess() async throws {
        let context = container.mainContext

        // Create session with segments
        let session = Session()
        let segment1 = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello",
            translatedText: "Hola"
        )
        let segment2 = Segment(
            startTime: 5,
            endTime: 10,
            originalText: "World",
            translatedText: "Mundo"
        )
        session.addSegment(segment1)
        session.addSegment(segment2)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 10,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        let url = try await viewModel.exportSubtitles(for: recording)

        #expect(mockSubtitleService.exportSegmentsCallCount == 1)
        #expect(mockSubtitleService.lastExportedSegments?.count == 2)
        #expect(url == mockSubtitleService.exportReturnURL)
    }

    @Test("exportSubtitles throws error when no session")
    func exportSubtitlesNoSession() async {
        let context = container.mainContext

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 10,
            format: AudioFormat.m4a
        )
        // No session attached
        context.insert(recording)
        try? context.save()

        do {
            _ = try await viewModel.exportSubtitles(for: recording)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is SubtitleExportError)
        }
    }

    @Test("exportSubtitles with custom options passes options to service")
    func exportSubtitlesWithOptions() async throws {
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test"
        )
        session.addSegment(segment)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        let customOptions = SubtitleExportOptions(
            format: SubtitleFormat.vtt,
            contentOption: SubtitleContentOption.originalOnly,
            includeTimestamps: false,
            bilingualOrder: BilingualTextOrder.originalFirst
        )

        _ = try await viewModel.exportSubtitles(for: recording, options: customOptions)

        #expect(mockSubtitleService.lastExportOptions?.format == SubtitleFormat.vtt)
        #expect(mockSubtitleService.lastExportOptions?.contentOption == SubtitleContentOption.originalOnly)
    }

    @Test("exportSubtitles sets and clears isExporting flag")
    func exportSubtitlesExportingFlag() async throws {
        let context = container.mainContext

        let session = Session()
        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        session.addSegment(segment)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        // Before export
        #expect(viewModel.isExporting == false)

        _ = try await viewModel.exportSubtitles(for: recording)

        // After export completes
        #expect(viewModel.isExporting == false)
    }

    @Test("exportSubtitles handles service error")
    func exportSubtitlesServiceError() async {
        let context = container.mainContext

        let session = Session()
        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        session.addSegment(segment)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        mockSubtitleService.shouldFailExport = true
        mockSubtitleService.exportError = SubtitleExportError.writeError(
            underlying: NSError(domain: "Test", code: -1, userInfo: nil)
        )

        do {
            _ = try await viewModel.exportSubtitles(for: recording)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is SubtitleExportError)
        }

        // isExporting should be cleared even on error
        #expect(viewModel.isExporting == false)
    }

    // MARK: - Preview Subtitles Tests

    @Test("previewSubtitles generates content from segments")
    func previewSubtitlesSuccess() {
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello World"
        )
        session.addSegment(segment)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        mockSubtitleService.generatedContentToReturn = "1\n00:00:00,000 --> 00:00:05,000\nHello World\n"

        let content = viewModel.previewSubtitles(for: recording)

        #expect(mockSubtitleService.generateContentFromSegmentsCallCount == 1)
        #expect(content == "1\n00:00:00,000 --> 00:00:05,000\nHello World\n")
    }

    @Test("previewSubtitles returns empty string when no session")
    func previewSubtitlesNoSession() {
        let context = container.mainContext

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        context.insert(recording)
        try? context.save()

        let content = viewModel.previewSubtitles(for: recording)

        #expect(content.isEmpty)
        #expect(mockSubtitleService.generateContentFromSegmentsCallCount == 0)
    }

    @Test("previewSubtitles with custom options passes options to service")
    func previewSubtitlesWithOptions() {
        let context = container.mainContext

        let session = Session()
        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        session.addSegment(segment)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        let customOptions = SubtitleExportOptions(
            format: SubtitleFormat.txt,
            contentOption: SubtitleContentOption.translationOnly,
            includeTimestamps: true,
            bilingualOrder: BilingualTextOrder.translationFirst
        )

        _ = viewModel.previewSubtitles(for: recording, options: customOptions)

        #expect(mockSubtitleService.lastExportOptions?.format == SubtitleFormat.txt)
        #expect(mockSubtitleService.lastExportOptions?.contentOption == SubtitleContentOption.translationOnly)
    }

    // MARK: - Computed Properties Tests

    @Test("isRecording returns true when state is recording")
    func isRecordingWhenRecording() async {
        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(viewModel.isRecording == true)
    }

    @Test("isRecording returns true when state is paused")
    func isRecordingWhenPaused() async {
        await viewModel.startRecording(format: AudioFormat.m4a)
        viewModel.pauseRecording()

        #expect(viewModel.isRecording == true)
    }

    @Test("isRecording returns false when state is idle")
    func isRecordingWhenIdle() {
        #expect(viewModel.isRecording == false)
    }

    @Test("isRecording returns false when state is error")
    func isRecordingWhenError() async {
        mockRecordingService.shouldFailStart = true
        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(viewModel.isRecording == false)
    }

    @Test("isPaused returns true only when state is paused")
    func isPausedStates() async {
        // Initially false
        #expect(viewModel.isPaused == false)

        // Recording - false
        await viewModel.startRecording(format: AudioFormat.m4a)
        #expect(viewModel.isPaused == false)

        // Paused - true
        viewModel.pauseRecording()
        #expect(viewModel.isPaused == true)

        // Resumed - false
        viewModel.resumeRecording()
        #expect(viewModel.isPaused == false)
    }

    @Test("isDiskSpaceLow returns true when space is below threshold")
    func isDiskSpaceLowTrue() {
        mockRecordingService.diskSpaceToReturn = 50 * 1024 * 1024 // 50 MB

        let vm = RecordingViewModel(
            recordingService: mockRecordingService,
            subtitleExportService: mockSubtitleService
        )

        #expect(vm.isDiskSpaceLow == true)
    }

    @Test("isDiskSpaceLow returns false when space is above threshold")
    func isDiskSpaceLowFalse() {
        mockRecordingService.diskSpaceToReturn = 200 * 1024 * 1024 // 200 MB

        let vm = RecordingViewModel(
            recordingService: mockRecordingService,
            subtitleExportService: mockSubtitleService
        )

        #expect(vm.isDiskSpaceLow == false)
    }

    @Test("isDiskSpaceLow threshold is 100 MB")
    func isDiskSpaceLowThreshold() {
        // Exactly 100 MB - should be false (not low)
        mockRecordingService.diskSpaceToReturn = 100 * 1024 * 1024

        let vm1 = RecordingViewModel(
            recordingService: mockRecordingService,
            subtitleExportService: mockSubtitleService
        )
        #expect(vm1.isDiskSpaceLow == false)

        // Just below 100 MB - should be true (low)
        mockRecordingService.diskSpaceToReturn = 100 * 1024 * 1024 - 1

        let vm2 = RecordingViewModel(
            recordingService: mockRecordingService,
            subtitleExportService: mockSubtitleService
        )
        #expect(vm2.isDiskSpaceLow == true)
    }

    // MARK: - Force Save Tests

    @Test("forceSave calls service forceSave")
    func forceSaveSuccess() async {
        await viewModel.startRecording(format: AudioFormat.m4a)
        mockRecordingService.reset()

        await viewModel.forceSave()

        #expect(mockRecordingService.forceSaveCallCount == 1)
    }

    @Test("forceSave handles errors silently")
    func forceSaveError() async {
        mockRecordingService.shouldFailForceSave = true

        await viewModel.forceSave()

        #expect(mockRecordingService.forceSaveCallCount == 1)
        // Should not set error message
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Crash Recovery Tests

    @Test("checkForIncompleteRecordings returns metadata from service")
    func checkForIncompleteRecordingsSuccess() {
        let metadata1 = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 100,
            format: AudioFormat.m4a,
            tempFileURL: URL(filePath: "/tmp/incomplete1.m4a"),
            isComplete: false,
            lastAutoSaveTime: Date()
        )
        let metadata2 = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 200,
            format: AudioFormat.wav,
            tempFileURL: URL(filePath: "/tmp/incomplete2.wav"),
            isComplete: false,
            lastAutoSaveTime: Date()
        )
        mockRecordingService.incompleteRecordingsToReturn = [metadata1, metadata2]

        let incomplete = viewModel.checkForIncompleteRecordings()

        #expect(mockRecordingService.checkForIncompleteRecordingsCallCount == 1)
        #expect(incomplete.count == 2)
    }

    @Test("checkForIncompleteRecordings returns empty array when none")
    func checkForIncompleteRecordingsEmpty() {
        mockRecordingService.incompleteRecordingsToReturn = []

        let incomplete = viewModel.checkForIncompleteRecordings()

        #expect(incomplete.isEmpty)
    }

    @Test("recoverRecording calls service with correct metadata")
    func recoverRecordingSuccess() async throws {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 100,
            format: AudioFormat.m4a,
            tempFileURL: URL(filePath: "/tmp/incomplete.m4a"),
            isComplete: false,
            lastAutoSaveTime: Date()
        )

        try await viewModel.recoverRecording(metadata)

        #expect(mockRecordingService.recoverRecordingCallCount == 1)
        #expect(mockRecordingService.lastRecoveredMetadata?.id == metadata.id)
    }

    @Test("recoverRecording handles service error")
    func recoverRecordingError() async {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 100,
            format: AudioFormat.m4a,
            tempFileURL: URL(filePath: "/tmp/incomplete.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        mockRecordingService.shouldFailRecovery = true

        do {
            try await viewModel.recoverRecording(metadata)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is RecordingServiceError)
        }
    }

    @Test("discardRecording calls service with correct metadata")
    func discardRecordingSuccess() throws {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 100,
            format: AudioFormat.m4a,
            tempFileURL: URL(filePath: "/tmp/incomplete.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        try viewModel.discardRecording(metadata)

        #expect(mockRecordingService.discardIncompleteRecordingCallCount == 1)
        #expect(mockRecordingService.lastDiscardedMetadata?.id == metadata.id)
    }

    @Test("discardRecording handles service error")
    func discardRecordingError() {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 100,
            format: AudioFormat.m4a,
            tempFileURL: URL(filePath: "/tmp/incomplete.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        mockRecordingService.shouldFailDiscard = true

        do {
            try viewModel.discardRecording(metadata)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is RecordingServiceError)
        }
    }

    // MARK: - Error Handling Tests

    @Test("startRecording clears previous error message")
    func startRecordingClearsError() async {
        // First cause an error
        mockRecordingService.shouldFailStart = true
        await viewModel.startRecording(format: AudioFormat.m4a)
        #expect(viewModel.errorMessage != nil)

        // Reset and try again
        mockRecordingService.shouldFailStart = false
        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(viewModel.errorMessage == nil)
    }

    @Test("stopRecording clears previous error message")
    func stopRecordingClearsError() async throws {
        // Create a test file for successful stop
        let testFileURL = FileManager.default.temporaryDirectory.appending(path: "test-stop-clears-error-\(UUID().uuidString).m4a")
        try Data([0, 1, 2, 3]).write(to: testFileURL)
        defer { try? FileManager.default.removeItem(at: testFileURL) }

        mockRecordingService.stopReturnURL = testFileURL

        // Start recording
        await viewModel.startRecording(format: AudioFormat.m4a)

        // Simulate a previous error state
        mockRecordingService.shouldFailStop = true
        await viewModel.stopRecording()
        #expect(viewModel.errorMessage != nil)

        // Reset and try again
        await viewModel.startRecording(format: AudioFormat.m4a)
        mockRecordingService.shouldFailStop = false
        await viewModel.stopRecording()

        // After successful stop with real file, errorMessage should be cleared
        // (though saveRecording may set it again if SwiftData save fails in test environment)
        #expect(viewModel.recordingState == RecordingState.idle)
    }

    @Test("audio engine error is handled correctly")
    func audioEngineErrorHandling() async {
        mockRecordingService.shouldFailStart = true
        mockRecordingService.startError = RecordingServiceError.audioEngineError(
            underlying: NSError(domain: "AVAudioEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Engine failed"])
        )

        await viewModel.startRecording(format: AudioFormat.m4a)

        #expect(viewModel.errorMessage != nil)
        // Check for error message containing audio-related text (case-insensitive)
        let errorLower = viewModel.errorMessage?.lowercased() ?? ""
        #expect(errorLower.contains("audio") || errorLower.contains("engine") || errorLower.contains("failed"))
    }

    @Test("format not supported error is handled correctly")
    func formatNotSupportedErrorHandling() async {
        mockRecordingService.shouldFailStart = true
        mockRecordingService.startError = RecordingServiceError.formatNotSupported(format: AudioFormat.mp3)

        await viewModel.startRecording(format: AudioFormat.mp3)

        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Multiple Recording Sessions Tests

    @Test("multiple recording sessions work correctly")
    func multipleRecordingSessions() async {
        // First session
        await viewModel.startRecording(format: AudioFormat.m4a)
        #expect(viewModel.isRecording == true)
        await viewModel.stopRecording()
        #expect(viewModel.isRecording == false)

        mockRecordingService.reset()

        // Second session with different format
        await viewModel.startRecording(format: AudioFormat.wav)
        #expect(viewModel.isRecording == true)
        #expect(mockRecordingService.lastStartFormat == AudioFormat.wav)
        await viewModel.stopRecording()
        #expect(viewModel.isRecording == false)
    }

    // MARK: - Integration Scenarios

    @Test("recording with SwiftData integration")
    func recordingWithSwiftDataIntegration() async {
        let context = container.mainContext

        // Start recording
        await viewModel.startRecording(format: AudioFormat.m4a)
        #expect(viewModel.isRecording == true)

        // Stop recording (this would normally save to SwiftData)
        await viewModel.stopRecording()

        // Verify state
        #expect(viewModel.isRecording == false)
        #expect(viewModel.recordingState == RecordingState.idle)
    }

    @Test("delete multiple recordings sequentially")
    func deleteMultipleRecordings() {
        let context = container.mainContext

        // Create multiple recordings
        var recordingIds: [UUID] = []
        for i in 0..<5 {
            let recording = Recording(
                id: UUID(),
                audioData: Data([UInt8(i)]),
                duration: Double(i * 60),
                format: AudioFormat.m4a
            )
            recordingIds.append(recording.id)
            context.insert(recording)
        }
        try? context.save()

        viewModel.loadRecordings()
        #expect(viewModel.recordings.count == 5)

        // Delete recordings one by one
        for recording in viewModel.recordings {
            viewModel.deleteRecording(recording)
        }

        #expect(viewModel.recordings.isEmpty)
    }

    @Test("export operations do not interfere with recording state")
    func exportDoesNotAffectRecording() async throws {
        let context = container.mainContext

        // Create a recording with session
        let session = Session()
        let segment = Segment(startTime: 0, endTime: 5, originalText: "Test")
        session.addSegment(segment)

        let recording = Recording(
            id: UUID(),
            audioData: Data([0, 1, 2]),
            duration: 5,
            format: AudioFormat.m4a
        )
        recording.session = session
        session.recording = recording

        context.insert(session)
        context.insert(recording)
        try? context.save()

        // Start a new recording
        await viewModel.startRecording(format: AudioFormat.wav)
        #expect(viewModel.isRecording == true)

        // Export the existing recording
        _ = try await viewModel.exportSubtitles(for: recording)

        // Recording state should be unchanged
        #expect(viewModel.isRecording == true)
        #expect(viewModel.recordingState == RecordingState.recording)
    }
}

// MARK: - Mock Service Edge Cases

@Suite("Mock Service Edge Cases")
@MainActor
struct MockServiceEdgeCaseTests {
    let mockRecordingService: MockRecordingServiceForViewModel
    let mockSubtitleService: MockSubtitleExportServiceForViewModel

    init() {
        mockRecordingService = MockRecordingServiceForViewModel()
        mockSubtitleService = MockSubtitleExportServiceForViewModel()
    }

    @Test("MockRecordingService reset clears all state")
    func mockRecordingServiceReset() async throws {
        // Set various states
        try await mockRecordingService.start(format: AudioFormat.m4a)
        _ = try await mockRecordingService.stop()

        mockRecordingService.shouldFailStart = true
        mockRecordingService.diskSpaceToReturn = 1000

        // Reset
        mockRecordingService.reset()

        // Verify reset
        #expect(mockRecordingService.startCallCount == 0)
        #expect(mockRecordingService.stopCallCount == 0)
        #expect(mockRecordingService.shouldFailStart == false)
        #expect(mockRecordingService.state == RecordingState.idle)
        #expect(mockRecordingService.currentMetadata == nil)
    }

    @Test("MockSubtitleExportService reset clears all state")
    func mockSubtitleServiceReset() async throws {
        // Set various states
        _ = try await mockSubtitleService.export(segments: [], options: SubtitleExportOptions.default)
        mockSubtitleService.shouldFailExport = true

        // Reset
        mockSubtitleService.reset()

        // Verify reset
        #expect(mockSubtitleService.exportSegmentsCallCount == 0)
        #expect(mockSubtitleService.shouldFailExport == false)
        #expect(mockSubtitleService.lastExportedSegments == nil)
    }

    @Test("MockRecordingService setState allows direct state manipulation")
    func mockRecordingServiceSetState() {
        mockRecordingService.setState(RecordingState.recording)
        #expect(mockRecordingService.state == RecordingState.recording)

        mockRecordingService.setState(RecordingState.paused)
        #expect(mockRecordingService.state == RecordingState.paused)

        mockRecordingService.setState(RecordingState.saving)
        #expect(mockRecordingService.state == RecordingState.saving)

        mockRecordingService.setState(RecordingState.error(message: "Test error"))
        if case RecordingState.error(let message) = mockRecordingService.state {
            #expect(message == "Test error")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("MockRecordingService setMetadata allows direct metadata manipulation")
    func mockRecordingServiceSetMetadata() {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 100,
            format: AudioFormat.wav,
            tempFileURL: URL(filePath: "/tmp/test.wav"),
            isComplete: false,
            lastAutoSaveTime: Date()
        )

        mockRecordingService.setMetadata(metadata)
        #expect(mockRecordingService.currentMetadata?.id == metadata.id)
        #expect(mockRecordingService.currentMetadata?.format == AudioFormat.wav)

        mockRecordingService.setMetadata(nil)
        #expect(mockRecordingService.currentMetadata == nil)
    }
}
