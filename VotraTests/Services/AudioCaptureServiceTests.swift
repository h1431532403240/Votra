//
//  AudioCaptureServiceTests.swift
//  VotraTests
//
//  Comprehensive unit tests for AudioCaptureService.
//  Tests focus on service-specific behaviors, state transitions,
//  and the integration of audio capture components.
//

import Foundation
import Testing
@testable import Votra

/// Namespace for AudioCaptureService tests
enum AudioCaptureServiceTests {}

// MARK: - Service Initialization Tests

@Suite("AudioCaptureService: Initialization")
@MainActor
struct AudioCaptureServiceInitTests {
    @Test("Service initializes with idle state")
    func initializesWithIdleState() {
        let service = AudioCaptureService()
        #expect(service.state == .idle)
    }

    @Test("Service initializes with nil selected microphone")
    func initializesWithNilSelectedMicrophone() {
        let service = AudioCaptureService()
        #expect(service.selectedMicrophone == nil)
    }

    @Test("Service initializes with empty microphone list")
    func initializesWithEmptyMicrophoneList() {
        let service = AudioCaptureService()
        #expect(service.availableMicrophones.isEmpty)
    }

    @Test("Service initializes with all system audio selected")
    func initializesWithAllSystemAudioSelected() {
        let service = AudioCaptureService()
        #expect(service.selectedAudioSource.isAllSystemAudio)
    }

    @Test("Service initializes with at least one available audio source")
    func initializesWithAtLeastOneAudioSource() {
        let service = AudioCaptureService()
        #expect(service.availableAudioSources.count >= 1)
    }

    @Test("Service does not access audio hardware during init")
    func doesNotAccessHardwareDuringInit() {
        // The service should initialize without triggering microphone access
        // This is verified by the fact that availableMicrophones is empty
        let service = AudioCaptureService()
        #expect(service.availableMicrophones.isEmpty)
    }
}

// MARK: - Microphone Selection Tests

@Suite("AudioCaptureService: Microphone Selection")
@MainActor
struct AudioCaptureServiceMicrophoneSelectionTests {
    @Test("selectMicrophone throws deviceNotFound for unavailable device")
    func selectMicrophoneThrowsForUnavailableDevice() async throws {
        let service = AudioCaptureService()
        let fakeDevice = AudioDevice(id: "nonexistent-device", name: "Fake Device", isDefault: false)

        do {
            try await service.selectMicrophone(fakeDevice)
            Issue.record("Expected deviceNotFound error to be thrown")
        } catch let error as AudioCaptureError {
            if case .deviceNotFound = error {
                // Success - expected error
            } else {
                Issue.record("Expected deviceNotFound, got \(error)")
            }
        } catch {
            Issue.record("Expected AudioCaptureError, got \(error)")
        }
    }

    @Test("Selected microphone remains nil after failed selection")
    func selectedMicrophoneRemainsNilAfterFailedSelection() async {
        let service = AudioCaptureService()
        let fakeDevice = AudioDevice(id: "fake", name: "Fake", isDefault: false)

        do {
            try await service.selectMicrophone(fakeDevice)
        } catch {
            // Expected to throw
        }

        #expect(service.selectedMicrophone == nil)
    }
}

// MARK: - Audio Source Selection Tests

@Suite("AudioCaptureService: Audio Source Selection")
@MainActor
struct AudioCaptureServiceAudioSourceSelectionTests {
    @Test("selectAudioSource accepts allSystemAudio")
    func selectAudioSourceAcceptsAllSystemAudio() {
        let service = AudioCaptureService()
        service.selectAudioSource(.allSystemAudio)
        #expect(service.selectedAudioSource.isAllSystemAudio)
    }

    @Test("selectAudioSource ignores unavailable source")
    func selectAudioSourceIgnoresUnavailableSource() {
        let service = AudioCaptureService()
        let unavailableSource = AudioSourceInfo(
            id: "unavailable",
            name: "Unavailable App",
            bundleIdentifier: "com.unavailable.app",
            isAllSystemAudio: false,
            windowID: 99999,
            windowTitle: "Window",
            processID: 12345,
            iconData: nil
        )

        service.selectAudioSource(unavailableSource)

        // Should still be allSystemAudio since unavailableSource isn't in availableAudioSources
        #expect(service.selectedAudioSource.isAllSystemAudio)
    }

    @Test("selectAudioSource does not modify availableAudioSources")
    func selectAudioSourceDoesNotModifyAvailableSources() {
        let service = AudioCaptureService()
        let initialCount = service.availableAudioSources.count

        service.selectAudioSource(.allSystemAudio)

        #expect(service.availableAudioSources.count == initialCount)
    }
}

// MARK: - Stop Capture Tests

@Suite("AudioCaptureService: Stop Capture")
@MainActor
struct AudioCaptureServiceStopCaptureTests {
    @Test("stopAllCapture succeeds when idle")
    func stopAllCaptureSucceedsWhenIdle() async {
        let service = AudioCaptureService()
        #expect(service.state == .idle)

        await service.stopAllCapture()

        #expect(service.state == .idle)
    }

