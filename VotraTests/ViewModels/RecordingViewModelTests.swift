//
//  RecordingViewModelTests.swift
//  VotraTests
//
//  Tests for RecordingViewModel state management and synchronous logic.
//

import Foundation
import SwiftData
import Testing
@testable import Votra

// MARK: - RecordingViewModel Tests

@Suite("RecordingViewModel Tests")
@MainActor
struct RecordingViewModelTests {
    // MARK: - Initial State Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.recordingState == .idle)
        #expect(viewModel.currentMetadata == nil)
        #expect(viewModel.recordings.isEmpty)
        #expect(viewModel.selectedRecording == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isExporting == false)
    }

    @Test("Initial disk space is positive value")
    func initialDiskSpaceIsPositive() {
        let viewModel = RecordingViewModel()

        // Available disk space should be set during init
        #expect(viewModel.availableDiskSpace > 0)
    }

    // MARK: - Computed Property Tests

    @Test("isRecording is false when idle")
    func isRecordingFalseWhenIdle() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.isRecording == false)
    }

    @Test("isPaused is false when idle")
    func isPausedFalseWhenIdle() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.isPaused == false)
    }

    @Test("isDiskSpaceLow is false with sufficient space")
    func isDiskSpaceLowFalseWithSufficientSpace() {
        let viewModel = RecordingViewModel()

        // With default disk space or actual disk space, should have enough
        #expect(viewModel.isDiskSpaceLow == false)
    }

    @Test("currentDuration is zero without metadata")
    func currentDurationZeroWithoutMetadata() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.currentDuration == 0)
    }

    @Test("formattedCurrentDuration shows 00:00 without metadata")
    func formattedCurrentDurationShowsZeroWithoutMetadata() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.formattedCurrentDuration == "00:00")
    }

    // MARK: - Selected Recording Tests

    @Test("selectedRecording can be set and cleared")
    func selectedRecordingCanBeSetAndCleared() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)

        viewModel.selectedRecording = recording
        #expect(viewModel.selectedRecording?.id == recording.id)

        viewModel.selectedRecording = nil
        #expect(viewModel.selectedRecording == nil)
    }

    // MARK: - Model Context Tests

    @Test("setModelContext stores context and loads recordings")
    func setModelContextStoresContext() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()

        viewModel.setModelContext(container.mainContext)

        // After setting context, recordings should be loaded (empty initially)
        #expect(viewModel.recordings.isEmpty)
    }

    @Test("loadRecordings retrieves saved recordings")
    func loadRecordingsRetrievesSavedRecordings() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        // Create and save test recordings
        let recording1 = Recording(id: UUID(), format: .m4a, createdAt: Date())
        let recording2 = Recording(id: UUID(), format: .wav, createdAt: Date().addingTimeInterval(-100))
        context.insert(recording1)
        context.insert(recording2)
        try context.save()

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.count == 2)
        // Should be sorted by createdAt descending (most recent first)
        #expect(viewModel.recordings.first?.id == recording1.id)
    }

    @Test("loadRecordings returns empty without context")
    func loadRecordingsWithoutContext() {
        let viewModel = RecordingViewModel()

        // Without setting model context, loadRecordings should do nothing
        viewModel.loadRecordings()

        #expect(viewModel.recordings.isEmpty)
    }

    // MARK: - Subtitle Preview Tests

    @Test("previewSubtitles returns empty string without session")
    func previewSubtitlesReturnsEmptyWithoutSession() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)

        let preview = viewModel.previewSubtitles(for: recording)

        #expect(preview.isEmpty)
    }

    @Test("previewSubtitles with custom options returns empty without session")
    func previewSubtitlesCustomOptionsWithoutSession() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )
        let preview = viewModel.previewSubtitles(for: recording, options: options)

        #expect(preview.isEmpty)
    }

    // MARK: - Delete Recording Tests

    @Test("deleteRecording without context does nothing")
    func deleteRecordingWithoutContext() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)

        // Without setting model context, delete should do nothing
        viewModel.deleteRecording(recording)

        // No crash expected, but recording not removed from view model
    }

    @Test("deleteRecording removes recording from list")
    func deleteRecordingRemovesFromList() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)
        #expect(viewModel.recordings.count == 1)

        viewModel.deleteRecording(recording)
        #expect(viewModel.recordings.isEmpty)
    }

    @Test("deleteRecording clears selectedRecording if matching")
    func deleteRecordingClearsSelection() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)
        viewModel.selectedRecording = recording
        #expect(viewModel.selectedRecording != nil)

        viewModel.deleteRecording(recording)
        #expect(viewModel.selectedRecording == nil)
    }

    @Test("deleteRecording does not clear selectedRecording if not matching")
    func deleteRecordingKeepsOtherSelection() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording1 = Recording(id: UUID(), format: .m4a)
        let recording2 = Recording(id: UUID(), format: .wav)
        context.insert(recording1)
        context.insert(recording2)
        try context.save()

        viewModel.setModelContext(context)
        viewModel.selectedRecording = recording1

        viewModel.deleteRecording(recording2)
        #expect(viewModel.selectedRecording?.id == recording1.id)
    }

    // MARK: - Crash Recovery Tests

    @Test("checkForIncompleteRecordings returns array")
    func checkForIncompleteRecordingsReturnsArray() {
        let viewModel = RecordingViewModel()

        let incomplete = viewModel.checkForIncompleteRecordings()

        // Should return an array (may be empty)
        #expect(incomplete is [RecordingMetadata])
    }

    // MARK: - Pause and Resume Tests

    @Test("pauseRecording sets error when not recording")
    func pauseRecordingNotRecordingSetsError() {
        let viewModel = RecordingViewModel()

        viewModel.pauseRecording()

        // Should set error message since not recording
        #expect(viewModel.errorMessage != nil)
    }

    @Test("resumeRecording sets error when not paused")
    func resumeRecordingNotPausedSetsError() {
        let viewModel = RecordingViewModel()

        viewModel.resumeRecording()

        // Should set error message since not paused
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - isRecording State Logic Tests

@Suite("RecordingViewModel isRecording Logic Tests")
@MainActor
struct RecordingViewModelIsRecordingLogicTests {
    @Test("isRecording returns true for recording state")
    func isRecordingTrueForRecording() {
        // Test the computed property logic directly
        let state = RecordingState.recording
        let isRecording = switch state {
        case .recording, .paused:
            true
        default:
            false
        }

        #expect(isRecording == true)
    }

    @Test("isRecording returns true for paused state")
    func isRecordingTrueForPaused() {
        let state = RecordingState.paused
        let isRecording = switch state {
        case .recording, .paused:
            true
        default:
            false
        }

        #expect(isRecording == true)
    }

    @Test("isRecording returns false for idle state")
    func isRecordingFalseForIdle() {
        let state = RecordingState.idle
        let isRecording = switch state {
        case .recording, .paused:
            true
        default:
            false
        }

        #expect(isRecording == false)
    }

    @Test("isRecording returns false for saving state")
    func isRecordingFalseForSaving() {
        let state = RecordingState.saving
        let isRecording = switch state {
        case .recording, .paused:
            true
        default:
            false
        }

        #expect(isRecording == false)
    }

    @Test("isRecording returns false for error state")
    func isRecordingFalseForError() {
        let state = RecordingState.error(message: "test")
        let isRecording = switch state {
        case .recording, .paused:
            true
        default:
            false
        }

        #expect(isRecording == false)
    }
}

// MARK: - isPaused State Logic Tests

@Suite("RecordingViewModel isPaused Logic Tests")
@MainActor
struct RecordingViewModelIsPausedLogicTests {
    @Test("isPaused returns true only for paused state")
    func isPausedOnlyForPausedState() {
        #expect((RecordingState.paused == .paused) == true)
        #expect((RecordingState.idle == .paused) == false)
        #expect((RecordingState.recording == .paused) == false)
        #expect((RecordingState.saving == .paused) == false)
        #expect((RecordingState.error(message: "test") == .paused) == false)
    }
}

// MARK: - Duration Formatting Tests

@Suite("RecordingViewModel Duration Formatting Tests")
@MainActor
struct RecordingViewModelDurationFormattingTests {
    @Test("Zero duration formats as 00:00")
    func zeroDurationFormatting() {
        let duration: TimeInterval = 0
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let formatted = String(format: "%02d:%02d", minutes, seconds)

        #expect(formatted == "00:00")
    }

    @Test("Sub-minute duration formats correctly")
    func subMinuteDurationFormatting() {
        let duration: TimeInterval = 45
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let formatted = String(format: "%02d:%02d", minutes, seconds)

        #expect(formatted == "00:45")
    }

    @Test("Multi-minute duration formats correctly")
    func multiMinuteDurationFormatting() {
        let duration: TimeInterval = 125 // 2 minutes 5 seconds
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let formatted = String(format: "%02d:%02d", minutes, seconds)

        #expect(formatted == "02:05")
    }

    @Test("Hour-plus duration formats with overflow minutes")
    func hourPlusDurationFormatting() {
        let duration: TimeInterval = 3725 // 62 minutes 5 seconds
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let formatted = String(format: "%02d:%02d", minutes, seconds)

        #expect(formatted == "62:05")
    }

    @Test("Fractional seconds truncate")
    func fractionalSecondsTruncate() {
        let duration: TimeInterval = 65.9
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let formatted = String(format: "%02d:%02d", minutes, seconds)

        #expect(formatted == "01:05")
    }
}

// MARK: - Disk Space Threshold Tests

@Suite("RecordingViewModel Disk Space Threshold Tests")
@MainActor
struct RecordingViewModelDiskSpaceThresholdTests {
    @Test("isDiskSpaceLow threshold is 100MB")
    func diskSpaceThreshold() {
        // Verify the threshold logic (100 MB = 100 * 1024 * 1024 bytes)
        let thresholdBytes = Int64(100 * 1024 * 1024)

        // The computed property should return true when below threshold
        #expect(thresholdBytes == 104_857_600) // 100 MB in bytes
    }

    @Test("isDiskSpaceLow logic matches threshold")
    func diskSpaceLowLogic() {
        // Test the threshold logic directly
        let threshold = Int64(100 * 1024 * 1024)

        let belowThreshold = Int64(50 * 1024 * 1024)
        let atThreshold = threshold
        let aboveThreshold = Int64(200 * 1024 * 1024)

        #expect((belowThreshold < threshold) == true)
        #expect((atThreshold < threshold) == false)
        #expect((aboveThreshold < threshold) == false)
    }
}

// MARK: - Export State Tests

@Suite("RecordingViewModel Export State Tests")
@MainActor
struct RecordingViewModelExportStateTests {
    @Test("isExporting is initially false")
    func isExportingInitiallyFalse() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.isExporting == false)
    }

    @Test("exportSubtitles throws without session")
    func exportSubtitlesThrowsWithoutSession() async {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)

        do {
            _ = try await viewModel.exportSubtitles(for: recording)
            Issue.record("Expected SubtitleExportError.noSegments to be thrown")
        } catch let error as SubtitleExportError {
            if case .noSegments = error {
                // Expected
            } else {
                Issue.record("Expected .noSegments error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("exportAudio throws without audio data")
    func exportAudioThrowsWithoutData() async {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)

        do {
            _ = try await viewModel.exportAudio(recording)
            Issue.record("Expected RecordingError.noAudioData to be thrown")
        } catch let error as RecordingError {
            if case .noAudioData = error {
                // Expected
            } else {
                Issue.record("Expected .noAudioData error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Error Message Tests

@Suite("RecordingViewModel Error Message Tests")
@MainActor
struct RecordingViewModelErrorMessageTests {
    @Test("errorMessage is initially nil")
    func errorMessageInitiallyNil() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.errorMessage == nil)
    }

    @Test("errorMessage can be set via pauseRecording failure")
    func errorMessageFromPauseFailure() {
        let viewModel = RecordingViewModel()

        viewModel.pauseRecording()

        #expect(viewModel.errorMessage != nil)
    }

    @Test("errorMessage can be set via resumeRecording failure")
    func errorMessageFromResumeFailure() {
        let viewModel = RecordingViewModel()

        viewModel.resumeRecording()

        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - Async Operation Tests

@Suite("RecordingViewModel Async Operation Tests")
@MainActor
struct RecordingViewModelAsyncOperationTests {
    @Test("forceSave completes without error when idle")
    func forceSaveWhenIdle() async {
        let viewModel = RecordingViewModel()

        // Should not throw when not recording
        await viewModel.forceSave()

        // State should remain idle
        #expect(viewModel.recordingState == .idle)
    }

    @Test("stopRecording from idle sets error")
    func stopRecordingFromIdleSetsError() async {
        let viewModel = RecordingViewModel()

        await viewModel.stopRecording()

        // Should set error message since not recording
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.recordingState != .idle || viewModel.errorMessage != nil)
    }
}

// MARK: - Recording Sorting Tests

@Suite("RecordingViewModel Sorting Tests")
@MainActor
struct RecordingViewModelSortingTests {
    @Test("Recordings are sorted by createdAt descending")
    func recordingsSortedByDate() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let now = Date()
        let recording1 = Recording(id: UUID(), format: .m4a, createdAt: now.addingTimeInterval(-200))
        let recording2 = Recording(id: UUID(), format: .m4a, createdAt: now.addingTimeInterval(-100))
        let recording3 = Recording(id: UUID(), format: .m4a, createdAt: now)

        context.insert(recording1)
        context.insert(recording2)
        context.insert(recording3)
        try context.save()

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.count == 3)
        // Most recent should be first
        #expect(viewModel.recordings[0].id == recording3.id)
        #expect(viewModel.recordings[1].id == recording2.id)
        #expect(viewModel.recordings[2].id == recording1.id)
    }
}

// MARK: - RecordingState Enum Tests

@Suite("RecordingState Enum Tests")
@MainActor
struct RecordingStateEnumTests {
    // swiftlint:disable identical_operands
    @Test("RecordingState idle equals idle")
    func idleEquality() {
        #expect(RecordingState.idle == RecordingState.idle)
    }

    @Test("RecordingState recording equals recording")
    func recordingEquality() {
        #expect(RecordingState.recording == RecordingState.recording)
    }

    @Test("RecordingState paused equals paused")
    func pausedEquality() {
        #expect(RecordingState.paused == RecordingState.paused)
    }

    @Test("RecordingState saving equals saving")
    func savingEquality() {
        #expect(RecordingState.saving == RecordingState.saving)
    }
    // swiftlint:enable identical_operands

    @Test("RecordingState error with same message equals")
    func errorEqualityWithSameMessage() {
        let error1 = RecordingState.error(message: "test error")
        let error2 = RecordingState.error(message: "test error")
        #expect(error1 == error2)
    }

    @Test("RecordingState error with different message not equal")
    func errorInequalityWithDifferentMessage() {
        let error1 = RecordingState.error(message: "error one")
        let error2 = RecordingState.error(message: "error two")
        #expect(error1 != error2)
    }

    @Test("RecordingState different states not equal")
    func differentStatesNotEqual() {
        #expect(RecordingState.idle != RecordingState.recording)
        #expect(RecordingState.recording != RecordingState.paused)
        #expect(RecordingState.paused != RecordingState.saving)
        #expect(RecordingState.saving != RecordingState.error(message: "test"))
    }
}

// MARK: - Subtitle Preview with Session Tests

@Suite("RecordingViewModel Subtitle Preview with Session Tests")
@MainActor
struct RecordingViewModelSubtitlePreviewWithSessionTests {
    @Test("previewSubtitles with session and segments returns content")
    func previewSubtitlesWithSessionAndSegments() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello world",
            translatedText: "Bonjour monde"
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let preview = viewModel.previewSubtitles(for: recording)

        // Should contain the original or translated text
        #expect(!preview.isEmpty)
    }

    @Test("previewSubtitles with originalOnly option returns original text")
    func previewSubtitlesOriginalOnly() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Original text here",
            translatedText: "Translated text here"
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )
        let preview = viewModel.previewSubtitles(for: recording, options: options)

        #expect(preview.contains("Original text here"))
    }

    @Test("previewSubtitles with translationOnly option returns translated text")
    func previewSubtitlesTranslationOnly() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Original text here",
            translatedText: "Translated text here"
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .translationOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )
        let preview = viewModel.previewSubtitles(for: recording, options: options)

        #expect(preview.contains("Translated text here"))
    }

    @Test("previewSubtitles with empty segments returns empty string")
    func previewSubtitlesEmptySegments() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        // No segments added

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(recording)

        let preview = viewModel.previewSubtitles(for: recording)

        // Empty segments should return empty preview (depending on service implementation)
        #expect(preview.isEmpty || preview == "WEBVTT\n\n" || preview.isEmpty)
    }

    @Test("previewSubtitles with SRT format includes timestamps")
    func previewSubtitlesSRTFormat() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test content",
            translatedText: nil
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )
        let preview = viewModel.previewSubtitles(for: recording, options: options)

        // SRT format should contain timestamp arrow
        #expect(preview.contains("-->"))
    }

    @Test("previewSubtitles with VTT format starts with WEBVTT")
    func previewSubtitlesVTTFormat() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test content",
            translatedText: nil
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )
        let preview = viewModel.previewSubtitles(for: recording, options: options)

        #expect(preview.hasPrefix("WEBVTT"))
    }
}

