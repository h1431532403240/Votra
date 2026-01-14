//
//  PermissionGuidanceView.swift
//  Votra
//
//  View showing clear instructions to enable permissions in System Settings.
//

import AppKit
import SwiftUI

/// Type of permission being requested
enum PermissionType {
    case microphone
    case screenRecording
    case speechRecognition

    var title: String {
        switch self {
        case .microphone:
            return String(localized: "Microphone Access Required")
        case .screenRecording:
            return String(localized: "Screen Recording Access Required")
        case .speechRecognition:
            return String(localized: "Speech Recognition Access Required")
        }
    }

    var description: String {
        switch self {
        case .microphone:
            return String(localized: "Votra needs microphone access to capture your voice for translation.")
        case .screenRecording:
            return String(localized: "Votra needs screen recording access to capture system audio from other applications.")
        case .speechRecognition:
            return String(localized: "Votra needs speech recognition access to convert speech to text.")
        }
    }

    var systemImage: String {
        switch self {
        case .microphone:
            return "mic.fill"
        case .screenRecording:
            return "rectangle.on.rectangle"
        case .speechRecognition:
            return "waveform"
        }
    }

    var systemSettingsURL: URL? {
        switch self {
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        case .screenRecording:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        case .speechRecognition:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
        }
    }

    var steps: [String] {
        switch self {
        case .microphone:
            return [
                String(localized: "Open System Settings"),
                String(localized: "Go to Privacy & Security > Microphone"),
                String(localized: "Find Votra in the list and enable access"),
                String(localized: "You may need to restart Votra")
            ]
        case .screenRecording:
            return [
                String(localized: "Open System Settings"),
                String(localized: "Go to Privacy & Security > Screen Recording"),
                String(localized: "If Votra is already listed, remove it (−) then re-add it (+)"),
                String(localized: "Click the + button to add Votra if not listed"),
                String(localized: "Restart Votra after enabling")
            ]
        case .speechRecognition:
            return [
                String(localized: "Open System Settings"),
                String(localized: "Go to Privacy & Security > Speech Recognition"),
                String(localized: "Find Votra in the list and enable access"),
                String(localized: "You may need to restart Votra")
            ]
        }
    }
}

/// View showing guidance for enabling permissions
struct PermissionGuidanceView: View {
    let permissionType: PermissionType
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: permissionType.systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            // Title
            Text(permissionType.title)
                .font(.title2)
                .bold()

            // Description
            Text(permissionType.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "How to enable:"))
                    .font(.headline)

                ForEach(permissionType.steps.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        Text(permissionType.steps[index])
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))

            // Actions
            HStack(spacing: 16) {
                Button(String(localized: "Open System Settings")) {
                    openSystemSettings()
                }
                .buttonStyle(.borderedProminent)

                Button(String(localized: "Done")) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func openSystemSettings() {
        if let url = permissionType.systemSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Microphone Permission") {
    PermissionGuidanceView(permissionType: .microphone) {}
}

#Preview("Screen Recording Permission") {
    PermissionGuidanceView(permissionType: .screenRecording) {}
}

#Preview("Speech Recognition Permission") {
    PermissionGuidanceView(permissionType: .speechRecognition) {}
}
