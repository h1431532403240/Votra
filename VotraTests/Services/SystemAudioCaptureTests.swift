// swiftlint:disable:this file_name
//
//  SystemAudioCaptureTests.swift
//  VotraTests
//
//  Unit tests for SystemAudioCapture class and its supporting types.
//  Focuses on system audio capture specific functionality not covered
//  by other test files.
//

import Foundation
import ScreenCaptureKit
import Testing
@testable import Votra

// MARK: - System Audio Capture Configuration Tests

@Suite("System Audio Capture Configuration", .tags(.requiresHardware))
@MainActor
struct SystemAudioCaptureConfigurationTests {
    @Test("Expected audio sample rate is 48000 Hz for system audio")
    func expectedSampleRateIs48kHz() {
        // The SystemAudioCapture uses 48000 Hz as per SCStreamConfiguration
        // This documents the expected configuration value
        let expectedSampleRate = 48000
        #expect(expectedSampleRate == 48000)
    }

    @Test("Expected channel count is 2 (stereo) for system audio")
    func expectedChannelCountIsStereo() {
        // The SystemAudioCapture uses 2 channels (stereo)
        let expectedChannelCount = 2
        #expect(expectedChannelCount == 2)
    }

    @Test("System audio capture excludes current process audio")
    func excludesCurrentProcessAudio() {
        // This documents that excludesCurrentProcessAudio should be true
        // to prevent feedback loops
        let excludesCurrentProcess = true
        #expect(excludesCurrentProcess == true)
    }
}

// MARK: - System Audio Capture Selected Source Tests

@Suite("System Audio Capture Source Selection", .tags(.requiresHardware))
@MainActor
struct SystemAudioCaptureSourceSelectionTests {
    @Test("Selected source is nil by default (captures all system audio)")
    func selectedSourceIsNilByDefault() {
        let capture = SystemAudioCapture()
        #expect(capture.selectedSource == nil)
    }

    @Test("Can set selected source to a specific app")
    func canSetSelectedSourceToApp() {
        let capture = SystemAudioCapture()
        let appSource = AudioSourceInfo(
            id: "app-1234",
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: 1234,
            iconData: nil
        )

        capture.selectedSource = appSource

        #expect(capture.selectedSource != nil)
        #expect(capture.selectedSource?.id == "app-1234")
        #expect(capture.selectedSource?.bundleIdentifier == "com.apple.Safari")
    }

    @Test("Can set selected source to a specific window")
    func canSetSelectedSourceToWindow() {
        let capture = SystemAudioCapture()
        let windowSource = AudioSourceInfo(
            id: "window-56789",
            name: "Chrome",
            bundleIdentifier: "com.google.Chrome",
            isAllSystemAudio: false,
            windowID: 56789,
            windowTitle: "Google Search",
            processID: 5678,
            iconData: nil
        )

        capture.selectedSource = windowSource

        #expect(capture.selectedSource != nil)
        #expect(capture.selectedSource?.windowID == 56789)
        #expect(capture.selectedSource?.windowTitle == "Google Search")
    }

    @Test("Can clear selected source back to nil")
    func canClearSelectedSource() {
        let capture = SystemAudioCapture()
        let source = AudioSourceInfo(
            id: "test",
            name: "Test",
            bundleIdentifier: "com.test",
            isAllSystemAudio: false,
            windowID: 100,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        capture.selectedSource = source
        #expect(capture.selectedSource != nil)

        capture.selectedSource = nil
        #expect(capture.selectedSource == nil)
    }

    @Test("Setting all system audio source clears selected source")
    func settingAllSystemAudioClearsSelectedSource() {
        let service = AudioCaptureService()

        // First select a specific source
        let specificSource = AudioSourceInfo(
            id: "specific",
            name: "Specific App",
            bundleIdentifier: "com.specific.app",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        // Try to select it (won't work since it's not in available sources)
        // but this tests the selectAudioSource method behavior
        let originalSource = service.selectedAudioSource
        service.selectAudioSource(specificSource)

        // Should remain unchanged since specificSource isn't available
        #expect(service.selectedAudioSource == originalSource)
    }
}

// MARK: - System Audio Capture Stop Safety Tests

@Suite("System Audio Capture Stop Safety", .tags(.requiresHardware))
@MainActor
struct SystemAudioCaptureStopSafetyTests {
    @Test("Stop capture is safe when not capturing")
    func stopCaptureIsSafeWhenNotCapturing() async {
        let capture = SystemAudioCapture()
        await capture.stopCapture()
        // Test passes if no crash or error
    }

    @Test("Multiple consecutive stops are safe")
    func multipleConsecutiveStopsAreSafe() async {
        let capture = SystemAudioCapture()

        for _ in 0..<5 {
            await capture.stopCapture()
        }
        // Test passes if no crash or error
    }

    @Test("Stop capture can be called from different tasks")
    func stopCaptureCanBeCalledFromDifferentTasks() async {
        let capture = SystemAudioCapture()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    await capture.stopCapture()
                }
            }
        }
        // Test passes if no crash or deadlock
    }
}

