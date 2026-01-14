//
//  RecordingService.swift
//  Votra
//
//  Service for recording conversations with auto-save and crash recovery support.
//

import AVFoundation
import Foundation

// MARK: - Recording State

/// State of the recording service
nonisolated enum RecordingState: Equatable, Sendable {
    case idle
    case recording
    case paused
    case saving
    case error(message: String)
}

// MARK: - Recording Metadata

/// Metadata about a recording in progress or completed
struct RecordingMetadata: Sendable {
    let id: UUID
    let startTime: Date
    var duration: TimeInterval
    var format: AudioFormat
    var tempFileURL: URL?
    var isComplete: Bool
    var lastAutoSaveTime: Date?
}

// MARK: - Recording Service Error

/// Errors that can occur during recording operations
enum RecordingServiceError: LocalizedError {
    case notRecording
    case alreadyRecording
    case audioEngineError(underlying: Error)
    case fileWriteError(underlying: Error)
    case permissionDenied
    case insufficientDiskSpace(available: Int64, required: Int64)
    case formatNotSupported(format: AudioFormat)
    case recoveryFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notRecording:
            return String(localized: "No recording is in progress")
        case .alreadyRecording:
            return String(localized: "A recording is already in progress")
        case .audioEngineError(let error):
            return String(localized: "Audio engine error: \(error.localizedDescription)")
        case .fileWriteError(let error):
            return String(localized: "Failed to write audio file: \(error.localizedDescription)")
        case .permissionDenied:
            return String(localized: "Microphone permission denied")
        case let .insufficientDiskSpace(available, required):
            return String(localized: "Insufficient disk space. Available: \(formatBytes(available)), Required: \(formatBytes(required))")
        case .formatNotSupported(let format):
            return String(localized: "Audio format '\(format.rawValue)' is not supported")
        case .recoveryFailed(let error):
            return String(localized: "Failed to recover recording: \(error.localizedDescription)")
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Auto-Save Configuration

/// Configuration for auto-save behavior (FR-029)
struct RecordingAutoSaveConfig: Sendable {
    /// Default configuration
    static let `default` = RecordingAutoSaveConfig(
        interval: 30.0,
        minimumDiskSpace: 100 * 1024 * 1024 // 100 MB
    )

    /// Interval between auto-saves in seconds (default: 30s per FR-029)
    let interval: TimeInterval

    /// Minimum free disk space required in bytes before warning
    let minimumDiskSpace: Int64
}

// MARK: - Recording Service Protocol

/// Protocol for recording service operations
@MainActor
protocol RecordingServiceProtocol: AnyObject {
    /// Current recording state
    var state: RecordingState { get }

    /// Current recording metadata (nil if not recording)
    var currentMetadata: RecordingMetadata? { get }

    /// Start a new recording
    /// - Parameter format: Audio format for the recording
    /// - Throws: RecordingServiceError if unable to start
    func start(format: AudioFormat) async throws

    /// Stop the current recording
    /// - Returns: URL to the final audio file
    /// - Throws: RecordingServiceError if unable to stop
    func stop() async throws -> URL

    /// Pause the current recording
    /// - Throws: RecordingServiceError if unable to pause
    func pause() throws

    /// Resume a paused recording
    /// - Throws: RecordingServiceError if unable to resume
    func resume() throws

    /// Force save current recording state (used before app termination)
    func forceSave() async throws

    /// Check for incomplete recordings from previous sessions
    /// - Returns: Array of metadata for incomplete recordings
    func checkForIncompleteRecordings() -> [RecordingMetadata]

    /// Recover an incomplete recording
    /// - Parameter metadata: Metadata of the recording to recover
    /// - Returns: URL to the recovered audio file
    func recoverRecording(_ metadata: RecordingMetadata) async throws -> URL

    /// Discard an incomplete recording
    /// - Parameter metadata: Metadata of the recording to discard
    func discardIncompleteRecording(_ metadata: RecordingMetadata) throws

    /// Check available disk space
    /// - Returns: Available disk space in bytes
    func availableDiskSpace() -> Int64
}

// MARK: - Recording Service Implementation

/// Service for recording audio with auto-save support
@MainActor
@Observable
final class RecordingService: RecordingServiceProtocol {
    // MARK: - State

    private(set) var state: RecordingState = .idle
    private(set) var currentMetadata: RecordingMetadata?

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var autoSaveTask: Task<Void, Never>?
    private let config: RecordingAutoSaveConfig

    // Directory for temporary recordings
    private var tempRecordingDirectory: URL {
        StoragePaths.recordings.appending(path: "temp")
    }

    // MARK: - Initialization

    init(config: RecordingAutoSaveConfig = .default) {
        self.config = config
        ensureTempDirectoryExists()
    }

    // MARK: - RecordingServiceProtocol