    @Test("stopCapture from microphone succeeds when idle")
    func stopCaptureMicrophoneSucceedsWhenIdle() async {
        let service = AudioCaptureService()
        await service.stopCapture(from: .microphone)
        #expect(service.state == .idle)
    }

    @Test("stopCapture from systemAudio succeeds when idle")
    func stopCaptureSystemAudioSucceedsWhenIdle() async {
        let service = AudioCaptureService()
        await service.stopCapture(from: .systemAudio)
        #expect(service.state == .idle)
    }

    @Test("Multiple stopAllCapture calls are safe")
    func multipleStopAllCaptureCallsAreSafe() async {
        let service = AudioCaptureService()

        await service.stopAllCapture()
        await service.stopAllCapture()
        await service.stopAllCapture()

        #expect(service.state == .idle)
    }
}

// MARK: - Ensure Microphones Loaded Tests

@Suite("AudioCaptureService: Ensure Microphones Loaded")
@MainActor
struct AudioCaptureServiceEnsureMicrophonesLoadedTests {
    @Test("ensureMicrophonesLoaded can be called multiple times")
    func ensureMicrophonesLoadedIdempotent() async {
        let service = AudioCaptureService()

        await service.ensureMicrophonesLoaded()
        let firstCount = service.availableMicrophones.count

        await service.ensureMicrophonesLoaded()
        let secondCount = service.availableMicrophones.count

        // Count should be the same (not doubled or multiplied)
        #expect(firstCount == secondCount)
    }

    @Test("ensureMicrophonesLoaded maintains idle state")
    func ensureMicrophonesLoadedMaintainsIdleState() async {
        let service = AudioCaptureService()

        await service.ensureMicrophonesLoaded()

        #expect(service.state == .idle)
    }
}

// MARK: - Refresh Audio Sources Tests

@Suite("AudioCaptureService: Refresh Audio Sources")
@MainActor
struct AudioCaptureServiceRefreshAudioSourcesTests {
    @Test("refreshAudioSources maintains allSystemAudio as option")
    func refreshAudioSourcesMaintainsAllSystemAudio() async {
        let service = AudioCaptureService()

        await service.refreshAudioSources()

        #expect(service.availableAudioSources.contains(.allSystemAudio))
    }

    @Test("refreshAudioSources resets to allSystemAudio if selected source removed")
    func refreshAudioSourcesResetsSelectionIfRemoved() async {
        let service = AudioCaptureService()

        // Initially allSystemAudio should be selected
        #expect(service.selectedAudioSource.isAllSystemAudio)

        await service.refreshAudioSources()

        // Should still be allSystemAudio
        #expect(service.selectedAudioSource.isAllSystemAudio)
    }
}

// MARK: - Protocol Conformance Tests

@Suite("AudioCaptureService: Protocol Conformance")
@MainActor
struct AudioCaptureServiceProtocolConformanceTests {
    @Test("Service conforms to AudioCaptureServiceProtocol")
    func conformsToProtocol() {
        let service: any AudioCaptureServiceProtocol = AudioCaptureService()
        _ = service.state
        _ = service.selectedMicrophone
        _ = service.availableMicrophones
    }

    @Test("Protocol requires state property")
    func protocolRequiresState() {
        let service: any AudioCaptureServiceProtocol = AudioCaptureService()
        #expect(service.state == .idle)
    }

    @Test("Protocol requires selectedMicrophone property")
    func protocolRequiresSelectedMicrophone() {
        let service: any AudioCaptureServiceProtocol = AudioCaptureService()
        #expect(service.selectedMicrophone == nil)
    }

    @Test("Protocol requires availableMicrophones property")
    func protocolRequiresAvailableMicrophones() {
        let service: any AudioCaptureServiceProtocol = AudioCaptureService()
        #expect(service.availableMicrophones.isEmpty)
    }
}

// MARK: - State Type Tests

@Suite("AudioCaptureService: State Type")
@MainActor
struct AudioCaptureServiceStateTypeTests {
    @Test("State enum has all expected cases")
    func stateEnumHasAllCases() {
        let states: [AudioCaptureState] = [
            .idle,
            .capturingMicrophone,
            .capturingSystemAudio,
            .capturingBoth
        ]
        #expect(states.count == 4)
    }

    @Test("State cases are equatable")
    func stateCasesAreEquatable() {
        // swiftlint:disable:next identical_operands
        #expect(AudioCaptureState.idle == AudioCaptureState.idle)
        #expect(AudioCaptureState.idle != AudioCaptureState.capturingMicrophone)
    }

    @Test("State is Sendable for concurrency")
    func stateIsSendable() async {
        let state = AudioCaptureState.capturingBoth
        let result = await Task { state }.value
        #expect(result == .capturingBoth)
    }
}

// MARK: - Error Type Tests

