//
//  RecordingListView.swift
//  Votra
//
//  List view for displaying saved recordings.
//

import SwiftUI
import SwiftData

/// View displaying a list of saved recordings
struct RecordingListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var viewModel: RecordingViewModel
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var recordingToDelete: Recording?

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
        List(selection: $viewModel.selectedRecording) {
            if filteredRecordings.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredRecordings) { recording in
                    RecordingRowView(recording: recording)
                        .tag(recording)
                        .contextMenu {
                            contextMenuItems(for: recording)
                        }
                }
                .onDelete(perform: deleteRecordings)
            }
        }
        .searchable(text: $searchText, prompt: String(localized: "Search recordings"))
        .navigationTitle(String(localized: "Recordings"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                recordingButton
            }
        }
        .confirmationDialog(
            String(localized: "Delete Recording?"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let recording = recordingToDelete {
                    viewModel.deleteRecording(recording)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This action cannot be undone."))
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    // MARK: - Empty State

    @ViewBuilder private var emptyStateView: some View {
        ContentUnavailableView {
            Label(String(localized: "No Recordings"), systemImage: "waveform")
        } description: {
            Text(String(localized: "Start a recording during a translation session to save it here."))
        }
    }

    // MARK: - Recording Button

    @ViewBuilder private var recordingButton: some View {
        if viewModel.isRecording {
            Button {
                Task {
                    await viewModel.stopRecording()
                }
            } label: {
                Label(String(localized: "Stop"), systemImage: "stop.fill")
                    .foregroundStyle(.red)
            }
        } else {
            Button {
                Task {
                    await viewModel.startRecording()
                }
            } label: {
                Label(String(localized: "Record"), systemImage: "record.circle")
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for recording: Recording) -> some View {
        Button {
            viewModel.selectedRecording = recording
        } label: {
            Label(String(localized: "View Details"), systemImage: "info.circle")
        }

        Divider()

        Button {
            Task {
                if let url = try? await viewModel.exportAudio(recording) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        } label: {
            Label(String(localized: "Export Audio"), systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: .destructive) {
            recordingToDelete = recording
            showingDeleteConfirmation = true
        } label: {
            Label(String(localized: "Delete"), systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = filteredRecordings[index]
            viewModel.deleteRecording(recording)
        }
    }
}

// MARK: - Recording Row View

/// Row view for a single recording in the list
struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            // Recording info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.originalFileName.isEmpty ?
                     String(localized: "Recording \(recording.id.uuidString.prefix(8))") :
                     recording.originalFileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Duration
                    Label(recording.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // File size
                    Label(recording.formattedFileSize, systemImage: "doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Format
                    Text(recording.format.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .clipShape(.capsule)
                }
            }

            Spacer()

            // Date
            Text(recording.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Recording List") {
    RecordingListView(viewModel: RecordingViewModel())
        .frame(width: 400, height: 500)
}
