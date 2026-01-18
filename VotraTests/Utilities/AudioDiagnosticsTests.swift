//
//  AudioDiagnosticsTests.swift
//  VotraTests
//
//  Tests for AudioDiagnostics utility for checking audio capture capabilities.
//

import Foundation
import Testing
@testable import Votra

@Suite("Audio Diagnostic Result Tests")
@MainActor
struct AudioDiagnosticResultTests {

    // MARK: - Description Tests

    @Test("Description includes all sections")
    func descriptionContainsAllSections() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Authorized",
            screenRecordingPermission: "Authorized",
            availableMicrophones: ["Built-in Microphone"],
            defaultMicrophone: "Built-in Microphone",
            availableDisplays: 1,
            availableApps: 10,
            macOSVersion: "15.0.0",
            errors: []
        )

        let description = result.description

        #expect(description.contains("=== Votra Audio Diagnostics ==="))
        #expect(description.contains("macOS Version: 15.0.0"))
        #expect(description.contains("Microphone: Authorized"))
        #expect(description.contains("Screen Recording: Authorized"))
        #expect(description.contains("Default: Built-in Microphone"))
        #expect(description.contains("Available: Built-in Microphone"))
        #expect(description.contains("Displays: 1"))
        #expect(description.contains("Applications: 10"))
        #expect(description.contains("Errors: None"))
    }

    @Test("Description handles nil default microphone")
    func descriptionWithNilDefaultMicrophone() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Authorized",
            screenRecordingPermission: "Authorized",
            availableMicrophones: [],
            defaultMicrophone: nil,
            availableDisplays: 1,
            availableApps: 5,
            macOSVersion: "15.0.0",
            errors: []
        )

        let description = result.description

        #expect(description.contains("Default: None"))
    }

    @Test("Description handles empty microphones list")
    func descriptionWithEmptyMicrophonesList() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Authorized",
            screenRecordingPermission: "Authorized",
            availableMicrophones: [],
            defaultMicrophone: nil,
            availableDisplays: 1,
            availableApps: 5,
            macOSVersion: "15.0.0",
            errors: []
        )

        let description = result.description

        #expect(description.contains("Available: None"))
    }

    @Test("Description handles multiple microphones")
    func descriptionWithMultipleMicrophones() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Authorized",
            screenRecordingPermission: "Authorized",
            availableMicrophones: ["Built-in Microphone", "External USB Mic", "AirPods Pro"],
            defaultMicrophone: "Built-in Microphone",
            availableDisplays: 2,
            availableApps: 15,
            macOSVersion: "15.0.0",
            errors: []
        )

        let description = result.description

        #expect(description.contains("Built-in Microphone, External USB Mic, AirPods Pro"))
    }

    @Test("Description handles errors list")
    func descriptionWithErrors() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Denied",
            screenRecordingPermission: "Denied",
            availableMicrophones: [],
            defaultMicrophone: nil,
            availableDisplays: 0,
            availableApps: 0,
            macOSVersion: "15.0.0",
            errors: ["Error 1", "Error 2"]
        )

        let description = result.description

        #expect(description.contains("Error 1"))
        #expect(description.contains("Error 2"))
        #expect(!description.contains("Errors: None"))
    }

    @Test("Description handles single error")
    func descriptionWithSingleError() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Denied",
            screenRecordingPermission: "Denied",
            availableMicrophones: [],
            defaultMicrophone: nil,
            availableDisplays: 0,
            availableApps: 0,
            macOSVersion: "15.0.0",
            errors: ["AVAudioEngine: Invalid input format"]
        )

        let description = result.description

        #expect(description.contains("AVAudioEngine: Invalid input format"))
    }

    // MARK: - Property Tests

    @Test("All properties are stored correctly")
    func allPropertiesStoredCorrectly() {
        let result = AudioDiagnosticResult(
            microphonePermission: "Test Permission",
            screenRecordingPermission: "Test Screen",
            availableMicrophones: ["Mic1", "Mic2"],
            defaultMicrophone: "Mic1",
            availableDisplays: 3,
            availableApps: 20,
            macOSVersion: "14.5.0",
            errors: ["Test Error"]
        )

        #expect(result.microphonePermission == "Test Permission")
        #expect(result.screenRecordingPermission == "Test Screen")
        #expect(result.availableMicrophones == ["Mic1", "Mic2"])
        #expect(result.defaultMicrophone == "Mic1")
        #expect(result.availableDisplays == 3)
        #expect(result.availableApps == 20)
        #expect(result.macOSVersion == "14.5.0")
        #expect(result.errors == ["Test Error"])
    }
}

@Suite("Audio Diagnostics Tests")
@MainActor
struct AudioDiagnosticsTests {

    // MARK: - runDiagnostics Tests

    @Test("runDiagnostics returns valid result", .disabled("Queries hardware - run locally"))
    func runDiagnosticsReturnsValidResult() async {
        let result = await AudioDiagnostics.runDiagnostics()

        // Verify macOS version is populated
        #expect(!result.macOSVersion.isEmpty)

        // Verify permission strings are populated
        #expect(!result.microphonePermission.isEmpty)
        #expect(!result.screenRecordingPermission.isEmpty)

        // Verify counts are non-negative
        #expect(result.availableDisplays >= 0)
        #expect(result.availableApps >= 0)
    }

    @Test("runDiagnostics macOS version format is correct", .disabled("Queries hardware - run locally"))
    func runDiagnosticsMacOSVersionFormat() async {
        let result = await AudioDiagnostics.runDiagnostics()

        // macOS version should be in format "X.Y.Z"
        let components = result.macOSVersion.split(separator: ".")
        #expect(components.count == 3, "macOS version should have 3 components separated by dots")

        // Each component should be a valid number
        for component in components {
            #expect(Int(component) != nil, "Each version component should be a number")
        }
    }

    @Test("runDiagnostics microphone permission is valid status", .disabled("Queries hardware - run locally"))
    func runDiagnosticsMicrophonePermissionStatus() async {
        let result = await AudioDiagnostics.runDiagnostics()

        let validStatuses = [
            "Authorized",
            "Denied",
            "Restricted",
            "Not Determined",
            "Unknown"
        ]

        let containsValidStatus = validStatuses.contains { result.microphonePermission.contains($0) }
        #expect(containsValidStatus, "Microphone permission should contain a valid status")
    }

    @Test("runDiagnostics screen recording permission is valid", .disabled("Queries hardware - run locally"))
    func runDiagnosticsScreenRecordingPermissionStatus() async {
        let result = await AudioDiagnostics.runDiagnostics()

        let validStatuses = [
            "Authorized",
            "Denied or Not Determined"
        ]

        let containsValidStatus = validStatuses.contains { result.screenRecordingPermission.contains($0) }
        #expect(containsValidStatus, "Screen recording permission should contain a valid status")
    }

    // MARK: - printDiagnostics Tests

    @Test("printDiagnostics completes without error", .disabled("Queries hardware - run locally"))
    func printDiagnosticsCompletes() async {
        // This test verifies printDiagnostics runs without throwing
        await AudioDiagnostics.printDiagnostics()

        // If we reach here, the method completed successfully
        #expect(Bool(true))
    }
}