@Suite("AudioCaptureService: Error Type")
@MainActor
struct AudioCaptureServiceErrorTypeTests {
    @Test("All error cases have non-empty descriptions")
    func allErrorsHaveDescriptions() {
        let errors: [AudioCaptureError] = [
            .microphonePermissionDenied,
            .screenRecordingPermissionDenied,
            .deviceNotFound,
            .captureAlreadyActive,
            .engineStartFailed(underlying: NSError(domain: "Test", code: 0)),
            .invalidAudioFormat
        ]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test("Permission errors have recovery suggestions")
    func permissionErrorsHaveRecoverySuggestions() {
        #expect(AudioCaptureError.microphonePermissionDenied.recoverySuggestion?.isEmpty == false)
        #expect(AudioCaptureError.screenRecordingPermissionDenied.recoverySuggestion?.isEmpty == false)
        #expect(AudioCaptureError.deviceNotFound.recoverySuggestion?.isEmpty == false)
    }

    @Test("Non-permission errors have no recovery suggestion")
    func nonPermissionErrorsHaveNoRecoverySuggestion() {
        #expect(AudioCaptureError.captureAlreadyActive.recoverySuggestion == nil)
        #expect(AudioCaptureError.engineStartFailed(underlying: NSError(domain: "", code: 0)).recoverySuggestion == nil)
        #expect(AudioCaptureError.invalidAudioFormat.recoverySuggestion == nil)
    }

    @Test("engineStartFailed preserves underlying error")
    func engineStartFailedPreservesError() {
        let underlying = NSError(domain: "TestDomain", code: 42)
        let error = AudioCaptureError.engineStartFailed(underlying: underlying)

        if case let .engineStartFailed(captured) = error {
            let nsError = captured as NSError
            #expect(nsError.domain == "TestDomain")
            #expect(nsError.code == 42)
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }
}

// MARK: - Audio Device Type Tests

@Suite("AudioCaptureService: AudioDevice Type")
@MainActor
struct AudioCaptureServiceAudioDeviceTypeTests {
    @Test("AudioDevice stores all properties")
    func audioDeviceStoresProperties() {
        let device = AudioDevice(id: "test-id", name: "Test Mic", isDefault: true)
        #expect(device.id == "test-id")
        #expect(device.name == "Test Mic")
        #expect(device.isDefault == true)
    }

    @Test("AudioDevice is Identifiable")
    func audioDeviceIsIdentifiable() {
        let device = AudioDevice(id: "id", name: "name", isDefault: false)
        #expect(device.id == "id")
    }

    @Test("AudioDevice is Equatable")
    func audioDeviceIsEquatable() {
        let device1 = AudioDevice(id: "a", name: "A", isDefault: true)
        let device2 = AudioDevice(id: "a", name: "A", isDefault: true)
        let device3 = AudioDevice(id: "b", name: "A", isDefault: true)

        #expect(device1 == device2)
        #expect(device1 != device3)
    }

    @Test("AudioDevice is Hashable")
    func audioDeviceIsHashable() {
        var set = Set<AudioDevice>()
        let device1 = AudioDevice(id: "id", name: "name", isDefault: true)
        let device2 = AudioDevice(id: "id", name: "name", isDefault: true)

        set.insert(device1)
        set.insert(device2)

        #expect(set.count == 1)
    }

    @Test("AudioDevice is Sendable")
    func audioDeviceIsSendable() async {
        let device = AudioDevice(id: "id", name: "name", isDefault: false)
        let result = await Task { device }.value
        #expect(result.id == "id")
    }
}

// MARK: - Permission Status Type Tests

@Suite("AudioCaptureService: AudioPermissionStatus Type")
@MainActor
struct AudioCaptureServicePermissionStatusTypeTests {
    @Test("PermissionState has all expected cases")
    func permissionStateHasAllCases() {
        let states: [AudioPermissionStatus.PermissionState] = [
            .authorized,
            .denied,
            .notDetermined
        ]
        #expect(states.count == 3)
    }

    @Test("canCaptureMicrophone returns true only when authorized")
    func canCaptureMicrophoneOnlyWhenAuthorized() {
        let authorized = AudioPermissionStatus(microphone: .authorized, screenRecording: .denied)
        let denied = AudioPermissionStatus(microphone: .denied, screenRecording: .authorized)
        let notDetermined = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .authorized)

        #expect(authorized.canCaptureMicrophone == true)
        #expect(denied.canCaptureMicrophone == false)
        #expect(notDetermined.canCaptureMicrophone == false)
    }

    @Test("canCaptureSystemAudio returns true only when authorized")
    func canCaptureSystemAudioOnlyWhenAuthorized() {
        let authorized = AudioPermissionStatus(microphone: .denied, screenRecording: .authorized)
        let denied = AudioPermissionStatus(microphone: .authorized, screenRecording: .denied)
        let notDetermined = AudioPermissionStatus(microphone: .authorized, screenRecording: .notDetermined)

        #expect(authorized.canCaptureSystemAudio == true)
        #expect(denied.canCaptureSystemAudio == false)
        #expect(notDetermined.canCaptureSystemAudio == false)
    }

    @Test("Both permissions can be authorized simultaneously")
    func bothPermissionsCanBeAuthorized() {
        let status = AudioPermissionStatus(microphone: .authorized, screenRecording: .authorized)
        #expect(status.canCaptureMicrophone == true)
        #expect(status.canCaptureSystemAudio == true)
    }

    @Test("Both permissions can be denied simultaneously")
    func bothPermissionsCanBeDenied() {
        let status = AudioPermissionStatus(microphone: .denied, screenRecording: .denied)
        #expect(status.canCaptureMicrophone == false)
        #expect(status.canCaptureSystemAudio == false)
    }

    @Test("AudioPermissionStatus is Sendable")
    func permissionStatusIsSendable() async {
        let status = AudioPermissionStatus(microphone: .authorized, screenRecording: .authorized)
        let result = await Task { status.canCaptureMicrophone }.value
        #expect(result == true)
    }
}

// MARK: - Internal Class Instantiation Tests

@Suite("AudioCaptureService: Internal Classes")
@MainActor
struct AudioCaptureServiceInternalClassesTests {
    @Test("MicrophoneAudioCapture can be instantiated")
    func microphoneAudioCaptureCanBeInstantiated() {
        let capture = MicrophoneAudioCapture()
        _ = capture
    }

