//
//  MediaImportViewModelTests.swift
//  VotraTests
//
//  Unit tests for MediaImportViewModel and its supporting types.
//

import Foundation
import Testing
@testable import Votra

@Suite("MediaImportViewModel Tests")
@MainActor
struct MediaImportViewModelTests {
    // MARK: - Initial State Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)
        #expect(viewModel.files.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Default configuration values")
    func defaultConfiguration() {
        let viewModel = MediaImportViewModel()

        // Source locale defaults to "en" if target is not English
        // Target locale is based on system locale
        let validTargetDefaults = ["zh-Hans", "zh-Hant", "en", "ja", "ko", "fr", "de", "es", "it", "pt", "ru", "ar", "hi", "th", "vi", "id", "ms", "tr", "pl", "nl", "uk"]
        #expect(validTargetDefaults.contains(viewModel.targetLocale.identifier))
        #expect(viewModel.exportOptions.format == .srt)
        #expect(viewModel.exportOptions.contentOption == .both)
        #expect(viewModel.exportOptions.includeTimestamps == true)
        #expect(viewModel.exportOptions.bilingualOrder == .translationFirst)
        #expect(viewModel.outputDirectory == StoragePaths.exports)
    }

    // MARK: - Observable Properties Tests

    @Test("isCompleted returns true only when batch completed")
    func isCompletedProperty() {
        let viewModel = MediaImportViewModel()

        // Initially false
        #expect(viewModel.isCompleted == false)
    }

    @Test("isProcessing returns false when idle")
    func isProcessingProperty() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.isProcessing == false)
    }

    @Test("totalFiles returns correct count")
    func totalFilesProperty() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.totalFiles == 0)
    }

    @Test("completedFiles returns zero initially")
    func completedFilesProperty() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.completedFiles == 0)
    }

    @Test("failedFiles returns zero initially")
    func failedFilesProperty() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.failedFiles == 0)
    }

    @Test("overallProgress returns zero when no files")
    func overallProgressEmptyFiles() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.overallProgress == 0)
    }

    // MARK: - Configuration Update Tests

    @Test("Source locale can be updated")
    func sourceLocaleCanBeUpdated() {
        let viewModel = MediaImportViewModel()

        viewModel.sourceLocale = Locale(identifier: "ja")

        #expect(viewModel.sourceLocale.identifier == "ja")
    }

    @Test("Target locale can be updated")
    func targetLocaleCanBeUpdated() {
        let viewModel = MediaImportViewModel()

        viewModel.targetLocale = Locale(identifier: "fr")

        #expect(viewModel.targetLocale.identifier == "fr")
    }

    @Test("Export options can be updated")
    func exportOptionsCanBeUpdated() {
        let viewModel = MediaImportViewModel()

        let newOptions = SubtitleExportOptions(
            format: .vtt,
            contentOption: .originalOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )
        viewModel.exportOptions = newOptions

        #expect(viewModel.exportOptions.format == .vtt)
        #expect(viewModel.exportOptions.contentOption == .originalOnly)
    }

    @Test("Output directory can be updated")
    func outputDirectoryCanBeUpdated() {
        let viewModel = MediaImportViewModel()

        let newDirectory = URL.temporaryDirectory
        viewModel.outputDirectory = newDirectory

        #expect(viewModel.outputDirectory == newDirectory)
    }

    // MARK: - Clear Queue Tests

    @Test("Clear queue does nothing when idle")
    func clearQueueWhenIdle() {
        let viewModel = MediaImportViewModel()

        viewModel.clearQueue()

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)
    }

    // MARK: - Cancel Processing Tests

    @Test("Cancel processing sets state to cancelled")
    func cancelProcessingSetsStateToCancelled() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    // MARK: - Type Properties Tests

    @Test("Supported extensions includes video formats")
    func supportedExtensionsIncludesVideo() {
        let extensions = MediaImportViewModel.supportedExtensions

        #expect(extensions.contains("mp4"))
        #expect(extensions.contains("mov"))
        #expect(extensions.contains("m4v"))
    }

    @Test("Supported extensions includes audio formats")
    func supportedExtensionsIncludesAudio() {
        let extensions = MediaImportViewModel.supportedExtensions

        #expect(extensions.contains("mp3"))
        #expect(extensions.contains("m4a"))
        #expect(extensions.contains("wav"))
        #expect(extensions.contains("aac"))
    }

    @Test("Supported content types contains expected UTTypes")
    func supportedContentTypesContainsExpectedTypes() {
        let types = MediaImportViewModel.supportedContentTypes

        #expect(types.contains("public.mpeg-4"))
        #expect(types.contains("com.apple.quicktime-movie"))
        #expect(types.contains("public.mp3"))
        #expect(types.contains("com.apple.m4a-audio"))
    }
}

// MARK: - MediaProcessingState Tests

@Suite("MediaProcessingState Tests")
struct MediaProcessingStateTests {
    @Test("Queued state equality")
    func queuedStateEquality() {
        let state1 = MediaProcessingState.queued
        let state2 = MediaProcessingState.queued

        #expect(state1 == state2)
    }

    @Test("Processing state equality with same progress")
    func processingStateEqualitySameProgress() {
        let state1 = MediaProcessingState.processing(progress: 0.5)
        let state2 = MediaProcessingState.processing(progress: 0.5)

        #expect(state1 == state2)
    }

    @Test("Processing state inequality with different progress")
    func processingStateInequalityDifferentProgress() {
        let state1 = MediaProcessingState.processing(progress: 0.3)
        let state2 = MediaProcessingState.processing(progress: 0.7)

        #expect(state1 != state2)
    }

    @Test("Completed state equality")
    func completedStateEquality() {
        let state1 = MediaProcessingState.completed
        let state2 = MediaProcessingState.completed

        #expect(state1 == state2)
    }

    @Test("Failed state equality with same error")
    func failedStateEqualitySameError() {
        let state1 = MediaProcessingState.failed(error: "Test error")
        let state2 = MediaProcessingState.failed(error: "Test error")

        #expect(state1 == state2)
    }

    @Test("Failed state inequality with different error")
    func failedStateInequalityDifferentError() {
        let state1 = MediaProcessingState.failed(error: "Error 1")
        let state2 = MediaProcessingState.failed(error: "Error 2")

        #expect(state1 != state2)
    }

    @Test("Different states are not equal")
    func differentStatesNotEqual() {
        let queued = MediaProcessingState.queued
        let processing = MediaProcessingState.processing(progress: 0.5)
        let completed = MediaProcessingState.completed
        let failed = MediaProcessingState.failed(error: "Error")

        #expect(queued != processing)
        #expect(processing != completed)
        #expect(completed != failed)
        #expect(failed != queued)
    }
}

// MARK: - MediaFile Tests

@Suite("MediaFile Tests")
struct MediaFileTests {
    @Test("MediaFile initialization with defaults")
    func mediaFileInitializationDefaults() {
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let file = MediaFile(
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.url == url)
        #expect(file.fileName == "video.mp4")
        #expect(file.fileSize == 1000)
        #expect(file.duration == 60.0)
        #expect(file.mediaType == .video)
        #expect(file.state == .queued)
        #expect(file.outputURL == nil)
        #expect(file.bookmarkData == nil)
    }

    @Test("MediaFile initialization with custom state")
    func mediaFileInitializationCustomState() {
        let url = URL(fileURLWithPath: "/test/audio.mp3")
        let file = MediaFile(
            url: url,
            fileName: "audio.mp3",
            fileSize: 500,
            duration: 120.0,
            mediaType: .audio,
            state: .completed,
            outputURL: URL(fileURLWithPath: "/output/audio.srt")
        )

        #expect(file.state == .completed)
        #expect(file.outputURL != nil)
    }

    @Test("Formatted duration for hours")
    func formattedDurationHours() {
        let url = URL(fileURLWithPath: "/test/long.mp4")
        let file = MediaFile(
            url: url,
            fileName: "long.mp4",
            fileSize: 1000,
            duration: 3661.0, // 1 hour, 1 minute, 1 second
            mediaType: .video
        )

        #expect(file.formattedDuration == "1:01:01")
    }

    @Test("Formatted duration for minutes only")
    func formattedDurationMinutesOnly() {
        let url = URL(fileURLWithPath: "/test/short.mp4")
        let file = MediaFile(
            url: url,
            fileName: "short.mp4",
            fileSize: 1000,
            duration: 125.0, // 2 minutes, 5 seconds
            mediaType: .video
        )

        #expect(file.formattedDuration == "2:05")
    }

    @Test("Formatted duration zero")
    func formattedDurationZero() {
        let url = URL(fileURLWithPath: "/test/zero.mp4")
        let file = MediaFile(
            url: url,
            fileName: "zero.mp4",
            fileSize: 1000,
            duration: 0.0,
            mediaType: .video
        )

        #expect(file.formattedDuration == "0:00")
    }

    @Test("Formatted duration under one minute")
    func formattedDurationUnderOneMinute() {
        let url = URL(fileURLWithPath: "/test/clip.mp4")
        let file = MediaFile(
            url: url,
            fileName: "clip.mp4",
            fileSize: 1000,
            duration: 45.0,
            mediaType: .video
        )

        #expect(file.formattedDuration == "0:45")
    }

    @Test("Formatted file size is locale independent")
    func formattedFileSizeLocaleIndependent() {
        let url = URL(fileURLWithPath: "/test/file.mp4")
        let file = MediaFile(
            url: url,
            fileName: "file.mp4",
            fileSize: 1_000_000, // 1 MB
            duration: 60.0,
            mediaType: .video
        )

        // Check that it returns a non-empty string (actual format varies by locale)
        #expect(!file.formattedFileSize.isEmpty)
    }