    func start(format: AudioFormat) async throws {
        guard state == .idle else {
            throw RecordingServiceError.alreadyRecording
        }

        // Check disk space
        let available = availableDiskSpace()
        if available < config.minimumDiskSpace {
            throw RecordingServiceError.insufficientDiskSpace(
                available: available,
                required: config.minimumDiskSpace
            )
        }

        // Create new recording metadata
        let recordingId = UUID()
        let tempURL = tempRecordingDirectory
            .appending(path: "\(recordingId.uuidString).\(format.fileExtension)")

        let metadata = RecordingMetadata(
            id: recordingId,
            startTime: Date(),
            duration: 0,
            format: format,
            tempFileURL: tempURL,
            isComplete: false,
            lastAutoSaveTime: nil
        )

        // Setup audio engine
        try await setupAudioEngine(outputURL: tempURL, format: format)

        // Start recording
        do {
            try audioEngine?.start()
            state = .recording
            currentMetadata = metadata

            // Start auto-save timer
            startAutoSaveTimer()
        } catch {
            cleanupAudioEngine()
            throw RecordingServiceError.audioEngineError(underlying: error)
        }
    }

    func stop() async throws -> URL {
        guard state == .recording || state == .paused else {
            throw RecordingServiceError.notRecording
        }

        state = .saving

        // Stop auto-save timer
        stopAutoSaveTimer()

        // Stop audio engine
        audioEngine?.stop()

        // Close audio file
        audioFile = nil

        guard var metadata = currentMetadata, let tempURL = metadata.tempFileURL else {
            state = .error(message: "No recording metadata available")
            throw RecordingServiceError.notRecording
        }

        // Calculate final duration
        metadata.duration = Date().timeIntervalSince(metadata.startTime)
        metadata.isComplete = true

        // Move to final location
        let finalURL = StoragePaths.recordings
            .appending(path: "\(metadata.id.uuidString).\(metadata.format.fileExtension)")

        do {
            if FileManager.default.fileExists(atPath: finalURL.path()) {
                try FileManager.default.removeItem(at: finalURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: finalURL)

            // Save metadata file for crash recovery
            saveMetadata(metadata, completed: true)

            // Clean up
            cleanupAudioEngine()
            currentMetadata = nil
            state = .idle

            return finalURL
        } catch {
            state = .error(message: error.localizedDescription)
            throw RecordingServiceError.fileWriteError(underlying: error)
        }
    }

    func pause() throws {
        guard state == .recording else {
            throw RecordingServiceError.notRecording
        }

        audioEngine?.pause()
        state = .paused
    }

    func resume() throws {
        guard state == .paused else {
            throw RecordingServiceError.notRecording
        }

        do {
            try audioEngine?.start()
            state = .recording
        } catch {
            throw RecordingServiceError.audioEngineError(underlying: error)
        }
    }

    func forceSave() async throws {
        guard state == .recording || state == .paused, var metadata = currentMetadata else {
            return // Nothing to save
        }

        metadata.duration = Date().timeIntervalSince(metadata.startTime)
        metadata.lastAutoSaveTime = Date()
        currentMetadata = metadata

        saveMetadata(metadata, completed: false)
    }

    func checkForIncompleteRecordings() -> [RecordingMetadata] {
        let metadataDirectory = tempRecordingDirectory
        guard FileManager.default.fileExists(atPath: metadataDirectory.path()) else {
            return []
        }

        var incompleteRecordings: [RecordingMetadata] = []

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: metadataDirectory,
                includingPropertiesForKeys: nil
            )

            for file in files where file.pathExtension == "json" {
                if let metadata = loadMetadata(from: file), !metadata.isComplete {
                    // Verify audio file exists
                    if let tempURL = metadata.tempFileURL,
                       FileManager.default.fileExists(atPath: tempURL.path()) {
                        incompleteRecordings.append(metadata)
                    }
                }
            }
        } catch {
            // Log error but don't throw - recovery is best-effort
            print("Error checking for incomplete recordings: \(error)")
        }

        return incompleteRecordings
    }

    func recoverRecording(_ metadata: RecordingMetadata) async throws -> URL {
        guard let tempURL = metadata.tempFileURL,
              FileManager.default.fileExists(atPath: tempURL.path()) else {
            throw RecordingServiceError.recoveryFailed(
                underlying: NSError(
                    domain: "RecordingService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Recording file not found"]
                )
            )
        }

        // Move to final location
        let finalURL = StoragePaths.recordings
            .appending(path: "\(metadata.id.uuidString).\(metadata.format.fileExtension)")

        do {
            if FileManager.default.fileExists(atPath: finalURL.path()) {
                try FileManager.default.removeItem(at: finalURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: finalURL)

            // Remove metadata file
            removeMetadataFile(for: metadata)

            return finalURL
        } catch {
            throw RecordingServiceError.recoveryFailed(underlying: error)
        }
    }

    func discardIncompleteRecording(_ metadata: RecordingMetadata) throws {
        // Remove audio file
        if let tempURL = metadata.tempFileURL,
           FileManager.default.fileExists(atPath: tempURL.path()) {
            try FileManager.default.removeItem(at: tempURL)
        }

        // Remove metadata file
        removeMetadataFile(for: metadata)
    }