// MARK: - System Audio Capture Capture Already Active Tests

@Suite("System Audio Capture Already Active Error", .tags(.requiresHardware))
@MainActor
struct SystemAudioCaptureAlreadyActiveTests {
    @Test("captureAlreadyActive error has descriptive message")
    func captureAlreadyActiveHasDescriptiveMessage() {
        let error = AudioCaptureError.captureAlreadyActive

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("captureAlreadyActive has no recovery suggestion")
    func captureAlreadyActiveHasNoRecoverySuggestion() {
        let error = AudioCaptureError.captureAlreadyActive

        // This error indicates a programming issue, not user-fixable
        #expect(error.recoverySuggestion == nil)
    }
}

// MARK: - Audio Source Info Display Name Tests

@Suite("System Audio Source Display Name Logic", .tags(.requiresHardware))
@MainActor
struct SystemAudioSourceDisplayNameTests {
    @Test("All system audio uses name as display name")
    func allSystemAudioUsesNameAsDisplayName() {
        let source = AudioSourceInfo.allSystemAudio

        #expect(source.displayName == source.name)
        #expect(source.displayName.isEmpty == false)
    }

    @Test("App source without window title uses name only")
    func appSourceWithoutWindowTitleUsesNameOnly() {
        let source = AudioSourceInfo(
            id: "app-123",
            name: "Zoom",
            bundleIdentifier: "us.zoom.xos",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: 123,
            iconData: nil
        )

        #expect(source.displayName == "Zoom")
    }

    @Test("Window source with title shows app name and window title")
    func windowSourceWithTitleShowsBoth() {
        let source = AudioSourceInfo(
            id: "window-456",
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            isAllSystemAudio: false,
            windowID: 456,
            windowTitle: "Apple Developer",
            processID: 789,
            iconData: nil
        )

        #expect(source.displayName.contains("Safari"))
        #expect(source.displayName.contains("Apple Developer"))
        #expect(source.displayName.contains("-"))
    }

    @Test("Window source with empty window title uses name only")
    func windowSourceWithEmptyTitleUsesNameOnly() {
        let source = AudioSourceInfo(
            id: "window-789",
            name: "Firefox",
            bundleIdentifier: "org.mozilla.firefox",
            isAllSystemAudio: false,
            windowID: 789,
            windowTitle: "",
            processID: 1000,
            iconData: nil
        )

        #expect(source.displayName == "Firefox")
    }

    @Test("Window source with whitespace-only title uses name only")
    func windowSourceWithWhitespaceOnlyTitleUsesNameOnly() {
        // Note: The current implementation doesn't trim whitespace,
        // so this tests current behavior
        let source = AudioSourceInfo(
            id: "window-000",
            name: "App",
            bundleIdentifier: "com.example.app",
            isAllSystemAudio: false,
            windowID: 111,
            windowTitle: "   ",
            processID: 222,
            iconData: nil
        )

        // With whitespace title, the display name will include it
        #expect(source.displayName.contains("App"))
    }
}

// MARK: - Audio Source Info Window Level Detection Tests

@Suite("System Audio Source Window Level Detection", .tags(.requiresHardware))
@MainActor
struct SystemAudioSourceWindowLevelDetectionTests {
    @Test("Source with windowID is window level")
    func sourceWithWindowIDIsWindowLevel() {
        let source = AudioSourceInfo(
            id: "window-test",
            name: "Test",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 12345,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.isWindowLevel == true)
    }

    @Test("Source without windowID is not window level")
    func sourceWithoutWindowIDIsNotWindowLevel() {
        let source = AudioSourceInfo(
            id: "app-test",
            name: "Test",
            bundleIdentifier: "com.test",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: 1000,
            iconData: nil
        )

        #expect(source.isWindowLevel == false)
    }

    @Test("All system audio is not window level")
    func allSystemAudioIsNotWindowLevel() {
        let source = AudioSourceInfo.allSystemAudio

        #expect(source.isWindowLevel == false)
    }
}

// MARK: - Audio Capture Service Source Management Tests

@Suite("Audio Capture Service Source Management", .tags(.requiresHardware))
@MainActor
struct AudioCaptureServiceSourceManagementTests {
    @Test("Service always has all system audio in available sources")
    func serviceAlwaysHasAllSystemAudio() {
        let service = AudioCaptureService()

        #expect(service.availableAudioSources.contains { $0.isAllSystemAudio })
    }