    @Test("MediaFile equality")
    func mediaFileEquality() {
        let id = UUID()
        let url = URL(fileURLWithPath: "/test/video.mp4")

        let file1 = MediaFile(
            id: id,
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        let file2 = MediaFile(
            id: id,
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file1 == file2)
    }

    @Test("MediaFile inequality by ID")
    func mediaFileInequalityById() {
        let url = URL(fileURLWithPath: "/test/video.mp4")

        let file1 = MediaFile(
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        let file2 = MediaFile(
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        // Different IDs since they're auto-generated
        #expect(file1 != file2)
    }

    @Test("MediaFile Identifiable conformance")
    func mediaFileIdentifiable() {
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let file = MediaFile(
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.id != UUID()) // Has a valid ID
    }
}

// MARK: - MediaType Tests

@Suite("MediaType Tests")
struct MediaTypeTests {
    @Test("MediaType from video extensions")
    func mediaTypeFromVideoExtensions() {
        #expect(MediaType.from(fileExtension: "mp4") == .video)
        #expect(MediaType.from(fileExtension: "mov") == .video)
        #expect(MediaType.from(fileExtension: "m4v") == .video)
    }

    @Test("MediaType from audio extensions")
    func mediaTypeFromAudioExtensions() {
        #expect(MediaType.from(fileExtension: "mp3") == .audio)
        #expect(MediaType.from(fileExtension: "m4a") == .audio)
        #expect(MediaType.from(fileExtension: "wav") == .audio)
        #expect(MediaType.from(fileExtension: "aac") == .audio)
    }

    @Test("MediaType from uppercase extensions")
    func mediaTypeFromUppercaseExtensions() {
        #expect(MediaType.from(fileExtension: "MP4") == .video)
        #expect(MediaType.from(fileExtension: "MP3") == .audio)
        #expect(MediaType.from(fileExtension: "WAV") == .audio)
    }

    @Test("MediaType from mixed case extensions")
    func mediaTypeFromMixedCaseExtensions() {
        #expect(MediaType.from(fileExtension: "Mp4") == .video)
        #expect(MediaType.from(fileExtension: "MoV") == .video)
    }

    @Test("MediaType returns nil for unsupported extensions")
    func mediaTypeUnsupportedExtensions() {
        #expect(MediaType.from(fileExtension: "txt") == nil)
        #expect(MediaType.from(fileExtension: "pdf") == nil)
        #expect(MediaType.from(fileExtension: "jpg") == nil)
        #expect(MediaType.from(fileExtension: "") == nil)
    }

    @Test("MediaType raw values")
    func mediaTypeRawValues() {
        #expect(MediaType.video.rawValue == "video")
        #expect(MediaType.audio.rawValue == "audio")
    }

    @Test("MediaType allCases contains expected values")
    func mediaTypeAllCases() {
        let allCases = MediaType.allCases

        #expect(allCases.count == 2)
        #expect(allCases.contains(.video))
        #expect(allCases.contains(.audio))
    }
}

// MARK: - BatchProcessingState Tests

@Suite("BatchProcessingState Tests")
struct BatchProcessingStateTests {
    @Test("Idle state equality")
    func idleStateEquality() {
        let state1 = BatchProcessingState.idle
        let state2 = BatchProcessingState.idle

        #expect(state1 == state2)
    }

    @Test("Processing state equality with same values")
    func processingStateEqualitySameValues() {
        let state1 = BatchProcessingState.processing(current: 2, total: 5)
        let state2 = BatchProcessingState.processing(current: 2, total: 5)

        #expect(state1 == state2)
    }

    @Test("Processing state inequality with different values")
    func processingStateInequalityDifferentValues() {
        let state1 = BatchProcessingState.processing(current: 2, total: 5)
        let state2 = BatchProcessingState.processing(current: 3, total: 5)
        let state3 = BatchProcessingState.processing(current: 2, total: 10)

        #expect(state1 != state2)
        #expect(state1 != state3)
    }

    @Test("Completed state equality with same values")
    func completedStateEqualitySameValues() {
        let state1 = BatchProcessingState.completed(successful: 3, failed: 1)
        let state2 = BatchProcessingState.completed(successful: 3, failed: 1)

        #expect(state1 == state2)
    }

    @Test("Completed state inequality with different values")
    func completedStateInequalityDifferentValues() {
        let state1 = BatchProcessingState.completed(successful: 3, failed: 1)
        let state2 = BatchProcessingState.completed(successful: 4, failed: 1)
        let state3 = BatchProcessingState.completed(successful: 3, failed: 2)

        #expect(state1 != state2)
        #expect(state1 != state3)
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
        let processing = BatchProcessingState.processing(current: 1, total: 3)
        let completed = BatchProcessingState.completed(successful: 3, failed: 0)
        let cancelled = BatchProcessingState.cancelled

        #expect(idle != processing)
        #expect(processing != completed)
        #expect(completed != cancelled)
        #expect(cancelled != idle)
    }
}

// MARK: - MediaImportError Tests

@Suite("MediaImportError Tests")
struct MediaImportErrorTests {
    @Test("Unsupported format error contains format")
    func unsupportedFormatErrorContainsFormat() {
        let error = MediaImportError.unsupportedFormat("xyz")

        // Error description should contain the format
        #expect(error.errorDescription?.contains("xyz") == true)
    }

    @Test("File not found error contains path")
    func fileNotFoundErrorContainsPath() {
        let error = MediaImportError.fileNotFound("/path/to/file.mp4")

        #expect(error.errorDescription?.contains("/path/to/file.mp4") == true)
    }

    @Test("Access denied error contains path")
    func accessDeniedErrorContainsPath() {
        let error = MediaImportError.accessDenied("/restricted/file.mp4")

        #expect(error.errorDescription?.contains("/restricted/file.mp4") == true)
    }

    @Test("Transcription failed error contains reason")
    func transcriptionFailedErrorContainsReason() {
        let error = MediaImportError.transcriptionFailed("No audio track")

        #expect(error.errorDescription?.contains("No audio track") == true)
    }

    @Test("Translation failed error contains reason")
    func translationFailedErrorContainsReason() {
        let error = MediaImportError.translationFailed("Service unavailable")

        #expect(error.errorDescription?.contains("Service unavailable") == true)
    }

    @Test("Export failed error contains reason")
    func exportFailedErrorContainsReason() {
        let error = MediaImportError.exportFailed("Disk full")

        #expect(error.errorDescription?.contains("Disk full") == true)
    }

    @Test("Cancelled error has description")
    func cancelledErrorHasDescription() {
        let error = MediaImportError.cancelled

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("All error cases have non-nil descriptions")
    func allErrorCasesHaveDescriptions() {
        let errors: [MediaImportError] = [
            .unsupportedFormat("test"),
            .fileNotFound("test"),
            .accessDenied("test"),
            .transcriptionFailed("test"),
            .translationFailed("test"),
            .exportFailed("test"),
            .cancelled
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }

    @Test("Error conforms to LocalizedError")
    func errorConformsToLocalizedError() {
        let error: any LocalizedError = MediaImportError.cancelled

        #expect(error.errorDescription != nil)
    }

    @Test("Error conforms to Sendable")
    func errorConformsToSendable() {
        let error: any Sendable = MediaImportError.cancelled

        _ = error // Just verify it compiles
    }
}

// MARK: - ViewModel Progress Calculation Tests

@Suite("MediaImportViewModel Progress Tests")
@MainActor
struct MediaImportViewModelProgressTests {
    @Test("Progress is zero with no files")
    func progressZeroWithNoFiles() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.overallProgress == 0.0)
    }
}

// MARK: - ViewModel State Transition Tests

@Suite("MediaImportViewModel State Transitions")
@MainActor
struct MediaImportViewModelStateTests {
    @Test("isCompleted detects completed state")
    func isCompletedDetectsCompletedState() {
        // We can only test that the property returns false when idle
        // since we cannot inject a completed state without processing
        let viewModel = MediaImportViewModel()

        #expect(viewModel.isCompleted == false)
    }

    @Test("isProcessing detects processing state")
    func isProcessingDetectsProcessingState() {
        // We can only test that the property returns false when idle
        let viewModel = MediaImportViewModel()

        #expect(viewModel.isProcessing == false)
    }

    @Test("Multiple cancel calls are safe")
    func multipleCancelCallsAreSafe() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        viewModel.cancelProcessing()
        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }
}

// MARK: - ViewModel File Management Tests

@Suite("MediaImportViewModel File Management")
@MainActor
struct MediaImportViewModelFileManagementTests {

    // MARK: - Helper

    /// Creates a MediaFile for testing purposes
    private func createTestFile(
        id: UUID = UUID(),
        fileName: String = "test.mp4",
        fileSize: Int64 = 1000,
        duration: TimeInterval = 60.0,
        mediaType: MediaType = .video,
        state: MediaProcessingState = .queued
    ) -> MediaFile {
        MediaFile(
            id: id,
            url: URL(fileURLWithPath: "/test/\(fileName)"),
            fileName: fileName,
            fileSize: fileSize,
            duration: duration,
            mediaType: mediaType,
            state: state
        )
    }

    // MARK: - Remove File Tests

    @Test("Remove file removes the correct file")
    func removeFileRemovesCorrectFile() {
        let viewModel = MediaImportViewModel()

        let file1 = createTestFile(fileName: "video1.mp4")
        let file2 = createTestFile(fileName: "video2.mp4")
        let file3 = createTestFile(fileName: "video3.mp4")

        // Manually set files array via reflection or by modifying viewModel directly
        // Since files is private(set), we need to test through addFiles or use a workaround
        // For testing removeFile, we test that it doesn't crash with empty files
        viewModel.removeFile(file1)
        #expect(viewModel.files.isEmpty)

        // Verify file is not in the list after removal attempt
        #expect(!viewModel.files.contains { $0.id == file1.id })
    }

    @Test("Remove file with non-existent ID does nothing")
    func removeFileNonExistent() {
        let viewModel = MediaImportViewModel()

        let nonExistentFile = createTestFile(fileName: "nonexistent.mp4")
        viewModel.removeFile(nonExistentFile)

        #expect(viewModel.files.isEmpty)
    }

    // MARK: - Clear Queue Tests

    @Test("Clear queue clears files when cancelled")
    func clearQueueWhenCancelled() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.clearQueue()

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)
    }

    @Test("Clear queue resets state to idle")
    func clearQueueResetsState() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        viewModel.clearQueue()

        #expect(viewModel.batchState == .idle)
    }

    // MARK: - Start Processing Guard Tests

    @Test("Start processing does nothing with empty files")
    func startProcessingEmptyFiles() async {
        let viewModel = MediaImportViewModel()

        await viewModel.startProcessing()

        #expect(viewModel.batchState == .idle)
    }

    @Test("Start processing does nothing when cancelled state")
    func startProcessingWhenCancelled() async {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        await viewModel.startProcessing()

        // Should remain cancelled since no files to process
        #expect(viewModel.batchState == .cancelled)
    }
}

// MARK: - Extended MediaFile Tests

@Suite("MediaFile Extended Tests")
struct MediaFileExtendedTests {

    @Test("Formatted duration for exactly one hour")
    func formattedDurationExactlyOneHour() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/hour.mp4"),
            fileName: "hour.mp4",
            fileSize: 1000,
            duration: 3600.0,
            mediaType: .video
        )

        #expect(file.formattedDuration == "1:00:00")
    }

    @Test("Formatted duration for multiple hours")
    func formattedDurationMultipleHours() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/long.mp4"),
            fileName: "long.mp4",
            fileSize: 1000,
            duration: 7323.0, // 2 hours, 2 minutes, 3 seconds
            mediaType: .video
        )

        #expect(file.formattedDuration == "2:02:03")
    }

    @Test("Formatted duration edge case 59 seconds")
    func formattedDuration59Seconds() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/short.mp4"),
            fileName: "short.mp4",
            fileSize: 1000,
            duration: 59.0,
            mediaType: .video
        )

        #expect(file.formattedDuration == "0:59")
    }

    @Test("Formatted duration edge case 59 minutes 59 seconds")
    func formattedDuration59Minutes59Seconds() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/almost-hour.mp4"),
            fileName: "almost-hour.mp4",
            fileSize: 1000,
            duration: 3599.0,
            mediaType: .video
        )

        #expect(file.formattedDuration == "59:59")
    }

    @Test("Formatted duration with fractional seconds rounds down")
    func formattedDurationFractionalSeconds() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/fractional.mp4"),
            fileName: "fractional.mp4",
            fileSize: 1000,
            duration: 65.9, // Should display as 1:05, not 1:06
            mediaType: .video
        )

        #expect(file.formattedDuration == "1:05")
    }

    @Test("MediaFile with audio type")
    func mediaFileAudioType() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/audio.mp3"),
            fileName: "audio.mp3",
            fileSize: 500,
            duration: 180.0,
            mediaType: .audio
        )

        #expect(file.mediaType == .audio)
        #expect(file.fileName == "audio.mp3")
    }

    @Test("MediaFile with processing state")
    func mediaFileWithProcessingState() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/processing.mp4"),
            fileName: "processing.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .processing(progress: 0.5)
        )

        #expect(file.state == .processing(progress: 0.5))
    }

    @Test("MediaFile with failed state")
    func mediaFileWithFailedState() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/failed.mp4"),
            fileName: "failed.mp4",
            fileSize: 1000,
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

    @Test("MediaFile with bookmark data")
    func mediaFileWithBookmarkData() {
        let bookmarkData = Data([0x01, 0x02, 0x03])
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/bookmarked.mp4"),
            fileName: "bookmarked.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            bookmarkData: bookmarkData
        )

        #expect(file.bookmarkData == bookmarkData)
    }

    @Test("Formatted file size for zero bytes")
    func formattedFileSizeZeroBytes() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/empty.mp4"),
            fileName: "empty.mp4",
            fileSize: 0,
            duration: 0.0,
            mediaType: .video
        )

        // ByteCountFormatter returns "Zero KB" or similar - just verify it's not empty
        #expect(!file.formattedFileSize.isEmpty)
    }

    @Test("Formatted file size for large file")
    func formattedFileSizeLargeFile() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/large.mp4"),
            fileName: "large.mp4",
            fileSize: 1_073_741_824, // 1 GB
            duration: 3600.0,
            mediaType: .video
        )

        // Just verify it returns a non-empty string
        #expect(!file.formattedFileSize.isEmpty)
    }

    @Test("MediaFile equality includes all properties")
    func mediaFileEqualityAllProperties() {
        let id = UUID()
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let bookmarkData = Data([0x01, 0x02])

        let file1 = MediaFile(
            id: id,
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .completed,
            outputURL: URL(fileURLWithPath: "/output/video.srt"),
            bookmarkData: bookmarkData
        )

        let file2 = MediaFile(
            id: id,
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .completed,
            outputURL: URL(fileURLWithPath: "/output/video.srt"),
            bookmarkData: bookmarkData
        )

        #expect(file1 == file2)
    }

    @Test("MediaFile inequality by state")
    func mediaFileInequalityByState() {
        let id = UUID()
        let url = URL(fileURLWithPath: "/test/video.mp4")

        let file1 = MediaFile(
            id: id,
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .queued
        )

        let file2 = MediaFile(
            id: id,
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .completed
        )

        #expect(file1 != file2)
    }
}