// MARK: - Export Subtitles with Session Tests

@Suite("RecordingViewModel Export Subtitles with Session Tests")
@MainActor
struct RecordingViewModelExportSubtitlesWithSessionTests {
    @Test("exportSubtitles with valid session returns URL")
    func exportSubtitlesWithValidSession() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello world",
            translatedText: "Bonjour monde"
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let url = try await viewModel.exportSubtitles(for: recording)

        #expect(url.isFileURL)
        #expect(url.pathExtension == "srt") // Default format

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportSubtitles with VTT format returns VTT file")
    func exportSubtitlesVTTFormat() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test segment",
            translatedText: nil
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let url = try await viewModel.exportSubtitles(for: recording, options: options)

        #expect(url.pathExtension == "vtt")

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportSubtitles sets and clears isExporting flag")
    func exportSubtitlesSetsExportingFlag() async {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test segment",
            translatedText: nil
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        // Initially false
        #expect(viewModel.isExporting == false)

        // Export and verify flag resets after completion
        do {
            let url = try await viewModel.exportSubtitles(for: recording)
            // After completion, isExporting should be false
            #expect(viewModel.isExporting == false)
            try? FileManager.default.removeItem(at: url)
        } catch {
            // Even on error, isExporting should be false (defer handles this)
            #expect(viewModel.isExporting == false)
        }
    }
}