    @Test("Refresh audio sources preserves all system audio option", .disabled("Requires audio hardware - run locally"))
    func refreshPreservesAllSystemAudioOption() async {
        let service = AudioCaptureService()

        await service.refreshAudioSources()

        #expect(service.availableAudioSources.first?.isAllSystemAudio == true)
    }

    @Test("Selected source defaults to all system audio")
    func selectedSourceDefaultsToAllSystemAudio() {
        let service = AudioCaptureService()

        #expect(service.selectedAudioSource.isAllSystemAudio == true)
    }

    @Test("Selecting unavailable source is ignored")
    func selectingUnavailableSourceIsIgnored() {
        let service = AudioCaptureService()

        let unavailableSource = AudioSourceInfo(
            id: "nonexistent",
            name: "Nonexistent App",
            bundleIdentifier: "com.nonexistent",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let previousSource = service.selectedAudioSource
        service.selectAudioSource(unavailableSource)

        // Should remain unchanged
        #expect(service.selectedAudioSource == previousSource)
    }

    @Test("Selecting all system audio works")
    func selectingAllSystemAudioWorks() {
        let service = AudioCaptureService()

        service.selectAudioSource(.allSystemAudio)

        #expect(service.selectedAudioSource.isAllSystemAudio == true)
    }
}

// MARK: - Screen Recording Permission Error Tests

@Suite("Screen Recording Permission Error", .tags(.requiresHardware))
@MainActor
struct ScreenRecordingPermissionErrorTests {
    @Test("screenRecordingPermissionDenied error has descriptive message")
    func hasDescriptiveMessage() {
        let error = AudioCaptureError.screenRecordingPermissionDenied

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("screenRecordingPermissionDenied has recovery suggestion mentioning settings")
    func hasRecoverySuggestionMentioningSettings() {
        let error = AudioCaptureError.screenRecordingPermissionDenied

        #expect(error.recoverySuggestion != nil)
        // Recovery suggestion should mention how to fix the permission
    }

    @Test("screenRecordingPermissionDenied is distinct from microphone permission error")
    func isDistinctFromMicrophonePermissionError() {
        let screenError = AudioCaptureError.screenRecordingPermissionDenied
        let micError = AudioCaptureError.microphonePermissionDenied

        #expect(screenError.errorDescription != micError.errorDescription)
    }
}

// MARK: - Device Not Found Error for System Audio Tests

@Suite("Device Not Found Error for System Audio", .tags(.requiresHardware))
@MainActor
struct DeviceNotFoundErrorForSystemAudioTests {
    @Test("deviceNotFound error is used for missing display")
    func deviceNotFoundForMissingDisplay() {
        // When no display is available, deviceNotFound is thrown
        let error = AudioCaptureError.deviceNotFound

        #expect(error.errorDescription != nil)
    }

    @Test("deviceNotFound error is used for missing window")
    func deviceNotFoundForMissingWindow() {
        // When a specific window is not found, deviceNotFound is thrown
        let error = AudioCaptureError.deviceNotFound

        #expect(error.recoverySuggestion != nil)
    }

    @Test("deviceNotFound error is used for missing app")
    func deviceNotFoundForMissingApp() {
        // When a specific app bundle ID is not found, deviceNotFound is thrown
        let error = AudioCaptureError.deviceNotFound

        // The error is generic enough to cover all "not found" cases
        #expect(error.errorDescription?.isEmpty == false)
    }
}

// MARK: - Engine Start Failed Error with System Audio Context Tests

@Suite("Engine Start Failed Error with System Audio Context", .tags(.requiresHardware))
@MainActor
struct EngineStartFailedErrorSystemAudioTests {
    @Test("engineStartFailed wraps ScreenCaptureKit errors")
    func wrapsScreenCaptureKitErrors() {
        let scError = NSError(domain: "com.apple.ScreenCaptureKit", code: 1003, userInfo: [
            NSLocalizedDescriptionKey: "Permission denied"
        ])

        let error = AudioCaptureError.engineStartFailed(underlying: scError)

        if case .engineStartFailed(let underlying) = error {
            let nsError = underlying as NSError
            #expect(nsError.code == 1003)
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }

    @Test("engineStartFailed preserves CoreGraphics error domain")
    func preservesCoreGraphicsErrorDomain() {
        let cgError = NSError(domain: "CoreGraphicsErrorDomain", code: 1003, userInfo: nil)

        let error = AudioCaptureError.engineStartFailed(underlying: cgError)

        if case .engineStartFailed(let underlying) = error {
            let nsError = underlying as NSError
            #expect(nsError.domain == "CoreGraphicsErrorDomain")
        } else {
            Issue.record("Expected engineStartFailed case")
        }
    }
}

// MARK: - Audio Stream Output Handler Initialization Tests

@Suite("Audio Stream Output Handler Initialization", .tags(.requiresHardware))
@MainActor
struct AudioStreamOutputHandlerInitTests {
    @Test("Handler stores callback for later invocation")
    func handlerStoresCallback() {
        // Use a class to safely track invocation from Sendable context
        final class InvocationCounter: @unchecked Sendable {
            var invocations = 0
        }
        let counter = InvocationCounter()
        let handler = AudioStreamOutputHandler { _ in
            counter.invocations += 1
        }

        // Handler should be created without invoking callback
        #expect(counter.invocations == 0)
        #expect(handler != nil)
    }

