//
//  ProcessingQueueView.swift
//  Votra
//
//  Batch processing queue view with progress display.
//

import AppKit
import SwiftUI

/// View displaying the batch processing queue with detailed progress
struct ProcessingQueueView: View {
    @Bindable var viewModel: MediaImportViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with overall progress
            headerSection
                .padding()

            Divider()

            // Queue list
            queueList
                .frame(maxHeight: .infinity)

            Divider()

            // Footer with actions
            footerSection
                .padding()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and status
            HStack {
                Text(String(localized: "Processing Queue"))
                    .font(.title2)
                    .bold()

                Spacer()

                statusBadge
            }

            // Overall progress bar
            if viewModel.isProcessing {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: viewModel.overallProgress)
                        .progressViewStyle(.linear)

                    HStack {
                        Text(String(localized: "Overall Progress"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(viewModel.overallProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Summary stats
            HStack(spacing: 24) {
                statItem(
                    title: String(localized: "Total"),
                    value: "\(viewModel.totalFiles)",
                    icon: "doc.on.doc"
                )
                statItem(
                    title: String(localized: "Completed"),
                    value: "\(viewModel.completedFiles)",
                    icon: "checkmark.circle",
                    color: .green
                )
                statItem(
                    title: String(localized: "Failed"),
                    value: "\(viewModel.failedFiles)",
                    icon: "xmark.circle",
                    color: viewModel.failedFiles > 0 ? .red : .secondary
                )
            }
        }
    }

    @ViewBuilder private var statusBadge: some View {
        switch viewModel.batchState {
        case .idle:
            Text(String(localized: "Ready"))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.2))
                .clipShape(.capsule)

        case let .processing(current, total):
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text(String(localized: "\(current)/\(total)"))
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.2))
            .clipShape(.capsule)

        case .completed(_, let failed):
            if failed == 0 {
                Label(String(localized: "Complete"), systemImage: "checkmark")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(.capsule)
            } else {
                Label(String(localized: "\(failed) Failed"), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(.capsule)
            }

        case .cancelled:
            Label(String(localized: "Cancelled"), systemImage: "xmark")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(.capsule)
        }
    }

    // MARK: - Queue List

    private var queueList: some View {
        List {
            ForEach(viewModel.files) { file in
                ProcessingQueueRowView(file: file)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            // Output location
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(viewModel.outputDirectory.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action buttons
            if viewModel.isProcessing {
                Button(String(localized: "Cancel")) {
                    viewModel.cancelProcessing()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            } else if viewModel.isCompleted {
                HStack(spacing: 12) {
                    Button(String(localized: "Open Output Folder")) {
                        viewModel.openOutputDirectory()
                    }
                    .buttonStyle(.bordered)

                    Button(String(localized: "Clear Queue")) {
                        viewModel.clearQueue()
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(String(localized: "Start Processing")) {
                    Task {
                        await viewModel.startProcessing()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.files.isEmpty)
            }
        }
    }

    // MARK: - Helper Methods

    private func statItem(
        title: String,
        value: String,
        icon: String,
        color: Color = .secondary
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Processing Queue Row View

/// Row view for a file in the processing queue
struct ProcessingQueueRowView: View {
    let file: MediaFile

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 24)

            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(file.formattedDuration, systemImage: "clock")
                    Label(file.formattedFileSize, systemImage: "doc")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress or status detail
            statusDetail
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder private var statusIcon: some View {
        switch file.state {
        case .queued:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)

        case .processing:
            ProgressView()
                .controlSize(.small)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder private var statusDetail: some View {
        switch file.state {
        case .queued:
            Text(String(localized: "Waiting"))
                .font(.caption)
                .foregroundStyle(.secondary)

        case .processing(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 80)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

        case .completed:
            if let outputURL = file.outputURL {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                } label: {
                    Label(String(localized: "Show"), systemImage: "folder")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text(String(localized: "Done"))
                    .font(.caption)
                    .foregroundStyle(.green)
            }

        case .failed(let error):
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
                .frame(maxWidth: 150, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview("Processing Queue - Empty") {
    ProcessingQueueView(viewModel: MediaImportViewModel())
        .frame(width: 500, height: 400)
}

#Preview("Processing Queue - With Files") {
    let vm = MediaImportViewModel()
    // Note: In actual usage, files would be added via addFiles()
    return ProcessingQueueView(viewModel: vm)
        .frame(width: 500, height: 400)
}
