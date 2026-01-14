//
//  SubtitleExportOptionsView.swift
//  Votra
//
//  Dialog for choosing subtitle export options (FR-033).
//

import SwiftUI

/// View for selecting subtitle export options
struct SubtitleExportOptionsView: View {
    let recording: Recording
    @Bindable var viewModel: RecordingViewModel
    @Binding var isPresented: Bool

    @State private var selectedFormat: SubtitleFormat = .srt
    @State private var selectedContent: SubtitleContentOption = .both
    @State private var selectedBilingualOrder: BilingualTextOrder = .translationFirst
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var exportedURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                // Format selection
                Section(String(localized: "Format")) {
                    Picker(String(localized: "File Format"), selection: $selectedFormat) {
                        ForEach(SubtitleFormat.allCases, id: \.self) { format in
                            Text(format.displayName)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Content selection (FR-033)
                Section(String(localized: "Content")) {
                    Picker(String(localized: "Include"), selection: $selectedContent) {
                        ForEach(SubtitleContentOption.allCases, id: \.self) { option in
                            HStack {
                                self.contentIcon(for: option)
                                Text(option.localizedName)
                            }
                            .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    // Bilingual order selection (only shown when bilingual mode is selected)
                    if selectedContent == .both {
                        Picker(String(localized: "Text Order"), selection: $selectedBilingualOrder) {
                            ForEach(BilingualTextOrder.allCases, id: \.self) { order in
                                Text(order.localizedName)
                                    .tag(order)
                            }
                        }
                    }
                }

                // Preview section
                Section(String(localized: "Preview")) {
                    previewContent
                }

                // Error message
                if let error = exportError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "Export Subtitles"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Export")) {
                        Task {
                            await exportSubtitles()
                        }
                    }
                    .disabled(isExporting || !hasContent)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    // MARK: - Preview

    @ViewBuilder private var previewContent: some View {
        let options = SubtitleExportOptions(
            format: selectedFormat,
            contentOption: selectedContent,
            includeTimestamps: true,
            bilingualOrder: selectedBilingualOrder
        )
        let preview = viewModel.previewSubtitles(for: recording, options: options)

        if preview.isEmpty {
            Text(String(localized: "No content available for preview"))
                .foregroundStyle(.secondary)
        } else {
            ScrollView {
                Text(preview.prefix(1000) + (preview.count > 1000 ? "\n..." : ""))
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
        }
    }

    // MARK: - Computed Properties

    private var hasContent: Bool {
        let options = SubtitleExportOptions(
            format: selectedFormat,
            contentOption: selectedContent,
            includeTimestamps: true,
            bilingualOrder: selectedBilingualOrder
        )
        return !viewModel.previewSubtitles(for: recording, options: options).isEmpty
    }

    // MARK: - Content Icon

    @ViewBuilder
    private func contentIcon(for option: SubtitleContentOption) -> some View {
        switch option {
        case .originalOnly:
            Image(systemName: "text.quote")
                .foregroundStyle(.blue)
        case .translationOnly:
            Image(systemName: "globe")
                .foregroundStyle(.green)
        case .both:
            Image(systemName: "text.badge.checkmark")
                .foregroundStyle(.purple)
        }
    }

    // MARK: - Actions

    private func exportSubtitles() async {
        isExporting = true
        exportError = nil

        let options = SubtitleExportOptions(
            format: selectedFormat,
            contentOption: selectedContent,
            includeTimestamps: true,
            bilingualOrder: selectedBilingualOrder
        )

        do {
            let url = try await viewModel.exportSubtitles(for: recording, options: options)
            exportedURL = url

            // Show in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])

            // Close dialog
            isPresented = false
        } catch {
            exportError = error.localizedDescription
        }

        isExporting = false
    }
}

// MARK: - Preview

#Preview("Subtitle Export Options") {
    SubtitleExportOptionsView(
        recording: Recording(
            duration: 60,
            format: .m4a,
            originalFileName: "Test Recording"
        ),
        viewModel: RecordingViewModel(),
        isPresented: .constant(true)
    )
}