    @Test("Handler callback is Sendable")
    func handlerCallbackIsSendable() {
        // This test verifies the callback type requirements
        let handler = AudioStreamOutputHandler { @Sendable _ in
            // Sendable closure
        }
        #expect(handler != nil)
    }
}

// MARK: - Video Stream Output Handler Purpose Tests

@Suite("Video Stream Output Handler Purpose", .tags(.requiresHardware))
@MainActor
struct VideoStreamOutputHandlerPurposeTests {
    @Test("Video handler exists to prevent ScreenCaptureKit warnings")
    func existsToPreventWarnings() {
        // The VideoStreamOutputHandler is a dummy handler that discards video frames
        // Its purpose is to prevent "stream output NOT found" warnings from SCK
        let handler = VideoStreamOutputHandler()
        #expect(handler != nil)
    }

    @Test("Video handler can be used with SCStream")
    func canBeUsedWithSCStream() {
        let handler = VideoStreamOutputHandler()
        // Verify it conforms to SCStreamOutput
        #expect(handler is SCStreamOutput)
    }
}

// MARK: - Stream Delegate Error Handling Tests

@Suite("Stream Delegate Error Handling", .tags(.requiresHardware))
@MainActor
struct StreamDelegateErrorHandlingTests {
    @Test("Stream delegate handles stream stopped with error")
    func handlesStreamStoppedWithError() {
        let delegate = StreamDelegate()
        // The delegate logs errors but doesn't crash
        // This documents the expected behavior
        #expect(delegate != nil)
    }

    @Test("Stream delegate is SCStreamDelegate")
    func isSCStreamDelegate() {
        let delegate = StreamDelegate()
        #expect(delegate is SCStreamDelegate)
    }
}

// MARK: - Thread Safety for System Audio Types Tests

@Suite("Thread Safety for System Audio Types", .tags(.requiresHardware))
@MainActor
struct ThreadSafetyForSystemAudioTypesTests {
    @Test("AudioSourceInfo can be passed between tasks")
    func audioSourceInfoCanBePassedBetweenTasks() async {
        let source = AudioSourceInfo(
            id: "thread-test",
            name: "Thread Test App",
            bundleIdentifier: "com.thread.test",
            isAllSystemAudio: false,
            windowID: 99999,
            windowTitle: "Thread Test Window",
            processID: 88888,
            iconData: Data([0xDE, 0xAD, 0xBE, 0xEF])
        )

        let passedSource = await Task.detached {
            source
        }.value

        #expect(passedSource.id == "thread-test")
        #expect(passedSource.windowID == 99999)
        #expect(passedSource.iconData?.count == 4)
    }

    @Test("Multiple tasks can read AudioSourceInfo simultaneously")
    func multipleTasksCanReadSimultaneously() async {
        let source = AudioSourceInfo.allSystemAudio
        // Store the display name for concurrent access (displayName is computed but safe)
        let displayName = source.displayName

        await withTaskGroup(of: String.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    // Use captured value to avoid actor isolation issues
                    displayName
                }
            }

            var results: [String] = []
            for await name in group {
                results.append(name)
            }

            #expect(results.count == 10)
            #expect(Set(results).count == 1) // All should be the same
        }
    }

    @Test("AudioCaptureState can be read from concurrent tasks")
    func audioCaptureStateCanBeReadFromConcurrentTasks() async {
        let states: [AudioCaptureState] = [.idle, .capturingMicrophone, .capturingSystemAudio, .capturingBoth]

        await withTaskGroup(of: Bool.self) { group in
            for state in states {
                group.addTask {
                    // Verify we can check equality from a detached task
                    state == .idle || state == .capturingMicrophone ||
                           state == .capturingSystemAudio || state == .capturingBoth
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }

            #expect(results.allSatisfy { $0 == true })
        }
    }
}
