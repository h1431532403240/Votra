//
//  RecoveryDialogView.swift
//  Votra
//
//  Dialog for recovering or discarding incomplete recordings (FR-030).
//

import SwiftUI

/// View for prompting user to recover or discard incomplete recordings
struct RecoveryDialogView: View {
    let incompleteRecordings: [RecordingMetadata]
    @Bindable var viewModel: RecordingViewModel
    @Binding var isPresented: Bool

    @State private var selectedRecordings: Set<UUID> = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                headerView

                // Recording list
                if incompleteRecordings.isEmpty {
                    noRecordingsView
                } else {
                    recordingsList
                }

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Action buttons
                actionButtons
            }
            .padding()
            .frame(minWidth: 400, maxWidth: 500)
            .navigationTitle(String(localized: "Recover Recordings"))
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(String(localized: "Incomplete Recordings Found"))
                .font(.title2)
                .bold()

            Text(String(localized: "The app was closed unexpectedly. Would you like to recover these recordings?"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - No Recordings View

    private var noRecordingsView: some View {
        Text(String(localized: "No incomplete recordings found."))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        List(incompleteRecordings, id: \.id, selection: $selectedRecordings) { metadata in
            RecoveryRowView(metadata: metadata)
                .tag(metadata.id)
        }
        .listStyle(.bordered)
        .frame(minHeight: 150)
        .onAppear {
            // Select all by default
            selectedRecordings = Set(incompleteRecordings.map(\.id))
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Discard all
            Button(role: .destructive) {
                Task {
                    await discardAll()
                }
            } label: {
                Text(String(localized: "Discard All"))
            }
            .disabled(isProcessing)

            Spacer()

            // Cancel
            Button(String(localized: "Cancel")) {
                isPresented = false
            }
            .disabled(isProcessing)

            // Recover selected
            Button {
                Task {
                    await recoverSelected()
                }
            } label: {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(String(localized: "Recover Selected"))
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedRecordings.isEmpty || isProcessing)
        }
    }

    // MARK: - Actions

    private func recoverSelected() async {
        isProcessing = true
        errorMessage = nil

        let toRecover = incompleteRecordings.filter { selectedRecordings.contains($0.id) }

        for metadata in toRecover {
            do {
                try await viewModel.recoverRecording(metadata)
            } catch {
                errorMessage = "Failed to recover: \(error.localizedDescription)"
            }
        }

        // Discard unselected
        let toDiscard = incompleteRecordings.filter { !selectedRecordings.contains($0.id) }
        for metadata in toDiscard {
            try? viewModel.discardRecording(metadata)
        }

        isProcessing = false
        isPresented = false
    }

    private func discardAll() async {
        isProcessing = true

        for metadata in incompleteRecordings {
            try? viewModel.discardRecording(metadata)
        }

        isProcessing = false
        isPresented = false
    }
}

// MARK: - Recovery Row View

/// Row view for an incomplete recording in the recovery dialog
struct RecoveryRowView: View {
    let metadata: RecordingMetadata

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Recording from \(metadata.startTime, format: .dateTime)"))
                    .font(.headline)

                HStack(spacing: 12) {
                    // Duration
                    Label(formatDuration(metadata.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Format
                    Text(metadata.format.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .clipShape(.capsule)

                    // Last auto-save time
                    if let lastSave = metadata.lastAutoSaveTime {
                        Label(
                            String(localized: "Last saved \(lastSave, format: .relative(presentation: .named))"),
                            systemImage: "clock.arrow.circlepath"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Recovery Dialog") {
    RecoveryDialogView(
        incompleteRecordings: [
            RecordingMetadata(
                id: UUID(),
                startTime: Date().addingTimeInterval(-3600),
                duration: 1800,
                format: .m4a,
                tempFileURL: nil,
                isComplete: false,
                lastAutoSaveTime: Date().addingTimeInterval(-60)
            ),
            RecordingMetadata(
                id: UUID(),
                startTime: Date().addingTimeInterval(-7200),
                duration: 900,
                format: .m4a,
                tempFileURL: nil,
                isComplete: false,
                lastAutoSaveTime: nil
            )
        ],
        viewModel: RecordingViewModel(),
        isPresented: .constant(true)
    )
}