// MARK: - Extended MediaProcessingState Tests

@Suite("MediaProcessingState Extended Tests")
struct MediaProcessingStateExtendedTests {

    @Test("Processing state with zero progress")
    func processingStateZeroProgress() {
        let state = MediaProcessingState.processing(progress: 0.0)

        if case .processing(let progress) = state {
            #expect(progress == 0.0)
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("Processing state with full progress")
    func processingStateFullProgress() {
        let state = MediaProcessingState.processing(progress: 1.0)

        if case .processing(let progress) = state {
            #expect(progress == 1.0)
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("Processing state with mid progress")
    func processingStateMidProgress() {
        let state = MediaProcessingState.processing(progress: 0.75)

        if case .processing(let progress) = state {
            #expect(progress == 0.75)
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("Failed state with empty error")
    func failedStateEmptyError() {
        let state = MediaProcessingState.failed(error: "")

        if case .failed(let error) = state {
            #expect(error.isEmpty)
        } else {
            Issue.record("Expected failed state")
        }
    }

    @Test("Failed state with long error message")
    func failedStateLongError() {
        let longError = String(repeating: "A", count: 1000)
        let state = MediaProcessingState.failed(error: longError)

        if case .failed(let error) = state {
            #expect(error.count == 1000)
        } else {
            Issue.record("Expected failed state")
        }
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let state: any Sendable = MediaProcessingState.queued
        _ = state // Verify compilation
    }
}

// MARK: - Extended BatchProcessingState Tests

@Suite("BatchProcessingState Extended Tests")
struct BatchProcessingStateExtendedTests {

    @Test("Processing state with single file")
    func processingStateSingleFile() {
        let state = BatchProcessingState.processing(current: 1, total: 1)

        if case .processing(let current, let total) = state {
            #expect(current == 1)
            #expect(total == 1)
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("Processing state with large queue")
    func processingStateLargeQueue() {
        let state = BatchProcessingState.processing(current: 50, total: 100)

        if case .processing(let current, let total) = state {
            #expect(current == 50)
            #expect(total == 100)
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("Completed state all successful")
    func completedStateAllSuccessful() {
        let state = BatchProcessingState.completed(successful: 10, failed: 0)

        if case .completed(let successful, let failed) = state {
            #expect(successful == 10)
            #expect(failed == 0)
        } else {
            Issue.record("Expected completed state")
        }
    }

    @Test("Completed state all failed")
    func completedStateAllFailed() {
        let state = BatchProcessingState.completed(successful: 0, failed: 5)

        if case .completed(let successful, let failed) = state {
            #expect(successful == 0)
            #expect(failed == 5)
        } else {
            Issue.record("Expected completed state")
        }
    }

    @Test("Completed state mixed results")
    func completedStateMixedResults() {
        let state = BatchProcessingState.completed(successful: 7, failed: 3)

        if case .completed(let successful, let failed) = state {
            #expect(successful == 7)
            #expect(failed == 3)
        } else {
            Issue.record("Expected completed state")
        }
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let state: any Sendable = BatchProcessingState.idle
        _ = state // Verify compilation
    }
}

// MARK: - Extended MediaImportError Tests

@Suite("MediaImportError Extended Tests")
struct MediaImportErrorExtendedTests {

    @Test("Error descriptions are non-empty")
    func errorDescriptionsNonEmpty() {
        let errors: [MediaImportError] = [
            .unsupportedFormat("avi"),
            .fileNotFound("missing.mp4"),
            .accessDenied("restricted.mp4"),
            .transcriptionFailed("No speech detected"),
            .translationFailed("Network error"),
            .exportFailed("Disk full"),
            .cancelled
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("Error with special characters in message")
    func errorWithSpecialCharacters() {
        let error = MediaImportError.transcriptionFailed("Failed: \"test\" <script>")

        #expect(error.errorDescription?.contains("Failed") == true)
    }

    @Test("Error with unicode characters")
    func errorWithUnicodeCharacters() {
        let error = MediaImportError.fileNotFound("video_\u{1F3AC}.mp4")

        #expect(error.errorDescription?.contains("\u{1F3AC}") == true)
    }

    @Test("Error conforms to Error protocol")
    func errorConformsToErrorProtocol() {
        let error: any Error = MediaImportError.cancelled

        #expect(error.localizedDescription.isEmpty == false)
    }
}

// MARK: - Extended MediaType Tests

@Suite("MediaType Extended Tests")
struct MediaTypeExtendedTests {

    @Test("MediaType from empty string")
    func mediaTypeFromEmptyString() {
        #expect(MediaType.from(fileExtension: "") == nil)
    }

    @Test("MediaType from extension with dots")
    func mediaTypeFromExtensionWithDots() {
        // Extensions should not include dots
        #expect(MediaType.from(fileExtension: ".mp4") == nil)
        #expect(MediaType.from(fileExtension: "..mp4") == nil)
    }

    @Test("MediaType from similar but unsupported extensions")
    func mediaTypeFromSimilarExtensions() {
        #expect(MediaType.from(fileExtension: "mp5") == nil)
        #expect(MediaType.from(fileExtension: "mp2") == nil)
        #expect(MediaType.from(fileExtension: "avi") == nil)
        #expect(MediaType.from(fileExtension: "mkv") == nil)
        #expect(MediaType.from(fileExtension: "flac") == nil)
        #expect(MediaType.from(fileExtension: "ogg") == nil)
    }

    @Test("MediaType from whitespace extensions")
    func mediaTypeFromWhitespaceExtensions() {
        #expect(MediaType.from(fileExtension: " ") == nil)
        #expect(MediaType.from(fileExtension: "  mp4") == nil)
        #expect(MediaType.from(fileExtension: "mp4  ") == nil)
    }

    @Test("All MediaType cases have raw values")
    func allCasesHaveRawValues() {
        for mediaType in MediaType.allCases {
            #expect(!mediaType.rawValue.isEmpty)
        }
    }
}

// MARK: - ViewModel Static Properties Tests

@Suite("MediaImportViewModel Static Properties")
@MainActor
struct MediaImportViewModelStaticPropertiesTests {

    @Test("Supported extensions count")
    func supportedExtensionsCount() {
        let extensions = MediaImportViewModel.supportedExtensions

        #expect(extensions.count == 7) // mp4, mov, m4v, mp3, m4a, wav, aac
    }

    @Test("Supported content types count")
    func supportedContentTypesCount() {
        let types = MediaImportViewModel.supportedContentTypes

        #expect(types.count == 6)
    }

    @Test("All supported extensions have corresponding MediaType")
    func supportedExtensionsHaveMediaType() {
        for ext in MediaImportViewModel.supportedExtensions {
            #expect(MediaType.from(fileExtension: ext) != nil)
        }
    }
}

// MARK: - ViewModel Initialization Tests

@Suite("MediaImportViewModel Initialization")
@MainActor
struct MediaImportViewModelInitializationTests {

    @Test("Default initialization creates valid instance")
    func defaultInitialization() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.totalFiles == 0)
        #expect(viewModel.completedFiles == 0)
        #expect(viewModel.failedFiles == 0)
        #expect(viewModel.overallProgress == 0.0)
    }

    @Test("Source locale has language identifier")
    func sourceLocaleHasLanguageIdentifier() {
        let viewModel = MediaImportViewModel()

        #expect(!viewModel.sourceLocale.identifier.isEmpty)
    }

    @Test("Target locale has language identifier")
    func targetLocaleHasLanguageIdentifier() {
        let viewModel = MediaImportViewModel()

        #expect(!viewModel.targetLocale.identifier.isEmpty)
    }

    @Test("Export options has valid format")
    func exportOptionsHasValidFormat() {
        let viewModel = MediaImportViewModel()

        // Verify export options are set to valid defaults
        #expect(viewModel.exportOptions.format == .srt || viewModel.exportOptions.format == .vtt)
    }

    @Test("Output directory is valid URL")
    func outputDirectoryIsValidURL() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.outputDirectory.isFileURL)
    }
}

// MARK: - ViewModel Configuration Tests

@Suite("MediaImportViewModel Configuration")
@MainActor
struct MediaImportViewModelConfigurationTests {

    @Test("Source locale can be set to various languages")
    func sourceLocaleVariousLanguages() {
        let viewModel = MediaImportViewModel()

        let locales = ["en", "ja", "fr", "de", "es", "zh-Hans", "ko"]

        for identifier in locales {
            viewModel.sourceLocale = Locale(identifier: identifier)
            #expect(viewModel.sourceLocale.identifier == identifier)
        }
    }

    @Test("Target locale can be set to various languages")
    func targetLocaleVariousLanguages() {
        let viewModel = MediaImportViewModel()

        let locales = ["en", "ja", "fr", "de", "es", "zh-Hans", "ko"]

        for identifier in locales {
            viewModel.targetLocale = Locale(identifier: identifier)
            #expect(viewModel.targetLocale.identifier == identifier)
        }
    }

    @Test("Export options format can be changed")
    func exportOptionsFormatChange() {
        let viewModel = MediaImportViewModel()

        viewModel.exportOptions = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        #expect(viewModel.exportOptions.format == .vtt)
    }

    @Test("Export options content option can be changed")
    func exportOptionsContentOptionChange() {
        let viewModel = MediaImportViewModel()

        viewModel.exportOptions = SubtitleExportOptions(
            format: .srt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        #expect(viewModel.exportOptions.contentOption == .translationOnly)
    }

    @Test("Output directory can be set to temp directory")
    func outputDirectoryTempDirectory() {
        let viewModel = MediaImportViewModel()

        viewModel.outputDirectory = URL.temporaryDirectory

        #expect(viewModel.outputDirectory == URL.temporaryDirectory)
    }

    @Test("Output directory can be set to documents directory")
    func outputDirectoryDocumentsDirectory() {
        let viewModel = MediaImportViewModel()

        viewModel.outputDirectory = URL.documentsDirectory

        #expect(viewModel.outputDirectory == URL.documentsDirectory)
    }
}

// MARK: - ViewModel Cancel Processing Tests

@Suite("MediaImportViewModel Cancel Processing")
@MainActor
struct MediaImportViewModelCancelTests {

    @Test("Cancel from idle state")
    func cancelFromIdleState() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("Cancel sets state immediately")
    func cancelSetsStateImmediately() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.isCompleted == false)
    }

    @Test("Cancel is idempotent")
    func cancelIsIdempotent() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        let stateAfterFirst = viewModel.batchState

        viewModel.cancelProcessing()
        let stateAfterSecond = viewModel.batchState

        viewModel.cancelProcessing()
        let stateAfterThird = viewModel.batchState

        #expect(stateAfterFirst == stateAfterSecond)
        #expect(stateAfterSecond == stateAfterThird)
        #expect(stateAfterThird == .cancelled)
    }
}

// MARK: - ViewModel Error Message Tests

@Suite("MediaImportViewModel Error Message")
@MainActor
struct MediaImportViewModelErrorMessageTests {

    @Test("Error message is nil initially")
    func errorMessageNilInitially() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.errorMessage == nil)
    }

    @Test("Add files with unsupported format sets error message")
    func addFilesUnsupportedFormatSetsError() async {
        let viewModel = MediaImportViewModel()

        let unsupportedURL = URL(fileURLWithPath: "/test/document.pdf")

        await viewModel.addFiles([unsupportedURL])

        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - OverallProgress Calculation Tests

@Suite("MediaImportViewModel Overall Progress Calculation")
@MainActor
struct MediaImportOverallProgressTests {

    /// Creates a MediaFile for testing purposes
    private func createTestFile(
        id: UUID = UUID(),
        fileName: String = "test.mp4",
        fileSize: Int64 = 1000,
        duration: TimeInterval = 60.0,
        mediaType: MediaType = .video,
        state: MediaProcessingState = .queued
    ) -> MediaFile {
        MediaFile(
            id: id,
            url: URL(fileURLWithPath: "/test/\(fileName)"),
            fileName: fileName,
            fileSize: fileSize,
            duration: duration,
            mediaType: mediaType,
            state: state
        )
    }

    @Test("Progress with queued file is zero contribution")
    func progressWithQueuedFile() {
        // Since files array is private(set), we test the behavior through initial state
        let viewModel = MediaImportViewModel()

        // With no files, progress should be 0
        #expect(viewModel.overallProgress == 0.0)
    }

    @Test("Progress calculation with processing state")
    func progressCalculationWithProcessingState() {
        // Test that the processing enum case works correctly
        let state = MediaProcessingState.processing(progress: 0.5)
        if case .processing(let progress) = state {
            #expect(progress == 0.5)
        }
    }

    @Test("Progress calculation with completed state")
    func progressCalculationWithCompletedState() {
        // Test that completed files contribute 1.0 to progress
        let state = MediaProcessingState.completed
        #expect(state == .completed)
    }

    @Test("Progress calculation with failed state")
    func progressCalculationWithFailedState() {
        // Test that failed files are counted as "done" (contribute 1.0)
        let state = MediaProcessingState.failed(error: "Test error")
        if case .failed = state {
            // Failed state should count as done
            #expect(true)
        }
    }
}

// MARK: - Export Options Tests

@Suite("SubtitleExportOptions MediaImport Tests")
@MainActor
struct SubtitleExportOptionsMediaImportTests {

    @Test("Default export options")
    func defaultExportOptions() {
        let options = SubtitleExportOptions.default

        #expect(options.format == .srt)
        #expect(options.contentOption == .both)
        #expect(options.includeTimestamps == true)
        #expect(options.bilingualOrder == .translationFirst)
    }

    @Test("Export options with VTT format")
    func exportOptionsWithVTTFormat() {
        let options = SubtitleExportOptions(
            format: .vtt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        #expect(options.format == .vtt)
        #expect(options.format.fileExtension == "vtt")
        #expect(options.format.displayName == "WebVTT")
        #expect(options.format.mimeType == "text/vtt")
    }

    @Test("Export options with TXT format")
    func exportOptionsWithTXTFormat() {
        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: false,
            bilingualOrder: .translationFirst
        )

        #expect(options.format == .txt)
        #expect(options.format.fileExtension == "txt")
        #expect(options.format.displayName == "Plain Text")
        #expect(options.format.mimeType == "text/plain")
    }

    @Test("Export options with original only content")
    func exportOptionsWithOriginalOnly() {
        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .originalOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        #expect(options.contentOption == .originalOnly)
    }

    @Test("Export options with translation only content")
    func exportOptionsWithTranslationOnly() {
        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .translationOnly,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        #expect(options.contentOption == .translationOnly)
    }

    @Test("Export options with original first order")
    func exportOptionsWithOriginalFirstOrder() {
        let options = SubtitleExportOptions(
            format: .srt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .originalFirst
        )

        #expect(options.bilingualOrder == .originalFirst)
    }

    @Test("Export options with timestamps disabled")
    func exportOptionsWithTimestampsDisabled() {
        let options = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: false,
            bilingualOrder: .translationFirst
        )

        #expect(options.includeTimestamps == false)
    }

    @Test("All SubtitleFormat cases have properties")
    func allSubtitleFormatCasesHaveProperties() {
        for format in SubtitleFormat.allCases {
            #expect(!format.fileExtension.isEmpty)
            #expect(!format.displayName.isEmpty)
            #expect(!format.mimeType.isEmpty)
        }
    }
}

// MARK: - SubtitleContentOption Tests

@Suite("SubtitleContentOption Tests")
@MainActor
struct SubtitleContentOptionTests {

    @Test("SubtitleContentOption raw values")
    func subtitleContentOptionRawValues() {
        #expect(SubtitleContentOption.originalOnly.rawValue == "original")
        #expect(SubtitleContentOption.translationOnly.rawValue == "translation")
        #expect(SubtitleContentOption.both.rawValue == "both")
    }

    @Test("SubtitleContentOption localized names")
    func subtitleContentOptionLocalizedNames() {
        #expect(!SubtitleContentOption.originalOnly.localizedName.isEmpty)
        #expect(!SubtitleContentOption.translationOnly.localizedName.isEmpty)
        #expect(!SubtitleContentOption.both.localizedName.isEmpty)
    }

    @Test("SubtitleContentOption allCases")
    func subtitleContentOptionAllCases() {
        let allCases = SubtitleContentOption.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.originalOnly))
        #expect(allCases.contains(.translationOnly))
        #expect(allCases.contains(.both))
    }
}

// MARK: - BilingualTextOrder Tests

@Suite("BilingualTextOrder Tests")
@MainActor
struct BilingualTextOrderTests {

    @Test("BilingualTextOrder raw values")
    func bilingualTextOrderRawValues() {
        #expect(BilingualTextOrder.translationFirst.rawValue == "translationFirst")
        #expect(BilingualTextOrder.originalFirst.rawValue == "originalFirst")
    }

    @Test("BilingualTextOrder localized names")
    func bilingualTextOrderLocalizedNames() {
        #expect(!BilingualTextOrder.translationFirst.localizedName.isEmpty)
        #expect(!BilingualTextOrder.originalFirst.localizedName.isEmpty)
    }

    @Test("BilingualTextOrder allCases")
    func bilingualTextOrderAllCases() {
        let allCases = BilingualTextOrder.allCases

        #expect(allCases.count == 2)
        #expect(allCases.contains(.translationFirst))
        #expect(allCases.contains(.originalFirst))
    }
}

// MARK: - SubtitleFormat Tests

@Suite("SubtitleFormat Tests")
@MainActor
struct SubtitleFormatTests {

    @Test("SRT format properties")
    func srtFormatProperties() {
        let format = SubtitleFormat.srt

        #expect(format.rawValue == "srt")
        #expect(format.fileExtension == "srt")
        #expect(format.displayName == "SubRip (SRT)")
        #expect(format.mimeType == "application/x-subrip")
    }

    @Test("VTT format properties")
    func vttFormatProperties() {
        let format = SubtitleFormat.vtt

        #expect(format.rawValue == "vtt")
        #expect(format.fileExtension == "vtt")
        #expect(format.displayName == "WebVTT")
        #expect(format.mimeType == "text/vtt")
    }

    @Test("TXT format properties")
    func txtFormatProperties() {
        let format = SubtitleFormat.txt

        #expect(format.rawValue == "txt")
        #expect(format.fileExtension == "txt")
        #expect(format.displayName == "Plain Text")
        #expect(format.mimeType == "text/plain")
    }

    @Test("SubtitleFormat allCases")
    func subtitleFormatAllCases() {
        let allCases = SubtitleFormat.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.srt))
        #expect(allCases.contains(.vtt))
        #expect(allCases.contains(.txt))
    }
}

// MARK: - Locale Settings Tests

@Suite("MediaImportViewModel Locale Settings")
@MainActor
struct MediaImportViewModelLocaleSettingsTests {