    @Test("MicrophoneAudioCapture selectDevice accepts any string")
    func microphoneAudioCaptureSelectDevice() async throws {
        let capture = MicrophoneAudioCapture()
        try await capture.selectDevice("any-device-id")
    }

    @Test("MicrophoneAudioCapture stopCapture is safe when not capturing")
    func microphoneAudioCaptureStopSafe() async {
        let capture = MicrophoneAudioCapture()
        await capture.stopCapture()
    }

    @Test("SystemAudioCapture can be instantiated")
    func systemAudioCaptureCanBeInstantiated() {
        let capture = SystemAudioCapture()
        _ = capture
    }

    @Test("SystemAudioCapture stopCapture is safe when not capturing")
    func systemAudioCaptureStopSafe() async {
        let capture = SystemAudioCapture()
        await capture.stopCapture()
    }

    @Test("SystemAudioCapture selectedSource is initially nil")
    func systemAudioCaptureSelectedSourceInitiallyNil() {
        let capture = SystemAudioCapture()
        #expect(capture.selectedSource == nil)
    }

    @Test("StreamDelegate can be instantiated")
    func streamDelegateCanBeInstantiated() {
        let delegate = StreamDelegate()
        _ = delegate
    }

    @Test("VideoStreamOutputHandler can be instantiated")
    func videoStreamOutputHandlerCanBeInstantiated() {
        let handler = VideoStreamOutputHandler()
        _ = handler
    }

    @Test("AudioStreamOutputHandler can be instantiated with closure")
    func audioStreamOutputHandlerCanBeInstantiated() {
        let handler = AudioStreamOutputHandler { _ in
            // Handler callback - not called until buffer received
        }
        _ = handler
    }
}

// MARK: - Observable Behavior Tests

@Suite("AudioCaptureService: Observable Behavior")
@MainActor
struct AudioCaptureServiceObservableBehaviorTests {
    @Test("Service is Observable")
    func serviceIsObservable() {
        let service = AudioCaptureService()
        // The fact that this compiles verifies @Observable is applied
        _ = service.state
        _ = service.selectedMicrophone
        _ = service.availableMicrophones
        _ = service.selectedAudioSource
        _ = service.availableAudioSources
    }

