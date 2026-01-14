//
//  SettingsView.swift
//  Votra
//
//  Main settings view container with tabs for different settings categories.
//

import AppKit
import SwiftUI

/// Main settings view with tabbed navigation
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "General"), systemImage: "gear", value: .general) {
                GeneralSettingsView()
                    .accessibilityIdentifier("settings_general_content")
            }

            Tab(String(localized: "Audio"), systemImage: "speaker.wave.2", value: .audio) {
                AudioSettingsView()
                    .accessibilityIdentifier("settings_audio_content")
            }

            Tab(String(localized: "Languages"), systemImage: "globe", value: .languages) {
                LanguageSettingsView()
                    .accessibilityIdentifier("settings_languages_content")
            }

            Tab(String(localized: "Privacy"), systemImage: "lock.shield", value: .privacy) {
                PrivacySettingsView()
                    .accessibilityIdentifier("settings_privacy_content")
            }
        }
        .frame(width: 500, height: 400)
        .accessibilityIdentifier("settingsView")
    }
}

// MARK: - Settings Tab

enum SettingsTab: Hashable {
    case general
    case audio
    case languages
    case privacy
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section(String(localized: "Appearance")) {
                let opacity = Binding(
                    get: { UserPreferences.shared.floatingWindowOpacity },
                    set: { UserPreferences.shared.floatingWindowOpacity = $0 }
                )
                Slider(
                    value: opacity,
                    in: 0.3...1.0,
                    step: 0.1
                ) {
                    Text(String(localized: "Window Opacity"))
                } minimumValueLabel: {
                    Text("30%")
                } maximumValueLabel: {
                    Text("100%")
                }
            }

            Section(String(localized: "Translation")) {
                let autoSpeak = Binding(
                    get: { UserPreferences.shared.autoSpeak },
                    set: { UserPreferences.shared.autoSpeak = $0 }
                )
                Toggle(String(localized: "Auto-speak Translations"), isOn: autoSpeak)
            }

            Section(String(localized: "Speech")) {
                let speechRate = Binding(
                    get: { Double(UserPreferences.shared.speechRate) },
                    set: { UserPreferences.shared.speechRate = Float($0) }
                )
                Slider(
                    value: speechRate,
                    in: 0.1...1.0,
                    step: 0.1
                ) {
                    Text(String(localized: "Speech Rate"))
                } minimumValueLabel: {
                    Text(String(localized: "Slow"))
                } maximumValueLabel: {
                    Text(String(localized: "Fast"))
                }

                let usePersonalVoice = Binding(
                    get: { UserPreferences.shared.usePersonalVoice },
                    set: { UserPreferences.shared.usePersonalVoice = $0 }
                )
                Toggle(String(localized: "Use Personal Voice"), isOn: usePersonalVoice)
                    .help(String(localized: "Use your Personal Voice for speech synthesis when available"))
            }

        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "General"))
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section(String(localized: "Data Storage")) {
                let iCloudSync = Binding(
                    get: { UserPreferences.shared.iCloudSyncEnabled },
                    set: { UserPreferences.shared.iCloudSyncEnabled = $0 }
                )
                Toggle(String(localized: "Sync with iCloud"), isOn: iCloudSync)
                    .help(String(localized: "Sync recordings and sessions across your devices"))

                Text(String(localized: "All data is stored locally on your device. Enable iCloud sync to access your recordings on other devices."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Crash Reporting")) {
                let crashReporting = Binding(
                    get: { UserPreferences.shared.crashReportingEnabled },
                    set: { UserPreferences.shared.crashReportingEnabled = $0 }
                )
                Toggle(String(localized: "Send Crash Reports"), isOn: crashReporting)
                    .help(String(localized: "Help improve Votra by sending anonymous crash reports"))

                Text(String(localized: "Crash reports never include conversation content, audio recordings, or personal information."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Permissions")) {
                PermissionStatusRow(
                    title: String(localized: "Microphone"),
                    systemImage: "mic",
                    status: .authorized
                )

                PermissionStatusRow(
                    title: String(localized: "Screen Recording"),
                    systemImage: "rectangle.on.rectangle",
                    status: .authorized
                )

                PermissionStatusRow(
                    title: String(localized: "Speech Recognition"),
                    systemImage: "waveform",
                    status: .authorized
                )

                Button(String(localized: "Open System Settings")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "Privacy"))
    }
}

// MARK: - Permission Status Row

struct PermissionStatusRow: View {
    let title: String
    let systemImage: String
    let status: PermissionStatus

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            statusBadge
        }
    }

    @ViewBuilder private var statusBadge: some View {
        switch status {
        case .authorized:
            Label(String(localized: "Granted"), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .denied:
            Label(String(localized: "Denied"), systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        case .notDetermined:
            Label(String(localized: "Not Set"), systemImage: "questionmark.circle")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}