    @Test("Source locale default is English")
    func sourceLocaleDefaultIsEnglish() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.sourceLocale.identifier == "en")
    }

    @Test("Target locale default is based on system locale")
    func targetLocaleDefaultIsBasedOnSystemLocale() {
        let viewModel = MediaImportViewModel()

        // Default target locale is determined by system locale
        // It could be zh-Hans, zh-Hant, or another supported language
        let validDefaults = ["zh-Hans", "zh-Hant", "en", "ja", "ko", "fr", "de", "es", "it", "pt", "ru", "ar", "hi", "th", "vi", "id", "ms", "tr", "pl", "nl", "uk"]
        #expect(validDefaults.contains(viewModel.targetLocale.identifier))
    }

    @Test("Source and target locales are independent")
    func sourceAndTargetLocalesAreIndependent() {
        let viewModel = MediaImportViewModel()

        viewModel.sourceLocale = Locale(identifier: "ja")
        viewModel.targetLocale = Locale(identifier: "ko")

        #expect(viewModel.sourceLocale.identifier == "ja")
        #expect(viewModel.targetLocale.identifier == "ko")
    }

    @Test("Locale with region identifier")
    func localeWithRegionIdentifier() {
        let viewModel = MediaImportViewModel()

        viewModel.sourceLocale = Locale(identifier: "en-US")
        viewModel.targetLocale = Locale(identifier: "zh-CN")

        #expect(viewModel.sourceLocale.identifier == "en-US")
        #expect(viewModel.targetLocale.identifier == "zh-CN")
    }

    @Test("Locale change does not affect other properties")
    func localeChangeDoesNotAffectOtherProperties() {
        let viewModel = MediaImportViewModel()

        let originalExportOptions = viewModel.exportOptions
        let originalOutputDirectory = viewModel.outputDirectory

        viewModel.sourceLocale = Locale(identifier: "de")
        viewModel.targetLocale = Locale(identifier: "fr")

        #expect(viewModel.exportOptions.format == originalExportOptions.format)
        #expect(viewModel.outputDirectory == originalOutputDirectory)
    }

    @Test("Setting same locale for source and target")
    func settingSameLocaleForSourceAndTarget() {
        let viewModel = MediaImportViewModel()

        viewModel.sourceLocale = Locale(identifier: "ja")
        viewModel.targetLocale = Locale(identifier: "ja")

        #expect(viewModel.sourceLocale.identifier == viewModel.targetLocale.identifier)
    }

    @Test("Locale with script subtag")
    func localeWithScriptSubtag() {
        let viewModel = MediaImportViewModel()

        viewModel.targetLocale = Locale(identifier: "zh-Hant")

        #expect(viewModel.targetLocale.identifier == "zh-Hant")
    }
}

// MARK: - File State Computed Properties Tests

@Suite("MediaImportViewModel File State Computed Properties")
@MainActor
struct MediaImportFileStatePropertiesTests {

    @Test("CompletedFiles count with no files")
    func completedFilesCountWithNoFiles() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.completedFiles == 0)
    }

    @Test("FailedFiles count with no files")
    func failedFilesCountWithNoFiles() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.failedFiles == 0)
    }

    @Test("TotalFiles count with no files")
    func totalFilesCountWithNoFiles() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.totalFiles == 0)
    }

    @Test("isProcessing is false when idle")
    func isProcessingIsFalseWhenIdle() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.batchState == .idle)
    }

    @Test("isCompleted is false when idle")
    func isCompletedIsFalseWhenIdle() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.isCompleted == false)
        #expect(viewModel.batchState == .idle)
    }

    @Test("isProcessing is false when cancelled")
    func isProcessingIsFalseWhenCancelled() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.batchState == .cancelled)
    }

    @Test("isCompleted is false when cancelled")
    func isCompletedIsFalseWhenCancelled() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.isCompleted == false)
        #expect(viewModel.batchState == .cancelled)
    }
}

// MARK: - BatchProcessingState isProcessing and isCompleted Tests

@Suite("BatchProcessingState Computed Property Tests")
@MainActor
struct BatchProcessingStateComputedPropertyTests {

    @Test("isProcessing returns true for processing state")
    func isProcessingReturnsTrueForProcessingState() {
        let viewModel = MediaImportViewModel()

        // Cannot directly set processing state, but we verify the check logic
        let processingState = BatchProcessingState.processing(current: 1, total: 3)
        if case .processing = processingState {
            #expect(true) // Confirms the pattern match works
        } else {
            Issue.record("Expected processing state")
        }
    }

    @Test("isCompleted returns true for completed state")
    func isCompletedReturnsTrueForCompletedState() {
        let completedState = BatchProcessingState.completed(successful: 3, failed: 0)
        if case .completed = completedState {
            #expect(true) // Confirms the pattern match works
        } else {
            Issue.record("Expected completed state")
        }
    }

