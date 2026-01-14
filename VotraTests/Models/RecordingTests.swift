//
//  RecordingTests.swift
//  VotraTests
//
//  Unit tests for the Recording model.
//

import Testing
import Foundation
import SwiftData
@testable import Votra

// MARK: - Test Helpers

/// Mock formatter that always returns nil to test fallback behavior
final class NilReturningDateComponentsFormatter: DateComponentsFormatter {
    override func string(from ti: TimeInterval) -> String? {
        nil
    }
}

@MainActor
struct RecordingTests {
    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    // MARK: - Initialization Tests

    @Test
    func testDefaultInitialization() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        #expect(recording.audioData == nil)
        #expect(recording.duration == 0)
        #expect(recording.format == .m4a)
        #expect(recording.formatRawValue == "m4a")
        #expect(recording.originalFileName.isEmpty)
        #expect(recording.createdAt <= Date())
        #expect(recording.session == nil)
    }

    @Test
    func testCustomInitialization() {
        let context = container.mainContext
        let testID = UUID()
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let testDuration: TimeInterval = 120.5
        let testDate = Date(timeIntervalSince1970: 1000000)
        let testFileName = "test_recording.wav"

        let recording = Recording(
            id: testID,
            audioData: testData,
            duration: testDuration,
            format: .wav,
            createdAt: testDate,
            originalFileName: testFileName
        )
        context.insert(recording)

        #expect(recording.id == testID)
        #expect(recording.audioData == testData)
        #expect(recording.duration == testDuration)
        #expect(recording.format == .wav)
        #expect(recording.formatRawValue == "wav")
        #expect(recording.createdAt == testDate)
        #expect(recording.originalFileName == testFileName)
    }

    @Test
    func testInitializationWithMP3Format() {
        let context = container.mainContext
        let recording = Recording(format: .mp3)
        context.insert(recording)

        #expect(recording.format == .mp3)
        #expect(recording.formatRawValue == "mp3")
    }

    // MARK: - Computed Property Tests

    @Test
    func testFormatComputedPropertyGetter() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        recording.formatRawValue = "wav"
        #expect(recording.format == .wav)

        recording.formatRawValue = "mp3"
        #expect(recording.format == .mp3)

        recording.formatRawValue = "m4a"
        #expect(recording.format == .m4a)
    }

    @Test
    func testFormatComputedPropertySetter() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        recording.format = .wav
        #expect(recording.formatRawValue == "wav")

        recording.format = .mp3
        #expect(recording.formatRawValue == "mp3")

        recording.format = .m4a
        #expect(recording.formatRawValue == "m4a")
    }

    @Test
    func testFormatFallbackToDefaultForInvalidRawValue() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        recording.formatRawValue = "invalid_format"
        #expect(recording.format == .m4a)
    }

    @Test
    func testFileSizeWithNoData() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        #expect(recording.fileSize == 0)
    }

    @Test
    func testFileSizeWithData() {
        let context = container.mainContext
        let testData = Data(repeating: 0xFF, count: 1024)
        let recording = Recording(audioData: testData)
        context.insert(recording)

        #expect(recording.fileSize == 1024)
    }

    @Test
    func testFormattedDurationZero() {
        let context = container.mainContext
        let recording = Recording(duration: 0)
        context.insert(recording)

        // Formatter uses zeroFormattingBehavior: .pad, so hours are included
        #expect(recording.formattedDuration.contains("0"))
        #expect(recording.formattedDuration.contains(":"))
    }

    @Test
    func testFormatDurationWithNilReturningFormatter() {
        // Use a mock formatter that returns nil to test the fallback path
        let mockFormatter = NilReturningDateComponentsFormatter()
        let result = Recording.formatDuration(100, using: mockFormatter)

        #expect(result == "00:00:00")
    }

    @Test
    func testFormatDurationStaticMethodWithDefaultFormatter() {
        // Test the static method directly with the default formatter
        let result = Recording.formatDuration(3661) // 1 hour 1 minute 1 second

        // Verify the output format contains expected components
        #expect(result.contains("1"))
        #expect(result.contains(":"))
    }

    @Test
    func testFormattedDurationSeconds() {
        let context = container.mainContext
        let recording = Recording(duration: 45)
        context.insert(recording)

        // Should contain 45 seconds component
        #expect(recording.formattedDuration.contains("45"))
    }

    @Test
    func testFormattedDurationMinutesAndSeconds() {
        let context = container.mainContext
        let recording = Recording(duration: 125) // 2 minutes 5 seconds
        context.insert(recording)

        // Should contain minutes and seconds components
        #expect(recording.formattedDuration.contains("02") || recording.formattedDuration.contains("2"))
        #expect(recording.formattedDuration.contains("05") || recording.formattedDuration.contains("5"))
    }

    @Test
    func testFormattedDurationHoursMinutesSeconds() {
        let context = container.mainContext
        let recording = Recording(duration: 3661) // 1 hour 1 minute 1 second
        context.insert(recording)

        // Should contain hours, minutes, and seconds components
        #expect(recording.formattedDuration.contains("1"))
        #expect(recording.formattedDuration.contains(":"))
    }

    @Test
    func testFormattedFileSizeZeroBytes() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        // ByteCountFormatter output varies by locale ("Zero KB" or "0 KB")
        #expect(recording.formattedFileSize.contains("0") || recording.formattedFileSize.lowercased().contains("zero"))
    }

    @Test
    func testFormattedFileSizeKilobytes() {
        let context = container.mainContext
        let testData = Data(repeating: 0x00, count: 1024)
        let recording = Recording(audioData: testData)
        context.insert(recording)

        #expect(recording.formattedFileSize == "1 KB")
    }

    @Test
    func testFormattedFileSizeMegabytes() {
        let context = container.mainContext
        let testData = Data(repeating: 0x00, count: 1024 * 1024)
        let recording = Recording(audioData: testData)
        context.insert(recording)

        #expect(recording.formattedFileSize == "1 MB")
    }

    @Test
    func testHasAudioDataWhenNil() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        #expect(recording.hasAudioData == false)
    }

    @Test
    func testHasAudioDataWhenEmpty() {
        let context = container.mainContext
        let recording = Recording(audioData: Data())
        context.insert(recording)

        #expect(recording.hasAudioData == false)
    }

    @Test
    func testHasAudioDataWhenPresent() {
        let context = container.mainContext
        let testData = Data([0x00, 0x01, 0x02])
        let recording = Recording(audioData: testData)
        context.insert(recording)

        #expect(recording.hasAudioData == true)
    }

    // MARK: - Relationship Tests

    @Test
    func testSessionRelationship() {
        let context = container.mainContext
        let recording = Recording()
        let session = Session()

        context.insert(recording)
        context.insert(session)

        recording.session = session

        #expect(recording.session === session)
    }

    // MARK: - Method Tests

    @Test
    func testExportToTemporaryFileWithNoData() throws {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        #expect(throws: RecordingError.noAudioData) {
            try recording.exportToTemporaryFile()
        }
    }

    @Test
    func testExportToTemporaryFileSuccess() throws {
        let context = container.mainContext
        let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        let recording = Recording(audioData: testData, format: .wav)
        context.insert(recording)

        let exportedURL = try recording.exportToTemporaryFile()

        #expect(exportedURL.pathExtension == "wav")
        #expect(exportedURL.lastPathComponent.contains(recording.id.uuidString))
        #expect(FileManager.default.fileExists(atPath: exportedURL.path()))

        let exportedData = try Data(contentsOf: exportedURL)
        #expect(exportedData == testData)

        // Clean up
        try? FileManager.default.removeItem(at: exportedURL)
    }

    @Test
    func testExportToTemporaryFileWithM4AFormat() throws {
        let context = container.mainContext
        let testData = Data([0xFF, 0xFE, 0xFD])
        let recording = Recording(audioData: testData, format: .m4a)
        context.insert(recording)

        let exportedURL = try recording.exportToTemporaryFile()

        #expect(exportedURL.pathExtension == "m4a")

        // Clean up
        try? FileManager.default.removeItem(at: exportedURL)
    }

    @Test
    func testLoadAudioFromFile() throws {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        // Create a temporary file with test data
        let testData = Data([0xAA, 0xBB, 0xCC, 0xDD])
        let tempURL = FileManager.default.temporaryDirectory
            .appending(path: "test_audio_load.m4a")
        try testData.write(to: tempURL)

        // Load audio from the file
        try recording.loadAudio(from: tempURL)

        #expect(recording.audioData == testData)
        #expect(recording.originalFileName == "test_audio_load.m4a")

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test
    func testLoadAudioFromNonExistentFile() {
        let context = container.mainContext
        let recording = Recording()
        context.insert(recording)

        let nonExistentURL = FileManager.default.temporaryDirectory
            .appending(path: "nonexistent_file_\(UUID().uuidString).m4a")

        #expect(throws: (any Error).self) {
            try recording.loadAudio(from: nonExistentURL)
        }
    }

    // MARK: - RecordingError Tests

    @Test
    func testRecordingErrorDescription() {
        let error = RecordingError.noAudioData
        // Error description is localized via String(localized:), so just verify it is not nil
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }
}
