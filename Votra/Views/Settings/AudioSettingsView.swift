//
//  AudioSettingsView.swift
//  Votra
//
//  Settings view for audio configuration including microphone selection.
//

import SwiftUI

/// View for configuring audio settings
struct AudioSettingsView: View {
    @State private var audioService = AudioCaptureService()
    @State private var selectedMicrophoneID: String?
    @State private var isLoading = true

    var body: some View {
        Form {
            Section(String(localized: "Input Device")) {
                if isLoading {
                    ProgressView()
                } else if audioService.availableMicrophones.isEmpty {
                    Text(String(localized: "No microphones available"))
                        .foregroundStyle(.secondary)
                } else {
                    Picker(String(localized: "Microphone"), selection: $selectedMicrophoneID) {
                        ForEach(audioService.availableMicrophones, id: \.id) { device in
                            HStack {
                                Image(systemName: device.isDefault ? "mic.fill" : "mic")
                                Text(device.name)
                                if device.isDefault {
                                    Text(String(localized: "(Default)"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(device.id as String?)
                        }
                    }
                    .onChange(of: selectedMicrophoneID) { _, newValue in
                        if let id = newValue {
                            selectMicrophone(id: id)
                        }
                    }
                }

                Button(String(localized: "Refresh Devices")) {
                    Task {
                        await loadDevices()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }

            Section(String(localized: "Audio Sources")) {
                HStack {
                    Label(String(localized: "Microphone"), systemImage: "mic")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                HStack {
                    Label(String(localized: "System Audio"), systemImage: "speaker.wave.2")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Text(String(localized: "Both microphone and system audio are captured simultaneously for comprehensive translation."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Audio Quality")) {
                HStack {
                    Text(String(localized: "Sample Rate"))
                    Spacer()
                    Text("48 kHz")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(String(localized: "Format"))
                    Spacer()
                    Text("32-bit Float")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "Audio"))
        .task {
            await loadDevices()
        }
    }

    private func loadDevices() async {
        isLoading = true
        // Load microphones - must call ensureMicrophonesLoaded first
        await audioService.ensureMicrophonesLoaded()
        selectedMicrophoneID = audioService.availableMicrophones.first { $0.isDefault }?.id
            ?? audioService.availableMicrophones.first?.id
        isLoading = false
    }

    private func selectMicrophone(id: String) {
        Task {
            guard let device = audioService.availableMicrophones.first(where: { $0.id == id }) else { return }
            do {
                try await audioService.selectMicrophone(device)
            } catch {
                print("Failed to select microphone: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview("Audio Settings") {
    AudioSettingsView()
}