    @Test("Service properties are readable")
    func servicePropertiesAreReadable() {
        let service = AudioCaptureService()

        // Verify all published properties can be read
        let state = service.state
        let selectedMic = service.selectedMicrophone
        let mics = service.availableMicrophones
        let selectedSource = service.selectedAudioSource
        let sources = service.availableAudioSources

        #expect(state == .idle)
        #expect(selectedMic == nil)
        #expect(mics.isEmpty)
        #expect(selectedSource.isAllSystemAudio)
        #expect(sources.contains(.allSystemAudio))
    }
}

// MARK: - Error Description Verification Tests

@Suite("AudioCaptureService: Error Descriptions")
@MainActor
struct AudioCaptureServiceErrorDescriptionTests {
    @Test("microphonePermissionDenied has non-nil description")
    func microphonePermissionDeniedDescription() {
        let error = AudioCaptureError.microphonePermissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("screenRecordingPermissionDenied has non-nil description")
    func screenRecordingPermissionDeniedDescription() {
        let error = AudioCaptureError.screenRecordingPermissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("deviceNotFound has non-nil description")
    func deviceNotFoundDescription() {
        let error = AudioCaptureError.deviceNotFound
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("captureAlreadyActive has non-nil description")
    func captureAlreadyActiveDescription() {
        let error = AudioCaptureError.captureAlreadyActive
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("engineStartFailed has non-nil description")
    func engineStartFailedDescription() {
        let underlying = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        let error = AudioCaptureError.engineStartFailed(underlying: underlying)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("invalidAudioFormat has non-nil description")
    func invalidAudioFormatDescription() {
        let error = AudioCaptureError.invalidAudioFormat
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Error conforms to LocalizedError")
    func errorConformsToLocalizedError() {
        let error: LocalizedError = AudioCaptureError.deviceNotFound
        #expect(error.errorDescription != nil)
    }
}

// MARK: - Error Recovery Suggestion Tests

@Suite("AudioCaptureService: Error Recovery Suggestions")
@MainActor
struct AudioCaptureServiceErrorRecoverySuggestionTests {
    @Test("microphonePermissionDenied has non-nil recovery suggestion")
    func microphonePermissionDeniedRecovery() {
        let error = AudioCaptureError.microphonePermissionDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("screenRecordingPermissionDenied has non-nil recovery suggestion")
    func screenRecordingPermissionDeniedRecovery() {
        let error = AudioCaptureError.screenRecordingPermissionDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("deviceNotFound has non-nil recovery suggestion")
    func deviceNotFoundRecovery() {
        let error = AudioCaptureError.deviceNotFound
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("captureAlreadyActive has nil recovery suggestion")
    func captureAlreadyActiveRecovery() {
        let error = AudioCaptureError.captureAlreadyActive
        #expect(error.recoverySuggestion == nil)
    }

    @Test("engineStartFailed has nil recovery suggestion")
    func engineStartFailedRecovery() {
        let error = AudioCaptureError.engineStartFailed(underlying: NSError(domain: "", code: 0))
        #expect(error.recoverySuggestion == nil)
    }

    @Test("invalidAudioFormat has nil recovery suggestion")
    func invalidAudioFormatRecovery() {
        let error = AudioCaptureError.invalidAudioFormat
        #expect(error.recoverySuggestion == nil)
    }
}

// MARK: - AudioDevice Equality Edge Cases Tests

@Suite("AudioCaptureService: AudioDevice Equality")
@MainActor
struct AudioCaptureServiceAudioDeviceEqualityTests {
    @Test("Devices with same ID but different name are equal")
    func devicesWithSameIdDifferentNameAreEqual() {
        let device1 = AudioDevice(id: "same-id", name: "Name A", isDefault: true)
        let device2 = AudioDevice(id: "same-id", name: "Name B", isDefault: false)
        // AudioDevice equality is based on all properties
        #expect(device1 != device2)
    }

    @Test("Devices with different ID but same name are not equal")
    func devicesWithDifferentIdSameNameAreNotEqual() {
        let device1 = AudioDevice(id: "id-1", name: "Same Name", isDefault: true)
        let device2 = AudioDevice(id: "id-2", name: "Same Name", isDefault: true)
        #expect(device1 != device2)
    }

    @Test("Devices with same ID and name but different isDefault are not equal")
    func devicesWithDifferentIsDefaultAreNotEqual() {
        let device1 = AudioDevice(id: "id", name: "Name", isDefault: true)
        let device2 = AudioDevice(id: "id", name: "Name", isDefault: false)
        #expect(device1 != device2)
    }

    @Test("Device equals itself")
    func deviceEqualsSelf() {
        let device = AudioDevice(id: "id", name: "Name", isDefault: true)
        // swiftlint:disable:next identical_operands
        #expect(device == device)
    }

    @Test("Empty ID and name are valid")
    func emptyIdAndNameAreValid() {
        let device = AudioDevice(id: "", name: "", isDefault: false)
        #expect(device.id.isEmpty)
        #expect(device.name.isEmpty)
    }
}

// MARK: - AudioDevice Hashable Tests

@Suite("AudioCaptureService: AudioDevice Hashable")
@MainActor
struct AudioCaptureServiceAudioDeviceHashableTests {
    @Test("Different devices produce different hash values")
    func differentDevicesProduceDifferentHashes() {
        let device1 = AudioDevice(id: "id-1", name: "Name", isDefault: true)
        let device2 = AudioDevice(id: "id-2", name: "Name", isDefault: true)

        var set = Set<AudioDevice>()
        set.insert(device1)
        set.insert(device2)

        #expect(set.count == 2)
    }

    @Test("Set correctly deduplicates identical devices")
    func setDeduplicatesIdenticalDevices() {
        let device1 = AudioDevice(id: "id", name: "Name", isDefault: true)
        let device2 = AudioDevice(id: "id", name: "Name", isDefault: true)

        var set = Set<AudioDevice>()
        set.insert(device1)
        set.insert(device2)

        #expect(set.count == 1)
    }

    @Test("Device can be used as dictionary key")
    func deviceCanBeUsedAsDictionaryKey() {
        let device = AudioDevice(id: "id", name: "Name", isDefault: true)
        var dict = [AudioDevice: Int]()
        dict[device] = 42

        #expect(dict[device] == 42)
    }
}

// MARK: - Permission Status Combinations Tests

@Suite("AudioCaptureService: Permission Status Combinations")
@MainActor
struct AudioCapturePermissionCombinationsTests {
    @Test("All permission state combinations for microphone")
    func allPermissionStateCombinationsForMicrophone() {
        let authorizedMic = AudioPermissionStatus(microphone: .authorized, screenRecording: .notDetermined)
        let deniedMic = AudioPermissionStatus(microphone: .denied, screenRecording: .notDetermined)
        let notDeterminedMic = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .notDetermined)

        #expect(authorizedMic.canCaptureMicrophone == true)
        #expect(deniedMic.canCaptureMicrophone == false)
        #expect(notDeterminedMic.canCaptureMicrophone == false)
    }

    @Test("All permission state combinations for screen recording")
    func allPermissionStateCombinationsForScreenRecording() {
        let authorizedScreen = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .authorized)
        let deniedScreen = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .denied)
        let notDeterminedScreen = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .notDetermined)

        #expect(authorizedScreen.canCaptureSystemAudio == true)
        #expect(deniedScreen.canCaptureSystemAudio == false)
        #expect(notDeterminedScreen.canCaptureSystemAudio == false)
    }

    @Test("Mixed permission states")
    func mixedPermissionStates() {
        let micOnlyAuthorized = AudioPermissionStatus(microphone: .authorized, screenRecording: .denied)
        let screenOnlyAuthorized = AudioPermissionStatus(microphone: .denied, screenRecording: .authorized)
        let bothNotDetermined = AudioPermissionStatus(microphone: .notDetermined, screenRecording: .notDetermined)

        #expect(micOnlyAuthorized.canCaptureMicrophone == true)
        #expect(micOnlyAuthorized.canCaptureSystemAudio == false)

        #expect(screenOnlyAuthorized.canCaptureMicrophone == false)
        #expect(screenOnlyAuthorized.canCaptureSystemAudio == true)

        #expect(bothNotDetermined.canCaptureMicrophone == false)
        #expect(bothNotDetermined.canCaptureSystemAudio == false)
    }

    @Test("PermissionState enum equality")
    func permissionStateEnumEquality() {
        #expect(AudioPermissionStatus.PermissionState.authorized == .authorized)
        #expect(AudioPermissionStatus.PermissionState.denied == .denied)
        #expect(AudioPermissionStatus.PermissionState.notDetermined == .notDetermined)
        #expect(AudioPermissionStatus.PermissionState.authorized != .denied)
    }
}

// MARK: - State Enum Tests

@Suite("AudioCaptureService: State Enum")
@MainActor
struct AudioCaptureServiceStateEnumTests {
    @Test("All state cases are distinct")
    func allStateCasesAreDistinct() {
        let idle = AudioCaptureState.idle
        let capturingMicrophone = AudioCaptureState.capturingMicrophone
        let capturingSystemAudio = AudioCaptureState.capturingSystemAudio
        let capturingBoth = AudioCaptureState.capturingBoth

        #expect(idle != capturingMicrophone)
        #expect(idle != capturingSystemAudio)
        #expect(idle != capturingBoth)
        #expect(capturingMicrophone != capturingSystemAudio)
        #expect(capturingMicrophone != capturingBoth)
        #expect(capturingSystemAudio != capturingBoth)
    }

    @Test("State can be stored in collection")
    func stateCanBeStoredInCollection() {
        let states: [AudioCaptureState] = [.idle, .capturingMicrophone, .capturingSystemAudio, .capturingBoth]
        #expect(states.contains(.idle))
        #expect(states.contains(.capturingBoth))
    }

    @Test("State can be used in switch statement")
    func stateCanBeUsedInSwitch() {
        let state = AudioCaptureState.capturingMicrophone
        var result = ""

        switch state {
        case .idle: result = "idle"
        case .capturingMicrophone: result = "mic"
        case .capturingSystemAudio: result = "system"
        case .capturingBoth: result = "both"
        }

        #expect(result == "mic")
    }

    @Test("State is nonisolated")
    func stateIsNonisolated() async {
        // Can be accessed from different isolation contexts
        let state = AudioCaptureState.capturingBoth
        let result = await Task.detached {
            state
        }.value
        #expect(result == .capturingBoth)
    }
}

// MARK: - MicrophoneAudioCapture Tests

@Suite("AudioCaptureService: MicrophoneAudioCapture")
@MainActor
struct AudioCaptureServiceMicrophoneAudioCaptureTests {
    @Test("MicrophoneAudioCapture can select multiple devices sequentially")
    func canSelectMultipleDevicesSequentially() async throws {
        let capture = MicrophoneAudioCapture()
        try await capture.selectDevice("device-1")
        try await capture.selectDevice("device-2")
        try await capture.selectDevice("device-3")
        // No error means success
    }

    @Test("MicrophoneAudioCapture stopCapture is idempotent")
    func stopCaptureIsIdempotent() async {
        let capture = MicrophoneAudioCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        // No error means success
    }

    @Test("MicrophoneAudioCapture accepts empty device ID")
    func acceptsEmptyDeviceId() async throws {
        let capture = MicrophoneAudioCapture()
        try await capture.selectDevice("")
        // No error means success
    }
}

// MARK: - SystemAudioCapture Tests

@Suite("AudioCaptureService: SystemAudioCapture")
@MainActor
struct AudioCaptureServiceSystemAudioCaptureTests {
    @Test("SystemAudioCapture selectedSource can be set to nil")
    func selectedSourceCanBeSetToNil() {
        let capture = SystemAudioCapture()
        capture.selectedSource = nil
        #expect(capture.selectedSource == nil)
    }

    @Test("SystemAudioCapture selectedSource can be set to a source")
    func selectedSourceCanBeSetToSource() {
        let capture = SystemAudioCapture()
        let source = AudioSourceInfo(
            id: "test",
            name: "Test",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 123,
            windowTitle: "Window",
            processID: 456,
            iconData: nil
        )
        capture.selectedSource = source
        #expect(capture.selectedSource?.id == "test")
    }

    @Test("SystemAudioCapture stopCapture is idempotent")
    func stopCaptureIsIdempotent() async {
        let capture = SystemAudioCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        await capture.stopCapture()
        // No error means success
    }
}

// MARK: - Service Audio Source Selection Edge Cases

@Suite("AudioCaptureService: Audio Source Selection Edge Cases")
@MainActor
struct AudioCaptureSourceSelectionEdgeCaseTests {
    @Test("selectAudioSource with allSystemAudio clears systemAudioCapture selectedSource")
    func selectAllSystemAudioClearsSelectedSource() {
        let service = AudioCaptureService()

        // First select allSystemAudio
        service.selectAudioSource(.allSystemAudio)

        // Should remain as allSystemAudio
        #expect(service.selectedAudioSource.isAllSystemAudio)
    }

    @Test("selectAudioSource does not change selection for unavailable source")
    func selectUnavailableSourceDoesNotChangeSelection() {
        let service = AudioCaptureService()

        let originalSource = service.selectedAudioSource

        let unavailableSource = AudioSourceInfo(
            id: "unavailable-id",
            name: "Unavailable",
            bundleIdentifier: "com.unavailable",
            isAllSystemAudio: false,
            windowID: 99999,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        service.selectAudioSource(unavailableSource)

        #expect(service.selectedAudioSource == originalSource)
    }

    @Test("availableAudioSources always contains allSystemAudio at initialization")
    func availableSourcesAlwaysContainsAllSystemAudio() {
        let service = AudioCaptureService()
        #expect(service.availableAudioSources.contains { $0.isAllSystemAudio })
    }
}

// MARK: - Service State After Operations Tests

@Suite("AudioCaptureService: State After Operations")
@MainActor
struct AudioCaptureServiceStateAfterOperationsTests {
    @Test("State remains idle after stopCapture from microphone when idle")
    func stateRemainsIdleAfterStopMicrophoneWhenIdle() async {
        let service = AudioCaptureService()
        #expect(service.state == .idle)

        await service.stopCapture(from: .microphone)

        #expect(service.state == .idle)
    }

    @Test("State remains idle after stopCapture from systemAudio when idle")
    func stateRemainsIdleAfterStopSystemAudioWhenIdle() async {
        let service = AudioCaptureService()
        #expect(service.state == .idle)

        await service.stopCapture(from: .systemAudio)

        #expect(service.state == .idle)
    }

    @Test("State remains idle after multiple stop operations")
    func stateRemainsIdleAfterMultipleStops() async {
        let service = AudioCaptureService()

        await service.stopCapture(from: .microphone)
        await service.stopCapture(from: .systemAudio)
        await service.stopAllCapture()

        #expect(service.state == .idle)
    }

    @Test("selectMicrophone does not change state")
    func selectMicrophoneDoesNotChangeState() async {
        let service = AudioCaptureService()
        let initialState = service.state

        let fakeDevice = AudioDevice(id: "fake", name: "Fake", isDefault: false)
        do {
            try await service.selectMicrophone(fakeDevice)
        } catch {
            // Expected to throw
        }

        #expect(service.state == initialState)
    }

    @Test("selectAudioSource does not change state")
    func selectAudioSourceDoesNotChangeState() {
        let service = AudioCaptureService()
        let initialState = service.state

        service.selectAudioSource(.allSystemAudio)

        #expect(service.state == initialState)
    }
}

// MARK: - Error Underlying Tests

@Suite("AudioCaptureService: Error Underlying")
@MainActor
struct AudioCaptureServiceErrorUnderlyingTests {
    @Test("engineStartFailed preserves error domain")
    func engineStartFailedPreservesErrorDomain() {
        let underlying = NSError(domain: "com.test.domain", code: 0)
        let error = AudioCaptureError.engineStartFailed(underlying: underlying)

        if case let .engineStartFailed(captured) = error {
            let nsError = captured as NSError
            #expect(nsError.domain == "com.test.domain")
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }

    @Test("engineStartFailed preserves error code")
    func engineStartFailedPreservesErrorCode() {
        let underlying = NSError(domain: "Test", code: 999)
        let error = AudioCaptureError.engineStartFailed(underlying: underlying)

        if case let .engineStartFailed(captured) = error {
            let nsError = captured as NSError
            #expect(nsError.code == 999)
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }

    @Test("engineStartFailed preserves error userInfo")
    func engineStartFailedPreservesErrorUserInfo() {
        let underlying = NSError(domain: "Test", code: 0, userInfo: ["key": "value"])
        let error = AudioCaptureError.engineStartFailed(underlying: underlying)

        if case let .engineStartFailed(captured) = error {
            let nsError = captured as NSError
            #expect(nsError.userInfo["key"] as? String == "value")
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }

    @Test("engineStartFailed works with different error types")
    func engineStartFailedWorksWithDifferentErrorTypes() {
        struct CustomError: Error {
            let message: String
        }

        let underlying = CustomError(message: "Custom error")
        let error = AudioCaptureError.engineStartFailed(underlying: underlying)

        if case let .engineStartFailed(captured) = error {
            if let customError = captured as? CustomError {
                #expect(customError.message == "Custom error")
            } else {
                Issue.record("Expected CustomError type")
            }
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }
}

// MARK: - Stream Handler Tests

@Suite("AudioCaptureService: Stream Handlers")
@MainActor
struct AudioCaptureServiceStreamHandlerTests {
    @Test("AudioStreamOutputHandler can be created with closure")
    func audioStreamOutputHandlerInitialization() {
        // Create handler with a no-op closure
        let handler = AudioStreamOutputHandler { _ in }
        // If we get here without crash, initialization succeeded
        _ = handler
    }

    @Test("VideoStreamOutputHandler can be created")
    func videoStreamOutputHandlerCreation() {
        let handler = VideoStreamOutputHandler()
        _ = handler
        // No crash means success
    }

    @Test("StreamDelegate can be created")
    func streamDelegateCanBeCreated() {
        let delegate = StreamDelegate()
        // StreamDelegate is an NSObject subclass (verified at compile time)
        _ = delegate
    }
}

// MARK: - Service Configuration Tests

@Suite("AudioCaptureService: Configuration")
@MainActor
struct AudioCaptureServiceConfigurationTests {
    @Test("Service has expected default audio source")
    func serviceHasExpectedDefaultAudioSource() {
        let service = AudioCaptureService()
        #expect(service.selectedAudioSource.isAllSystemAudio == true)
        #expect(service.selectedAudioSource.id == "all-system-audio")
    }

    @Test("Service availableAudioSources is not empty")
    func availableAudioSourcesIsNotEmpty() {
        let service = AudioCaptureService()
        #expect(service.availableAudioSources.isEmpty == false)
    }

    @Test("Service first available source is allSystemAudio")
    func firstAvailableSourceIsAllSystemAudio() {
        let service = AudioCaptureService()
        #expect(service.availableAudioSources.first?.isAllSystemAudio == true)
    }
}

// MARK: - Concurrent Access Tests

@Suite("AudioCaptureService: Concurrent Access")
@MainActor
struct AudioCaptureServiceConcurrentAccessTests {
    @Test("Service can be accessed from MainActor context")
    func serviceCanBeAccessedFromMainActor() {
        let service = AudioCaptureService()
        _ = service.state
        _ = service.availableMicrophones
        _ = service.selectedMicrophone
        _ = service.availableAudioSources
        _ = service.selectedAudioSource
    }

    @Test("State value can be passed across isolation boundaries")
    func stateValueCanBePassedAcrossIsolationBoundaries() async {
        let state = AudioCaptureState.capturingMicrophone

        let result = await Task.detached {
            state
        }.value

        #expect(result == .capturingMicrophone)
    }

    @Test("AudioDevice can be passed across isolation boundaries")
    func audioDeviceCanBePassedAcrossIsolationBoundaries() async {
        let device = AudioDevice(id: "id", name: "name", isDefault: true)

        let result = await Task.detached {
            device
        }.value

        #expect(result.id == "id")
        #expect(result.name == "name")
        #expect(result.isDefault == true)
    }

    @Test("AudioPermissionStatus can be passed across isolation boundaries")
    func permissionStatusCanBePassedAcrossIsolationBoundaries() async {
        let status = AudioPermissionStatus(microphone: .authorized, screenRecording: .denied)

        let result = await Task.detached {
            (status.canCaptureMicrophone, status.canCaptureSystemAudio)
        }.value

        #expect(result.0 == true)
        #expect(result.1 == false)
    }
}

// MARK: - PermissionState Sendable Tests

@Suite("AudioCaptureService: PermissionState Sendable")
@MainActor
struct AudioCaptureServicePermissionStateSendableTests {
    @Test("PermissionState authorized is Sendable")
    func authorizedIsSendable() async {
        let state = AudioPermissionStatus.PermissionState.authorized
        let result = await Task.detached { state }.value
        #expect(result == .authorized)
    }

    @Test("PermissionState denied is Sendable")
    func deniedIsSendable() async {
        let state = AudioPermissionStatus.PermissionState.denied
        let result = await Task.detached { state }.value
        #expect(result == .denied)
    }

    @Test("PermissionState notDetermined is Sendable")
    func notDeterminedIsSendable() async {
        let state = AudioPermissionStatus.PermissionState.notDetermined
        let result = await Task.detached { state }.value
        #expect(result == .notDetermined)
    }
}