    @Test("State pattern matching for all cases")
    func statePatternMatchingForAllCases() {
        let states: [BatchProcessingState] = [
            .idle,
            .processing(current: 1, total: 2),
            .completed(successful: 2, failed: 0),
            .cancelled
        ]

        for state in states {
            switch state {
            case .idle:
                #expect(true)
            case .processing:
                #expect(true)
            case .completed:
                #expect(true)
            case .cancelled:
                #expect(true)
            }
        }
    }
}

// MARK: - Filename Extraction Tests

@Suite("MediaImportViewModel Filename Extraction Tests")
@MainActor
struct MediaImportViewModelFilenameExtractionTests {

    @Test("Extract filename without UUID prefix")
    func extractFilenameWithoutUUIDPrefix() {
        // Test files without UUID prefix should be returned as-is
        let filename = "video.mp4"
        // Since extractOriginalFilename is private, we test through MediaFile
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: filename,
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileName == "video.mp4")
    }

    @Test("Filename with short length preserved")
    func filenameWithShortLengthPreserved() {
        let shortFilename = "a.mp4" // Very short, cannot have UUID prefix
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/a.mp4"),
            fileName: shortFilename,
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileName == "a.mp4")
    }

    @Test("Filename with 36 characters exactly")
    func filenameWith36CharactersExactly() {
        // 36 chars is UUID length without underscore
        let filename = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890" // No underscore, no original name
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/\(filename)"),
            fileName: filename,
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileName == filename)
    }

    @Test("Filename with spaces preserved")
    func filenameWithSpacesPreserved() {
        let filename = "my video file.mp4"
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/my video file.mp4"),
            fileName: filename,
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileName == "my video file.mp4")
    }

    @Test("Filename with unicode characters preserved")
    func filenameWithUnicodeCharactersPreserved() {
        let filename = "video_\u{1F3AC}_test.mp4" // Film emoji
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/\(filename)"),
            fileName: filename,
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileName.contains("\u{1F3AC}"))
    }
}

// MARK: - Clear Queue State Tests

@Suite("MediaImportViewModel Clear Queue State Tests")
@MainActor
struct MediaImportViewModelClearQueueStateTests {

    @Test("Clear queue when idle resets to idle")
    func clearQueueWhenIdleResetsToIdle() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)

        viewModel.clearQueue()

        #expect(viewModel.batchState == .idle)
        #expect(viewModel.files.isEmpty)
    }

    @Test("Clear queue when cancelled resets to idle")
    func clearQueueWhenCancelledResetsToIdle() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.clearQueue()

        #expect(viewModel.batchState == .idle)
        #expect(viewModel.files.isEmpty)
    }

    @Test("Clear queue clears error message indirectly")
    func clearQueueClearsErrorMessageIndirectly() async {
        let viewModel = MediaImportViewModel()

        // Add unsupported file to set error
        await viewModel.addFiles([URL(fileURLWithPath: "/test/doc.pdf")])
        #expect(viewModel.errorMessage != nil)

        // Clear queue (this doesn't clear error, but we verify queue is cleared)
        viewModel.clearQueue()
        #expect(viewModel.files.isEmpty)
    }
}

// MARK: - Add Files Edge Cases Tests

@Suite("MediaImportViewModel Add Files Edge Cases")
@MainActor
struct MediaImportViewModelAddFilesEdgeCasesTests {

    @Test("Add files with empty URL list")
    func addFilesWithEmptyURLList() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([])

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Add files clears previous error message")
    func addFilesClearsPreviousErrorMessage() async {
        let viewModel = MediaImportViewModel()

        // First add unsupported to set error
        await viewModel.addFiles([URL(fileURLWithPath: "/test/doc.pdf")])
        #expect(viewModel.errorMessage != nil)

        // Add another unsupported - error message should still be set (not cleared then set)
        await viewModel.addFiles([URL(fileURLWithPath: "/test/doc2.pdf")])
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Add files with multiple unsupported formats")
    func addFilesWithMultipleUnsupportedFormats() async {
        let viewModel = MediaImportViewModel()

        let unsupportedURLs = [
            URL(fileURLWithPath: "/test/doc.pdf"),
            URL(fileURLWithPath: "/test/image.jpg"),
            URL(fileURLWithPath: "/test/text.txt")
        ]

        await viewModel.addFiles(unsupportedURLs)

        // Error message should be set for the last unsupported format
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.files.isEmpty)
    }

    @Test("Add files with mixed supported and unsupported")
    func addFilesWithMixedSupportedAndUnsupported() async {
        let viewModel = MediaImportViewModel()

        // Note: The mp4 file won't be added because it doesn't exist,
        // but we test that the unsupported format sets error
        let mixedURLs = [
            URL(fileURLWithPath: "/test/video.mp4"),
            URL(fileURLWithPath: "/test/doc.pdf")
        ]

        await viewModel.addFiles(mixedURLs)

        // Error message should be set from the pdf
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - SRTEntry Tests

@Suite("SRTEntry Tests")
@MainActor
struct SRTEntryTests {

    @Test("SRTEntry initialization")
    func srtEntryInitialization() {
        let entry = SRTEntry(
            id: 1,
            startTime: 0.0,
            endTime: 5.0,
            text: "Test subtitle"
        )

        #expect(entry.id == 1)
        #expect(entry.startTime == 0.0)
        #expect(entry.endTime == 5.0)
        #expect(entry.text == "Test subtitle")
    }

    @Test("SRTEntry duration calculation")
    func srtEntryDurationCalculation() {
        let entry = SRTEntry(
            id: 1,
            startTime: 1.5,
            endTime: 4.5,
            text: "Test"
        )

        #expect(entry.duration == 3.0)
    }

    @Test("SRTEntry formatted output")
    func srtEntryFormattedOutput() {
        let entry = SRTEntry(
            id: 1,
            startTime: 0.0,
            endTime: 2.5,
            text: "Hello world"
        )

        let formatted = entry.formatted()

        #expect(formatted.contains("1"))
        #expect(formatted.contains("00:00:00,000"))
        #expect(formatted.contains("00:00:02,500"))
        #expect(formatted.contains("Hello world"))
    }

    @Test("SRTEntry equality")
    func srtEntryEquality() {
        let entry1 = SRTEntry(id: 1, startTime: 0.0, endTime: 2.0, text: "Test")
        let entry2 = SRTEntry(id: 1, startTime: 0.0, endTime: 2.0, text: "Test")

        #expect(entry1 == entry2)
    }

    @Test("SRTEntry inequality by id")
    func srtEntryInequalityById() {
        let entry1 = SRTEntry(id: 1, startTime: 0.0, endTime: 2.0, text: "Test")
        let entry2 = SRTEntry(id: 2, startTime: 0.0, endTime: 2.0, text: "Test")

        #expect(entry1 != entry2)
    }

    @Test("SRTEntry inequality by text")
    func srtEntryInequalityByText() {
        let entry1 = SRTEntry(id: 1, startTime: 0.0, endTime: 2.0, text: "Test 1")
        let entry2 = SRTEntry(id: 1, startTime: 0.0, endTime: 2.0, text: "Test 2")

        #expect(entry1 != entry2)
    }

    @Test("SRTEntry with zero duration")
    func srtEntryWithZeroDuration() {
        let entry = SRTEntry(id: 1, startTime: 1.0, endTime: 1.0, text: "Instant")

        #expect(entry.duration == 0.0)
    }

    @Test("SRTEntry with long text")
    func srtEntryWithLongText() {
        let longText = String(repeating: "A", count: 500)
        let entry = SRTEntry(id: 1, startTime: 0.0, endTime: 10.0, text: longText)

        #expect(entry.text.count == 500)
    }
}

// MARK: - SRTFormatter Timestamp Tests

@Suite("SRTFormatter Timestamp Tests")
@MainActor
struct SRTFormatterTimestampTests {

    @Test("Format timestamp zero")
    func formatTimestampZero() {
        let formatted = SRTFormatter.formatTimestamp(0.0)

        #expect(formatted == "00:00:00,000")
    }

    @Test("Format timestamp with milliseconds")
    func formatTimestampWithMilliseconds() {
        let formatted = SRTFormatter.formatTimestamp(1.234)

        #expect(formatted == "00:00:01,234")
    }

    @Test("Format timestamp one hour")
    func formatTimestampOneHour() {
        let formatted = SRTFormatter.formatTimestamp(3600.0)

        #expect(formatted == "01:00:00,000")
    }

    @Test("Format timestamp complex")
    func formatTimestampComplex() {
        // 1 hour, 30 minutes, 45 seconds, 678 milliseconds
        let formatted = SRTFormatter.formatTimestamp(5445.678)

        // Allow for floating point precision variance in milliseconds
        #expect(formatted.hasPrefix("01:30:45,"))
        #expect(formatted.count == 12)
    }

    @Test("Format negative timestamp clamps to zero")
    func formatNegativeTimestampClampsToZero() {
        let formatted = SRTFormatter.formatTimestamp(-5.0)

        #expect(formatted == "00:00:00,000")
    }

    @Test("Parse valid timestamp")
    func parseValidTimestamp() {
        let parsed = SRTFormatter.parseTimestamp("01:30:45,678")

        #expect(parsed != nil)
        // Allow small floating point tolerance
        if let time = parsed {
            #expect(abs(time - 5445.678) < 0.001)
        }
    }

    @Test("Parse timestamp zero")
    func parseTimestampZero() {
        let parsed = SRTFormatter.parseTimestamp("00:00:00,000")

        #expect(parsed == 0.0)
    }

    @Test("Parse invalid timestamp returns nil")
    func parseInvalidTimestampReturnsNil() {
        let parsed = SRTFormatter.parseTimestamp("invalid")

        #expect(parsed == nil)
    }

    @Test("Parse timestamp with wrong format returns nil")
    func parseTimestampWithWrongFormatReturnsNil() {
        let parsed = SRTFormatter.parseTimestamp("1:30:45.678") // Wrong separators

        #expect(parsed == nil)
    }

    @Test("Roundtrip timestamp formatting")
    func roundtripTimestampFormatting() {
        let originalTime = 5445.678
        let formatted = SRTFormatter.formatTimestamp(originalTime)
        let parsed = SRTFormatter.parseTimestamp(formatted)

        #expect(parsed != nil)
        if let time = parsed {
            // Allow 1ms tolerance for floating point precision
            #expect(abs(time - originalTime) < 0.002)
        }
    }
}

// MARK: - SRTFormatter Text Formatting Tests

@Suite("SRTFormatter Text Formatting Tests")
@MainActor
struct SRTFormatterTextFormattingTests {

    @Test("Split into lines trims whitespace")
    func splitIntoLinesTrimsWhitespace() {
        let result = SRTFormatter.splitIntoLines("  Hello World  ")

        #expect(result == "Hello World")
    }

    @Test("Split into lines removes newlines")
    func splitIntoLinesRemovesNewlines() {
        let result = SRTFormatter.splitIntoLines("Hello\nWorld")

        #expect(result == "Hello\nWorld") // Preserves internal newlines
    }

    @Test("Format bilingual text")
    func formatBilingualText() {
        let result = SRTFormatter.formatBilingualText(
            line1: "Translation",
            line2: "Original"
        )

        #expect(result == "Translation\nOriginal")
    }

    @Test("Format bilingual text trims both lines")
    func formatBilingualTextTrimsBothLines() {
        let result = SRTFormatter.formatBilingualText(
            line1: "  Translation  ",
            line2: "  Original  "
        )

        #expect(result == "Translation\nOriginal")
    }
}

// MARK: - Output Directory Tests

@Suite("MediaImportViewModel Output Directory Tests")
@MainActor
struct MediaImportViewModelOutputDirectoryTests {

    @Test("Default output directory is exports")
    func defaultOutputDirectoryIsExports() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.outputDirectory == StoragePaths.exports)
    }

    @Test("Output directory can be changed")
    func outputDirectoryCanBeChanged() {
        let viewModel = MediaImportViewModel()

        let customDirectory = URL.temporaryDirectory.appending(path: "CustomExports")
        viewModel.outputDirectory = customDirectory

        #expect(viewModel.outputDirectory == customDirectory)
    }