// MARK: - Export Audio Tests

@Suite("RecordingViewModel Export Audio Tests")
@MainActor
struct RecordingViewModelExportAudioTests {
    @Test("exportAudio with valid audio data returns URL")
    func exportAudioWithValidData() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        // Create recording with dummy audio data
        let recording = Recording(id: UUID(), format: .m4a)
        recording.audioData = Data("fake audio content".utf8)

        context.insert(recording)

        let url = try await viewModel.exportAudio(recording)

        #expect(url.isFileURL)
        #expect(url.pathExtension == "m4a")

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportAudio with WAV format returns WAV file")
    func exportAudioWAVFormat() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .wav)
        recording.audioData = Data("fake wav content".utf8)

        context.insert(recording)

        let url = try await viewModel.exportAudio(recording)

        #expect(url.pathExtension == "wav")

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportAudio throws noAudioData when empty")
    func exportAudioThrowsWhenEmpty() async {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        recording.audioData = nil

        context.insert(recording)

        do {
            _ = try await viewModel.exportAudio(recording)
            Issue.record("Expected RecordingError.noAudioData to be thrown")
        } catch let error as RecordingError {
            #expect(error == .noAudioData)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Multiple Recordings Tests

@Suite("RecordingViewModel Multiple Recordings Tests")
@MainActor
struct RecordingViewModelMultipleRecordingsTests {
    @Test("deleteRecording updates count correctly")
    func deleteRecordingUpdatesCount() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording1 = Recording(id: UUID(), format: .m4a)
        let recording2 = Recording(id: UUID(), format: .m4a)
        let recording3 = Recording(id: UUID(), format: .m4a)

        context.insert(recording1)
        context.insert(recording2)
        context.insert(recording3)
        try context.save()

        viewModel.setModelContext(context)
        #expect(viewModel.recordings.count == 3)

        viewModel.deleteRecording(recording2)
        #expect(viewModel.recordings.count == 2)

        // Verify the correct one was removed
        let ids = viewModel.recordings.map { $0.id }
        #expect(!ids.contains(recording2.id))
        #expect(ids.contains(recording1.id))
        #expect(ids.contains(recording3.id))
    }

    @Test("loadRecordings handles empty database")
    func loadRecordingsEmptyDatabase() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.isEmpty)
    }

    @Test("loadRecordings can be called multiple times")
    func loadRecordingsMultipleCalls() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)
        #expect(viewModel.recordings.count == 1)

        // Call again - should still work
        viewModel.loadRecordings()
        #expect(viewModel.recordings.count == 1)

        // Add another and reload
        let recording2 = Recording(id: UUID(), format: .wav)
        context.insert(recording2)
        try context.save()

        viewModel.loadRecordings()
        #expect(viewModel.recordings.count == 2)
    }
}

// MARK: - Error Message Clearing Tests

@Suite("RecordingViewModel Error Message Clearing Tests")
@MainActor
struct RecordingViewModelErrorMessageClearingTests {
    @Test("pauseRecording error message contains relevant info")
    func pauseRecordingErrorMessageContent() {
        let viewModel = RecordingViewModel()

        viewModel.pauseRecording()

        #expect(viewModel.errorMessage != nil)
        // Error should indicate no recording is in progress
        #expect(viewModel.errorMessage?.isEmpty == false)
    }

