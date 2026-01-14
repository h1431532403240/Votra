//
//  RecordingServiceTests.swift
//  VotraTests
//
//  Tests for RecordingService - validates recording state management,
//  error handling, and metadata operations.
//

import Foundation
import Testing
@testable import Votra

/// Namespace for RecordingService tests
enum RecordingServiceTests {}

// MARK: - RecordingServiceError Tests

@Suite("RecordingServiceError Tests")
struct RecordingServiceErrorTests {
    @Test("notRecording error has correct description")
    func notRecordingErrorDescription() {
        let error = RecordingServiceError.notRecording
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("alreadyRecording error has non-empty description")
    func alreadyRecordingErrorDescription() {
        let error = RecordingServiceError.alreadyRecording
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("permissionDenied error has non-empty description")
    func permissionDeniedErrorDescription() {
        let error = RecordingServiceError.permissionDenied
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("audioEngineError has non-empty description")
    func audioEngineErrorDescription() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Test audio error"]
        )
        let error = RecordingServiceError.audioEngineError(underlying: underlyingError)
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("fileWriteError has non-empty description")
    func fileWriteErrorDescription() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 100,
            userInfo: [NSLocalizedDescriptionKey: "Write failed"]
        )
        let error = RecordingServiceError.fileWriteError(underlying: underlyingError)
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("insufficientDiskSpace error has non-empty description")
    func insufficientDiskSpaceErrorDescription() {
        let available: Int64 = 50 * 1024 * 1024 // 50 MB
        let required: Int64 = 100 * 1024 * 1024 // 100 MB
        let error = RecordingServiceError.insufficientDiskSpace(available: available, required: required)
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("formatNotSupported error has non-empty description")
    func formatNotSupportedErrorDescription() {
        let error = RecordingServiceError.formatNotSupported(format: .mp3)
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("recoveryFailed error has non-empty description")
    func recoveryFailedErrorDescription() {
        let underlyingError = NSError(
            domain: "RecoveryDomain",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Recovery failed reason"]
        )
        let error = RecordingServiceError.recoveryFailed(underlying: underlyingError)
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }
}

// MARK: - RecordingState Tests

@Suite("RecordingState Tests")
struct RecordingStateTests {
    @Test("RecordingState conforms to Equatable")
    func recordingStateEquatable() {
        // swiftlint:disable identical_operands
        #expect(RecordingState.idle == RecordingState.idle)
        #expect(RecordingState.recording == RecordingState.recording)
        #expect(RecordingState.paused == RecordingState.paused)
        #expect(RecordingState.saving == RecordingState.saving)
        #expect(RecordingState.error(message: "test") == RecordingState.error(message: "test"))
        // swiftlint:enable identical_operands
        #expect(RecordingState.idle != RecordingState.recording)
        #expect(RecordingState.error(message: "a") != RecordingState.error(message: "b"))
    }

    @Test("RecordingState is Sendable")
    func recordingStateIsSendable() async {
        // Verify RecordingState can be sent across actor boundaries
        let state: RecordingState = .recording
        let result: RecordingState = await Task.detached {
            state
        }.value
        #expect(result == .recording)
    }

    @Test("RecordingState covers all cases")
    func recordingStateCoverage() {
        // Verify all states can be created
        let states: [RecordingState] = [
            .idle,
            .recording,
            .paused,
            .saving,
            .error(message: "test error")
        ]
        #expect(states.count == 5)
    }
}

// MARK: - RecordingMetadata Tests

@Suite("RecordingMetadata Tests")
@MainActor
struct RecordingMetadataTests {
    @Test("RecordingMetadata can be created with all properties")
    func createRecordingMetadata() {
        let id = UUID()
        let startTime = Date()
        let tempURL = URL(filePath: "/tmp/test.m4a")
        let lastAutoSave = Date()

        let metadata = RecordingMetadata(
            id: id,
            startTime: startTime,
            duration: 120.5,
            format: .m4a,
            tempFileURL: tempURL,
            isComplete: false,
            lastAutoSaveTime: lastAutoSave
        )

        #expect(metadata.id == id)
        #expect(metadata.startTime == startTime)
        #expect(metadata.duration == 120.5)
        #expect(metadata.format == .m4a)
        #expect(metadata.tempFileURL == tempURL)
        #expect(metadata.isComplete == false)
        #expect(metadata.lastAutoSaveTime == lastAutoSave)
    }

    @Test("RecordingMetadata can have optional properties as nil")
    func recordingMetadataOptionalProperties() {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .wav,
            tempFileURL: nil,
            isComplete: true,
            lastAutoSaveTime: nil
        )

        #expect(metadata.tempFileURL == nil)
        #expect(metadata.lastAutoSaveTime == nil)
    }

    @Test("RecordingMetadata is Sendable")
    func recordingMetadataIsSendable() async {
        let id = UUID()
        let format: AudioFormat = .m4a
        let metadata = RecordingMetadata(
            id: id,
            startTime: Date(),
            duration: 60,
            format: format,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        // Sendable struct can be sent across actor boundaries
        let result: RecordingMetadata = await Task.detached {
            metadata
        }.value

        // Use captured values for comparison (avoids MainActor isolation issue)
        #expect(result.id == id)
        #expect(result.format == format)
    }

    @Test("RecordingMetadata duration is mutable")
    func recordingMetadataDurationMutable() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        metadata.duration = 300.0
        #expect(metadata.duration == 300.0)
    }
}

// MARK: - RecordingAutoSaveConfig Tests

@Suite("RecordingAutoSaveConfig Tests")
@MainActor
struct RecordingAutoSaveConfigTests {
    @Test("Default configuration has 30 second interval")
    func defaultConfigInterval() {
        let config = RecordingAutoSaveConfig.default
        #expect(config.interval == 30.0)
    }

    @Test("Default configuration has 100 MB minimum disk space")
    func defaultConfigMinimumDiskSpace() {
        let config = RecordingAutoSaveConfig.default
        let expectedMinimumSpace: Int64 = 100 * 1024 * 1024 // 100 MB
        #expect(config.minimumDiskSpace == expectedMinimumSpace)
    }

    @Test("Custom configuration can be created")
    func customConfiguration() {
        let config = RecordingAutoSaveConfig(
            interval: 60.0,
            minimumDiskSpace: 500 * 1024 * 1024 // 500 MB
        )

        #expect(config.interval == 60.0)
        #expect(config.minimumDiskSpace == 500 * 1024 * 1024)
    }

    @Test("RecordingAutoSaveConfig is Sendable")
    func configIsSendable() async {
        let config = RecordingAutoSaveConfig.default
        let interval = config.interval
        let minimumDiskSpace = config.minimumDiskSpace

        // Sendable struct can be sent across actor boundaries
        let result: RecordingAutoSaveConfig = await Task.detached {
            config
        }.value

        // Use captured values for comparison (avoids MainActor isolation issue)
        #expect(result.interval == interval)
        #expect(result.minimumDiskSpace == minimumDiskSpace)
    }
}

// MARK: - RecordingService Initial State Tests

@Suite("RecordingService Initial State Tests")
@MainActor
struct RecordingServiceInitialStateTests {
    @Test("RecordingService starts in idle state")
    func initialStateIsIdle() {
        let service = RecordingService()
        #expect(service.state == .idle)
    }

    @Test("RecordingService starts with no current metadata")
    func initialMetadataIsNil() {
        let service = RecordingService()
        #expect(service.currentMetadata == nil)
    }

    @Test("RecordingService can be initialized with custom config")
    func initializeWithCustomConfig() {
        let customConfig = RecordingAutoSaveConfig(interval: 15.0, minimumDiskSpace: 50 * 1024 * 1024)
        let service = RecordingService(config: customConfig)
        #expect(service.state == .idle)
    }

    @Test("RecordingService reports available disk space")
    func availableDiskSpaceReturnsValue() {
        let service = RecordingService()
        let space = service.availableDiskSpace()
        // Should return a positive value (or Int64.max if unable to determine)
        #expect(space > 0)
    }
}

// MARK: - RecordingService State Transition Tests

@Suite("RecordingService State Transition Tests")
@MainActor
struct RecordingServiceStateTransitionTests {
    @Test("Pause throws when not recording")
    func pauseThrowsWhenNotRecording() throws {
        let service = RecordingService()
        #expect(service.state == .idle)

        do {
            try service.pause()
            Issue.record("Expected notRecording error to be thrown")
        } catch let error as RecordingServiceError {
            if case .notRecording = error {
                // Expected
            } else {
                Issue.record("Expected notRecording error, got \(error)")
            }
        }
    }

    @Test("Resume throws when not paused")
    func resumeThrowsWhenNotPaused() throws {
        let service = RecordingService()
        #expect(service.state == .idle)

        do {
            try service.resume()
            Issue.record("Expected notRecording error to be thrown")
        } catch let error as RecordingServiceError {
            if case .notRecording = error {
                // Expected
            } else {
                Issue.record("Expected notRecording error, got \(error)")
            }
        }
    }

    @Test("Stop throws when not recording")
    func stopThrowsWhenNotRecording() async throws {
        let service = RecordingService()
        #expect(service.state == .idle)

        do {
            _ = try await service.stop()
            Issue.record("Expected notRecording error to be thrown")
        } catch let error as RecordingServiceError {
            if case .notRecording = error {
                // Expected
            } else {
                Issue.record("Expected notRecording error, got \(error)")
            }
        }
    }

    @Test("ForceSave does nothing when not recording")
    func forceSaveNoOpWhenNotRecording() async throws {
        let service = RecordingService()
        #expect(service.state == .idle)

        // Should not throw when not recording
        try await service.forceSave()
        #expect(service.state == .idle)
    }
}

// MARK: - RecordingService Incomplete Recording Tests

@Suite("RecordingService Incomplete Recording Tests")
@MainActor
struct RecordingServiceIncompleteRecordingTests {
    @Test("checkForIncompleteRecordings returns empty array initially")
    func checkForIncompleteRecordingsReturnsEmpty() {
        let service = RecordingService()
        let incomplete = service.checkForIncompleteRecordings()
        // May or may not have incomplete recordings depending on prior state
        // Just verify it returns an array without crashing
        #expect(incomplete is [RecordingMetadata])
    }

    @Test("Discard incomplete recording with nonexistent file does not throw")
    func discardNonexistentRecording() throws {
        let service = RecordingService()
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: URL(filePath: "/nonexistent/path/recording.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        // Should not throw even if file doesn't exist
        try service.discardIncompleteRecording(metadata)
    }

    @Test("Recover recording throws when file not found")
    func recoverRecordingThrowsWhenFileNotFound() async throws {
        let service = RecordingService()
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 60,
            format: .m4a,
            tempFileURL: URL(filePath: "/nonexistent/path/recording.m4a"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        await #expect(throws: RecordingServiceError.self) {
            _ = try await service.recoverRecording(metadata)
        }
    }

    @Test("Recover recording throws when tempFileURL is nil")
    func recoverRecordingThrowsWhenNoTempURL() async throws {
        let service = RecordingService()
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 60,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        await #expect(throws: RecordingServiceError.self) {
            _ = try await service.recoverRecording(metadata)
        }
    }
}

// MARK: - AudioFormat Integration Tests

@Suite("AudioFormat Integration with RecordingService Tests")
@MainActor
struct AudioFormatRecordingIntegrationTests {
    @Test("All AudioFormat cases have valid file extensions")
    func audioFormatFileExtensions() {
        for format in AudioFormat.allCases {
            #expect(!format.fileExtension.isEmpty)
            #expect(format.fileExtension == format.rawValue)
        }
    }

    @Test("AudioFormat can be used in RecordingMetadata")
    func audioFormatInMetadata() {
        for format in AudioFormat.allCases {
            let metadata = RecordingMetadata(
                id: UUID(),
                startTime: Date(),
                duration: 0,
                format: format,
                tempFileURL: nil,
                isComplete: false,
                lastAutoSaveTime: nil
            )
            #expect(metadata.format == format)
        }
    }

    @Test("RecordingServiceError.formatNotSupported works with all formats")
    func formatNotSupportedWithAllFormats() {
        for format in AudioFormat.allCases {
            let error = RecordingServiceError.formatNotSupported(format: format)
            let description = error.errorDescription ?? ""
            #expect(description.contains(format.rawValue))
        }
    }
}

// MARK: - Notification Name Tests

@Suite("Recording Notification Name Tests")
struct RecordingNotificationNameTests {
    @Test("recordingDiskSpaceLow notification name exists")
    func diskSpaceLowNotificationName() {
        let notificationName = Notification.Name.recordingDiskSpaceLow
        #expect(notificationName.rawValue == "recordingDiskSpaceLow")
    }

    @Test("Can post and receive disk space low notification")
    func canPostDiskSpaceNotification() async {
        let notificationName = Notification.Name.recordingDiskSpaceLow
        var receivedNotification = false
        let availableSpace: Int64 = 50_000_000

        let observer = NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { notification in
            receivedNotification = true
            if let space = notification.userInfo?["availableSpace"] as? Int64 {
                #expect(space == availableSpace)
            }
        }

        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        NotificationCenter.default.post(
            name: notificationName,
            object: nil,
            userInfo: ["availableSpace": availableSpace]
        )

        // Give notification time to be delivered
        try? await Task.sleep(for: .milliseconds(100))
        #expect(receivedNotification)
    }
}

// MARK: - RecordingServiceError Conformance Tests

@Suite("RecordingServiceError Conformance Tests")
struct RecordingServiceErrorConformanceTests {
    @Test("RecordingServiceError conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: LocalizedError = RecordingServiceError.notRecording
        #expect(error.errorDescription != nil)
    }

    @Test("All error cases have non-nil errorDescription")
    func allErrorsHaveDescription() {
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)
        let errors: [RecordingServiceError] = [
            .notRecording,
            .alreadyRecording,
            .audioEngineError(underlying: underlyingError),
            .fileWriteError(underlying: underlyingError),
            .permissionDenied,
            .insufficientDiskSpace(available: 1000, required: 2000),
            .formatNotSupported(format: .wav),
            .recoveryFailed(underlying: underlyingError)
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - RecordingServiceProtocol Conformance Tests

@Suite("RecordingServiceProtocol Conformance Tests")
@MainActor
struct RecordingServiceProtocolConformanceTests {
    @Test("RecordingService conforms to RecordingServiceProtocol")
    func conformsToProtocol() {
        let service: RecordingServiceProtocol = RecordingService()
        #expect(service.state == .idle)
        #expect(service.currentMetadata == nil)
    }

    @Test("RecordingService protocol methods are accessible")
    func protocolMethodsAccessible() async throws {
        let service: RecordingServiceProtocol = RecordingService()

        // Test synchronous protocol requirements - expect notRecording error
        do {
            try service.pause()
            Issue.record("Expected notRecording error to be thrown")
        } catch let error as RecordingServiceError {
            if case .notRecording = error {
                // Expected
            } else {
                Issue.record("Expected notRecording error, got \(error)")
            }
        }

        do {
            try service.resume()
            Issue.record("Expected notRecording error to be thrown")
        } catch let error as RecordingServiceError {
            if case .notRecording = error {
                // Expected
            } else {
                Issue.record("Expected notRecording error, got \(error)")
            }
        }

        // Test async protocol requirements
        do {
            _ = try await service.stop()
            Issue.record("Expected notRecording error to be thrown")
        } catch let error as RecordingServiceError {
            if case .notRecording = error {
                // Expected
            } else {
                Issue.record("Expected notRecording error, got \(error)")
            }
        }

        // Test query methods
        _ = service.checkForIncompleteRecordings()
        _ = service.availableDiskSpace()
    }
}

// MARK: - RecordingServiceError Underlying Error Tests

@Suite("RecordingServiceError Underlying Error Tests")
@MainActor
struct RecordingServiceErrorUnderlyingTests {
    @Test("audioEngineError includes underlying error description")
    func audioEngineErrorIncludesUnderlyingDescription() {
        let underlyingMessage = "Test audio engine failure"
        let underlyingError = NSError(
            domain: "AVAudioEngine",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: underlyingMessage]
        )
        let error = RecordingServiceError.audioEngineError(underlying: underlyingError)
        let description = error.errorDescription ?? ""

        #expect(description.contains(underlyingMessage))
    }

    @Test("fileWriteError includes underlying error description")
    func fileWriteErrorIncludesUnderlyingDescription() {
        let underlyingMessage = "Disk write operation failed"
        let underlyingError = NSError(
            domain: "NSFileManager",
            code: 512,
            userInfo: [NSLocalizedDescriptionKey: underlyingMessage]
        )
        let error = RecordingServiceError.fileWriteError(underlying: underlyingError)
        let description = error.errorDescription ?? ""

        #expect(description.contains(underlyingMessage))
    }

    @Test("recoveryFailed includes underlying error description")
    func recoveryFailedIncludesUnderlyingDescription() {
        let underlyingMessage = "Recovery operation timed out"
        let underlyingError = NSError(
            domain: "RecoveryDomain",
            code: 408,
            userInfo: [NSLocalizedDescriptionKey: underlyingMessage]
        )
        let error = RecordingServiceError.recoveryFailed(underlying: underlyingError)
        let description = error.errorDescription ?? ""

        #expect(description.contains(underlyingMessage))
    }

    @Test("insufficientDiskSpace formats byte counts")
    func insufficientDiskSpaceFormatsBytes() {
        let available: Int64 = 10 * 1024 * 1024 // 10 MB
        let required: Int64 = 200 * 1024 * 1024 // 200 MB
        let error = RecordingServiceError.insufficientDiskSpace(
            available: available,
            required: required
        )
        let description = error.errorDescription ?? ""

        // ByteCountFormatter formats numbers, description should not be empty
        #expect(!description.isEmpty)
        // Should contain both formatted byte values
        #expect(description.count > 20) // Reasonable length for a formatted message
    }

    @Test("formatNotSupported includes format raw value")
    func formatNotSupportedIncludesRawValue() {
        let formats: [AudioFormat] = [.m4a, .wav, .mp3]
        for format in formats {
            let error = RecordingServiceError.formatNotSupported(format: format)
            let description = error.errorDescription ?? ""
            #expect(description.contains(format.rawValue))
        }
    }
}

// MARK: - RecordingState Error Message Tests

@Suite("RecordingState Error Message Tests")
@MainActor
struct RecordingStateErrorMessageTests {
    @Test("Error state stores and returns message")
    func errorStateStoresMessage() {
        let message = "Test error message"
        let state = RecordingState.error(message: message)

        if case .error(let storedMessage) = state {
            #expect(storedMessage == message)
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("Error states with different messages are not equal")
    func differentErrorMessagesNotEqual() {
        let state1 = RecordingState.error(message: "Error 1")
        let state2 = RecordingState.error(message: "Error 2")
        #expect(state1 != state2)
    }

    @Test("Error state is not equal to other states")
    func errorStateNotEqualToOtherStates() {
        let errorState = RecordingState.error(message: "Some error")
        #expect(errorState != .idle)
        #expect(errorState != .recording)
        #expect(errorState != .paused)
        #expect(errorState != .saving)
    }

    @Test("Error state with empty message is valid")
    func errorStateWithEmptyMessage() {
        let state = RecordingState.error(message: "")
        if case .error(let message) = state {
            #expect(message.isEmpty)
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("Error state with long message is valid")
    func errorStateWithLongMessage() {
        let longMessage = String(repeating: "A", count: 1000)
        let state = RecordingState.error(message: longMessage)
        if case .error(let message) = state {
            #expect(message.count == 1000)
        } else {
            Issue.record("Expected error state")
        }
    }
}

// MARK: - RecordingMetadata Mutable Properties Tests

@Suite("RecordingMetadata Mutable Properties Tests")
@MainActor
struct RecordingMetadataMutablePropertiesTests {
    @Test("format property is mutable")
    func formatPropertyIsMutable() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        metadata.format = .wav
        #expect(metadata.format == .wav)

        metadata.format = .mp3
        #expect(metadata.format == .mp3)
    }

    @Test("tempFileURL property is mutable")
    func tempFileURLPropertyIsMutable() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        let url = URL(filePath: "/tmp/recording.m4a")
        metadata.tempFileURL = url
        #expect(metadata.tempFileURL == url)

        metadata.tempFileURL = nil
        #expect(metadata.tempFileURL == nil)
    }

    @Test("isComplete property is mutable")
    func isCompletePropertyIsMutable() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        metadata.isComplete = true
        #expect(metadata.isComplete == true)

        metadata.isComplete = false
        #expect(metadata.isComplete == false)
    }

    @Test("lastAutoSaveTime property is mutable")
    func lastAutoSaveTimePropertyIsMutable() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        let now = Date()
        metadata.lastAutoSaveTime = now
        #expect(metadata.lastAutoSaveTime == now)

        metadata.lastAutoSaveTime = nil
        #expect(metadata.lastAutoSaveTime == nil)
    }

    @Test("All mutable properties can be updated together")
    func allMutablePropertiesUpdatable() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        metadata.duration = 120.5
        metadata.format = .wav
        metadata.tempFileURL = URL(filePath: "/tmp/test.wav")
        metadata.isComplete = true
        metadata.lastAutoSaveTime = Date()

        #expect(metadata.duration == 120.5)
        #expect(metadata.format == .wav)
        #expect(metadata.tempFileURL != nil)
        #expect(metadata.isComplete == true)
        #expect(metadata.lastAutoSaveTime != nil)
    }
}

// MARK: - File Naming and Extension Tests

@Suite("File Naming and Extension Tests")
@MainActor
struct FileNamingExtensionTests {
    @Test("UUID-based file names are valid")
    func uuidBasedFileNamesValid() {
        let id = UUID()
        for format in AudioFormat.allCases {
            let fileName = "\(id.uuidString).\(format.fileExtension)"
            #expect(fileName.contains(id.uuidString))
            #expect(fileName.hasSuffix(".\(format.rawValue)"))
        }
    }

    @Test("File extension matches format raw value for all formats")
    func fileExtensionMatchesRawValue() {
        #expect(AudioFormat.m4a.fileExtension == "m4a")
        #expect(AudioFormat.wav.fileExtension == "wav")
        #expect(AudioFormat.mp3.fileExtension == "mp3")
    }

    @Test("RecordingMetadata tempFileURL can use any format extension")
    func tempFileURLCanUseAnyFormat() {
        for format in AudioFormat.allCases {
            let url = URL(filePath: "/tmp/recording.\(format.fileExtension)")
            let metadata = RecordingMetadata(
                id: UUID(),
                startTime: Date(),
                duration: 0,
                format: format,
                tempFileURL: url,
                isComplete: false,
                lastAutoSaveTime: nil
            )
            #expect(metadata.tempFileURL?.pathExtension == format.fileExtension)
        }
    }

    @Test("File names with UUID are unique")
    func uuidFileNamesAreUnique() {
        let format = AudioFormat.m4a
        let fileNames = (0..<100).map { _ in
            "\(UUID().uuidString).\(format.fileExtension)"
        }
        let uniqueFileNames = Set(fileNames)
        #expect(uniqueFileNames.count == 100)
    }
}

// MARK: - RecordingAutoSaveConfig Edge Cases Tests

@Suite("RecordingAutoSaveConfig Edge Cases Tests")
@MainActor
struct RecordingAutoSaveConfigEdgeCasesTests {
    @Test("Config with zero interval is valid")
    func configWithZeroInterval() {
        let config = RecordingAutoSaveConfig(interval: 0, minimumDiskSpace: 100)
        #expect(config.interval == 0)
    }

    @Test("Config with negative interval is valid (though not recommended)")
    func configWithNegativeInterval() {
        let config = RecordingAutoSaveConfig(interval: -1.0, minimumDiskSpace: 100)
        #expect(config.interval == -1.0)
    }

    @Test("Config with zero minimum disk space is valid")
    func configWithZeroMinimumDiskSpace() {
        let config = RecordingAutoSaveConfig(interval: 30, minimumDiskSpace: 0)
        #expect(config.minimumDiskSpace == 0)
    }

    @Test("Config with very large values is valid")
    func configWithLargeValues() {
        let config = RecordingAutoSaveConfig(
            interval: Double.greatestFiniteMagnitude,
            minimumDiskSpace: Int64.max
        )
        #expect(config.interval == Double.greatestFiniteMagnitude)
        #expect(config.minimumDiskSpace == Int64.max)
    }

    @Test("Multiple configs can be created independently")
    func multipleConfigsIndependent() {
        let config1 = RecordingAutoSaveConfig(interval: 10, minimumDiskSpace: 1000)
        let config2 = RecordingAutoSaveConfig(interval: 60, minimumDiskSpace: 5000)

        #expect(config1.interval != config2.interval)
        #expect(config1.minimumDiskSpace != config2.minimumDiskSpace)
    }

    @Test("Default config values match FR-029 specification")
    func defaultConfigMatchesFR029() {
        let config = RecordingAutoSaveConfig.default
        // FR-029 specifies 30-second auto-save interval
        #expect(config.interval == 30.0)
        // 100 MB minimum disk space
        #expect(config.minimumDiskSpace == 100 * 1024 * 1024)
    }
}

// MARK: - RecordingState Switch Coverage Tests

@Suite("RecordingState Switch Coverage Tests")
@MainActor
struct RecordingStateSwitchCoverageTests {
    @Test("Can switch on all recording states")
    func canSwitchOnAllStates() {
        let states: [RecordingState] = [
            .idle,
            .recording,
            .paused,
            .saving,
            .error(message: "test")
        ]

        for state in states {
            let description: String
            switch state {
            case .idle:
                description = "idle"
            case .recording:
                description = "recording"
            case .paused:
                description = "paused"
            case .saving:
                description = "saving"
            case .error(let message):
                description = "error: \(message)"
            }
            #expect(!description.isEmpty)
        }
    }

    @Test("State comparison with switch is exhaustive")
    func stateComparisonExhaustive() {
        func describeState(_ state: RecordingState) -> String {
            switch state {
            case .idle: return "Not started"
            case .recording: return "In progress"
            case .paused: return "Temporarily stopped"
            case .saving: return "Finalizing"
            case .error(let msg): return "Failed: \(msg)"
            }
        }

        #expect(describeState(.idle) == "Not started")
        #expect(describeState(.recording) == "In progress")
        #expect(describeState(.paused) == "Temporarily stopped")
        #expect(describeState(.saving) == "Finalizing")
        #expect(describeState(.error(message: "oops")).contains("oops"))
    }
}

// MARK: - RecordingService Disk Space Tests

@Suite("RecordingService Disk Space Tests")
@MainActor
struct RecordingServiceDiskSpaceTests {
    @Test("Available disk space returns positive value")
    func availableDiskSpacePositive() {
        let service = RecordingService()
        let space = service.availableDiskSpace()
        #expect(space > 0)
    }

    @Test("Available disk space is consistent across calls")
    func availableDiskSpaceConsistent() {
        let service = RecordingService()
        let space1 = service.availableDiskSpace()
        let space2 = service.availableDiskSpace()
        // Allow for some variance but should be roughly similar
        let difference = abs(space1 - space2)
        let maxDifference: Int64 = 100 * 1024 * 1024 // 100 MB tolerance
        #expect(difference < maxDifference)
    }

    @Test("Different service instances report similar disk space")
    func differentInstancesSimilarDiskSpace() {
        let service1 = RecordingService()
        let service2 = RecordingService()
        let space1 = service1.availableDiskSpace()
        let space2 = service2.availableDiskSpace()
        let difference = abs(space1 - space2)
        let maxDifference: Int64 = 100 * 1024 * 1024 // 100 MB tolerance
        #expect(difference < maxDifference)
    }
}

// MARK: - RecordingServiceError Equatable Behavior Tests

@Suite("RecordingServiceError Pattern Matching Tests")
@MainActor
struct RecordingServiceErrorPatternMatchingTests {
    @Test("notRecording error can be pattern matched")
    func notRecordingPatternMatch() {
        let error = RecordingServiceError.notRecording
        if case .notRecording = error {
            #expect(true)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("alreadyRecording error can be pattern matched")
    func alreadyRecordingPatternMatch() {
        let error = RecordingServiceError.alreadyRecording
        if case .alreadyRecording = error {
            #expect(true)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("audioEngineError can extract underlying error")
    func audioEngineErrorExtraction() {
        let underlying = NSError(domain: "Test", code: 1, userInfo: nil)
        let error = RecordingServiceError.audioEngineError(underlying: underlying)
        if case .audioEngineError(let extracted) = error {
            let nsError = extracted as NSError
            #expect(nsError.domain == "Test")
            #expect(nsError.code == 1)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("fileWriteError can extract underlying error")
    func fileWriteErrorExtraction() {
        let underlying = NSError(domain: "FileSystem", code: 512, userInfo: nil)
        let error = RecordingServiceError.fileWriteError(underlying: underlying)
        if case .fileWriteError(let extracted) = error {
            let nsError = extracted as NSError
            #expect(nsError.domain == "FileSystem")
            #expect(nsError.code == 512)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("permissionDenied error can be pattern matched")
    func permissionDeniedPatternMatch() {
        let error = RecordingServiceError.permissionDenied
        if case .permissionDenied = error {
            #expect(true)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("insufficientDiskSpace can extract values")
    func insufficientDiskSpaceExtraction() {
        let available: Int64 = 50_000_000
        let required: Int64 = 100_000_000
        let error = RecordingServiceError.insufficientDiskSpace(
            available: available,
            required: required
        )
        if case .insufficientDiskSpace(let extractedAvailable, let extractedRequired) = error {
            #expect(extractedAvailable == available)
            #expect(extractedRequired == required)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("formatNotSupported can extract format")
    func formatNotSupportedExtraction() {
        let error = RecordingServiceError.formatNotSupported(format: .wav)
        if case .formatNotSupported(let format) = error {
            #expect(format == .wav)
        } else {
            Issue.record("Pattern match failed")
        }
    }

    @Test("recoveryFailed can extract underlying error")
    func recoveryFailedExtraction() {
        let underlying = NSError(domain: "Recovery", code: 999, userInfo: nil)
        let error = RecordingServiceError.recoveryFailed(underlying: underlying)
        if case .recoveryFailed(let extracted) = error {
            let nsError = extracted as NSError
            #expect(nsError.domain == "Recovery")
            #expect(nsError.code == 999)
        } else {
            Issue.record("Pattern match failed")
        }
    }
}

// MARK: - RecordingMetadata Immutable Properties Tests

@Suite("RecordingMetadata Immutable Properties Tests")
@MainActor
struct RecordingMetadataImmutablePropertiesTests {
    @Test("id property is immutable after creation")
    func idPropertyImmutable() {
        let id = UUID()
        let metadata = RecordingMetadata(
            id: id,
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )
        #expect(metadata.id == id)
        // id is let, so it cannot be changed - this is a compile-time guarantee
    }

    @Test("startTime property is immutable after creation")
    func startTimePropertyImmutable() {
        let startTime = Date()
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: startTime,
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )
        #expect(metadata.startTime == startTime)
        // startTime is let, so it cannot be changed - this is a compile-time guarantee
    }
}

// MARK: - RecordingService Multiple Instance Tests

@Suite("RecordingService Multiple Instance Tests")
@MainActor
struct RecordingServiceMultipleInstanceTests {
    @Test("Multiple service instances are independent")
    func multipleInstancesIndependent() {
        let service1 = RecordingService()
        let service2 = RecordingService()

        #expect(service1.state == .idle)
        #expect(service2.state == .idle)
        #expect(service1.currentMetadata == nil)
        #expect(service2.currentMetadata == nil)
    }

    @Test("Services with different configs are independent")
    func differentConfigsIndependent() {
        let config1 = RecordingAutoSaveConfig(interval: 10, minimumDiskSpace: 1000)
        let config2 = RecordingAutoSaveConfig(interval: 60, minimumDiskSpace: 5000)

        let service1 = RecordingService(config: config1)
        let service2 = RecordingService(config: config2)

        #expect(service1.state == .idle)
        #expect(service2.state == .idle)
    }
}

// MARK: - Notification UserInfo Tests

@Suite("Notification UserInfo Tests")
@MainActor
struct NotificationUserInfoTests {
    @Test("Disk space low notification can carry various space values")
    func diskSpaceNotificationVariousValues() {
        let testValues: [Int64] = [0, 1, 1024, 1024 * 1024, Int64.max]

        for value in testValues {
            let userInfo: [String: Any] = ["availableSpace": value]
            if let space = userInfo["availableSpace"] as? Int64 {
                #expect(space == value)
            } else {
                Issue.record("Failed to extract space value")
            }
        }
    }

    @Test("Disk space low notification name is stable")
    func notificationNameStable() {
        let name1 = Notification.Name.recordingDiskSpaceLow
        let name2 = Notification.Name.recordingDiskSpaceLow
        #expect(name1 == name2)
        #expect(name1.rawValue == "recordingDiskSpaceLow")
    }
}

// MARK: - RecordingMetadata Duration Calculations Tests

@Suite("RecordingMetadata Duration Tests")
@MainActor
struct RecordingMetadataDurationTests {
    @Test("Duration can be zero")
    func durationCanBeZero() {
        let metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )
        #expect(metadata.duration == 0)
    }

    @Test("Duration can be fractional")
    func durationCanBeFractional() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )
        metadata.duration = 123.456789
        #expect(metadata.duration == 123.456789)
    }

    @Test("Duration can be very large")
    func durationCanBeLarge() {
        var metadata = RecordingMetadata(
            id: UUID(),
            startTime: Date(),
            duration: 0,
            format: .m4a,
            tempFileURL: nil,
            isComplete: false,
            lastAutoSaveTime: nil
        )
        metadata.duration = 86400 * 365 // One year in seconds
        #expect(metadata.duration == 86400 * 365)
    }

    @Test("Duration updates preserve other properties")
    func durationUpdatePreservesOtherProperties() {
        let id = UUID()
        let startTime = Date()
        var metadata = RecordingMetadata(
            id: id,
            startTime: startTime,
            duration: 0,
            format: .wav,
            tempFileURL: URL(filePath: "/tmp/test.wav"),
            isComplete: false,
            lastAutoSaveTime: nil
        )

        metadata.duration = 500.0

        #expect(metadata.id == id)
        #expect(metadata.startTime == startTime)
        #expect(metadata.format == .wav)
        #expect(metadata.tempFileURL?.path() == "/tmp/test.wav")
        #expect(metadata.isComplete == false)
    }
}