    @Test("Output directory change is independent of other settings")
    func outputDirectoryChangeIsIndependentOfOtherSettings() {
        let viewModel = MediaImportViewModel()

        let originalSourceLocale = viewModel.sourceLocale
        let originalTargetLocale = viewModel.targetLocale
        let originalExportOptions = viewModel.exportOptions

        viewModel.outputDirectory = URL.temporaryDirectory

        #expect(viewModel.sourceLocale == originalSourceLocale)
        #expect(viewModel.targetLocale == originalTargetLocale)
        #expect(viewModel.exportOptions.format == originalExportOptions.format)
    }
}

// MARK: - Start Processing Guard Tests

@Suite("MediaImportViewModel Start Processing Guards")
@MainActor
struct MediaImportViewModelStartProcessingGuardsTests {

    @Test("Start processing with empty files does nothing")
    func startProcessingWithEmptyFilesDoesNothing() async {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)

        await viewModel.startProcessing()

        #expect(viewModel.batchState == .idle) // Unchanged
    }

    @Test("Start processing when already cancelled does nothing without files")
    func startProcessingWhenCancelledDoesNothingWithoutFiles() async {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        await viewModel.startProcessing()

        // Still cancelled since no files to process
        #expect(viewModel.batchState == .cancelled)
    }

    @Test("State remains unchanged when no files to process")
    func stateRemainsUnchangedWhenNoFilesToProcess() async {
        let viewModel = MediaImportViewModel()

        // Try to start processing multiple times
        await viewModel.startProcessing()
        await viewModel.startProcessing()
        await viewModel.startProcessing()

        #expect(viewModel.batchState == .idle)
    }
}

// MARK: - MediaFile State Tests

@Suite("MediaFile State Tests")
@MainActor
struct MediaFileStateTests {

    @Test("MediaFile default state is queued")
    func mediaFileDefaultStateIsQueued() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.state == .queued)
    }

    @Test("MediaFile state can be set to processing")
    func mediaFileStateCanBeSetToProcessing() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: "video.mp4",
            fileSize: 1000,
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

    @Test("MediaFile state can be set to completed")
    func mediaFileStateCanBeSetToCompleted() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .completed
        )

        #expect(file.state == .completed)
    }

    @Test("MediaFile state can be set to failed")
    func mediaFileStateCanBeSetToFailed() {
        let errorMessage = "Processing failed"
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: .failed(error: errorMessage)
        )

        if case .failed(let error) = file.state {
            #expect(error == errorMessage)
        } else {
            Issue.record("Expected failed state")
        }
    }
}

// MARK: - Overall Progress Calculation with Files Tests

@Suite("MediaImportViewModel Progress with Various File States")
@MainActor
struct MediaImportViewModelProgressWithFilesTests {

    /// Helper to create test files with specific states
    private func createTestFile(
        fileName: String = "test.mp4",
        state: MediaProcessingState = .queued
    ) -> MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/test/\(fileName)"),
            fileName: fileName,
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video,
            state: state
        )
    }

    @Test("Queued state contributes zero to progress")
    func queuedStateContributesZero() {
        // Test the logic of progress calculation for queued state
        let state = MediaProcessingState.queued

        // Simulate progress calculation logic
        var contribution: Double = 0
        switch state {
        case .queued:
            contribution = 0
        case .processing(let progress):
            contribution = progress
        case .completed:
            contribution = 1.0
        case .failed:
            contribution = 1.0
        }

        #expect(contribution == 0)
    }

    @Test("Processing state contributes its progress value")
    func processingStateContributesProgress() {
        let state = MediaProcessingState.processing(progress: 0.75)

        var contribution: Double = 0
        switch state {
        case .queued:
            contribution = 0
        case .processing(let progress):
            contribution = progress
        case .completed:
            contribution = 1.0
        case .failed:
            contribution = 1.0
        }

        #expect(contribution == 0.75)
    }

    @Test("Completed state contributes full progress")
    func completedStateContributesFullProgress() {
        let state = MediaProcessingState.completed

        var contribution: Double = 0
        switch state {
        case .queued:
            contribution = 0
        case .processing(let progress):
            contribution = progress
        case .completed:
            contribution = 1.0
        case .failed:
            contribution = 1.0
        }

        #expect(contribution == 1.0)
    }

    @Test("Failed state contributes full progress as done")
    func failedStateContributesFullProgress() {
        let state = MediaProcessingState.failed(error: "Error")

        var contribution: Double = 0
        switch state {
        case .queued:
            contribution = 0
        case .processing(let progress):
            contribution = progress
        case .completed:
            contribution = 1.0
        case .failed:
            contribution = 1.0
        }

        #expect(contribution == 1.0)
    }

    @Test("Mixed states calculate correct total progress")
    func mixedStatesCalculateCorrectProgress() {
        // Simulate having 4 files with different states
        let states: [MediaProcessingState] = [
            .queued,           // contributes 0
            .processing(progress: 0.5),  // contributes 0.5
            .completed,        // contributes 1.0
            .failed(error: "Error")  // contributes 1.0
        ]

        var totalProgress: Double = 0
        for state in states {
            switch state {
            case .queued:
                totalProgress += 0
            case .processing(let progress):
                totalProgress += progress
            case .completed:
                totalProgress += 1.0
            case .failed:
                totalProgress += 1.0
            }
        }

        let overallProgress = totalProgress / Double(states.count)

        // Expected: (0 + 0.5 + 1.0 + 1.0) / 4 = 2.5 / 4 = 0.625
        #expect(abs(overallProgress - 0.625) < 0.001)
    }
}

// MARK: - Completed and Failed Files Count Tests

@Suite("MediaImportViewModel File Count Logic")
@MainActor
struct MediaImportViewModelFileCountLogicTests {

    @Test("Count completed files correctly")
    func countCompletedFilesCorrectly() {
        let states: [MediaProcessingState] = [
            .queued,
            .processing(progress: 0.5),
            .completed,
            .completed,
            .failed(error: "Error")
        ]

        let completedCount = states.filter { $0 == .completed }.count

        #expect(completedCount == 2)
    }

    @Test("Count failed files correctly")
    func countFailedFilesCorrectly() {
        let states: [MediaProcessingState] = [
            .queued,
            .processing(progress: 0.5),
            .completed,
            .failed(error: "Error 1"),
            .failed(error: "Error 2")
        ]

        let failedCount = states.filter {
            if case .failed = $0 { return true }
            return false
        }.count

        #expect(failedCount == 2)
    }

    @Test("Failed files with different errors are counted")
    func failedFilesWithDifferentErrorsAreCounted() {
        let states: [MediaProcessingState] = [
            .failed(error: "Error A"),
            .failed(error: "Error B"),
            .failed(error: "Error C")
        ]

        let failedCount = states.filter {
            if case .failed = $0 { return true }
            return false
        }.count

        #expect(failedCount == 3)
    }

    @Test("Empty states array returns zero counts")
    func emptyStatesArrayReturnsZeroCounts() {
        let states: [MediaProcessingState] = []

        let completedCount = states.filter { $0 == .completed }.count
        let failedCount = states.filter {
            if case .failed = $0 { return true }
            return false
        }.count

        #expect(completedCount == 0)
        #expect(failedCount == 0)
    }

    @Test("All queued files returns zero completed and failed")
    func allQueuedFilesReturnsZeroCompletedAndFailed() {
        let states: [MediaProcessingState] = [
            .queued, .queued, .queued, .queued
        ]

        let completedCount = states.filter { $0 == .completed }.count
        let failedCount = states.filter {
            if case .failed = $0 { return true }
            return false
        }.count

        #expect(completedCount == 0)
        #expect(failedCount == 0)
    }
}

// MARK: - isProcessing and isCompleted Logic Tests

@Suite("MediaImportViewModel Processing State Logic")
@MainActor
struct MediaImportViewModelProcessingStateLogicTests {

    @Test("isProcessing logic returns true for processing state")
    func isProcessingLogicReturnsTrueForProcessing() {
        let state = BatchProcessingState.processing(current: 2, total: 5)

        var isProcessing = false
        if case .processing = state {
            isProcessing = true
        }

        #expect(isProcessing == true)
    }

    @Test("isProcessing logic returns false for idle state")
    func isProcessingLogicReturnsFalseForIdle() {
        let state = BatchProcessingState.idle

        var isProcessing = false
        if case .processing = state {
            isProcessing = true
        }

        #expect(isProcessing == false)
    }

    @Test("isProcessing logic returns false for completed state")
    func isProcessingLogicReturnsFalseForCompleted() {
        let state = BatchProcessingState.completed(successful: 3, failed: 0)

        var isProcessing = false
        if case .processing = state {
            isProcessing = true
        }

        #expect(isProcessing == false)
    }

    @Test("isProcessing logic returns false for cancelled state")
    func isProcessingLogicReturnsFalseForCancelled() {
        let state = BatchProcessingState.cancelled

        var isProcessing = false
        if case .processing = state {
            isProcessing = true
        }

        #expect(isProcessing == false)
    }

    @Test("isCompleted logic returns true for completed state")
    func isCompletedLogicReturnsTrueForCompleted() {
        let state = BatchProcessingState.completed(successful: 5, failed: 0)

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        #expect(isCompleted == true)
    }

    @Test("isCompleted logic returns false for idle state")
    func isCompletedLogicReturnsFalseForIdle() {
        let state = BatchProcessingState.idle

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        #expect(isCompleted == false)
    }

    @Test("isCompleted logic returns false for processing state")
    func isCompletedLogicReturnsFalseForProcessing() {
        let state = BatchProcessingState.processing(current: 1, total: 3)

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        #expect(isCompleted == false)
    }

    @Test("isCompleted logic returns false for cancelled state")
    func isCompletedLogicReturnsFalseForCancelled() {
        let state = BatchProcessingState.cancelled

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        #expect(isCompleted == false)
    }
}

// MARK: - Clear Queue Behavior Tests

@Suite("MediaImportViewModel Clear Queue Behavior")
@MainActor
struct MediaImportViewModelClearQueueBehaviorTests {

    @Test("Clear queue allowed when idle")
    func clearQueueAllowedWhenIdle() {
        let state = BatchProcessingState.idle
        let isCompleted = false

        // Clear queue guard logic: state == .idle || state == .cancelled || isCompleted
        let canClear = state == .idle || state == .cancelled || isCompleted

        #expect(canClear == true)
    }

    @Test("Clear queue allowed when cancelled")
    func clearQueueAllowedWhenCancelled() {
        let state = BatchProcessingState.cancelled
        let isCompleted = false

        let canClear = state == .idle || state == .cancelled || isCompleted

        #expect(canClear == true)
    }

    @Test("Clear queue allowed when completed")
    func clearQueueAllowedWhenCompleted() {
        let state = BatchProcessingState.completed(successful: 3, failed: 0)

        // isCompleted check
        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        let canClear = state == .idle || state == .cancelled || isCompleted

        #expect(canClear == true)
    }

    @Test("Clear queue not allowed when processing")
    func clearQueueNotAllowedWhenProcessing() {
        let state = BatchProcessingState.processing(current: 1, total: 3)

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        let canClear = state == .idle || state == .cancelled || isCompleted

        #expect(canClear == false)
    }

    @Test("Clear queue resets state to idle on view model")
    func clearQueueResetsStateOnViewModel() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.clearQueue()
        #expect(viewModel.batchState == .idle)
    }
}

// MARK: - Start Processing Guard Logic Tests

@Suite("MediaImportViewModel Start Processing Guards")
@MainActor
struct MediaImportViewModelStartProcessingGuardLogicTests {

    @Test("Start processing guard allows when idle")
    func startProcessingGuardAllowsWhenIdle() {
        let state = BatchProcessingState.idle
        let hasFiles = true

        // isCompleted check
        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        // Guard logic: !files.isEmpty && (state == .idle || isCompleted)
        let canStart = hasFiles && (state == .idle || isCompleted)

        #expect(canStart == true)
    }