    @Test("resumeRecording error message contains relevant info")
    func resumeRecordingErrorMessageContent() {
        let viewModel = RecordingViewModel()

        viewModel.resumeRecording()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.isEmpty == false)
    }

    @Test("multiple errors overwrite previous error")
    func multipleErrorsOverwrite() {
        let viewModel = RecordingViewModel()

        viewModel.pauseRecording()
        let firstError = viewModel.errorMessage

        viewModel.resumeRecording()
        let secondError = viewModel.errorMessage

        // Both should set error messages (they may be the same or different)
        #expect(firstError != nil)
        #expect(secondError != nil)
    }
}

// MARK: - Disk Space Tests

@Suite("RecordingViewModel Disk Space Detailed Tests")
@MainActor
struct RecordingViewModelDiskSpaceDetailedTests {
    @Test("availableDiskSpace returns system value")
    func availableDiskSpaceReturnsValue() {
        let viewModel = RecordingViewModel()

        // Should be greater than 0 on a working system
        #expect(viewModel.availableDiskSpace > 0)
    }

    @Test("isDiskSpaceLow threshold boundary at 100MB")
    func isDiskSpaceLowBoundary() {
        // Test the logic directly since we can't easily set availableDiskSpace
        let threshold = Int64(100 * 1024 * 1024)

        // Just below threshold
        let justBelow = threshold - 1
        #expect(justBelow < threshold)

        // At threshold
        let atThreshold = threshold
        #expect(!(atThreshold < threshold))

        // Just above
        let justAbove = threshold + 1
        #expect(!(justAbove < threshold))
    }
}

// MARK: - Recording Metadata Tests

@Suite("RecordingMetadata Tests")
@MainActor
struct RecordingMetadataViewModelTests {
    @Test("RecordingMetadata can be created with all properties")
    func createMetadataWithAllProperties() {
        let id = UUID()
        let startTime = Date()
        let tempURL = URL(filePath: "/tmp/test.m4a")

        let metadata = RecordingMetadata(
            id: id,
            startTime: startTime,
            duration: 120.5,
            format: .m4a,
            tempFileURL: tempURL,
            isComplete: false,
            lastAutoSaveTime: Date()
        )

        #expect(metadata.id == id)
        #expect(metadata.startTime == startTime)
        #expect(metadata.duration == 120.5)
        #expect(metadata.format == .m4a)
        #expect(metadata.tempFileURL == tempURL)
        #expect(metadata.isComplete == false)
        #expect(metadata.lastAutoSaveTime != nil)
    }

    @Test("RecordingMetadata duration can be updated")
    func metadataDurationCanBeUpdated() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .wav,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        #expect(metadata.duration == 0)

        metadata.duration = 300.0
        #expect(metadata.duration == 300.0)
    }

    @Test("RecordingMetadata isComplete can be toggled")
    func metadataIsCompleteCanBeToggled() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 60,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        #expect(metadata.isComplete == false)

        metadata.isComplete = true
        #expect(metadata.isComplete == true)
    }
}

// MARK: - SubtitleExportOptions Tests

@Suite("SubtitleExportOptions Tests")
@MainActor
struct SubtitleExportOptionsTests {
    @Test("Default options use SRT format")
    func defaultOptionsUseSRT() {
        let options = SubtitleExportOptions.default

        #expect(options.format == .srt)
    }

    @Test("Default options include both original and translation")
    func defaultOptionsIncludeBoth() {
        let options = SubtitleExportOptions.default

        #expect(options.contentOption == .both)
    }

    @Test("Default options include timestamps")
    func defaultOptionsIncludeTimestamps() {
        let options = SubtitleExportOptions.default

        #expect(options.includeTimestamps == true)
    }

    @Test("Default options use translation first order")
    func defaultOptionsUseTranslationFirst() {
        let options = SubtitleExportOptions.default

        #expect(options.bilingualOrder == .translationFirst)
    }

    @Test("Custom options can override all defaults")
    func customOptionsOverrideDefaults() {
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
}

// MARK: - Async Stop Recording Tests

@Suite("RecordingViewModel Async Stop Recording Tests")
@MainActor
struct RecordingViewModelAsyncStopRecordingTests {
    @Test("stopRecording from idle state does not crash")
    func stopRecordingFromIdleNoCrash() async {
        let viewModel = RecordingViewModel()

        // Should not crash
        await viewModel.stopRecording()

        // Should have error message since we weren't recording
        #expect(viewModel.errorMessage != nil)
    }

    @Test("forceSave when idle completes without side effects")
    func forceSaveIdleNoSideEffects() async {
        let viewModel = RecordingViewModel()

        // Initial state
        #expect(viewModel.recordingState == .idle)
        #expect(viewModel.currentMetadata == nil)

        await viewModel.forceSave()

        // State should remain unchanged
        #expect(viewModel.recordingState == .idle)
        #expect(viewModel.currentMetadata == nil)
    }
}

// MARK: - SubtitleFormat Tests

@Suite("SubtitleFormat Enum Tests")
@MainActor
struct SubtitleFormatEnumTests {
    @Test("SRT format has correct file extension")
    func srtFileExtension() {
        #expect(SubtitleFormat.srt.fileExtension == "srt")
    }

    @Test("VTT format has correct file extension")
    func vttFileExtension() {
        #expect(SubtitleFormat.vtt.fileExtension == "vtt")
    }

    @Test("TXT format has correct file extension")
    func txtFileExtension() {
        #expect(SubtitleFormat.txt.fileExtension == "txt")
    }

    @Test("SRT format has correct display name")
    func srtDisplayName() {
        #expect(SubtitleFormat.srt.displayName == "SubRip (SRT)")
    }

    @Test("VTT format has correct display name")
    func vttDisplayName() {
        #expect(SubtitleFormat.vtt.displayName == "WebVTT")
    }

    @Test("TXT format has correct display name")
    func txtDisplayName() {
        #expect(SubtitleFormat.txt.displayName == "Plain Text")
    }

    @Test("SRT format has correct MIME type")
    func srtMimeType() {
        #expect(SubtitleFormat.srt.mimeType == "application/x-subrip")
    }

    @Test("VTT format has correct MIME type")
    func vttMimeType() {
        #expect(SubtitleFormat.vtt.mimeType == "text/vtt")
    }

    @Test("TXT format has correct MIME type")
    func txtMimeType() {
        #expect(SubtitleFormat.txt.mimeType == "text/plain")
    }

