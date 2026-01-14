//
//  RecordingViewModel.swift
//  Votra
//
//  ViewModel for managing recording state and operations.
//

import Foundation
import SwiftData

/// ViewModel for recording management
@MainActor
@Observable
final class RecordingViewModel {
    // MARK: - State

    /// Current recording state
    private(set) var recordingState: RecordingState = .idle

    /// Current recording metadata
    private(set) var currentMetadata: RecordingMetadata?

    /// Saved recordings
    private(set) var recordings: [Recording] = []

    /// Currently selected recording for detail view
    var selectedRecording: Recording?

    /// Error message to display
    private(set) var errorMessage: String?

    /// Whether an export operation is in progress
    private(set) var isExporting = false

    /// Available disk space in bytes
    private(set) var availableDiskSpace = Int64.max

    /// Whether disk space is low
    var isDiskSpaceLow: Bool {
        availableDiskSpace < 100 * 1024 * 1024 // < 100 MB
    }

    /// Whether recording is currently in progress
    var isRecording: Bool {
        recordingState == .recording || recordingState == .paused
    }

    /// Whether recording is paused
    var isPaused: Bool {
        recordingState == .paused
    }

    /// Current recording duration
    var currentDuration: TimeInterval {
        guard let metadata = currentMetadata else { return 0 }
        return Date().timeIntervalSince(metadata.startTime)
    }

    /// Formatted current duration
    var formattedCurrentDuration: String {
        let duration = currentDuration
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Services

    private var recordingService: any RecordingServiceProtocol
    private var subtitleExportService: any SubtitleExportServiceProtocol
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init(
        recordingService: any RecordingServiceProtocol = RecordingService(),
        subtitleExportService: any SubtitleExportServiceProtocol = SubtitleExportService()
    ) {
        self.recordingService = recordingService
        self.subtitleExportService = subtitleExportService

        // Setup notifications
        setupNotifications()
        updateDiskSpace()
    }

    // MARK: - Model Context

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadRecordings()
    }

    // MARK: - Recording Operations

    /// Start a new recording
    /// - Parameter format: Audio format for the recording
    func startRecording(format: AudioFormat = .m4a) async {
        do {
            errorMessage = nil
            try await recordingService.start(format: format)
            recordingState = recordingService.state
            currentMetadata = recordingService.currentMetadata
        } catch let error as RecordingServiceError {
            errorMessage = error.localizedDescription
            recordingState = .error(message: error.localizedDescription)
        } catch {
            errorMessage = error.localizedDescription
            recordingState = .error(message: error.localizedDescription)
        }
    }

    /// Stop the current recording
    func stopRecording() async {
        do {
            errorMessage = nil
            let audioURL = try await recordingService.stop()
            recordingState = recordingService.state
            currentMetadata = nil

            // Create Recording model and save
            await saveRecording(from: audioURL)
        } catch let error as RecordingServiceError {
            errorMessage = error.localizedDescription
            recordingState = .error(message: error.localizedDescription)
        } catch {
            errorMessage = error.localizedDescription
            recordingState = .error(message: error.localizedDescription)
        }
    }

    /// Pause the current recording
    func pauseRecording() {
        do {
            try recordingService.pause()
            recordingState = recordingService.state
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Resume a paused recording
    func resumeRecording() {
        do {
            try recordingService.resume()
            recordingState = recordingService.state
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Force save current recording (for app termination)
    func forceSave() async {
        do {
            try await recordingService.forceSave()
        } catch {
            print("Force save failed: \(error)")
        }
    }

    // MARK: - Recording Management

    /// Load saved recordings from SwiftData
    func loadRecordings() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Recording>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            recordings = try context.fetch(descriptor)
        } catch {
            print("Failed to load recordings: \(error)")
            recordings = []
        }
    }

    /// Delete a recording
    func deleteRecording(_ recording: Recording) {
        guard let context = modelContext else { return }

        // Delete audio file
        if let data = recording.audioData {
            // Audio is stored in SwiftData, will be cleaned up automatically
            _ = data // Silence unused warning
        }

        context.delete(recording)

        do {
            try context.save()
            loadRecordings()

            if selectedRecording?.id == recording.id {
                selectedRecording = nil
            }
        } catch {
            errorMessage = "Failed to delete recording: \(error.localizedDescription)"
        }
    }

    // MARK: - Export Operations

    /// Export recording audio to a file
    /// - Parameter recording: Recording to export
    /// - Returns: URL to the exported file
    func exportAudio(_ recording: Recording) async throws -> URL {
        try recording.exportToTemporaryFile()
    }

    /// Export recording as subtitles
    /// - Parameters:
    ///   - recording: Recording to export (must have associated session)
    ///   - options: Export options
    /// - Returns: URL to the exported subtitle file
    func exportSubtitles(
        for recording: Recording,
        options: SubtitleExportOptions = .default
    ) async throws -> URL {
        guard let session = recording.session else {
            throw SubtitleExportError.noSegments
        }

        isExporting = true
        defer { isExporting = false }

        let segments = session.segments ?? []
        return try await subtitleExportService.export(segments: segments, options: options)
    }

    /// Generate subtitle preview without saving to file
    func previewSubtitles(
        for recording: Recording,
        options: SubtitleExportOptions = .default
    ) -> String {
        guard let session = recording.session else {
            return ""
        }

        let segments = session.segments ?? []
        return subtitleExportService.generateContent(from: segments, options: options)
    }

    // MARK: - Crash Recovery

    /// Check for incomplete recordings from previous sessions
    func checkForIncompleteRecordings() -> [RecordingMetadata] {
        recordingService.checkForIncompleteRecordings()
    }

    /// Recover an incomplete recording
    func recoverRecording(_ metadata: RecordingMetadata) async throws {
        let audioURL = try await recordingService.recoverRecording(metadata)
        await saveRecording(from: audioURL, metadata: metadata)
    }

    /// Discard an incomplete recording
    func discardRecording(_ metadata: RecordingMetadata) throws {
        try recordingService.discardIncompleteRecording(metadata)
    }

    // MARK: - Private Methods

    private func saveRecording(from audioURL: URL, metadata: RecordingMetadata? = nil) async {
        guard let context = modelContext else {
            errorMessage = "Cannot save recording: Model context not available"
            return
        }

        do {
            let recording = Recording(
                id: metadata?.id ?? UUID(),
                format: metadata?.format ?? .m4a,
                createdAt: metadata?.startTime ?? Date()
            )

            try recording.loadAudio(from: audioURL)
            recording.duration = metadata?.duration ?? 0

            context.insert(recording)
            try context.save()

            // Reload recordings
            loadRecordings()

            // Clean up temporary file
            try? FileManager.default.removeItem(at: audioURL)
        } catch {
            errorMessage = "Failed to save recording: \(error.localizedDescription)"
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .recordingDiskSpaceLow,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let space = notification.userInfo?["availableSpace"] as? Int64
            Task { @MainActor in
                if let space {
                    self?.availableDiskSpace = space
                }
            }
        }
    }

    private func updateDiskSpace() {
        availableDiskSpace = recordingService.availableDiskSpace()
    }
}
