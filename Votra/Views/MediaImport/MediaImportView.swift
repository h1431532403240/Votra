//
//  MediaImportView.swift
//  Votra
//
//  File picker and import UI for media subtitle generation.
//

import AppKit
import SwiftUI
@preconcurrency import Translation
import UniformTypeIdentifiers

/// Main view for media file import and subtitle generation
struct MediaImportView: View {
    // MARK: - Instance Properties

    @Bindable var viewModel: MediaImportViewModel
    @State private var isShowingFilePicker = false
    @State private var isDroppingFiles = false
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var isShowingSkippedSegments = false

    let availableLanguages: [Locale]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with language selection
            headerSection
                .padding()

            Divider()

            // File list or drop zone
            if viewModel.files.isEmpty {
                dropZoneView
                    .frame(maxHeight: .infinity)
            } else {
                fileListSection
                    .frame(maxHeight: .infinity)
            }

            Divider()

            // Footer with actions
            footerSection
                .padding()
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: supportedUTTypes,
            allowsMultipleSelection: true
        ) { result in
            handleFilePicker(result)
        }
        .onDrop(of: supportedUTTypes, isTargeted: $isDroppingFiles) { providers in
            handleDrop(providers)
        }
        .translationTask(translationConfiguration) { session in
            await viewModel.setTranslationSession(session)
        }
        .onAppear {
            // Initialize translation configuration
            updateTranslationConfiguration()
        }
        .onDisappear {
            // Invalidate session when view disappears to prevent crashes
            Task {
                await viewModel.invalidateTranslationSession()
            }
        }
        .onChange(of: viewModel.sourceLocale) { _, _ in
            // Don't change configuration during processing - it invalidates the session
            guard !viewModel.isProcessing else { return }
            updateTranslationConfiguration()
        }
        .onChange(of: viewModel.targetLocale) { _, _ in
            // Don't change configuration during processing - it invalidates the session
            guard !viewModel.isProcessing else { return }
            updateTranslationConfiguration()
        }
        .onChange(of: viewModel.skippedSegmentTexts) { _, newValue in
            // Show sheet when there are skipped segments after processing completes
            if !newValue.isEmpty && viewModel.isCompleted {
                isShowingSkippedSegments = true
            }
        }
        .sheet(isPresented: $isShowingSkippedSegments) {
            SkippedSegmentsSheet(skippedTexts: viewModel.skippedSegmentTexts)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Import Media Files"))
                .font(.title2)
                .bold()

            Text(String(localized: "Select audio or video files to generate translated subtitles."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Subtitle mode selection
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Subtitle Mode"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(String(localized: "Mode"), selection: $viewModel.exportOptions.contentOption) {
                        ForEach(SubtitleContentOption.allCases, id: \.self) { option in
                            Text(option.localizedName)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Bilingual order selection (only shown when bilingual mode is selected)
                if viewModel.exportOptions.contentOption == .both {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Text Order"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker(String(localized: "Order"), selection: $viewModel.exportOptions.bilingualOrder) {
                            ForEach(BilingualTextOrder.allCases, id: \.self) { order in
                                Text(order.localizedName)
                                    .tag(order)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                }
            }

            // Language and format selection
            HStack(spacing: 24) {
                // Source language
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Source Language"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(String(localized: "Source"), selection: $viewModel.sourceLocale) {
                        ForEach(availableLanguages, id: \.identifier) { locale in
                            Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                                .tag(locale)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }

                // Show arrow only when translation is involved
                if viewModel.exportOptions.contentOption != .originalOnly {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    // Target language
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Target Language"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker(String(localized: "Target"), selection: $viewModel.targetLocale) {
                            ForEach(availableLanguages, id: \.identifier) { locale in
                                Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                                    .tag(locale)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                }

                Spacer()

                // Export format
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Subtitle Format"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(String(localized: "Format"), selection: $viewModel.exportOptions.format) {
                        ForEach(SubtitleFormat.allCases, id: \.self) { format in
                            Text(format.rawValue.uppercased())
                                .tag(format)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
            }
        }
    }

    // MARK: - Drop Zone View

    private var dropZoneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(isDroppingFiles ? Color.accentColor : Color.secondary)

            Text(String(localized: "Drop files here"))
                .font(.headline)

            Text(String(localized: "or"))
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button(String(localized: "Browse Files")) {
                isShowingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("media_import_browse_button")

            Text(String(localized: "Supported formats: MP4, MOV, MP3, M4A"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundStyle(isDroppingFiles ? Color.accentColor : Color.secondary.opacity(0.5))
        }
        .padding()
        .accessibilityIdentifier("media_import_drop_zone")
    }

    // MARK: - File List Section

    private var fileListSection: some View {
        VStack(spacing: 0) {
            // Add more files button
            HStack {
                Button {
                    isShowingFilePicker = true
                } label: {
                    Label(String(localized: "Add Files"), systemImage: "plus")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing)

                Spacer()

                if !viewModel.files.isEmpty {
                    Text(String(localized: "\(viewModel.files.count) file(s)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // File list
            List {
                ForEach(viewModel.files) { file in
                    MediaFileRowView(file: file) {
                        viewModel.removeFile(file)
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            // Language download required banner
            if viewModel.languageDownloadRequired {
                languageDownloadBanner
            }

            HStack {
                // Clear queue button
                if !viewModel.files.isEmpty && !viewModel.isProcessing {
                    Button(String(localized: "Clear Queue")) {
                        viewModel.clearQueue()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }

                Spacer()

                // Processing status or action buttons
                if viewModel.isProcessing {
                    processingStatusView
                } else if viewModel.isCompleted {
                    completionStatusView
                } else {
                    // Start processing button
                    Button(String(localized: "Generate Subtitles")) {
                        Task {
                            await viewModel.startProcessing()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.files.isEmpty)
                    .accessibilityIdentifier("media_import_generate_button")
                }
            }
        }
    }

    // MARK: - Language Download Banner

    private var languageDownloadBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .bold()
                }
                Text(String(localized: "Please download the language pack from System Settings > General > Language & Region > Translation Languages."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(String(localized: "Open Settings")) {
                openTranslationSettings()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        }
    }

    // MARK: - Processing Status View

    private var processingStatusView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)

            if case .processing(let current, let total) = viewModel.batchState {
                Text(String(localized: "Processing \(current) of \(total)..."))
                    .font(.subheadline)
            }

            Button(String(localized: "Cancel")) {
                viewModel.cancelProcessing()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }

    // MARK: - Completion Status View

    private var completionStatusView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 12) {
                if case .completed(let successful, let failed) = viewModel.batchState {
                    if failed == 0 && viewModel.skippedSegmentTexts.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(String(localized: "Completed: \(successful) file(s)"))
                    } else if failed == 0 {
                        Image(systemName: "checkmark.circle.badge.questionmark")
                            .foregroundStyle(.orange)
                        Text(String(localized: "Completed: \(successful) file(s)"))
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.yellow)
                        Text(String(localized: "Completed: \(successful) succeeded, \(failed) failed"))
                    }
                }

                // Show button to view skipped segments if any
                if !viewModel.skippedSegmentTexts.isEmpty {
                    Button {
                        isShowingSkippedSegments = true
                    } label: {
                        Label(
                            String(localized: "\(viewModel.skippedSegmentTexts.count) Warning(s)"),
                            systemImage: "exclamationmark.triangle.fill"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                Button(String(localized: "Open Output Folder")) {
                    viewModel.openOutputDirectory()
                }
                .buttonStyle(.bordered)

                Button(String(localized: "Clear")) {
                    viewModel.clearQueue()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - File Handling

    private var supportedUTTypes: [UTType] {
        [
            .mpeg4Movie,
            .quickTimeMovie,
            .mp3,
            .mpeg4Audio, // m4a
            .wav,
            .aiff
        ]
    }

    // MARK: - Instance Methods

    private func updateTranslationConfiguration() {
        translationConfiguration = TranslationSession.Configuration(
            source: viewModel.sourceLocale.language,
            target: viewModel.targetLocale.language
        )
    }

    private func handleFilePicker(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await viewModel.addFiles(urls)
            }
        case .failure(let error):
            print("File picker error: \(error)")
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        Task {
            var urls: [URL] = []

            for provider in providers {
                for type in supportedUTTypes where provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    do {
                        // Use loadFileRepresentation for proper sandbox access
                        let url = try await loadSecurityScopedURL(from: provider, type: type)
                        if let url {
                            urls.append(url)
                        }
                    } catch {
                        print("Failed to load file: \(error)")
                    }
                    break
                }
            }

            if !urls.isEmpty {
                await viewModel.addFiles(urls)
            }
        }

        return true
    }

    private func loadSecurityScopedURL(from provider: NSItemProvider, type: UTType) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            // Use loadFileRepresentation which copies the file and provides proper access
            _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url else {
                    continuation.resume(returning: nil)
                    return
                }

                // Copy to temporary location preserving original filename
                // Use UUID prefix to avoid conflicts, but keep original name for display
                let originalFilename = url.lastPathComponent
                let tempURL = FileManager.default.temporaryDirectory
                    .appending(path: "\(UUID().uuidString)_\(originalFilename)")

                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func openTranslationSettings() {
        // Open System Settings > General > Language & Region
        if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Media File Row View

/// Row view for a media file in the import queue
struct MediaFileRowView: View {
    // MARK: - Instance Properties

    let file: MediaFile
    let onRemove: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            Image(systemName: file.mediaType == .video ? "film" : "music.note")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)

            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(file.formattedDuration, systemImage: "clock")
                    Label(file.formattedFileSize, systemImage: "doc")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // State indicator
            stateIndicator
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }

    @ViewBuilder private var stateIndicator: some View {
        switch file.state {
        case .queued:
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

        case .processing(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .completed:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                if let outputURL = file.outputURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    } label: {
                        Image(systemName: "folder")
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Show in Finder"))
                }
            }

        case .failed(let error):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

#Preview("Media Import") {
    MediaImportView(
        viewModel: MediaImportViewModel(),
        availableLanguages: [
            Locale(identifier: "en"),
            Locale(identifier: "zh-Hans"),
            Locale(identifier: "ja"),
            Locale(identifier: "ko"),
            Locale(identifier: "es"),
            Locale(identifier: "fr")
        ]
    )
    .frame(width: 600, height: 500)
}