    func availableDiskSpace() -> Int64 {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(
                forPath: NSHomeDirectory()
            )
            if let space = attrs[.systemFreeSize] as? Int64 {
                return space
            }
        } catch {
            // Log but don't fail - return conservative estimate
            print("Error getting disk space: \(error)")
        }
        return Int64.max // Assume plenty of space if we can't determine
    }

    // MARK: - Private Methods

    private func ensureTempDirectoryExists() {
        let url = tempRecordingDirectory
        if !FileManager.default.fileExists(atPath: url.path()) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func setupAudioEngine(outputURL: URL, format: AudioFormat) async throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create audio file with appropriate settings
        let settings = audioSettings(for: format, sampleRate: recordingFormat.sampleRate)

        do {
            let file = try AVAudioFile(
                forWriting: outputURL,
                settings: settings
            )
            audioFile = file

            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self, let file = self.audioFile else { return }

                do {
                    try file.write(from: buffer)
                } catch {
                    // Log error but continue recording
                    print("Error writing audio buffer: \(error)")
                }
            }

            audioEngine = engine
        } catch {
            throw RecordingServiceError.fileWriteError(underlying: error)
        }
    }

    private func audioSettings(for format: AudioFormat, sampleRate: Double) -> [String: Any] {
        switch format {
        case .m4a:
            return [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128000
            ]
        case .wav:
            return [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false
            ]
        case .mp3:
            // MP3 not directly supported, fallback to AAC
            return [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128000
            ]
        }
    }

    private func cleanupAudioEngine() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
    }

    private func startAutoSaveTimer() {
        autoSaveTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.config.interval ?? 30))

                guard !Task.isCancelled else { break }

                await self?.performAutoSave()
            }
        }
    }

    private func stopAutoSaveTimer() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
    }

    private func performAutoSave() async {
        guard state == .recording || state == .paused,
              var metadata = currentMetadata else { return }

        // Check disk space
        let available = availableDiskSpace()
        if available < config.minimumDiskSpace {
            // Post notification for UI to show warning
            NotificationCenter.default.post(
                name: .recordingDiskSpaceLow,
                object: nil,
                userInfo: ["availableSpace": available]
            )
        }

        // Update metadata
        metadata.duration = Date().timeIntervalSince(metadata.startTime)
        metadata.lastAutoSaveTime = Date()
        currentMetadata = metadata

        // Save metadata to disk for crash recovery
        saveMetadata(metadata, completed: false)
    }

    // MARK: - Metadata Persistence

    private func metadataFileURL(for metadata: RecordingMetadata) -> URL {
        tempRecordingDirectory.appending(path: "\(metadata.id.uuidString).json")
    }

    private func saveMetadata(_ metadata: RecordingMetadata, completed: Bool) {
        let data: [String: Any] = [
            "id": metadata.id.uuidString,
            "startTime": metadata.startTime.timeIntervalSince1970,
            "duration": metadata.duration,
            "format": metadata.format.rawValue,
            "tempFileURL": metadata.tempFileURL?.path() ?? "",
            "isComplete": completed,
            "lastAutoSaveTime": metadata.lastAutoSaveTime?.timeIntervalSince1970 ?? 0
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try jsonData.write(to: metadataFileURL(for: metadata))
        } catch {
            print("Error saving recording metadata: \(error)")
        }
    }

    private func loadMetadata(from url: URL) -> RecordingMetadata? {
        do {
            let data = try Data(contentsOf: url)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let idString = dict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let startTimestamp = dict["startTime"] as? TimeInterval,
                  let duration = dict["duration"] as? TimeInterval,
                  let formatRaw = dict["format"] as? String,
                  let tempPath = dict["tempFileURL"] as? String,
                  let isComplete = dict["isComplete"] as? Bool else {
                return nil
            }

            let format = AudioFormat(rawValue: formatRaw) ?? .m4a
            let tempURL = tempPath.isEmpty ? nil : URL(filePath: tempPath)
            let lastAutoSave: Date?
            if let timestamp = dict["lastAutoSaveTime"] as? TimeInterval, timestamp > 0 {
                lastAutoSave = Date(timeIntervalSince1970: timestamp)
            } else {
                lastAutoSave = nil
            }

            return RecordingMetadata(
                id: id,
                startTime: Date(timeIntervalSince1970: startTimestamp),
                duration: duration,
                format: format,
                tempFileURL: tempURL,
                isComplete: isComplete,
                lastAutoSaveTime: lastAutoSave
            )
        } catch {
            print("Error loading recording metadata: \(error)")
            return nil
        }
    }

    private func removeMetadataFile(for metadata: RecordingMetadata) {
        let url = metadataFileURL(for: metadata)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let recordingDiskSpaceLow = Notification.Name("recordingDiskSpaceLow")
}