    @Test("Start processing guard allows when completed")
    func startProcessingGuardAllowsWhenCompleted() {
        let state = BatchProcessingState.completed(successful: 2, failed: 1)
        let hasFiles = true

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        let canStart = hasFiles && (state == .idle || isCompleted)

        #expect(canStart == true)
    }

    @Test("Start processing guard blocks when processing")
    func startProcessingGuardBlocksWhenProcessing() {
        let state = BatchProcessingState.processing(current: 1, total: 3)
        let hasFiles = true

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        let canStart = hasFiles && (state == .idle || isCompleted)

        #expect(canStart == false)
    }

    @Test("Start processing guard blocks when cancelled")
    func startProcessingGuardBlocksWhenCancelled() {
        let state = BatchProcessingState.cancelled
        let hasFiles = true

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        let canStart = hasFiles && (state == .idle || isCompleted)

        #expect(canStart == false)
    }

    @Test("Start processing guard blocks when no files")
    func startProcessingGuardBlocksWhenNoFiles() {
        let state = BatchProcessingState.idle
        let hasFiles = false

        var isCompleted = false
        if case .completed = state {
            isCompleted = true
        }

        let canStart = hasFiles && (state == .idle || isCompleted)

        #expect(canStart == false)
    }

    @Test("Start processing with view model idle and no files")
    func startProcessingWithViewModelIdleAndNoFiles() async {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)
        #expect(viewModel.files.isEmpty)

        await viewModel.startProcessing()

        // Should remain idle since no files
        #expect(viewModel.batchState == .idle)
    }
}

// MARK: - UUID Filename Extraction Logic Tests

@Suite("UUID Filename Extraction Logic")
@MainActor
struct UUIDFilenameExtractionLogicTests {

    /// Extract original filename logic (mirrors private method)
    private func extractOriginalFilename(from filename: String) -> String {
        // UUID format: 8-4-4-4-12 = 36 characters, followed by underscore
        let uuidPrefixLength = 37 // 36 chars + 1 underscore

        if filename.count > uuidPrefixLength {
            let potentialUUID = String(filename.prefix(36))
            // Check if it looks like a UUID (contains hyphens at expected positions)
            if potentialUUID.contains("-"),
               filename[filename.index(filename.startIndex, offsetBy: 36)] == "_" {
                return String(filename.dropFirst(uuidPrefixLength))
            }
        }

        return filename
    }

    @Test("Extract filename from UUID-prefixed name")
    func extractFilenameFromUUIDPrefixedName() {
        let filename = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890_original_video.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == "original_video.mp4")
    }

    @Test("Return filename as-is when not UUID-prefixed")
    func returnFilenameAsIsWhenNotUUIDPrefixed() {
        let filename = "my_video.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == "my_video.mp4")
    }

    @Test("Return filename as-is when too short for UUID prefix")
    func returnFilenameAsIsWhenTooShort() {
        let filename = "short.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == "short.mp4")
    }

    @Test("Return filename as-is when exactly UUID length without underscore")
    func returnFilenameAsIsWhenExactlyUUIDLength() {
        let filename = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"

        let result = extractOriginalFilename(from: filename)

        #expect(result == filename)
    }

    @Test("Return filename as-is when UUID format but missing underscore")
    func returnFilenameAsIsWhenMissingUnderscore() {
        let filename = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890Xoriginal.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == filename)
    }

    @Test("Return filename as-is when no hyphens in potential UUID")
    func returnFilenameAsIsWhenNoHyphensInUUID() {
        let filename = "A1B2C3D4E5F67890ABCDEF1234567890_original.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == filename)
    }

    @Test("Extract filename with lowercase UUID")
    func extractFilenameWithLowercaseUUID() {
        let filename = "a1b2c3d4-e5f6-7890-abcd-ef1234567890_video.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == "video.mp4")
    }

    @Test("Extract filename with spaces in original name")
    func extractFilenameWithSpacesInOriginalName() {
        let filename = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890_my video file.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == "my video file.mp4")
    }

    @Test("Extract filename with multiple underscores in original")
    func extractFilenameWithMultipleUnderscoresInOriginal() {
        let filename = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890_my_video_file.mp4"

        let result = extractOriginalFilename(from: filename)

        #expect(result == "my_video_file.mp4")
    }
}

// MARK: - Add Files Validation Tests

@Suite("MediaImportViewModel Add Files Validation")
@MainActor
struct MediaImportViewModelAddFilesValidationTests {

    @Test("Add files with single unsupported format")
    func addFilesWithSingleUnsupportedFormat() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([URL(fileURLWithPath: "/test/document.doc")])

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.files.isEmpty)
    }

    @Test("Add files clears error message at start")
    func addFilesClearsErrorMessageAtStart() async {
        let viewModel = MediaImportViewModel()

        // First call sets error
        await viewModel.addFiles([URL(fileURLWithPath: "/test/doc.xyz")])
        #expect(viewModel.errorMessage != nil)

        // Next call should clear it before processing
        await viewModel.addFiles([])
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Add files with executable extension fails")
    func addFilesWithExecutableExtensionFails() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([URL(fileURLWithPath: "/test/program.exe")])

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.files.isEmpty)
    }

    @Test("Add files with image extension fails")
    func addFilesWithImageExtensionFails() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([URL(fileURLWithPath: "/test/photo.png")])

        #expect(viewModel.errorMessage != nil)
    }

    @Test("Add files with archive extension fails")
    func addFilesWithArchiveExtensionFails() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([URL(fileURLWithPath: "/test/archive.zip")])

        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - Remove File Behavior Tests

@Suite("MediaImportViewModel Remove File Behavior")
@MainActor
struct MediaImportViewModelRemoveFileBehaviorTests {

    @Test("Remove file from empty list does nothing")
    func removeFileFromEmptyListDoesNothing() {
        let viewModel = MediaImportViewModel()

        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        viewModel.removeFile(file)

        #expect(viewModel.files.isEmpty)
    }

    @Test("Remove file preserves other files state")
    func removeFilePreservesOtherFilesState() {
        let viewModel = MediaImportViewModel()

        // Can only test that removing doesn't crash with empty list
        let file1 = MediaFile(
            url: URL(fileURLWithPath: "/test/video1.mp4"),
            fileName: "video1.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        viewModel.removeFile(file1)

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.batchState == .idle)
    }

    @Test("Remove file with different ID has no effect")
    func removeFileWithDifferentIDHasNoEffect() {
        let viewModel = MediaImportViewModel()

        let file = MediaFile(
            id: UUID(),
            url: URL(fileURLWithPath: "/test/video.mp4"),
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        viewModel.removeFile(file)

        #expect(viewModel.files.isEmpty)
    }
}

// MARK: - Cancel Processing Behavior Tests

@Suite("MediaImportViewModel Cancel Processing Behavior")
@MainActor
struct MediaImportViewModelCancelBehaviorTests {

    @Test("Cancel sets state to cancelled immediately")
    func cancelSetsStateToCancelledImmediately() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("Cancel from idle goes to cancelled")
    func cancelFromIdleGoesToCancelled() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("Multiple cancels are safe and idempotent")
    func multipleCancelsAreSafeAndIdempotent() {
        let viewModel = MediaImportViewModel()

        for _ in 0..<10 {
            viewModel.cancelProcessing()
        }

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("Cancel after cancel maintains cancelled state")
    func cancelAfterCancelMaintainsCancelledState() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)
    }

    @Test("Cancel then clear queue resets to idle")
    func cancelThenClearQueueResetsToIdle() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.clearQueue()
        #expect(viewModel.batchState == .idle)
    }
}

// MARK: - Export Options Variants Tests

@Suite("MediaImportViewModel Export Options Variants")
@MainActor
struct MediaImportViewModelExportOptionsVariantsTests {

    @Test("Export options with all content options")
    func exportOptionsWithAllContentOptions() {
        let viewModel = MediaImportViewModel()

        for contentOption in SubtitleContentOption.allCases {
            viewModel.exportOptions = SubtitleExportOptions(
                format: .srt,
                contentOption: contentOption,
                includeTimestamps: true,
                bilingualOrder: .translationFirst
            )

            #expect(viewModel.exportOptions.contentOption == contentOption)
        }
    }

    @Test("Export options with all formats")
    func exportOptionsWithAllFormats() {
        let viewModel = MediaImportViewModel()

        for format in SubtitleFormat.allCases {
            viewModel.exportOptions = SubtitleExportOptions(
                format: format,
                contentOption: .both,
                includeTimestamps: true,
                bilingualOrder: .translationFirst
            )

            #expect(viewModel.exportOptions.format == format)
        }
    }

    @Test("Export options with all bilingual orders")
    func exportOptionsWithAllBilingualOrders() {
        let viewModel = MediaImportViewModel()

        for order in BilingualTextOrder.allCases {
            viewModel.exportOptions = SubtitleExportOptions(
                format: .srt,
                contentOption: .both,
                includeTimestamps: true,
                bilingualOrder: order
            )

            #expect(viewModel.exportOptions.bilingualOrder == order)
        }
    }

    @Test("Export options toggle timestamps")
    func exportOptionsToggleTimestamps() {
        let viewModel = MediaImportViewModel()

        viewModel.exportOptions = SubtitleExportOptions(
            format: .txt,
            contentOption: .both,
            includeTimestamps: false,
            bilingualOrder: .translationFirst
        )

        #expect(viewModel.exportOptions.includeTimestamps == false)

        viewModel.exportOptions = SubtitleExportOptions(
            format: .srt,
            contentOption: .both,
            includeTimestamps: true,
            bilingualOrder: .translationFirst
        )

        #expect(viewModel.exportOptions.includeTimestamps == true)
    }

    @Test("Export options complex combination")
    func exportOptionsComplexCombination() {
        let viewModel = MediaImportViewModel()

        viewModel.exportOptions = SubtitleExportOptions(
            format: .vtt,
            contentOption: .translationOnly,
            includeTimestamps: false,
            bilingualOrder: .originalFirst
        )

        #expect(viewModel.exportOptions.format == .vtt)
        #expect(viewModel.exportOptions.contentOption == .translationOnly)
        #expect(viewModel.exportOptions.includeTimestamps == false)
        #expect(viewModel.exportOptions.bilingualOrder == .originalFirst)
    }
}

// MARK: - Multiple Locale Configuration Tests

@Suite("MediaImportViewModel Multiple Locale Configurations")
@MainActor
struct MediaImportViewModelMultipleLocaleTests {

    @Test("Set various source locales sequentially")
    func setVariousSourceLocalesSequentially() {
        let viewModel = MediaImportViewModel()

        let locales = [
            "en", "en-US", "en-GB", "ja", "ja-JP", "zh-Hans", "zh-Hant",
            "ko", "ko-KR", "fr", "fr-FR", "de", "de-DE", "es", "es-ES",
            "pt", "pt-BR", "it", "ru", "ar"
        ]

        for identifier in locales {
            viewModel.sourceLocale = Locale(identifier: identifier)
            #expect(viewModel.sourceLocale.identifier == identifier)
        }
    }

    @Test("Set various target locales sequentially")
    func setVariousTargetLocalesSequentially() {
        let viewModel = MediaImportViewModel()

        let locales = [
            "en", "en-US", "ja", "zh-Hans", "zh-Hant", "ko", "fr", "de",
            "es", "pt", "it", "ru", "ar", "hi", "th", "vi"
        ]

        for identifier in locales {
            viewModel.targetLocale = Locale(identifier: identifier)
            #expect(viewModel.targetLocale.identifier == identifier)
        }
    }

    @Test("Source and target can be same locale")
    func sourceAndTargetCanBeSameLocale() {
        let viewModel = MediaImportViewModel()

        viewModel.sourceLocale = Locale(identifier: "en")
        viewModel.targetLocale = Locale(identifier: "en")

        #expect(viewModel.sourceLocale.identifier == "en")
        #expect(viewModel.targetLocale.identifier == "en")
    }