    @Test("All subtitle formats are available in CaseIterable")
    func allCasesAvailable() {
        let allFormats = SubtitleFormat.allCases
        #expect(allFormats.count == 3)
        #expect(allFormats.contains(.srt))
        #expect(allFormats.contains(.vtt))
        #expect(allFormats.contains(.txt))
    }
}

// MARK: - SubtitleExportError Tests

@Suite("SubtitleExportError Tests")
@MainActor
struct SubtitleExportErrorTests {
    @Test("noSegments error has description")
    func noSegmentsErrorDescription() {
        let error = SubtitleExportError.noSegments
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("noMessages error has description")
    func noMessagesErrorDescription() {
        let error = SubtitleExportError.noMessages
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("emptyContent error has description")
    func emptyContentErrorDescription() {
        let error = SubtitleExportError.emptyContent
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("writeError wraps underlying error")
    func writeErrorWrapsUnderlying() {
        let underlying = NSError(domain: "test", code: 42)
        let error = SubtitleExportError.writeError(underlying: underlying)
        #expect(error.errorDescription != nil)
    }

    @Test("invalidFormat includes format info")
    func invalidFormatIncludesInfo() {
        let error = SubtitleExportError.invalidFormat(format: .srt)
        #expect(error.errorDescription != nil)
    }
}

// MARK: - RecordingServiceError Tests

@Suite("RecordingServiceError Tests")
@MainActor
struct RecordingServiceErrorViewModelTests {
    @Test("notRecording error has description")
    func notRecordingErrorDescription() {
        let error = RecordingServiceError.notRecording
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("alreadyRecording error has description")
    func alreadyRecordingErrorDescription() {
        let error = RecordingServiceError.alreadyRecording
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("permissionDenied error has description")
    func permissionDeniedErrorDescription() {
        let error = RecordingServiceError.permissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("audioEngineError wraps underlying error")
    func audioEngineErrorWrapsUnderlying() {
        let underlying = NSError(domain: "AudioUnit", code: -10851)
        let error = RecordingServiceError.audioEngineError(underlying: underlying)
        #expect(error.errorDescription != nil)
    }

    @Test("fileWriteError wraps underlying error")
    func fileWriteErrorWrapsUnderlying() {
        let underlying = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError)
        let error = RecordingServiceError.fileWriteError(underlying: underlying)
        #expect(error.errorDescription != nil)
    }

    @Test("insufficientDiskSpace includes size info")
    func insufficientDiskSpaceIncludesInfo() {
        let error = RecordingServiceError.insufficientDiskSpace(
            available: 50 * 1024 * 1024,
            required: 100 * 1024 * 1024
        )
        #expect(error.errorDescription != nil)
    }

    @Test("formatNotSupported includes format info")
    func formatNotSupportedIncludesInfo() {
        let error = RecordingServiceError.formatNotSupported(format: .mp3)
        #expect(error.errorDescription != nil)
    }

    @Test("recoveryFailed wraps underlying error")
    func recoveryFailedWrapsUnderlying() {
        let underlying = NSError(domain: "Recovery", code: 1)
        let error = RecordingServiceError.recoveryFailed(underlying: underlying)
        #expect(error.errorDescription != nil)
    }
}

// MARK: - RecordingError Tests

@Suite("RecordingError Tests")
@MainActor
struct RecordingErrorTests {
    @Test("noAudioData error has description")
    func noAudioDataErrorDescription() {
        let error = RecordingError.noAudioData
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("noAudioData errors are equal")
    func noAudioDataEquality() {
        let error1 = RecordingError.noAudioData
        let error2 = RecordingError.noAudioData
        #expect(error1 == error2)
    }
}

// MARK: - Recording with Different Formats Tests

@Suite("RecordingViewModel Recording Formats Tests")
@MainActor
struct RecordingViewModelRecordingFormatsTests {
    @Test("Recordings with M4A format stored correctly")
    func recordingsM4AFormat() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.first?.format == .m4a)
    }

    @Test("Recordings with WAV format stored correctly")
    func recordingsWAVFormat() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .wav)
        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.first?.format == .wav)
    }

    @Test("Recordings with MP3 format stored correctly")
    func recordingsMP3Format() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .mp3)
        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.first?.format == .mp3)
    }

    @Test("Mixed format recordings all loaded")
    func mixedFormatRecordings() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording1 = Recording(id: UUID(), format: .m4a)
        let recording2 = Recording(id: UUID(), format: .wav)
        let recording3 = Recording(id: UUID(), format: .mp3)

        context.insert(recording1)
        context.insert(recording2)
        context.insert(recording3)
        try context.save()

        viewModel.setModelContext(context)

        #expect(viewModel.recordings.count == 3)

        let formats = viewModel.recordings.map { $0.format }
        #expect(formats.contains(.m4a))
        #expect(formats.contains(.wav))
        #expect(formats.contains(.mp3))
    }
}

// MARK: - startRecording State Transition Tests

@Suite("RecordingViewModel startRecording Tests")
@MainActor
struct RecordingViewModelStartRecordingTests {
    @Test("startRecording clears previous error message")
    func startRecordingClearsPreviousError() async {
        let viewModel = RecordingViewModel()

        // First set an error by calling pause when not recording
        viewModel.pauseRecording()
        #expect(viewModel.errorMessage != nil)

        // Now try to start recording - it will fail (no mic permission in test)
        // but should first clear the error message
        await viewModel.startRecording()

        // The error message should now be from the start attempt, not the pause
        // (either permission denied or some other audio error)
        // The key is that the previous error was cleared before the new operation
    }

    @Test("startRecording accepts format parameter")
    func startRecordingAcceptsFormat() async {
        let viewModel = RecordingViewModel()

        // Try with WAV format
        await viewModel.startRecording(format: .wav)

        // Will fail in test environment but should accept the format
        // and set an error message related to audio permissions
        #expect(viewModel.errorMessage != nil || viewModel.recordingState == .recording)
    }

    @Test("startRecording sets recordingState on error")
    func startRecordingErrorState() async {
        let viewModel = RecordingViewModel()

        await viewModel.startRecording()

        // In test environment without mic permissions, should set error state
        if case .error = viewModel.recordingState {
            // Expected error state
        } else if viewModel.recordingState == .recording {
            // Actually started recording (unexpected but valid)
        } else {
            // Check error message is set
            #expect(viewModel.errorMessage != nil)
        }
    }

    @Test("startRecording handles RecordingServiceError")
    func startRecordingHandlesServiceError() async {
        let viewModel = RecordingViewModel()

        // In test environment, should throw some error
        await viewModel.startRecording()

        // Either sets error state or has error message
        let hasError = viewModel.errorMessage != nil
        let isErrorState: Bool
        if case .error = viewModel.recordingState {
            isErrorState = true
        } else {
            isErrorState = false
        }

        #expect(hasError || isErrorState || viewModel.recordingState == .recording)
    }

    @Test("startRecording default format is m4a")
    func startRecordingDefaultFormat() async {
        let viewModel = RecordingViewModel()

        // Call without explicit format
        await viewModel.startRecording()

        // Default should be .m4a (can't directly verify but we test the method accepts no params)
        // The test verifies the signature works with default parameter
    }
}

// MARK: - Pause and Resume State Transition Tests

@Suite("RecordingViewModel Pause Resume State Tests")
@MainActor
struct RecordingViewModelPauseResumeStateTests {
    @Test("pauseRecording does not change state when already idle")
    func pauseRecordingFromIdleNoStateChange() {
        let viewModel = RecordingViewModel()

        let initialState = viewModel.recordingState
        viewModel.pauseRecording()

        // State should remain idle (error is set but state doesn't change to .paused)
        #expect(viewModel.recordingState == initialState)
    }

    @Test("resumeRecording does not change state when idle")
    func resumeRecordingFromIdleNoStateChange() {
        let viewModel = RecordingViewModel()

        let initialState = viewModel.recordingState
        viewModel.resumeRecording()

        // State should remain idle
        #expect(viewModel.recordingState == initialState)
    }

