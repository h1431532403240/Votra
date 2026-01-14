//
//  LanguageSettingsView.swift
//  Votra
//
//  Settings view for managing language packs and offline availability.
//

import Speech
import SwiftUI

// MARK: - Language Download Status

/// Status of a language pack download
nonisolated enum LanguagePackStatus: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case installed
    case error(message: String)
}

/// Information about a downloadable language
struct LanguageInfo: Identifiable, Sendable {
    let id: String
    let locale: Locale
    var status: LanguagePackStatus

    var displayName: String {
        locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
    }

    init(locale: Locale, status: LanguagePackStatus = .notDownloaded) {
        self.id = locale.identifier
        self.locale = locale
        self.status = status
    }
}

// MARK: - Language Settings View

/// View for managing language packs for offline operation
struct LanguageSettingsView: View {
    @State private var languages: [LanguageInfo] = []
    @State private var isRefreshing = false
    @State private var downloadTasks: [String: Task<Void, Never>] = [:]
    @State private var errorMessage: String?

    // Service for checking and downloading languages
    private let speechService = SpeechRecognitionService()

    // Persistent storage for interrupted downloads
    @AppStorage("interruptedDownloads")
    private var interruptedDownloadsData = Data()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding()

            Divider()

            // Language list
            if languages.isEmpty && !isRefreshing {
                emptyStateView
            } else {
                languageList
            }

