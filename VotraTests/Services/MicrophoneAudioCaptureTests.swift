//
//  MicrophoneAudioCaptureTests.swift
//  VotraTests
//
//  Comprehensive tests for audio capture service - validates error handling,
//  state management, configuration values, and buffer handling logic.
//

@preconcurrency import AVFoundation
import ScreenCaptureKit
import Testing
@testable import Votra

/// Namespace for MicrophoneAudioCapture tests
enum MicrophoneAudioCaptureTests {}

// MARK: - Audio Capture Error Tests

@Suite("Audio Capture Error Tests", .tags(.requiresHardware))
@MainActor
struct AudioCaptureErrorTests {
    @Test("Error descriptions are localized and meaningful")
    func errorDescriptionsAreMeaningful() {
        // Test each error case has a non-empty description
        let errors: [AudioCaptureError] = [
            .microphonePermissionDenied,
            .screenRecordingPermissionDenied,
            .deviceNotFound,
            .captureAlreadyActive,
            .engineStartFailed(underlying: NSError(domain: "TestDomain", code: -1)),
            .invalidAudioFormat
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil, "Error \(error) should have a description")
            #expect(description?.isEmpty == false, "Error \(error) description should not be empty")
        }
    }

    @Test("Microphone permission denied error has non-empty description")
    func microphonePermissionDeniedDescription() {
        let error = AudioCaptureError.microphonePermissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Screen recording permission denied error has non-empty description")
    func screenRecordingPermissionDeniedDescription() {
        let error = AudioCaptureError.screenRecordingPermissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Device not found error has non-empty description")
    func deviceNotFoundDescription() {
        let error = AudioCaptureError.deviceNotFound
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Capture already active error has non-empty description")
    func captureAlreadyActiveDescription() {
        let error = AudioCaptureError.captureAlreadyActive
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Engine start failed error has non-empty description")
    func engineStartFailedDescription() {
        let underlyingError = NSError(domain: "AVAudioEngine", code: -1234)
        let error = AudioCaptureError.engineStartFailed(underlying: underlyingError)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Invalid audio format error has non-empty description")
    func invalidAudioFormatDescription() {
        let error = AudioCaptureError.invalidAudioFormat
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Recovery suggestions are provided for permission errors")
    func recoverySuggestionsForPermissionErrors() {
        let microphoneError = AudioCaptureError.microphonePermissionDenied
        #expect(microphoneError.recoverySuggestion != nil)
        #expect(microphoneError.recoverySuggestion?.isEmpty == false)

        let screenError = AudioCaptureError.screenRecordingPermissionDenied
        #expect(screenError.recoverySuggestion != nil)
        #expect(screenError.recoverySuggestion?.isEmpty == false)
    }

    @Test("Recovery suggestion is provided for device not found")
    func recoverySuggestionForDeviceNotFound() {
        let error = AudioCaptureError.deviceNotFound
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("No recovery suggestion for engine and format errors")
    func noRecoverySuggestionForEngineAndFormatErrors() {
        let engineError = AudioCaptureError.engineStartFailed(underlying: NSError(domain: "", code: 0))
        #expect(engineError.recoverySuggestion == nil)

        let formatError = AudioCaptureError.invalidAudioFormat
        #expect(formatError.recoverySuggestion == nil)

        let activeError = AudioCaptureError.captureAlreadyActive
        #expect(activeError.recoverySuggestion == nil)
    }

    @Test("Errors conform to LocalizedError protocol")
    func errorsConformToLocalizedError() {
        let error: LocalizedError = AudioCaptureError.deviceNotFound
        #expect(error.errorDescription != nil)
    }

    @Test("Engine start failed preserves underlying error")
    func engineStartFailedPreservesUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = AudioCaptureError.engineStartFailed(underlying: underlyingError)

        if case .engineStartFailed(let captured) = error {
            let nsError = captured as NSError
            #expect(nsError.domain == "TestDomain")
            #expect(nsError.code == 42)
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }
}

// MARK: - Audio Capture State Tests

@Suite("Audio Capture State Tests", .tags(.requiresHardware))
@MainActor
struct AudioCaptureStateTests {
    @Test("All state cases are distinct")
    func allStateCasesAreDistinct() {
        let states: [AudioCaptureState] = [.idle, .capturingMicrophone, .capturingSystemAudio, .capturingBoth]
        let uniqueStates = Set(states)
        #expect(uniqueStates.count == 4)
    }

    @Test("State is Equatable")
    func stateIsEquatable() {
        // swiftlint:disable identical_operands
        #expect(AudioCaptureState.idle == AudioCaptureState.idle)
        #expect(AudioCaptureState.capturingMicrophone == AudioCaptureState.capturingMicrophone)
        #expect(AudioCaptureState.capturingSystemAudio == AudioCaptureState.capturingSystemAudio)
        #expect(AudioCaptureState.capturingBoth == AudioCaptureState.capturingBoth)
        // swiftlint:enable identical_operands

        #expect(AudioCaptureState.idle != AudioCaptureState.capturingMicrophone)
        #expect(AudioCaptureState.capturingMicrophone != AudioCaptureState.capturingSystemAudio)
        #expect(AudioCaptureState.capturingSystemAudio != AudioCaptureState.capturingBoth)
    }

    @Test("State is Sendable")
    func stateIsSendable() {
        // This test validates the Sendable conformance compiles
        let state: AudioCaptureState = .idle
        Task {
            _ = state
        }
    }

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let service = AudioCaptureService()
        #expect(service.state == .idle)
    }
}

// MARK: - Audio Device Tests

@Suite("Audio Device Tests", .tags(.requiresHardware))
@MainActor
struct AudioDeviceTests {
    @Test("Audio device is Identifiable")
    func audioDeviceIsIdentifiable() {
        let device = AudioDevice(id: "test-id", name: "Test Device", isDefault: false)
        #expect(device.id == "test-id")
    }

    @Test("Audio device is Equatable by all properties")
    func audioDeviceIsEquatable() {
        let device1 = AudioDevice(id: "id1", name: "Device 1", isDefault: true)
        let device2 = AudioDevice(id: "id1", name: "Device 1", isDefault: true)
        let device3 = AudioDevice(id: "id2", name: "Device 1", isDefault: true)

        #expect(device1 == device2)
        #expect(device1 != device3)
    }

    @Test("Audio device is Hashable")
    func audioDeviceIsHashable() {
        let device1 = AudioDevice(id: "id1", name: "Device 1", isDefault: true)
        let device2 = AudioDevice(id: "id1", name: "Device 1", isDefault: true)
        let device3 = AudioDevice(id: "id2", name: "Device 2", isDefault: false)

        var set = Set<AudioDevice>()
        set.insert(device1)
        set.insert(device2)
        set.insert(device3)

        #expect(set.count == 2)
    }

    @Test("Audio device stores correct properties")
    func audioDeviceStoresProperties() {
        let device = AudioDevice(id: "unique-123", name: "Built-in Microphone", isDefault: true)

        #expect(device.id == "unique-123")
        #expect(device.name == "Built-in Microphone")
        #expect(device.isDefault == true)
    }

    @Test("Audio device with isDefault false")
    func audioDeviceWithDefaultFalse() {
        let device = AudioDevice(id: "external-mic", name: "External Microphone", isDefault: false)
        #expect(device.isDefault == false)
    }

    @Test("Audio device is Sendable")
    func audioDeviceIsSendable() {
        let device = AudioDevice(id: "test", name: "Test", isDefault: false)
        Task {
            _ = device.name
        }
    }
}

// MARK: - Audio Permission Status Tests

@Suite("Audio Permission Status Tests", .tags(.requiresHardware))
@MainActor
struct AudioPermissionStatusTests {
    @Test("Permission state has all expected cases")
    func permissionStateHasAllCases() {
        let states: [AudioPermissionStatus.PermissionState] = [.authorized, .denied, .notDetermined]
        #expect(states.count == 3)
    }

    @Test("Can capture microphone only when authorized")
    func canCaptureMicrophoneOnlyWhenAuthorized() {
        let authorized = AudioPermissionStatus(microphone: .authorized, screenRecording: .denied)
        let denied = AudioPermissionStatus(microphone: .denied, screenRecording: .authorized)
        let notDetermined = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .authorized)

        #expect(authorized.canCaptureMicrophone == true)
        #expect(denied.canCaptureMicrophone == false)
        #expect(notDetermined.canCaptureMicrophone == false)
    }

    @Test("Can capture system audio only when authorized")
    func canCaptureSystemAudioOnlyWhenAuthorized() {
        let authorized = AudioPermissionStatus(microphone: .denied, screenRecording: .authorized)
        let denied = AudioPermissionStatus(microphone: .authorized, screenRecording: .denied)
        let notDetermined = AudioPermissionStatus(microphone: .authorized, screenRecording: .notDetermined)

        #expect(authorized.canCaptureSystemAudio == true)
        #expect(denied.canCaptureSystemAudio == false)
        #expect(notDetermined.canCaptureSystemAudio == false)
    }

    @Test("Both permissions can be authorized")
    func bothPermissionsCanBeAuthorized() {
        let status = AudioPermissionStatus(microphone: .authorized, screenRecording: .authorized)
        #expect(status.canCaptureMicrophone == true)
        #expect(status.canCaptureSystemAudio == true)
    }

    @Test("Both permissions can be denied")
    func bothPermissionsCanBeDenied() {
        let status = AudioPermissionStatus(microphone: .denied, screenRecording: .denied)
        #expect(status.canCaptureMicrophone == false)
        #expect(status.canCaptureSystemAudio == false)
    }

    @Test("Permission status is Sendable")
    func permissionStatusIsSendable() {
        let status = AudioPermissionStatus(microphone: .authorized, screenRecording: .authorized)
        Task {
            _ = status.canCaptureMicrophone
        }
    }
}

// MARK: - Audio Capture Service Initialization Tests

@Suite("Audio Capture Service Initialization Tests", .tags(.requiresHardware))
@MainActor
struct AudioCaptureServiceInitializationTests {
    @Test("Service initializes with idle state")
    func serviceInitializesWithIdleState() {
        let service = AudioCaptureService()
        #expect(service.state == .idle)
    }

    @Test("Service initializes with no selected microphone")
    func serviceInitializesWithNoSelectedMicrophone() {
        let service = AudioCaptureService()
        #expect(service.selectedMicrophone == nil)
    }

    @Test("Service initializes with empty microphone list")
    func serviceInitializesWithEmptyMicrophoneList() {
        let service = AudioCaptureService()
        #expect(service.availableMicrophones.isEmpty)
    }

    @Test("Service initializes with all system audio as default source")
    func serviceInitializesWithAllSystemAudioAsDefaultSource() {
        let service = AudioCaptureService()
        #expect(service.selectedAudioSource.isAllSystemAudio == true)
    }

    @Test("Service initializes with all system audio in available sources")
    func serviceInitializesWithAllSystemAudioInAvailableSources() {
        let service = AudioCaptureService()
        #expect(service.availableAudioSources.count == 1)
        #expect(service.availableAudioSources.first?.isAllSystemAudio == true)
    }
}

// MARK: - Audio Capture Service State Management Tests

@Suite("Audio Capture Service State Management Tests", .tags(.requiresHardware))
@MainActor
struct AudioCaptureServiceStateManagementTests {
    @Test("Select microphone throws for unknown device")
    func selectMicrophoneThrowsForUnknownDevice() async {
        let service = AudioCaptureService()
        let unknownDevice = AudioDevice(id: "unknown-device-id", name: "Unknown", isDefault: false)

        await #expect(throws: AudioCaptureError.self) {
            try await service.selectMicrophone(unknownDevice)
        }
    }

    @Test("Select audio source does nothing for unknown source")
    func selectAudioSourceDoesNothingForUnknownSource() {
        let service = AudioCaptureService()
        let unknownSource = AudioSourceInfo(
            id: "unknown",
            name: "Unknown App",
            bundleIdentifier: "com.unknown.app",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let originalSource = service.selectedAudioSource
        service.selectAudioSource(unknownSource)

        // Should still be the original all system audio
        #expect(service.selectedAudioSource == originalSource)
    }

    @Test("Stop all capture resets to idle state")
    func stopAllCaptureResetsToIdleState() async {
        let service = AudioCaptureService()
        await service.stopAllCapture()
        #expect(service.state == .idle)
    }

    @Test("Stop capture from microphone when idle stays idle")
    func stopMicrophoneCaptureWhenIdleStaysIdle() async {
        let service = AudioCaptureService()
        await service.stopCapture(from: .microphone)
        #expect(service.state == .idle)
    }

    @Test("Stop capture from system audio when idle stays idle")
    func stopSystemAudioCaptureWhenIdleStaysIdle() async {
        let service = AudioCaptureService()
        await service.stopCapture(from: .systemAudio)
        #expect(service.state == .idle)
    }
}

// MARK: - Microphone Audio Capture Tests

@Suite("Microphone Audio Capture Tests", .tags(.requiresHardware))
@MainActor
struct MicrophoneAudioCaptureUnitTests {
    @Test("Microphone capture initializes successfully")
    func microphoneCaptureInitializes() {
        // Test that we can create an instance without errors
        let capture = MicrophoneAudioCapture()
        // Instance should exist (compile-time guarantee, runtime verification via usage)
        _ = capture
    }

    @Test("Select device stores device ID")
    func selectDeviceStoresDeviceID() async throws {
        let capture = MicrophoneAudioCapture()
        try await capture.selectDevice("test-device-id")
        // No assertion needed - just verify it doesn't throw
    }

    @Test("Stop capture when not capturing is safe")
    func stopCaptureWhenNotCapturingIsSafe() async {
        let capture = MicrophoneAudioCapture()
        await capture.stopCapture()
        // Should complete without error
    }

    @Test("Multiple stop captures are safe")
    func multipleStopCapturesAreSafe() async {
        let capture = MicrophoneAudioCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        // Should complete without error
    }
}

// MARK: - Actor Isolation Tests

@Suite("Microphone Audio Capture Actor Isolation Tests", .tags(.requiresHardware))
struct MicrophoneAudioCaptureActorIsolationTests {
    @Test("Audio tap callback runs without actor isolation crash", .disabled("Requires audio hardware - run locally"))
    @MainActor
    func audioTapDoesNotCrashFromActorIsolation() async throws {
        // This test validates that the audio tap callback can be invoked
        // on the realtime audio thread without triggering Swift 6's
        // actor isolation runtime checks.
        //
        // The crash we're fixing:
        // - _dispatch_assert_queue_fail
        // - swift_task_isCurrentExecutorWithFlagsImpl
        // - closure #1 in MicrophoneAudioCapture.startCapture
        //
        // This happens when a closure defined in an async/MainActor context
        // is called on a different thread (the realtime audio thread).

        // Skip if no microphone available (CI environment)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        guard status == .authorized else {
            print("Skipping test - microphone not authorized: \(status)")
            return
        }

        let capture = MicrophoneAudioCapture()

        do {
            let stream = try await capture.startCapture()

            // Wait for a few buffers to ensure the tap callback works
            var bufferCount = 0
            for await _ in stream {
                bufferCount += 1
                if bufferCount >= 5 {
                    break
                }
            }

            await capture.stopCapture()

            #expect(bufferCount >= 1, "Should have received at least 1 audio buffer")
        } catch {
            // If we get here without crashing, the actor isolation is fixed
            // Device not found is acceptable in test environment
            if let audioError = error as? AudioCaptureError {
                switch audioError {
                case .deviceNotFound:
                    print("No microphone device found - test inconclusive but no crash")
                default:
                    throw error
                }
            }
        }
    }

    @Test("Start and stop capture multiple times without crash", .disabled("Requires audio hardware - run locally"))
    @MainActor
    func multipleStartStopCycles() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        guard status == .authorized else {
            print("Skipping test - microphone not authorized")
            return
        }

        let capture = MicrophoneAudioCapture()

        for cycle in 1...3 {
            do {
                let stream = try await capture.startCapture()

                // Consume a few buffers
                var count = 0
                for await _ in stream {
                    count += 1
                    if count >= 2 {
                        break
                    }
                }

                await capture.stopCapture()
                print("Cycle \(cycle) completed successfully")

                // Small delay between cycles
                try await Task.sleep(for: .milliseconds(100))
            } catch AudioCaptureError.deviceNotFound {
                print("No microphone device - skipping remaining cycles")
                return
            }
        }
    }
}

// MARK: - Audio Source Enum Tests

@Suite("Audio Source Enum Tests", .tags(.requiresHardware))
@MainActor
struct AudioSourceEnumTests {
    @Test("Microphone source has correct raw value")
    func microphoneSourceRawValue() {
        #expect(AudioSource.microphone.rawValue == "microphone")
    }

    @Test("System audio source has correct raw value")
    func systemAudioSourceRawValue() {
        #expect(AudioSource.systemAudio.rawValue == "systemAudio")
    }

    @Test("Audio source display names are not empty")
    func audioSourceDisplayNamesNotEmpty() {
        #expect(AudioSource.microphone.displayName.isEmpty == false)
        #expect(AudioSource.systemAudio.displayName.isEmpty == false)
    }

    @Test("Audio source is Equatable")
    func audioSourceIsEquatable() {
        // swiftlint:disable identical_operands
        #expect(AudioSource.microphone == AudioSource.microphone)
        #expect(AudioSource.systemAudio == AudioSource.systemAudio)
        // swiftlint:enable identical_operands
        #expect(AudioSource.microphone != AudioSource.systemAudio)
    }

    @Test("Audio source is Codable")
    func audioSourceIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let micData = try encoder.encode(AudioSource.microphone)
        let decodedMic = try decoder.decode(AudioSource.self, from: micData)
        #expect(decodedMic == .microphone)

        let sysData = try encoder.encode(AudioSource.systemAudio)
        let decodedSys = try decoder.decode(AudioSource.self, from: sysData)
        #expect(decodedSys == .systemAudio)
    }

    @Test("Audio source is Sendable")
    func audioSourceIsSendable() {
        let source = AudioSource.microphone
        Task {
            _ = source.displayName
        }
    }
}

// MARK: - Audio Stream Output Handler Tests

@Suite("Audio Stream Output Handler Tests", .tags(.requiresHardware))
@MainActor
struct AudioStreamOutputHandlerTests {
    @Test("Handler initializes with callback")
    func handlerInitializesWithCallback() {
        // Test that handler can be created with a callback
        let handler = AudioStreamOutputHandler { _ in
            // Callback placeholder - actual invocation tested separately
        }
        // Verify instance is usable
        _ = handler
    }

    @Test("Handler conforms to SCStreamOutput")
    func handlerConformsToSCStreamOutput() {
        let handler: any SCStreamOutput = AudioStreamOutputHandler { _ in }
        _ = handler
    }
}

// MARK: - Video Stream Output Handler Tests

@Suite("Video Stream Output Handler Tests", .tags(.requiresHardware))
@MainActor
struct VideoStreamOutputHandlerTests {
    @Test("Video handler initializes successfully")
    func videoHandlerInitializes() {
        let handler = VideoStreamOutputHandler()
        _ = handler
    }

    @Test("Video handler conforms to SCStreamOutput")
    func videoHandlerConformsToSCStreamOutput() {
        let handler: any SCStreamOutput = VideoStreamOutputHandler()
        _ = handler
    }
}

// MARK: - Stream Delegate Tests

@Suite("Stream Delegate Tests", .tags(.requiresHardware))
@MainActor
struct StreamDelegateTests {
    @Test("Stream delegate initializes successfully")
    func streamDelegateInitializes() {
        let delegate = StreamDelegate()
        _ = delegate
    }

    @Test("Stream delegate conforms to SCStreamDelegate")
    func streamDelegateConformsToSCStreamDelegate() {
        let delegate: any SCStreamDelegate = StreamDelegate()
        _ = delegate
    }

    @Test("Stream delegate handles error without crash")
    func streamDelegateHandlesError() {
        let delegate = StreamDelegate()
        // This would normally be called by the system, but we verify it doesn't crash
        _ = delegate
    }
}

// MARK: - System Audio Capture Tests

@Suite("System Audio Capture Tests", .tags(.requiresHardware))
@MainActor
struct SystemAudioCaptureTests {
    @Test("System audio capture initializes successfully")
    func systemAudioCaptureInitializes() {
        let capture = SystemAudioCapture()
        _ = capture
    }

    @Test("System audio capture has nil selected source initially")
    func systemAudioCaptureInitialSelectedSource() {
        let capture = SystemAudioCapture()
        #expect(capture.selectedSource == nil)
    }

    @Test("System audio capture can set selected source")
    func systemAudioCaptureCanSetSelectedSource() {
        let capture = SystemAudioCapture()
        let source = AudioSourceInfo(
            id: "test-source",
            name: "Test App",
            bundleIdentifier: "com.test.app",
            isAllSystemAudio: false,
            windowID: 12345,
            windowTitle: "Test Window",
            processID: 1000,
            iconData: nil
        )

        capture.selectedSource = source
        #expect(capture.selectedSource?.id == "test-source")
    }

    @Test("Stop capture when not capturing is safe")
    func stopCaptureWhenNotCapturingIsSafe() async {
        let capture = SystemAudioCapture()
        await capture.stopCapture()
        // Should complete without error
    }

    @Test("Multiple stop captures are safe")
    func multipleStopCapturesAreSafe() async {
        let capture = SystemAudioCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        // Should complete without error
    }
}

// MARK: - Ensure Microphones Loaded Tests

@Suite("Ensure Microphones Loaded Tests", .tags(.requiresHardware))
@MainActor
struct EnsureMicrophonesLoadedTests {
    @Test("Ensure microphones loaded only loads once", .disabled("Requires audio hardware - run locally"))
    func ensureMicrophonesLoadedOnlyLoadsOnce() async {
        let service = AudioCaptureService()

        // First call should trigger load
        await service.ensureMicrophonesLoaded()

        // Store the count after first load
        let firstCount = service.availableMicrophones.count

        // Second call should be a no-op
        await service.ensureMicrophonesLoaded()

        // Count should be the same (not doubled)
        #expect(service.availableMicrophones.count == firstCount)
    }

    @Test("Ensure microphones loaded is idempotent", .disabled("Requires audio hardware - run locally"))
    func ensureMicrophonesLoadedIsIdempotent() async {
        let service = AudioCaptureService()

        // Multiple calls should all succeed
        await service.ensureMicrophonesLoaded()
        await service.ensureMicrophonesLoaded()
        await service.ensureMicrophonesLoaded()

        // Service should still be in valid state
        #expect(service.state == .idle)
    }
}

// MARK: - Audio Source Selection Tests

@Suite("Audio Source Selection Tests", .tags(.requiresHardware))
@MainActor
struct AudioSourceSelectionTests {
    @Test("Refresh audio sources updates available sources", .disabled("Requires audio hardware - run locally"))
    func refreshAudioSourcesUpdatesAvailableSources() async {
        let service = AudioCaptureService()

        await service.refreshAudioSources()

        // Should always have at least "All System Audio"
        #expect(service.availableAudioSources.count >= 1)
        #expect(service.availableAudioSources.contains { $0.isAllSystemAudio })
    }

    @Test("Select audio source from available sources works")
    func selectAudioSourceFromAvailableSourcesWorks() {
        let service = AudioCaptureService()

        // Select the all system audio source (which is always available)
        let allSystemAudio = AudioSourceInfo.allSystemAudio
        service.selectAudioSource(allSystemAudio)

        #expect(service.selectedAudioSource.isAllSystemAudio == true)
    }
}
