//
//  ContentAreaView.swift
//  Votra
//
//  Detail content area for the main application window.
//

import SwiftUI
import SwiftData

struct ContentAreaView: View {
    let selectedTab: AppTab

    @Environment(TranslationViewModel.self)
    private var translationViewModel

    @Environment(RecordingViewModel.self)
    private var recordingViewModel

    @Environment(\.modelContext)
    private var modelContext

    private let supportedLanguages: [Locale] = [
        Locale(identifier: "en"),
        Locale(identifier: "zh-Hans"),
        Locale(identifier: "zh-Hant"),
        Locale(identifier: "ja"),
        Locale(identifier: "ko"),
        Locale(identifier: "es"),
        Locale(identifier: "fr"),
        Locale(identifier: "de"),
        Locale(identifier: "it"),
        Locale(identifier: "pt")
    ]

    var body: some View {
        switch selectedTab {
        case .translate:
            MainTranslationView()
        case .recordings:
            RecordingsContentView(viewModel: recordingViewModel)
        case .mediaImport:
            MediaImportContentView(availableLanguages: supportedLanguages)
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Recordings Content View

/// Wrapper view for recordings with integrated layout
struct RecordingsContentView: View {
    @Bindable var viewModel: RecordingViewModel
    @Environment(\.modelContext)
    private var modelContext
    @State private var searchText = ""

    private var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return viewModel.recordings
        }
        return viewModel.recordings.filter { recording in
            recording.originalFileName.localizedStandardContains(searchText) ||
            recording.formattedDuration.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        Group {
            if let recording = viewModel.selectedRecording {
                // Detail view
                VStack(spacing: 0) {
                    // Back button header
                    HStack {
                        Button {
                            viewModel.selectedRecording = nil
                        } label: {
                            Label(String(localized: "Back to Recordings"), systemImage: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("recordings_back_button")
                        Spacer()
                    }
                    .padding()

                    Divider()

                    RecordingDetailView(recording: recording, viewModel: viewModel)
                }
                .accessibilityIdentifier("recordings_detail_view")
            } else {
                // List view with integrated search and controls
                VStack(spacing: 0) {
                    // Header with search and record button
                    HStack {
                        // Search field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField(String(localized: "Search recordings"), text: $searchText)
                                .textFieldStyle(.plain)
                                .accessibilityIdentifier("recordings_search_field")
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("recordings_clear_search")
                            }
                        }
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.1))
                        }

                        Spacer()

                        // Record button
                        if viewModel.isRecording {
                            Button {
                                Task {
                                    await viewModel.stopRecording()
                                }
                            } label: {
                                Label(String(localized: "Stop"), systemImage: "stop.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("recordings_stop_button")
                        } else {
                            Button {
                                Task {
                                    await viewModel.startRecording()
                                }
                            } label: {
                                Label(String(localized: "Record"), systemImage: "record.circle")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("recordings_record_button")
                        }
                    }
                    .padding()

                    Divider()

                    // Recording list
                    if filteredRecordings.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "No Recordings"), systemImage: "waveform")
                        } description: {
                            Text(String(localized: "Start a recording during a translation session to save it here."))
                        }
                        .frame(maxHeight: .infinity)
                        .accessibilityIdentifier("recordings_empty_state")
                    } else {
                        List(selection: $viewModel.selectedRecording) {
                            ForEach(filteredRecordings) { recording in
                                RecordingRowView(recording: recording)
                                    .tag(recording)
                            }
                        }
                        .listStyle(.inset)
                        .accessibilityIdentifier("recordings_list")
                    }
                }
                .accessibilityIdentifier("recordings_list_view")
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

// MARK: - Media Import Content View

/// Wrapper view for media import with view model
struct MediaImportContentView: View {
    let availableLanguages: [Locale]
    @State private var mediaImportViewModel = MediaImportViewModel()

    var body: some View {
        MediaImportView(
            viewModel: mediaImportViewModel,
            availableLanguages: availableLanguages
        )
    }
}

#Preview {
    ContentAreaView(selectedTab: .translate)
        .environment(TranslationViewModel())
        .environment(RecordingViewModel())
        .modelContainer(for: [Session.self, Segment.self, Speaker.self, Recording.self, MeetingSummary.self], inMemory: true)
}