            // Error message
            if let error = errorMessage {
                errorBanner(error)
            }
        }
        .frame(minWidth: 400)
        .task {
            await loadLanguages()
            checkForInterruptedDownloads()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Language Packs"))
                    .font(.title2)
                    .bold()

                Spacer()

                if isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task {
                        await loadLanguages()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
                .help(String(localized: "Refresh"))
            }

            Text(String(localized: "Download language packs for offline speech recognition and translation."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Storage info
            HStack(spacing: 4) {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.secondary)
                Text(String(localized: "Estimated size: 100-500 MB per language"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(String(localized: "No languages available"))
                .font(.headline)

            Text(String(localized: "Make sure you have an internet connection to check available languages."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(String(localized: "Retry")) {
                Task {
                    await loadLanguages()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Language List

    private var languageList: some View {
        List {
            Section {
                ForEach($languages) { $language in
                    LanguageRowView(
                        language: $language,
                        onDownload: {
                            downloadLanguage(language)
                        },
                        onCancel: {
                            cancelDownload(language)
                        }
                    )
                }
            } header: {
                Text(String(localized: "Available Languages"))
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
            Spacer()
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.red.opacity(0.1))
    }

    // MARK: - Data Loading

    private func loadLanguages() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Get supported languages from service
        let supportedLocales = await speechService.supportedLanguages()

        var loadedLanguages: [LanguageInfo] = []

        for locale in supportedLocales {
            let status = await checkLanguageStatus(locale)
            loadedLanguages.append(LanguageInfo(locale: locale, status: status))
        }

        languages = loadedLanguages
    }

    private func checkLanguageStatus(_ locale: Locale) async -> LanguagePackStatus {
        // Check speech recognition asset status using service
        let availability = await speechService.isLanguageAvailable(locale)

        switch availability {
        case .available:
            return .installed
        case .downloadRequired:
            return .notDownloaded
        case .downloading(let progress):
            return .downloading(progress: progress)
        case .unsupported:
            return .error(message: String(localized: "Not supported"))
        }
    }

    // MARK: - Download Management

    private func downloadLanguage(_ language: LanguageInfo) {
        guard let index = languages.firstIndex(where: { $0.id == language.id }) else { return }

        // Update status to downloading
        languages[index].status = .downloading(progress: 0)

        // Create download task
        let task = Task {
            do {
                let progressStream = try await speechService.downloadLanguage(language.locale)

                for await progress in progressStream {
                    guard !Task.isCancelled else { break }

                    await MainActor.run {
                        if let idx = languages.firstIndex(where: { $0.id == language.id }) {
                            if progress.isComplete {
                                languages[idx].status = .installed
                                removeFromInterruptedDownloads(language.id)
                            } else {
                                let progressPercent = progress.totalBytes > 0
                                    ? Double(progress.bytesDownloaded) / Double(progress.totalBytes)
                                    : 0
                                languages[idx].status = .downloading(progress: progressPercent)
                                saveInterruptedDownload(language.id, progress: progressPercent)
                            }
                        }
                    }
                }

                // Download complete
                await MainActor.run {
                    if let idx = languages.firstIndex(where: { $0.id == language.id }) {
                        languages[idx].status = .installed
                        removeFromInterruptedDownloads(language.id)
                    }
                }
            } catch {
                await MainActor.run {
                    if let idx = languages.firstIndex(where: { $0.id == language.id }) {
                        languages[idx].status = .error(message: error.localizedDescription)
                    }
                    errorMessage = String(localized: "Download failed: \(error.localizedDescription)")
                }
            }
        }

        downloadTasks[language.id] = task
    }

    private func cancelDownload(_ language: LanguageInfo) {
        downloadTasks[language.id]?.cancel()
        downloadTasks[language.id] = nil

        if let index = languages.firstIndex(where: { $0.id == language.id }) {
            languages[index].status = .notDownloaded
        }
    }

    // MARK: - Interrupted Download Persistence

    private func interruptedDownloads() -> [String: Double] {
        (try? JSONDecoder().decode([String: Double].self, from: interruptedDownloadsData)) ?? [:]
    }

    private func updateInterruptedDownloads(_ downloads: [String: Double]) {
        interruptedDownloadsData = (try? JSONEncoder().encode(downloads)) ?? Data()
    }

    private func saveInterruptedDownload(_ id: String, progress: Double) {
        var downloads = interruptedDownloads()
        downloads[id] = progress
        updateInterruptedDownloads(downloads)
    }

    private func removeFromInterruptedDownloads(_ id: String) {
        var downloads = interruptedDownloads()
        downloads.removeValue(forKey: id)
        updateInterruptedDownloads(downloads)
    }

    private func checkForInterruptedDownloads() {
        let interrupted = interruptedDownloads()
        guard !interrupted.isEmpty else { return }

        // Auto-resume interrupted downloads
        for (id, _) in interrupted {
            if let language = languages.first(where: { $0.id == id }),
               case .notDownloaded = language.status {
                downloadLanguage(language)
            }
        }
    }
}

// MARK: - Language Row View

/// Row view for a single language in the settings
struct LanguageRowView: View {
    @Binding var language: LanguageInfo
    let onDownload: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 24)

            // Language info
            VStack(alignment: .leading, spacing: 4) {
                Text(language.displayName)
                    .font(.headline)

                statusText
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button
            actionButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var statusIcon: some View {
        switch language.status {
        case .notDownloaded:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.secondary)
        case .downloading:
            ProgressView()
                .controlSize(.small)
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder private var statusText: some View {
        switch language.status {
        case .notDownloaded:
            Text(String(localized: "Not downloaded"))
        case .downloading(let progress):
            Text(String(localized: "Downloading... \(Int(progress * 100))%"))
        case .installed:
            Text(String(localized: "Ready for offline use"))
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder private var actionButton: some View {
        switch language.status {
        case .notDownloaded:
            Button(String(localized: "Download")) {
                onDownload()
            }
            .buttonStyle(.bordered)

        case .downloading(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)

                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.plain)
                .help(String(localized: "Cancel download"))
            }

        case .installed:
            Text(String(localized: "Installed"))
                .font(.caption)
                .foregroundStyle(.secondary)

        case .error:
            Button(String(localized: "Retry")) {
                onDownload()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Preview

#Preview("Language Settings") {
    LanguageSettingsView()
        .frame(width: 500, height: 600)
}