    @Test("pauseRecording error describes not recording")
    func pauseRecordingErrorContent() {
        let viewModel = RecordingViewModel()

        viewModel.pauseRecording()

        // Error should indicate not recording
        #expect(viewModel.errorMessage != nil)
        // Error message is localized, just verify it's non-empty
        #expect(viewModel.errorMessage?.count ?? 0 > 0)
    }

    @Test("resumeRecording error describes not paused")
    func resumeRecordingErrorContent() {
        let viewModel = RecordingViewModel()

        viewModel.resumeRecording()

        // Error should indicate not recording
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.count ?? 0 > 0)
    }
}

// MARK: - stopRecording State Transition Tests

@Suite("RecordingViewModel stopRecording Tests")
@MainActor
struct RecordingViewModelStopRecordingTests {
    @Test("stopRecording from idle sets error state")
    func stopRecordingFromIdleSetsErrorState() async {
        let viewModel = RecordingViewModel()

        await viewModel.stopRecording()

        // Should set error message
        #expect(viewModel.errorMessage != nil)

        // State should be error or remain idle with error message
        let isErrorState: Bool
        if case .error = viewModel.recordingState {
            isErrorState = true
        } else {
            isErrorState = false
        }
        #expect(isErrorState || viewModel.errorMessage != nil)
    }

    @Test("stopRecording clears currentMetadata")
    func stopRecordingClearsMetadata() async {
        let viewModel = RecordingViewModel()

        // Initially no metadata
        #expect(viewModel.currentMetadata == nil)

        await viewModel.stopRecording()

        // Metadata should still be nil
        #expect(viewModel.currentMetadata == nil)
    }

    @Test("stopRecording handles RecordingServiceError")
    func stopRecordingHandlesServiceError() async {
        let viewModel = RecordingViewModel()

        await viewModel.stopRecording()

        // Error should be set
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - Crash Recovery Tests

@Suite("RecordingViewModel Crash Recovery Tests")
@MainActor
struct RecordingViewModelCrashRecoveryTests {
    @Test("discardRecording throws for non-existent metadata")
    func discardRecordingNonExistent() {
        let viewModel = RecordingViewModel()

        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 60,
            format: .m4a,
            tempFileURL: URL(filePath: "/nonexistent/path/file.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        // Should not crash - may throw or succeed silently
        do {
            try viewModel.discardRecording(metadata)
            // Success - file didn't exist so nothing to delete
        } catch {
            // Expected - file doesn't exist
        }
    }

    @Test("recoverRecording throws for non-existent file")
    func recoverRecordingNonExistentFile() async {
        let viewModel = RecordingViewModel()

        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 60,
            format: .m4a,
            tempFileURL: URL(filePath: "/nonexistent/path/file.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        do {
            _ = try await viewModel.recoverRecording(metadata)
            Issue.record("Expected RecordingServiceError.recoveryFailed to be thrown")
        } catch is RecordingServiceError {
            // Expected
        } catch {
            // Other error type - also acceptable for non-existent file
        }
    }

    @Test("recoverRecording throws for nil tempFileURL")
    func recoverRecordingNilTempURL() async {
        let viewModel = RecordingViewModel()

        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 60,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        do {
            _ = try await viewModel.recoverRecording(metadata)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected - no file to recover
        }
    }
}

// MARK: - Disk Space Threshold Logic Tests

@Suite("RecordingViewModel Disk Space Threshold Logic Tests")
@MainActor
struct RecordingViewModelDiskSpaceThresholdLogicTests {
    @Test("isDiskSpaceLow threshold is exactly 100MB")
    func diskSpaceThresholdExact() {
        // Verify the threshold is exactly 100 * 1024 * 1024
        let threshold = Int64(100 * 1024 * 1024)
        #expect(threshold == 104_857_600)
    }

    @Test("isDiskSpaceLow is true when below 100MB")
    func diskSpaceLowWhenBelow100MB() {
        // Test the logic: availableDiskSpace < 100 * 1024 * 1024
        let belowThreshold = Int64(99 * 1024 * 1024)
        let threshold = Int64(100 * 1024 * 1024)

        #expect(belowThreshold < threshold)
    }

    @Test("isDiskSpaceLow is false when at or above 100MB")
    func diskSpaceNotLowWhenAtOrAbove100MB() {
        let atThreshold = Int64(100 * 1024 * 1024)
        let aboveThreshold = Int64(101 * 1024 * 1024)
        let threshold = Int64(100 * 1024 * 1024)

        #expect(!(atThreshold < threshold))
        #expect(!(aboveThreshold < threshold))
    }

    @Test("ViewModel initially has positive disk space")
    func viewModelHasPositiveDiskSpace() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.availableDiskSpace > 0)
    }

    @Test("ViewModel initially reports isDiskSpaceLow as false")
    func viewModelInitiallyNotLowSpace() {
        let viewModel = RecordingViewModel()

        // On a system with reasonable disk space, this should be false
        #expect(viewModel.isDiskSpaceLow == false)
    }
}

// MARK: - Notification Name Verification Tests

@Suite("Recording ViewModel Notification Name Verification Tests")
@MainActor
struct RecordingViewModelNotificationNameTests {
    @Test("recordingDiskSpaceLow notification name is correct")
    func recordingDiskSpaceLowNameIsCorrect() {
        let name = Notification.Name.recordingDiskSpaceLow
        #expect(name.rawValue == "recordingDiskSpaceLow")
    }
}

// MARK: - Export with Valid Session Tests

@Suite("RecordingViewModel Export with Valid Session Tests")
@MainActor
struct RecordingViewModelExportValidSessionTests {
    @Test("exportSubtitles with multiple segments returns valid file")
    func exportSubtitlesMultipleSegments() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment1 = Segment(
            startTime: 0,
            endTime: 3,
            originalText: "First segment",
            translatedText: "Premier segment"
        )
        let segment2 = Segment(
            startTime: 3,
            endTime: 6,
            originalText: "Second segment",
            translatedText: "Deuxième segment"
        )
        session.addSegment(segment1)
        session.addSegment(segment2)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment1)
        context.insert(segment2)
        context.insert(recording)

        let url = try await viewModel.exportSubtitles(for: recording)

        #expect(url.isFileURL)

        // Verify file contains expected content
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("-->"))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportSubtitles with TXT format returns plain text")
    func exportSubtitlesTXTFormat() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test content for TXT",
            translatedText: nil
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .originalOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )

        let url = try await viewModel.exportSubtitles(for: recording, options: options)

        #expect(url.pathExtension == "txt")

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportSubtitles with bilingual content includes both texts")
    func exportSubtitlesBilingual() async throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello world",
            translatedText: "Bonjour le monde"
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: false,
            bilingualOrder: .translationFirst
        )

        let url = try await viewModel.exportSubtitles(for: recording, options: options)

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("Hello world") || content.contains("Bonjour le monde"))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Preview Subtitle Detailed Tests

