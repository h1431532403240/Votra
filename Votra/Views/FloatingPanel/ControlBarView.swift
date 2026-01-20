//
//  ControlBarView.swift
//  Votra
//
//  Control bar for language selection, recording controls, and auto-speak toggle.
//

import SwiftUI

/// Control bar displayed at the bottom of the floating panel
struct ControlBarView: View {
    @Binding var sourceLocale: Locale
    @Binding var targetLocale: Locale
    @Binding var autoSpeak: Bool
    @Binding var isRecording: Bool
    @Binding var audioInputMode: AudioInputMode

    let availableSourceLanguages: [Locale]
    let availableTargetLanguages: [Locale]
    let isTranslating: Bool
    let isOffline: Bool

    let onStartStop: () -> Void
    let onSwapLanguages: () -> Void
    let onRecordToggle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Language selection row
            HStack(spacing: 12) {
                // Source language picker
                LanguagePicker(
                    label: String(localized: "From"),
                    selection: $sourceLocale,
                    languages: availableSourceLanguages
                )

                // Swap button
                Button {
                    onSwapLanguages()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                }
                .buttonStyle(GlassButtonStyle())
                .help(String(localized: "Swap languages"))

                // Target language picker
                LanguagePicker(
                    label: String(localized: "To"),
                    selection: $targetLocale,
                    languages: availableTargetLanguages
                )
            }

            Divider()

            // Audio input mode selector
            HStack(spacing: 8) {
                Text(String(localized: "Mode"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("", selection: $audioInputMode) {
                    ForEach(AudioInputMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            Divider()

            // Controls row
            HStack(spacing: 16) {
                // Auto-speak toggle
                Toggle(isOn: $autoSpeak) {
                    Label(String(localized: "Auto-speak"), systemImage: "speaker.wave.2")
                        .font(.caption)
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                // Recording button (only show when microphone is enabled)
                if audioInputMode != .systemAudioOnly {
                    Button {
                        onRecordToggle()
                    } label: {
                        Label(
                            isRecording ? String(localized: "Stop") : String(localized: "Record"),
                            systemImage: isRecording ? "stop.circle.fill" : "record.circle"
                        )
                        .foregroundStyle(isRecording ? .red : .primary)
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                // Start/Stop translation button
                Button {
                    onStartStop()
                } label: {
                    Label(
                        isTranslating ? String(localized: "Stop") : String(localized: "Start"),
                        systemImage: isTranslating ? "stop.fill" : "play.fill"
                    )
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
            }

            // Status indicators
            HStack {
                // Offline indicator
                if isOffline {
                    Label(String(localized: "Offline"), systemImage: "wifi.slash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Translation status
                if isTranslating {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text(String(localized: "Listening..."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Language Picker

/// Picker for selecting a language
struct LanguagePicker: View {
    let label: String
    @Binding var selection: Locale
    let languages: [Locale]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(label, selection: $selection) {
                ForEach(languages, id: \.identifier) { locale in
                    Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                        .tag(locale)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
        }
    }
}

// MARK: - Compact Control Bar

/// Compact version of control bar for minimized view
struct CompactControlBarView: View {
    @Binding var isTranslating: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(isTranslating ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(isTranslating ? String(localized: "Translating") : String(localized: "Paused"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle button
            Button {
                onToggle()
            } label: {
                Image(systemName: isTranslating ? "pause.fill" : "play.fill")
            }
            .buttonStyle(GlassButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .glassCard(padding: 8)
    }
}

// MARK: - Preview

#Preview("Control Bar") {
    ControlBarView(
        sourceLocale: .constant(Locale(identifier: "en")),
        targetLocale: .constant(Locale(identifier: "zh-Hans")),
        autoSpeak: .constant(false),
        isRecording: .constant(false),
        audioInputMode: .constant(.systemAudioOnly),
        availableSourceLanguages: [
            Locale(identifier: "en"),
            Locale(identifier: "zh-Hans"),
            Locale(identifier: "ja"),
            Locale(identifier: "ko")
        ],
        availableTargetLanguages: [
            Locale(identifier: "en"),
            Locale(identifier: "zh-Hans"),
            Locale(identifier: "ja"),
            Locale(identifier: "ko")
        ],
        isTranslating: true,
        isOffline: false,
        onStartStop: {},
        onSwapLanguages: {},
        onRecordToggle: {}
    )
    .frame(width: 400)
    .padding()
}
