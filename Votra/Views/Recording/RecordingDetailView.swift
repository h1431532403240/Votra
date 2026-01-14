//
//  RecordingDetailView.swift
//  Votra
//
//  Detail view for a recording with playback and export options.
//

import AppKit
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

/// Detail view for viewing and managing a recording
struct RecordingDetailView: View {
    let recording: Recording
    @Bindable var viewModel: RecordingViewModel

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var showingExportOptions = false
    @State private var showingSubtitleExport = false
    @State private var exportedURL: URL?

    // Summary state
    @State private var summaryService = SummaryService()
    @State private var generatedSummary: SummaryDisplayData?
    @State private var showingSummaryView = false

    // Playback timer
    @State private var playbackTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                Divider()

                // Playback controls
                playbackSection

                Divider()

                // Export options
                exportSection

                // Subtitle preview (if session available)
                if recording.session != nil {
                    Divider()
                    subtitlePreviewSection
                }

                // Smart Summary section (if session has segments)
                if let session = recording.session, !(session.segments?.isEmpty ?? true) {
                    Divider()
                    summarySection
                }
            }
            .padding()
        }
        .navigationTitle(recording.originalFileName.isEmpty ?
                         String(localized: "Recording") :
                         recording.originalFileName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    exportMenuItems
                } label: {
                    Label(String(localized: "Export"), systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopPlayback()
        }
        .sheet(isPresented: $showingSubtitleExport) {
            SubtitleExportOptionsView(
                recording: recording,
                viewModel: viewModel,
                isPresented: $showingSubtitleExport
            )
        }
        .sheet(isPresented: $showingSummaryView) {
            if let summary = generatedSummary {
                SummaryView(
                    summary: summary,
                    onExport: {
                        exportSummaryMarkdown()
                    },
                    onClose: {
                        showingSummaryView = false
                    }
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Waveform icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            // Recording info
            VStack(spacing: 8) {
                Text(recording.formattedDuration)
                    .font(.title)
                    .bold()

                HStack(spacing: 16) {
                    Label(recording.formattedFileSize, systemImage: "doc")
                    Label(recording.format.rawValue.uppercased(), systemImage: "music.note")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(recording.createdAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Playback Section

    private var playbackSection: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Playback"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Progress bar
            VStack(spacing: 8) {
                Slider(value: $playbackProgress, in: 0...1) { editing in
                    if !editing {
                        seekTo(progress: playbackProgress)
                    }
                }

                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(recording.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Playback controls
            HStack(spacing: 24) {
                // Rewind 10s
                Button {
                    skip(seconds: -10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                // Play/Pause
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                }
                .buttonStyle(.plain)

                // Forward 10s
                Button {
                    skip(seconds: 10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .glassCard()
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Export"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                // Export audio
                Button {
                    Task {
                        await exportAudio()
                    }
                } label: {
                    Label(String(localized: "Audio File"), systemImage: "music.note")
                }
                .buttonStyle(GlassButtonStyle())

                // Export subtitles (if session available)
                if recording.session != nil {
                    Button {
                        showingSubtitleExport = true
                    } label: {
                        Label(String(localized: "Subtitles"), systemImage: "text.bubble")
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
        }
        .glassCard()
    }

    // MARK: - Subtitle Preview Section

    @ViewBuilder private var subtitlePreviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Subtitle Preview"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "Export")) {
                    showingSubtitleExport = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }

            let preview = viewModel.previewSubtitles(for: recording, options: .default)
            if preview.isEmpty {
                Text(String(localized: "No transcript available"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(preview.prefix(500) + (preview.count > 500 ? "..." : ""))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .glassCard()
    }

    // MARK: - Summary Section

    @ViewBuilder private var summarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Smart Summary"))
                    .font(.headline)
                Spacer()

                if summaryService.isAvailable {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.green)
                        .help(String(localized: "Apple Intelligence available"))
                } else {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.secondary)
                        .help(summaryService.availabilityMessage ?? String(localized: "Apple Intelligence unavailable"))
                }
            }

            if !summaryService.isAvailable {
                // Apple Intelligence unavailable notice
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(summaryService.availabilityMessage ?? String(localized: "Apple Intelligence is not available"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Show generation state or summary button
            switch summaryService.state {
            case .idle, .error:
                Button {
                    Task {
                        await generateSummary()
                    }
                } label: {
                    Label(String(localized: "Generate Summary"), systemImage: "sparkles")
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(!summaryService.isAvailable)

            case .preparing, .generating:
                SummaryGenerationView(state: summaryService.state) {
                    summaryService.cancel()
                }

            case .completed:
                if generatedSummary != nil {
                    HStack {
                        Button {
                            showingSummaryView = true
                        } label: {
                            Label(String(localized: "View Summary"), systemImage: "doc.text")
                        }
                        .buttonStyle(GlassButtonStyle())

                        Button {
                            Task {
                                await generateSummary()
                            }
                        } label: {
                            Label(String(localized: "Regenerate"), systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Export Menu Items

    @ViewBuilder private var exportMenuItems: some View {
        Button {
            Task {
                await exportAudio()
            }
        } label: {
            Label(String(localized: "Export Audio"), systemImage: "music.note")
        }

        if recording.session != nil {
            Button {
                showingSubtitleExport = true
            } label: {
                Label(String(localized: "Export Subtitles"), systemImage: "text.bubble")
            }
        }
    }

    // MARK: - Current Time

    private var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    // MARK: - Summary Methods

    private func generateSummary() async {
        guard let session = recording.session,
              let segments = session.segments else { return }

        do {
            let input = SummaryInput.from(segments: Array(segments))
            let result = try await summaryService.generateSummary(from: input)
            generatedSummary = SummaryDisplayData(from: result)
            showingSummaryView = true
        } catch {
            print("Summary generation failed: \(error)")
        }
    }

    private func exportSummaryMarkdown() {
        guard let summary = generatedSummary else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(recording.originalFileName.isEmpty ? "Summary" : recording.originalFileName)_summary.md"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try summary.markdownOutput.write(to: url, atomically: true, encoding: .utf8)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    print("Failed to export summary: \(error)")
                }
            }
        }
    }

    // MARK: - Audio Player

    private func setupAudioPlayer() {
        guard let data = recording.audioData else { return }

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }

    private func togglePlayback() {
        guard let player = audioPlayer else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
            startProgressTimer()
        }
        isPlaying.toggle()
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }

    private func skip(seconds: TimeInterval) {
        guard let player = audioPlayer else { return }
        let newTime = max(0, min(player.duration, player.currentTime + seconds))
        player.currentTime = newTime
        updatePlaybackProgress()
    }

    private func seekTo(progress: Double) {
        guard let player = audioPlayer else { return }
        player.currentTime = player.duration * progress
    }

    private func startProgressTimer() {
        stopProgressTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            MainActor.assumeIsolated {
                updatePlaybackProgress()
            }
        }
    }

    private func stopProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func updatePlaybackProgress() {
        guard isPlaying, let player = audioPlayer, player.duration > 0 else {
            stopProgressTimer()
            return
        }
        playbackProgress = player.currentTime / player.duration

        if player.currentTime >= player.duration {
            isPlaying = false
            playbackProgress = 0
            player.currentTime = 0
            stopProgressTimer()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Export

    private func exportAudio() async {
        do {
            let url = try await viewModel.exportAudio(recording)
            exportedURL = url
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Recording Detail") {
    NavigationStack {
        RecordingDetailView(
            recording: Recording(
                duration: 125,
                format: .m4a,
                originalFileName: "Meeting Recording"
            ),
            viewModel: RecordingViewModel()
        )
    }
    .frame(width: 500, height: 700)
}