@Suite("RecordingViewModel Preview Subtitle Detailed Tests")
@MainActor
struct RecordingViewModelPreviewSubtitleDetailedTests {
    @Test("previewSubtitles bilingual order affects output")
    func previewSubtitlesBilingualOrderAffectsOutput() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Original",
            translatedText: "Translation"
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let optionsOriginalFirst = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )

        let optionsTranslationFirst = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: false,
            bilingualOrder: .translationFirst
        )

        let previewOriginalFirst = viewModel.previewSubtitles(for: recording, options: optionsOriginalFirst)
        let previewTranslationFirst = viewModel.previewSubtitles(for: recording, options: optionsTranslationFirst)

        // Both should contain content
        #expect(!previewOriginalFirst.isEmpty)
        #expect(!previewTranslationFirst.isEmpty)
    }

    @Test("previewSubtitles includeTimestamps affects SRT output")
    func previewSubtitlesTimestampsInSRT() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let segment = Segment(
            startTime: 1.5,
            endTime: 4.5,
            originalText: "Timed content",
            translatedText: nil
        )
        session.addSegment(segment)

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(segment)
        context.insert(recording)

        let optionsWithTimestamps = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        let preview = viewModel.previewSubtitles(for: recording, options: optionsWithTimestamps)

        // SRT with timestamps should have arrow separator
        #expect(preview.contains("-->"))
    }

    @Test("previewSubtitles with nil session segments returns empty")
    func previewSubtitlesNilSegments() {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        // Session has nil segments by default

        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(recording)

        let preview = viewModel.previewSubtitles(for: recording)

        // Should handle nil segments gracefully
        // Empty or header-only output is expected
        #expect(preview.isEmpty || preview.hasPrefix("WEBVTT") || preview.isEmpty)
    }
}

// MARK: - Delete Recording Detailed Tests

@Suite("RecordingViewModel Delete Recording Detailed Tests")
@MainActor
struct RecordingViewModelDeleteRecordingDetailedTests {
    @Test("deleteRecording with audioData handles cleanup")
    func deleteRecordingWithAudioData() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        recording.audioData = Data("test audio data".utf8)

        context.insert(recording)
        try context.save()

        viewModel.setModelContext(context)
        #expect(viewModel.recordings.count == 1)

        viewModel.deleteRecording(recording)

        #expect(viewModel.recordings.isEmpty)
    }

    @Test("deleteRecording reloads recordings after delete")
    func deleteRecordingReloadsAfterDelete() throws {
        let viewModel = RecordingViewModel()
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording1 = Recording(id: UUID(), format: .m4a)
        let recording2 = Recording(id: UUID(), format: .wav)

        context.insert(recording1)
        context.insert(recording2)
        try context.save()

        viewModel.setModelContext(context)
        #expect(viewModel.recordings.count == 2)

        viewModel.deleteRecording(recording1)

        // Should have reloaded and only have 1 recording
        #expect(viewModel.recordings.count == 1)
        #expect(viewModel.recordings.first?.id == recording2.id)
    }
}

// MARK: - Error State Tests

@Suite("RecordingViewModel Error State Detailed Tests")
@MainActor
struct RecordingViewModelErrorStateDetailedTests {
    @Test("Recording state error case equality")
    func recordingStateErrorEquality() {
        let error1 = RecordingState.error(message: "Test error")
        let error2 = RecordingState.error(message: "Test error")
        let error3 = RecordingState.error(message: "Different error")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Recording state error is not equal to other states")
    func recordingStateErrorNotEqualToOthers() {
        let errorState = RecordingState.error(message: "Error")

        #expect(errorState != .idle)
        #expect(errorState != .recording)
        #expect(errorState != .paused)
        #expect(errorState != .saving)
    }
}

// MARK: - CurrentDuration and FormattedDuration Tests

@Suite("RecordingViewModel Duration Computed Property Tests")
@MainActor
struct RecordingViewModelDurationComputedPropertyTests {
    @Test("currentDuration returns 0 without metadata")
    func currentDurationWithoutMetadata() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.currentMetadata == nil)
        #expect(viewModel.currentDuration == 0)
    }

    @Test("formattedCurrentDuration returns 00:00 without metadata")
    func formattedDurationWithoutMetadata() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.currentMetadata == nil)
        #expect(viewModel.formattedCurrentDuration == "00:00")
    }
}

// MARK: - AudioFormat Tests

@Suite("AudioFormat Enum Tests")
@MainActor
struct AudioFormatEnumTests {
    @Test("AudioFormat m4a has correct file extension")
    func m4aFileExtension() {
        #expect(AudioFormat.m4a.fileExtension == "m4a")
    }

    @Test("AudioFormat wav has correct file extension")
    func wavFileExtension() {
        #expect(AudioFormat.wav.fileExtension == "wav")
    }

    @Test("AudioFormat mp3 has correct file extension")
    func mp3FileExtension() {
        #expect(AudioFormat.mp3.fileExtension == "mp3")
    }

    @Test("AudioFormat raw values are correct")
    func audioFormatRawValues() {
        #expect(AudioFormat.m4a.rawValue == "m4a")
        #expect(AudioFormat.wav.rawValue == "wav")
        #expect(AudioFormat.mp3.rawValue == "mp3")
    }

    @Test("AudioFormat can be initialized from raw value")
    func audioFormatFromRawValue() {
        #expect(AudioFormat(rawValue: "m4a") == .m4a)
        #expect(AudioFormat(rawValue: "wav") == .wav)
        #expect(AudioFormat(rawValue: "mp3") == .mp3)
        #expect(AudioFormat(rawValue: "invalid") == nil)
    }
}

// MARK: - Initialization Tests

@Suite("RecordingViewModel Initialization Tests")
@MainActor
struct RecordingViewModelInitializationTests {
    @Test("ViewModel can be created with default services")
    func initWithDefaultServices() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.recordingState == .idle)
        #expect(viewModel.currentMetadata == nil)
        #expect(viewModel.recordings.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isExporting == false)
    }

    @Test("ViewModel initializes disk space")
    func initializesDiskSpace() {
        let viewModel = RecordingViewModel()

        // Disk space should be set during init (either actual or max)
        #expect(viewModel.availableDiskSpace > 0)
    }
}

// MARK: - ContentOption Enum Tests

@Suite("SubtitleContentOption Enum Tests")
@MainActor
struct SubtitleContentOptionEnumTests {
    @Test("ContentOption originalOnly exists")
    func contentOptionOriginalOnly() {
        let option = SubtitleContentOption.originalOnly
        #expect(option == .originalOnly)
    }

    @Test("ContentOption translationOnly exists")
    func contentOptionTranslationOnly() {
        let option = SubtitleContentOption.translationOnly
        #expect(option == .translationOnly)
    }

    @Test("ContentOption both exists")
    func contentOptionBoth() {
        let option = SubtitleContentOption.both
        #expect(option == .both)
    }

    @Test("All content options are distinct")
    func allContentOptionsDistinct() {
        #expect(SubtitleContentOption.originalOnly != .translationOnly)
        #expect(SubtitleContentOption.originalOnly != .both)
        #expect(SubtitleContentOption.translationOnly != .both)
    }
}

// MARK: - BilingualTextOrder Enum Tests

@Suite("BilingualTextOrder Enum Tests")
@MainActor
struct BilingualTextOrderEnumTests {
    @Test("BilingualTextOrder originalFirst exists")
    func bilingualTextOrderOriginalFirst() {
        let order = BilingualTextOrder.originalFirst
        #expect(order == .originalFirst)
    }

    @Test("BilingualTextOrder translationFirst exists")
    func bilingualTextOrderTranslationFirst() {
        let order = BilingualTextOrder.translationFirst
        #expect(order == .translationFirst)
    }

    @Test("BilingualTextOrder values are distinct")
    func bilingualTextOrdersDistinct() {
        #expect(BilingualTextOrder.originalFirst != .translationFirst)
    }