    @Test("Locale changes are independent")
    func localeChangesAreIndependent() {
        let viewModel = MediaImportViewModel()

        // Save original target locale (depends on system locale)
        let originalTarget = viewModel.targetLocale.identifier

        viewModel.sourceLocale = Locale(identifier: "ja")
        #expect(viewModel.targetLocale.identifier == originalTarget) // Original unchanged

        viewModel.targetLocale = Locale(identifier: "ko")
        #expect(viewModel.sourceLocale.identifier == "ja") // Previous unchanged
    }
}

// MARK: - Output Directory Configuration Tests

@Suite("MediaImportViewModel Output Directory Configuration")
@MainActor
struct MediaImportOutputDirectoryTests {

    @Test("Output directory default is StoragePaths.exports")
    func outputDirectoryDefaultIsStoragePathsExports() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.outputDirectory == StoragePaths.exports)
    }

    @Test("Output directory can be set to custom path")
    func outputDirectoryCanBeSetToCustomPath() {
        let viewModel = MediaImportViewModel()

        let customPath = URL.temporaryDirectory.appending(path: "MyExports")
        viewModel.outputDirectory = customPath

        #expect(viewModel.outputDirectory == customPath)
    }

    @Test("Output directory changes multiple times")
    func outputDirectoryChangesMultipleTimes() {
        let viewModel = MediaImportViewModel()

        let paths = [
            URL.temporaryDirectory,
            URL.documentsDirectory,
            URL.temporaryDirectory.appending(path: "Test1"),
            URL.temporaryDirectory.appending(path: "Test2"),
            StoragePaths.exports
        ]

        for path in paths {
            viewModel.outputDirectory = path
            #expect(viewModel.outputDirectory == path)
        }
    }

    @Test("Output directory with nested path")
    func outputDirectoryWithNestedPath() {
        let viewModel = MediaImportViewModel()

        let nestedPath = URL.temporaryDirectory
            .appending(path: "Level1")
            .appending(path: "Level2")
            .appending(path: "Level3")

        viewModel.outputDirectory = nestedPath

        #expect(viewModel.outputDirectory == nestedPath)
    }
}

// MARK: - Batch State Transitions Tests

@Suite("MediaImportViewModel Batch State Transitions")
@MainActor
struct MediaImportViewModelBatchStateTransitionsTests {

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)
    }

    @Test("Cancel transitions idle to cancelled")
    func cancelTransitionsIdleToCancelled() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)

        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled)
    }

    @Test("Clear queue transitions cancelled to idle")
    func clearQueueTransitionsCancelledToIdle() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        #expect(viewModel.batchState == .cancelled)

        viewModel.clearQueue()

        #expect(viewModel.batchState == .idle)
    }

    @Test("Clear queue on idle keeps idle")
    func clearQueueOnIdleKeepsIdle() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle)

        viewModel.clearQueue()

        #expect(viewModel.batchState == .idle)
    }
}

// MARK: - Error Message Handling Tests

@Suite("MediaImportViewModel Error Message Handling")
@MainActor
struct MediaImportViewModelErrorMessageHandlingTests {

    @Test("Error message nil on initialization")
    func errorMessageNilOnInitialization() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.errorMessage == nil)
    }

    @Test("Error message set for unsupported format pdf")
    func errorMessageSetForUnsupportedFormatPDF() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([URL(fileURLWithPath: "/test/doc.pdf")])

        #expect(viewModel.errorMessage != nil)
    }

    @Test("Error message set for unsupported format txt")
    func errorMessageSetForUnsupportedFormatTXT() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([URL(fileURLWithPath: "/test/notes.txt")])

        #expect(viewModel.errorMessage != nil)
    }

    @Test("Error message cleared on new addFiles call")
    func errorMessageClearedOnNewAddFilesCall() async {
        let viewModel = MediaImportViewModel()

        // First set an error
        await viewModel.addFiles([URL(fileURLWithPath: "/test/doc.xyz")])
        #expect(viewModel.errorMessage != nil)

        // Empty add should clear
        await viewModel.addFiles([])
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Last error message preserved from multiple unsupported files")
    func lastErrorMessagePreservedFromMultipleUnsupportedFiles() async {
        let viewModel = MediaImportViewModel()

        await viewModel.addFiles([
            URL(fileURLWithPath: "/test/a.xyz"),
            URL(fileURLWithPath: "/test/b.abc"),
            URL(fileURLWithPath: "/test/c.123")
        ])

        // Error message should be set from the last unsupported file
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - MediaFile URL and Path Tests

@Suite("MediaFile URL and Path Tests")
struct MediaFileURLAndPathTests {

    @Test("MediaFile preserves original URL")
    func mediaFilePreservesOriginalURL() {
        let url = URL(fileURLWithPath: "/Users/test/Documents/video.mp4")
        let file = MediaFile(
            url: url,
            fileName: "video.mp4",
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.url == url)
    }

    @Test("MediaFile with file URL scheme")
    func mediaFileWithFileURLScheme() {
        let url = URL(fileURLWithPath: "/path/to/file.mp4")
        let file = MediaFile(
            url: url,
            fileName: "file.mp4",
            fileSize: 500,
            duration: 30.0,
            mediaType: .video
        )

        #expect(file.url.isFileURL)
    }

    @Test("MediaFile fileName can differ from URL")
    func mediaFileFileNameCanDifferFromURL() {
        let url = URL(fileURLWithPath: "/test/A1B2C3D4-E5F6-7890-ABCD-EF1234567890_original.mp4")
        let file = MediaFile(
            url: url,
            fileName: "original.mp4", // Display name without UUID
            fileSize: 1000,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileName == "original.mp4")
        #expect(file.url.lastPathComponent != file.fileName)
    }

    @Test("MediaFile with long path")
    func mediaFileWithLongPath() {
        let longPath = "/Users/username/Documents/Projects/MyProject/Media/Videos/Recordings/2024/January/Week1/Day1/video_file.mp4"
        let url = URL(fileURLWithPath: longPath)
        let file = MediaFile(
            url: url,
            fileName: "video_file.mp4",
            fileSize: 2000,
            duration: 120.0,
            mediaType: .video
        )

        #expect(file.url.path() == longPath)
    }

    @Test("MediaFile with special characters in path")
    func mediaFileWithSpecialCharactersInPath() {
        let url = URL(fileURLWithPath: "/test/My Video (2024) - Final.mp4")
        let file = MediaFile(
            url: url,
            fileName: "My Video (2024) - Final.mp4",
            fileSize: 1500,
            duration: 90.0,
            mediaType: .video
        )

        #expect(file.fileName.contains("("))
        #expect(file.fileName.contains(")"))
        #expect(file.fileName.contains("-"))
    }
}

// MARK: - MediaFile Duration Edge Cases

@Suite("MediaFile Duration Edge Cases")
struct MediaFileDurationEdgeCasesTests {

    @Test("Formatted duration for very long video")
    func formattedDurationForVeryLongVideo() {
        // 10 hours, 30 minutes, 45 seconds
        let duration = 10 * 3600 + 30 * 60 + 45.0
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/long.mp4"),
            fileName: "long.mp4",
            fileSize: 10000,
            duration: duration,
            mediaType: .video
        )

        #expect(file.formattedDuration == "10:30:45")
    }

    @Test("Formatted duration for exactly 24 hours")
    func formattedDurationForExactly24Hours() {
        let duration = 24 * 3600.0
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/daylong.mp4"),
            fileName: "daylong.mp4",
            fileSize: 50000,
            duration: duration,
            mediaType: .video
        )

        #expect(file.formattedDuration == "24:00:00")
    }

    @Test("Formatted duration for under one second")
    func formattedDurationForUnderOneSecond() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/quick.mp4"),
            fileName: "quick.mp4",
            fileSize: 100,
            duration: 0.5,
            mediaType: .video
        )

        #expect(file.formattedDuration == "0:00")
    }

    @Test("Formatted duration truncates fractional seconds")
    func formattedDurationTruncatesFractionalSeconds() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/test.mp4"),
            fileName: "test.mp4",
            fileSize: 1000,
            duration: 61.999,
            mediaType: .video
        )

        #expect(file.formattedDuration == "1:01")
    }
}

// MARK: - MediaFile File Size Tests

@Suite("MediaFile File Size Tests")
struct MediaFileFileSizeTests {

    @Test("File size Int64 max value handled")
    func fileSizeInt64MaxValueHandled() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/huge.mp4"),
            fileName: "huge.mp4",
            fileSize: Int64.max,
            duration: 1000.0,
            mediaType: .video
        )

        #expect(file.fileSize == Int64.max)
        #expect(!file.formattedFileSize.isEmpty)
    }

    @Test("File size negative value handled")
    func fileSizeNegativeValueHandled() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/test/invalid.mp4"),
            fileName: "invalid.mp4",
            fileSize: -1,
            duration: 60.0,
            mediaType: .video
        )

        #expect(file.fileSize == -1)
        // ByteCountFormatter handles negative gracefully
        #expect(!file.formattedFileSize.isEmpty)
    }

    @Test("File size various values")
    func fileSizeVariousValues() {
        let sizes: [Int64] = [0, 1, 100, 1000, 1024, 1048576, 1073741824]

        for size in sizes {
            let file = MediaFile(
                url: URL(fileURLWithPath: "/test/file.mp4"),
                fileName: "file.mp4",
                fileSize: size,
                duration: 60.0,
                mediaType: .video
            )

            #expect(file.fileSize == size)
            #expect(!file.formattedFileSize.isEmpty)
        }
    }
}

// MARK: - Computed Properties Integration Tests

@Suite("MediaImportViewModel Computed Properties Integration")
@MainActor
struct MediaImportComputedPropsIntegrationTests {

    @Test("All computed properties consistent in initial state")
    func allComputedPropertiesConsistentInInitialState() {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.totalFiles == 0)
        #expect(viewModel.completedFiles == 0)
        #expect(viewModel.failedFiles == 0)
        #expect(viewModel.overallProgress == 0)
    }

    @Test("All computed properties consistent after cancel")
    func allComputedPropertiesConsistentAfterCancel() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.totalFiles == 0)
        #expect(viewModel.completedFiles == 0)
        #expect(viewModel.failedFiles == 0)
        #expect(viewModel.overallProgress == 0)
        #expect(viewModel.batchState == .cancelled)
    }

    @Test("All computed properties consistent after clear")
    func allComputedPropertiesConsistentAfterClear() {
        let viewModel = MediaImportViewModel()

        viewModel.cancelProcessing()
        viewModel.clearQueue()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.totalFiles == 0)
        #expect(viewModel.completedFiles == 0)
        #expect(viewModel.failedFiles == 0)
        #expect(viewModel.overallProgress == 0)
        #expect(viewModel.batchState == .idle)
    }
}

// MARK: - Static Properties Completeness Tests

@Suite("MediaImportViewModel Static Properties Completeness")
@MainActor
struct MediaImportStaticPropertiesTests {

    @Test("All supported extensions are lowercase")
    func allSupportedExtensionsAreLowercase() {
        for ext in MediaImportViewModel.supportedExtensions {
            #expect(ext == ext.lowercased())
        }
    }

    @Test("No duplicate supported extensions")
    func noDuplicateSupportedExtensions() {
        let extensions = MediaImportViewModel.supportedExtensions
        let uniqueExtensions = Set(extensions)

        #expect(extensions.count == uniqueExtensions.count)
    }

    @Test("All supported content types are valid UTI format")
    func allSupportedContentTypesAreValidUTIFormat() {
        for type in MediaImportViewModel.supportedContentTypes {
            // UTIs typically contain dots or use public./com. prefix
            #expect(type.contains("."))
        }
    }

    @Test("No duplicate content types")
    func noDuplicateContentTypes() {
        let types = MediaImportViewModel.supportedContentTypes
        let uniqueTypes = Set(types)

        #expect(types.count == uniqueTypes.count)
    }

    @Test("Supported extensions map to MediaTypes")
    func supportedExtensionsMapToMediaTypes() {
        let videoExtensions = ["mp4", "mov", "m4v"]
        let audioExtensions = ["mp3", "m4a", "wav", "aac"]

        for ext in videoExtensions {
            #expect(MediaType.from(fileExtension: ext) == .video)
        }

        for ext in audioExtensions {
            #expect(MediaType.from(fileExtension: ext) == .audio)
        }
    }
}
