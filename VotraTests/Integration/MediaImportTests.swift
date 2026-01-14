//
//  MediaImportTests.swift
//  VotraTests
//
//  Integration tests for batch media file import and subtitle generation.
//

import Foundation
import Testing
@testable import Votra

/// Integration tests for batch media processing per SC-008.
///
/// **Prerequisites**: These tests require:
/// - Test media files (mp4, mov, mp3, m4a) in a known location
/// - Speech recognition language packs downloaded
///
/// **Manual Testing Steps**:
/// 1. Place 10 test media files in the test fixtures directory
/// 2. Ensure English speech recognition is available offline
/// 3. Run tests and verify all SRT files are generated
@Suite("Media Import Integration Tests")
struct MediaImportTests {
    // MARK: - Batch Processing Tests

    @Test("Processes batch of 10 files successfully", .disabled("Requires test media files"))
    @MainActor
    func batchProcessing10Files() async throws {
        // Test validates SC-008: Batch processing of 10 files
        // Prerequisites: 10 test media files available

        // Manual test steps:
        // 1. Open Votra app
        // 2. Navigate to Media Import
        // 3. Select 10 media files (mp4, mov, mp3, m4a mix)
        // 4. Start batch processing
        // 5. Wait for all files to complete
        // 6. Verify 10 SRT files are generated
        // 7. Verify each SRT has valid timestamp format
    }

    // MARK: - Format Support Tests

    @Test("Verifies supported formats list")
    @MainActor
    func supportedFormats() async throws {
        // Verify MediaImportViewModel supports expected formats
        let supported = MediaImportViewModel.supportedExtensions

        #expect(supported.contains("mp4"), "Should support mp4")
        #expect(supported.contains("mov"), "Should support mov")
        #expect(supported.contains("mp3"), "Should support mp3")
        #expect(supported.contains("m4a"), "Should support m4a")
    }

    // MARK: - State Tests

    @Test("Initial state is correct")
    @MainActor
    func initialState() async throws {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.batchState == .idle, "Initial batch state should be idle")
        #expect(viewModel.overallProgress == 0.0, "Initial progress should be 0")
        #expect(viewModel.files.isEmpty, "Files should be empty initially")
        #expect(viewModel.isProcessing == false, "Should not be processing initially")
    }

    // MARK: - Cancellation Tests

    @Test("Cancellation updates state correctly")
    @MainActor
    func processingCancellation() async throws {
        let viewModel = MediaImportViewModel()

        // Cancel should update state
        viewModel.cancelProcessing()

        #expect(viewModel.batchState == .cancelled, "State should be cancelled after cancel")
    }

    // MARK: - SRT Output Tests

    @Test("SRT timestamp accuracy", .disabled("Requires test media files with known speech timing"))
    @MainActor
    func srtTimestampAccuracy() async throws {
        // Test validates SC-005: SRT timestamp accuracy ±0.5s
        // Prerequisites: Media file with known speech at specific times

        // Manual test steps:
        // 1. Create/use a test file with speech at known timestamps
        //    - Speech at 1.0s: "Hello"
        //    - Speech at 5.0s: "World"
        //    - Speech at 10.0s: "Test"
        // 2. Process file and export SRT
        // 3. Verify timestamps in SRT are within ±0.5s of actual times
        // 4. Expected: "00:00:01,000 --> 00:00:02,000" for 1.0s speech
    }

    // MARK: - MediaType Tests

    @Test("MediaType detection from file extension")
    func mediaTypeDetection() {
        #expect(MediaType.from(fileExtension: "mp4") == .video)
        #expect(MediaType.from(fileExtension: "mov") == .video)
        #expect(MediaType.from(fileExtension: "MP4") == .video) // Case insensitive
        #expect(MediaType.from(fileExtension: "mp3") == .audio)
        #expect(MediaType.from(fileExtension: "m4a") == .audio)
        #expect(MediaType.from(fileExtension: "txt") == nil) // Unsupported
    }

    // MARK: - Computed Properties Tests

    @Test("Computed properties reflect state correctly")
    @MainActor
    func computedProperties() async throws {
        let viewModel = MediaImportViewModel()

        #expect(viewModel.totalFiles == 0)
        #expect(viewModel.completedFiles == 0)
        #expect(viewModel.failedFiles == 0)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.isProcessing == false)
    }

    // MARK: - Queue Management Tests

    @Test("Clear queue works in idle state")
    @MainActor
    func clearQueueInIdleState() async throws {
        let viewModel = MediaImportViewModel()

        // Should not crash when clearing empty queue
        viewModel.clearQueue()

        #expect(viewModel.files.isEmpty)
    }

    // MARK: - Error Handling Tests

    @Test("MediaImportError provides localized descriptions")
    func errorDescriptions() {
        let unsupportedError = MediaImportError.unsupportedFormat("xyz")
        #expect(unsupportedError.errorDescription != nil)

        let fileNotFoundError = MediaImportError.fileNotFound("test.mp4")
        #expect(fileNotFoundError.errorDescription != nil)

        let cancelledError = MediaImportError.cancelled
        #expect(cancelledError.errorDescription != nil)
    }

    // MARK: - BatchProcessingState Tests

    @Test("BatchProcessingState equality")
    func batchProcessingStateEquality() {
        let idle1 = BatchProcessingState.idle
        let idle2 = BatchProcessingState.idle
        let cancelled1 = BatchProcessingState.cancelled
        let cancelled2 = BatchProcessingState.cancelled
        let processing1 = BatchProcessingState.processing(current: 1, total: 10)
        let processing2 = BatchProcessingState.processing(current: 1, total: 10)
        let completed1 = BatchProcessingState.completed(successful: 5, failed: 0)
        let completed2 = BatchProcessingState.completed(successful: 5, failed: 0)

        #expect(idle1 == idle2)
        #expect(cancelled1 == cancelled2)
        #expect(processing1 == processing2)
        #expect(BatchProcessingState.processing(current: 1, total: 10) != BatchProcessingState.processing(current: 2, total: 10))
        #expect(completed1 == completed2)
    }

    // MARK: - MediaFile Tests

    @Test("MediaFile formatted duration")
    func mediaFileFormattedDuration() {
        let shortFile = MediaFile(
            url: URL(fileURLWithPath: "/test.mp4"),
            fileName: "test.mp4",
            fileSize: 1000,
            duration: 65, // 1 minute 5 seconds
            mediaType: .video
        )

        #expect(shortFile.formattedDuration == "1:05")

        let longFile = MediaFile(
            url: URL(fileURLWithPath: "/test.mp4"),
            fileName: "test.mp4",
            fileSize: 1000,
            duration: 3665, // 1 hour 1 minute 5 seconds
            mediaType: .video
        )

        #expect(longFile.formattedDuration == "1:01:05")
    }
}