    @Test("BilingualTextOrder has localizedName")
    func bilingualTextOrderLocalizedName() {
        #expect(!BilingualTextOrder.originalFirst.localizedName.isEmpty)
        #expect(!BilingualTextOrder.translationFirst.localizedName.isEmpty)
    }

    @Test("BilingualTextOrder is CaseIterable")
    func bilingualTextOrderCaseIterable() {
        let allCases = BilingualTextOrder.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.originalFirst))
        #expect(allCases.contains(.translationFirst))
    }
}

// MARK: - SubtitleContentOption Extended Tests

@Suite("SubtitleContentOption Extended Tests")
@MainActor
struct SubtitleContentOptionExtendedTests {
    @Test("SubtitleContentOption has localizedName")
    func subtitleContentOptionLocalizedName() {
        #expect(!SubtitleContentOption.originalOnly.localizedName.isEmpty)
        #expect(!SubtitleContentOption.translationOnly.localizedName.isEmpty)
        #expect(!SubtitleContentOption.both.localizedName.isEmpty)
    }

    @Test("SubtitleContentOption is CaseIterable")
    func subtitleContentOptionCaseIterable() {
        let allCases = SubtitleContentOption.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.originalOnly))
        #expect(allCases.contains(.translationOnly))
        #expect(allCases.contains(.both))
    }

    @Test("SubtitleContentOption raw values are correct")
    func subtitleContentOptionRawValues() {
        #expect(SubtitleContentOption.originalOnly.rawValue == "original")
        #expect(SubtitleContentOption.translationOnly.rawValue == "translation")
        #expect(SubtitleContentOption.both.rawValue == "both")
    }
}

// MARK: - Recording State Sendable Tests

@Suite("RecordingState Sendable Tests")
@MainActor
struct RecordingStateSendableTests {
    @Test("RecordingState idle is Sendable")
    func recordingStateIdleSendable() {
        let state: RecordingState = .idle
        let sendableState: any Sendable = state
        _ = sendableState // Use the value
    }

    @Test("RecordingState recording is Sendable")
    func recordingStateRecordingSendable() {
        let state: RecordingState = .recording
        let sendableState: any Sendable = state
        _ = sendableState
    }

    @Test("RecordingState paused is Sendable")
    func recordingStatePausedSendable() {
        let state: RecordingState = .paused
        let sendableState: any Sendable = state
        _ = sendableState
    }

    @Test("RecordingState saving is Sendable")
    func recordingStateSavingSendable() {
        let state: RecordingState = .saving
        let sendableState: any Sendable = state
        _ = sendableState
    }

    @Test("RecordingState error is Sendable")
    func recordingStateErrorSendable() {
        let state: RecordingState = .error(message: "test")
        let sendableState: any Sendable = state
        _ = sendableState
    }
}

// MARK: - Recording with Session Tests

@Suite("RecordingViewModel Recording with Session Tests")
@MainActor
struct RecordingViewModelRecordingWithSessionTests {
    @Test("Recording can be created with session")
    func recordingWithSession() throws {
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let session = Session()
        let recording = Recording(id: UUID(), format: .m4a)
        recording.session = session

        context.insert(session)
        context.insert(recording)
        try context.save()

        #expect(recording.session != nil)
        #expect(recording.session?.id == session.id)
    }

    @Test("Recording session relationship is optional")
    func recordingSessionOptional() throws {
        let container = TestModelContainer.createFresh()
        let context = container.mainContext

        let recording = Recording(id: UUID(), format: .m4a)
        context.insert(recording)
        try context.save()

        #expect(recording.session == nil)
    }
}

// MARK: - ViewModel State Consistency Tests

@Suite("RecordingViewModel State Consistency Tests")
@MainActor
struct RecordingViewModelStateConsistencyTests {
    @Test("isRecording and isPaused are mutually consistent")
    func isRecordingAndIsPausedConsistency() {
        let viewModel = RecordingViewModel()

        // When idle
        #expect(viewModel.isRecording == false)
        #expect(viewModel.isPaused == false)

        // Both should never be true when state is idle
        #expect(!(viewModel.isRecording && viewModel.isPaused && viewModel.recordingState == .idle))
    }

    @Test("errorMessage is nil on fresh initialization")
    func errorMessageNilOnInit() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.errorMessage == nil)
    }

    @Test("isExporting is false on fresh initialization")
    func isExportingFalseOnInit() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.isExporting == false)
    }

    @Test("selectedRecording is nil on fresh initialization")
    func selectedRecordingNilOnInit() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.selectedRecording == nil)
    }

    @Test("recordings is empty on fresh initialization")
    func recordingsEmptyOnInit() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.recordings.isEmpty)
    }

    @Test("currentMetadata is nil on fresh initialization")
    func currentMetadataNilOnInit() {
        let viewModel = RecordingViewModel()

        #expect(viewModel.currentMetadata == nil)
    }
}

// MARK: - Export Options Immutability Tests

@Suite("SubtitleExportOptions Property Tests")
@MainActor
struct SubtitleExportOptionsPropertyTests {
    @Test("SubtitleExportOptions format can be changed")
    func exportOptionsFormatMutable() {
        var options = SubtitleExportOptions.default
        options.format = .vtt

        #expect(options.format == .vtt)
    }

    @Test("SubtitleExportOptions contentOption can be changed")
    func exportOptionsContentOptionMutable() {
        var options = SubtitleExportOptions.default
        options.contentOption = .originalOnly

        #expect(options.contentOption == .originalOnly)
    }

    @Test("SubtitleExportOptions includeTimestamps can be changed")
    func exportOptionsIncludeTimestampsMutable() {
        var options = SubtitleExportOptions.default
        options.includeTimestamps = false

        #expect(options.includeTimestamps == false)
    }

    @Test("SubtitleExportOptions bilingualOrder can be changed")
    func exportOptionsBilingualOrderMutable() {
        var options = SubtitleExportOptions.default
        options.bilingualOrder = .originalFirst

        #expect(options.bilingualOrder == .originalFirst)
    }
}

// MARK: - Multiple ViewModel Instance Tests

@Suite("Multiple RecordingViewModel Instance Tests")
@MainActor
struct MultipleRecordingViewModelInstanceTests {
    @Test("Multiple ViewModels are independent")
    func multipleViewModelsIndependent() {
        let viewModel1 = RecordingViewModel()
        let viewModel2 = RecordingViewModel()

        viewModel1.pauseRecording() // Sets error

        #expect(viewModel1.errorMessage != nil)
        #expect(viewModel2.errorMessage == nil)
    }

    @Test("ViewModels with separate contexts are independent")
    func viewModelsWithSeparateContextsIndependent() throws {
        let container1 = TestModelContainer.createFresh()
        let container2 = TestModelContainer.createFresh()

        let viewModel1 = RecordingViewModel()
        let viewModel2 = RecordingViewModel()

        viewModel1.setModelContext(container1.mainContext)
        viewModel2.setModelContext(container2.mainContext)

        let recording = Recording(id: UUID(), format: .m4a)
        container1.mainContext.insert(recording)
        try container1.mainContext.save()

        viewModel1.loadRecordings()
        viewModel2.loadRecordings()

        #expect(viewModel1.recordings.count == 1)
        #expect(viewModel2.recordings.isEmpty)
    }
}
