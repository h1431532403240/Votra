//
//  AudioDiagnostics.swift
//  Votra
//
//  Diagnostic utility to check audio capture capabilities and permissions.
//

import AVFoundation
import Foundation
import ScreenCaptureKit

/// Diagnostic results for audio capture capabilities
struct AudioDiagnosticResult: CustomStringConvertible {
    let microphonePermission: String
    let screenRecordingPermission: String
    let availableMicrophones: [String]
    let defaultMicrophone: String?
    let availableDisplays: Int
    let availableApps: Int
    let macOSVersion: String
    let errors: [String]

    var description: String {
        """
        === Votra Audio Diagnostics ===
        macOS Version: \(macOSVersion)

        Permissions:
          - Microphone: \(microphonePermission)
          - Screen Recording: \(screenRecordingPermission)

        Microphones:
          - Default: \(defaultMicrophone ?? "None")
          - Available: \(availableMicrophones.isEmpty ? "None" : availableMicrophones.joined(separator: ", "))

        ScreenCaptureKit:
          - Displays: \(availableDisplays)
          - Applications: \(availableApps)

        Errors: \(errors.isEmpty ? "None" : "\n  - " + errors.joined(separator: "\n  - "))
        ================================
        """
    }
}

/// Utility for diagnosing audio capture issues
enum AudioDiagnostics {
    /// Run full diagnostics and return results
    static func runDiagnostics() async -> AudioDiagnosticResult {
        var errors: [String] = []

        // Check macOS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let macOSVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"

        // Check microphone permission
        let micPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let micPermissionStr: String
        switch micPermission {
        case .authorized: micPermissionStr = "✅ Authorized"
        case .denied: micPermissionStr = "❌ Denied"
        case .restricted: micPermissionStr = "⚠️ Restricted"
        case .notDetermined: micPermissionStr = "⏳ Not Determined"
        @unknown default: micPermissionStr = "❓ Unknown"
        }

        // Check screen recording permission
        let screenPermission = CGPreflightScreenCaptureAccess()
        let screenPermissionStr = screenPermission ? "✅ Authorized" : "❌ Denied or Not Determined"

        // Get available microphones
        let microphoneDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        ).devices

        let microphoneNames = microphoneDevices.map { $0.localizedName }
        let defaultMic = AVCaptureDevice.default(for: .audio)?.localizedName

        // Test AVAudioEngine initialization
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        if format.channelCount == 0 || format.sampleRate == 0 {
            errors.append("AVAudioEngine: Invalid input format (channels: \(format.channelCount), sampleRate: \(format.sampleRate))")
        } else {
            print("[Votra] AVAudioEngine input format: \(format.sampleRate)Hz, \(format.channelCount) channels")
        }

        // Check ScreenCaptureKit availability
        var displayCount = 0
        var appCount = 0

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            displayCount = content.displays.count
            appCount = content.applications.count

            if displayCount == 0 {
                errors.append("ScreenCaptureKit: No displays available")
            }
        } catch {
            errors.append("ScreenCaptureKit: \(error.localizedDescription)")
        }

        return AudioDiagnosticResult(
            microphonePermission: micPermissionStr,
            screenRecordingPermission: screenPermissionStr,
            availableMicrophones: microphoneNames,
            defaultMicrophone: defaultMic,
            availableDisplays: displayCount,
            availableApps: appCount,
            macOSVersion: macOSVersion,
            errors: errors
        )
    }

    /// Print diagnostics to console
    static func printDiagnostics() async {
        let result = await runDiagnostics()
        print(result)
    }
}
