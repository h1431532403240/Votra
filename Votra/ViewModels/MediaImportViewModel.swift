//
//  MediaImportViewModel.swift
//  Votra
//
//  ViewModel for media file import and batch subtitle generation.
//

import AppKit
import AVFoundation
import Foundation
import FoundationModels
import Speech

// MARK: - Supporting Types

/// State of a media file in the processing queue
nonisolated enum MediaProcessingState: Equatable, Sendable {
    case queued
    case processing(progress: Double)
    case completed
    case failed(error: String)
}

/// A media file in the processing queue
nonisolated struct MediaFile: Identifiable, Sendable, Equatable {
    let id: UUID
    let url: URL
    let fileName: String
    let fileSize: Int64
    let duration: TimeInterval
    let mediaType: MediaType
    var state: MediaProcessingState
    var outputURL: URL?
    let bookmarkData: Data?

    /// Formatted duration string
    var formattedDuration: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formatted file size string
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    init(
        id: UUID = UUID(),
        url: URL,
        fileName: String,
        fileSize: Int64,
        duration: TimeInterval,
        mediaType: MediaType,
        state: MediaProcessingState = .queued,
        outputURL: URL? = nil,
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
        self.duration = duration
        self.mediaType = mediaType
        self.state = state
        self.outputURL = outputURL
        self.bookmarkData = bookmarkData
    }
}

/// Supported media types for import
nonisolated enum MediaType: String, Sendable, CaseIterable {
    case video
    case audio

    static func from(fileExtension: String) -> MediaType? {
        switch fileExtension.lowercased() {
        case "mp4", "mov", "m4v":
            return .video
        case "mp3", "m4a", "wav", "aac":
            return .audio
        default:
            return nil
        }
    }
}

/// Overall batch processing state
nonisolated enum BatchProcessingState: Equatable, Sendable {
    case idle
    case processing(current: Int, total: Int)
    case completed(successful: Int, failed: Int)
    case cancelled
}

/// Errors during media import
nonisolated enum MediaImportError: Error, LocalizedError, Sendable {
    case unsupportedFormat(String)
    case fileNotFound(String)
    case accessDenied(String)
    case transcriptionFailed(String)
    case translationFailed(String)
    case languageNotInstalled(source: String, target: String)
    case exportFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return String(localized: "Unsupported file format: \(format)")
        case .fileNotFound(let path):
            return String(localized: "File not found: \(path)")
        case .accessDenied(let path):
            return String(localized: "Access denied: \(path)")
        case .transcriptionFailed(let reason):
            return String(localized: "Transcription failed: \(reason)")
        case .translationFailed(let reason):
            return String(localized: "Translation failed: \(reason)")
        case let .languageNotInstalled(source, target):
            return String(localized: "Language pack not installed for \(source) → \(target)")
        case .exportFailed(let reason):
            return String(localized: "Export failed: \(reason)")
        case .cancelled:
            return String(localized: "Processing was cancelled")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .languageNotInstalled:
            return String(localized: "Please download the language pack from System Settings > General > Language & Region > Translation Languages, or click \"Download\" when prompted.")
        default:
            return nil
        }
    }
}

// MARK: - MediaImportViewModel

/// ViewModel for managing media file import and batch subtitle generation
@MainActor
@Observable
final class MediaImportViewModel {
    // MARK: - Subtypes

    /// Individual word/run with timing information (used across Task boundaries)
    private struct WordTiming: Sendable {
        let text: String
        let startTime: TimeInterval
        let endTime: TimeInterval
    }

    /// A transcription segment with word-level timing (used across Task boundaries)
    private struct TranscriptionData: Sendable {
        let text: String
        let startTime: TimeInterval
        let endTime: TimeInterval
        let wordTimings: [WordTiming]
    }

    // MARK: - Type Properties

    /// Supported file extensions for import
    static var supportedExtensions: [String] {
        ["mp4", "mov", "m4v", "mp3", "m4a", "wav", "aac"]
    }

    /// UTTypes for file picker
    static var supportedContentTypes: [String] {
        [
            "public.mpeg-4",
            "com.apple.quicktime-movie",
            "public.mp3",
            "com.apple.m4a-audio",
            "com.microsoft.waveform-audio",
            "public.aac-audio"
        ]
    }

    // MARK: - Type Properties - Language Defaults

    /// Supported locales for translation
    private static let supportedLocales = Set([
        "en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de", "it", "pt"
    ])

    /// Returns the system locale if supported, otherwise returns a fallback
    private static func systemTargetLocale() -> Locale {
        // Get the user's preferred language
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.language.languageCode?.identifier ?? ""

            // Check for Chinese variants
            if languageCode == "zh" {
                let script = locale.language.script?.identifier
                if script == "Hant" || preferredLanguage.contains("Hant") || preferredLanguage.contains("TW") || preferredLanguage.contains("HK") {
                    return Locale(identifier: "zh-Hant")
                } else {
                    return Locale(identifier: "zh-Hans")
                }
            }

            // Check if the language code is supported
            if supportedLocales.contains(languageCode) {
                return Locale(identifier: languageCode)
            }
        }

        // Default fallback to English
        return Locale(identifier: "en")
    }

    /// Returns a source locale different from the target
    private static func defaultSourceLocale(targetLocale: Locale) -> Locale {
        let targetId = targetLocale.identifier
        // If target is English, default source to Simplified Chinese
        if targetId == "en" {
            return Locale(identifier: "zh-Hans")
        }
        // Otherwise, default source to English
        return Locale(identifier: "en")
    }

    // MARK: - Instance Properties

    /// Files in the processing queue
    private(set) var files: [MediaFile] = []

    /// Current batch processing state
    private(set) var batchState: BatchProcessingState = .idle

    /// Source language for transcription
    var sourceLocale: Locale

    /// Target language for translation
    var targetLocale: Locale

    /// Subtitle export options
    var exportOptions: SubtitleExportOptions = .default

    /// Output directory for generated subtitles
    var outputDirectory: URL = StoragePaths.exports

    /// Error message to display
    private(set) var errorMessage: String?

    /// Warning message (non-fatal issues like skipped segments)
    private(set) var warningMessage: String?

    /// Texts that were skipped due to AI safety filters
    private(set) var skippedSegmentTexts: [String] = []

    /// Whether language pack needs to be downloaded
    private(set) var languageDownloadRequired = false

    /// Whether processing is complete
    var isCompleted: Bool {
        guard case .completed = batchState else { return false }
        return true
    }

    /// Whether currently processing
    var isProcessing: Bool {
        guard case .processing = batchState else { return false }
        return true
    }

    /// Total number of files in queue
    var totalFiles: Int {
        files.count
    }

    /// Number of completed files
    var completedFiles: Int {
        files.filter { $0.state == .completed }.count
    }

    /// Number of failed files
    var failedFiles: Int {
        files.filter { file in
            guard case .failed = file.state else { return false }
            return true
        }.count
    }

    /// Overall progress (0.0 - 1.0)
    var overallProgress: Double {
        guard !files.isEmpty else { return 0 }

        var totalProgress = 0.0
        for file in files {
            switch file.state {
            case .queued:
                totalProgress += 0
            case .processing(let progress):
                totalProgress += progress
            case .completed:
                totalProgress += 1.0
            case .failed:
                totalProgress += 1.0 // Count failed as "done"
            }
        }

        return totalProgress / Double(files.count)
    }

    // MARK: - Private Properties

    private var speechRecognitionService: any SpeechRecognitionServiceProtocol
    private var translationService: any TranslationServiceProtocol
    private var subtitleExportService: any SubtitleExportServiceProtocol
    private var intelligentSegmentationService: any IntelligentSegmentationServiceProtocol
    private var processingTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        speechRecognitionService: any SpeechRecognitionServiceProtocol = SpeechRecognitionService(),
        translationService: any TranslationServiceProtocol = TranslationService(),
        subtitleExportService: any SubtitleExportServiceProtocol = SubtitleExportService(),
        intelligentSegmentationService: any IntelligentSegmentationServiceProtocol = IntelligentSegmentationService()
    ) {
        // Set default locales based on system language
        let target = Self.systemTargetLocale()
        let source = Self.defaultSourceLocale(targetLocale: target)
        self.targetLocale = target
        self.sourceLocale = source

        self.speechRecognitionService = speechRecognitionService
        self.translationService = translationService
        self.subtitleExportService = subtitleExportService
        self.intelligentSegmentationService = intelligentSegmentationService
    }

    // MARK: - Public Methods

    /// Add files to the processing queue
    /// - Parameter urls: URLs of media files to add
    func addFiles(_ urls: [URL]) async {
        errorMessage = nil

        for url in urls {
            // Try to start accessing security-scoped resource for sandboxed apps
            // This will return false for non-security-scoped URLs (like temp files from drag-drop)
            let hasSecurityAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Validate file format
            let ext = url.pathExtension.lowercased()
            guard let mediaType = MediaType.from(fileExtension: ext) else {
                errorMessage = MediaImportError.unsupportedFormat(ext).localizedDescription
                continue
            }

            // Get file info
            do {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = Int64(resourceValues.fileSize ?? 0)

                // Get duration using AVAsset
                let duration = await getMediaDuration(url)

                // Try to create a security-scoped bookmark for persistent access
                // This may fail for temp files from drag-drop (which is OK)
                var bookmarkData: Data?
                if hasSecurityAccess {
                    bookmarkData = try? url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                }

                // Store the file with bookmark (if available)
                // Extract original filename (temp files from drag-drop have UUID prefix)
                let displayFileName = extractOriginalFilename(from: url.lastPathComponent)

                let file = MediaFile(
                    url: url,
                    fileName: displayFileName,
                    fileSize: fileSize,
                    duration: duration,
                    mediaType: mediaType,
                    bookmarkData: bookmarkData
                )

                files.append(file)
            } catch {
                errorMessage = MediaImportError.accessDenied(url.lastPathComponent).localizedDescription
            }
        }
    }

    /// Remove a file from the queue
    /// - Parameter file: File to remove
    func removeFile(_ file: MediaFile) {
        files.removeAll { $0.id == file.id }
    }

    /// Clear all files from the queue
    func clearQueue() {
        guard batchState == .idle || batchState == .cancelled || isCompleted else { return }
        files.removeAll()
        batchState = .idle
    }

    /// Start processing all queued files
    func startProcessing() async {
        guard !files.isEmpty else { return }
        guard batchState == .idle || isCompleted else { return }

        errorMessage = nil
        warningMessage = nil
        skippedSegmentTexts = []
        languageDownloadRequired = false

        // Check if language pack is installed (only if translation is needed)
        if exportOptions.contentOption != .originalOnly {
            let isInstalled = await translationService.isLanguagePairInstalled(
                source: sourceLocale,
                target: targetLocale
            )
            if !isInstalled {
                languageDownloadRequired = true
                let sourceName = sourceLocale.localizedString(forIdentifier: sourceLocale.identifier) ?? sourceLocale.identifier
                let targetName = targetLocale.localizedString(forIdentifier: targetLocale.identifier) ?? targetLocale.identifier
                errorMessage = MediaImportError.languageNotInstalled(source: sourceName, target: targetName).localizedDescription
                return
            }
        }

        let totalFiles = files.count

        processingTask = Task { [weak self] in
            guard let self else { return }

            var successCount = 0
            var failCount = 0

            for (index, file) in files.enumerated() {
                guard !Task.isCancelled else {
                    await MainActor.run {
                        self.batchState = .cancelled
                    }
                    return
                }

                await MainActor.run {
                    self.batchState = .processing(current: index + 1, total: totalFiles)
                }

                do {
                    try await self.processFile(file)
                    successCount += 1
                } catch {
                    failCount += 1
                    if let index = self.files.firstIndex(where: { $0.id == file.id }) {
                        await MainActor.run {
                            self.files[index].state = .failed(error: error.localizedDescription)
                        }
                    }
                }
            }

            await MainActor.run {
                self.batchState = .completed(successful: successCount, failed: failCount)

                // Generate warning message for skipped segments with details
                if !self.skippedSegmentTexts.isEmpty {
                    let count = self.skippedSegmentTexts.count
                    // Truncate each segment text for display (first 50 chars)
                    let truncatedTexts = self.skippedSegmentTexts.map { text in
                        if text.count > 50 {
                            return String(text.prefix(50)) + "..."
                        }
                        return text
                    }
                    let segmentList = truncatedTexts
                        .enumerated()
                        .map { index, text in "[\(index + 1)] \(text)" }
                        .joined(separator: "\n")

                    self.warningMessage = String(
                        localized: "\(count) segment(s) could not be processed by AI due to content restrictions:\n\(segmentList)"
                    )
                }
            }
        }

        await processingTask?.value
    }

    /// Cancel ongoing processing
    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        batchState = .cancelled
    }

    /// Open output directory in Finder
    func openOutputDirectory() {
        NSWorkspace.shared.open(outputDirectory)
    }

    /// Set the translation session (provided by SwiftUI translationTask)
    func setTranslationSession(_ session: Any) async {
        await translationService.setSession(session)
    }

    /// Invalidate the translation session (call when view disappears)
    func invalidateTranslationSession() async {
        await translationService.invalidateSession()
    }

    // MARK: - Private Methods

    private func getMediaDuration(_ url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return 0
        }
    }

    private func processFile(_ file: MediaFile) async throws {
        guard let index = files.firstIndex(where: { $0.id == file.id }) else {
            throw MediaImportError.fileNotFound(file.fileName)
        }

        // Resolve security-scoped bookmark if available
        var resolvedURL = file.url
        var isStale = false
        var hasSecurityAccess = false

        if let bookmarkData = file.bookmarkData {
            do {
                resolvedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                hasSecurityAccess = resolvedURL.startAccessingSecurityScopedResource()
            } catch {
                throw MediaImportError.accessDenied(file.fileName)
            }
        }

        defer {
            if hasSecurityAccess {
                resolvedURL.stopAccessingSecurityScopedResource()
            }
        }

        // Update state to processing
        files[index].state = .processing(progress: 0.0)

        // Extract audio from media file
        let audioURL = try await extractAudio(from: resolvedURL)

        files[index].state = .processing(progress: 0.05)

        // Transcribe audio with progress updates (5% - 50%)
        let segments = try await transcribeAudio(audioURL, for: file) { [weak self] progress in
            guard let self else { return }
            // Map transcription progress (0.0 - 1.0) to (0.05 - 0.50)
            let mappedProgress = 0.05 + (progress * 0.45)
            if let idx = self.files.firstIndex(where: { $0.id == file.id }) {
                self.files[idx].state = .processing(progress: mappedProgress)
            }
        }

        files[index].state = .processing(progress: 0.5)

        // Translate segments
        let translatedSegments = try await translateSegments(segments)

        files[index].state = .processing(progress: 0.8)

        // Generate subtitle file
        let outputURL = try await generateSubtitles(from: translatedSegments, for: file)

        // Update state to completed
        files[index].state = .completed
        files[index].outputURL = outputURL

        // Clean up temporary audio file
        try? FileManager.default.removeItem(at: audioURL)
    }

    private func extractAudio(from url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)

        // Check if already audio-only
        do {
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            guard !tracks.isEmpty else {
                throw MediaImportError.transcriptionFailed("No audio track found")
            }
        } catch {
            throw MediaImportError.transcriptionFailed(error.localizedDescription)
        }

        // For audio files, return the original URL
        let videoTracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
        if videoTracks.isEmpty {
            return url
        }

        // For video files, extract audio to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("m4a")

        // Use AVAssetExportSession to extract audio
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw MediaImportError.transcriptionFailed("Cannot create export session")
        }

        exportSession.audioTimePitchAlgorithm = .spectral

        do {
            try await exportSession.export(to: tempURL, as: .m4a)
        } catch {
            throw MediaImportError.transcriptionFailed("Audio extraction failed: \(error.localizedDescription)")
        }

        return tempURL
    }

    private func transcribeAudio(
        _ audioURL: URL,
        for file: MediaFile,
        progressHandler: @escaping @MainActor (Double) -> Void
    ) async throws -> [Segment] {
        // Use macOS 26 SpeechTranscriber for on-device, offline transcription
        // Find the matching locale using built-in API
        guard let actualLocale = await SpeechTranscriber.supportedLocale(equivalentTo: sourceLocale) else {
            throw MediaImportError.transcriptionFailed("Language not supported: \(sourceLocale.identifier)")
        }

        // Create transcriber for file processing with word-level timing
        // Use .timeIndexedTranscriptionWithAlternatives preset for media import:
        // - More accurate (no volatile/fast results)
        // - Has alternativeTranscriptions for better recognition
        // - Has audioTimeRange for subtitle timing and pause-based segmentation
        let transcriber = SpeechTranscriber(
            locale: actualLocale,
            preset: .timeIndexedTranscriptionWithAlternatives
        )

        // Check and download model if needed
        if let downloader = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await downloader.downloadAndInstall()
        }

        // Create analyzer with the transcriber
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        // Note: Voice analytics via SFSpeechRecognizer has been disabled due to unreliable pitch data.
        // The acousticFeatureValuePerFrame arrays often return empty/zero values, causing
        // incorrect speaker change detection. Using pause-based segmentation only.

        // Open audio file first to get source format
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: audioURL)
        } catch {
            throw MediaImportError.transcriptionFailed("Cannot open audio file: \(error.localizedDescription)")
        }

        let sourceFormat = audioFile.processingFormat
        let sourceSampleRate = sourceFormat.sampleRate

        // Get the optimal audio format considering the source format
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber],
            considering: sourceFormat
        ) else {
            throw MediaImportError.transcriptionFailed("Cannot determine audio format")
        }

        // Create buffer converter
        let bufferConverter = SpeechBufferConverter()

        // Read audio in chunks and feed to analyzer
        let chunkSize = AVAudioFrameCount(sourceSampleRate) // 1 second chunks at source rate

        // Use makeStream pattern for better control
        let (audioStream, audioStreamContinuation) = AsyncStream.makeStream(of: AnalyzerInput.self)

        // Capture values for detached task
        let totalFrames = audioFile.length
        let capturedSourceFormat = sourceFormat
        let capturedAnalyzerFormat = analyzerFormat
        let capturedChunkSize = chunkSize

        // Start audio reading in a DETACHED task to avoid main actor blocking
        let audioTask = Task.detached { [bufferConverter] in
            var currentFrame: AVAudioFramePosition = 0

            // Re-open the file in detached context
            guard let detachedAudioFile = try? AVAudioFile(forReading: audioURL) else {
                audioStreamContinuation.finish()
                return
            }

            while currentFrame < totalFrames {
                let framesToRead = min(capturedChunkSize, AVAudioFrameCount(totalFrames - currentFrame))

                guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: capturedSourceFormat, frameCapacity: framesToRead) else {
                    break
                }

                do {
                    try detachedAudioFile.read(into: sourceBuffer, frameCount: framesToRead)

                    if let pcmBuffer = try? AudioBufferConverter.convertToSpeechFormat(
                        sourceBuffer,
                        targetFormat: capturedAnalyzerFormat,
                        converter: bufferConverter
                    ) {
                        audioStreamContinuation.yield(AnalyzerInput(buffer: pcmBuffer))
                    }

                    currentFrame += AVAudioFramePosition(framesToRead)

                    // Report progress on main actor
                    let progress = Double(currentFrame) / Double(totalFrames)
                    await progressHandler(progress)
                } catch {
                    break
                }
            }
            audioStreamContinuation.finish()
        }

        // Start collecting results BEFORE starting analyzer
        let resultsTask = createTranscriptionResultsTask(for: transcriber)

        // Start analyzer with audio stream (non-blocking)
        do {
            try await analyzer.start(inputSequence: audioStream)
        } catch {
            audioTask.cancel()
            resultsTask.cancel()
            throw MediaImportError.transcriptionFailed("Failed to start analyzer: \(error.localizedDescription)")
        }

        // Wait for audio reading to complete
        await audioTask.value

        // Signal end of input
        try? await analyzer.finalizeAndFinishThroughEndOfInput()

        // Wait for transcription results
        let transcriptionData = await resultsTask.value

        // Convert to Segments using Apple Intelligence
        return try await convertTranscriptionToSegments(
            transcriptionData,
            fileDuration: file.duration
        )
    }

    /// Create a detached task to collect transcription results
    nonisolated private func createTranscriptionResultsTask(
        for transcriber: SpeechTranscriber
    ) -> Task<[TranscriptionData], Never> {
        Task.detached { () -> [TranscriptionData] in
            var collectedData: [TranscriptionData] = []
            do {
                for try await result in transcriber.results {
                    let textString = String(result.text.characters)
                    guard !textString.isEmpty, result.isFinal else { continue }

                    // Extract word-level timing from AttributedString runs
                    // audioTimeRange is only available on final results
                    var wordTimings: [WordTiming] = []
                    for run in result.text.runs {
                        let runText = String(result.text[run.range].characters)
                        guard !runText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

                        if let timeRange = run.audioTimeRange {
                            wordTimings.append(WordTiming(
                                text: runText,
                                startTime: CMTimeGetSeconds(timeRange.start),
                                endTime: CMTimeGetSeconds(timeRange.end)
                            ))
                        }
                    }

                    collectedData.append(TranscriptionData(
                        text: textString,
                        startTime: CMTimeGetSeconds(result.range.start),
                        endTime: CMTimeGetSeconds(result.range.end),
                        wordTimings: wordTimings
                    ))
                }
            } catch {
                // Results stream ended
            }
            return collectedData
        }
    }

    /// Combine adjacent transcription data chunks into larger units for better AI segmentation
    /// Uses pause detection to determine natural boundaries
    private func combineTranscriptionData(_ data: [TranscriptionData]) -> [TranscriptionData] {
        guard !data.isEmpty else { return [] }

        // Pause threshold in seconds - if gap between chunks is larger, start a new combined chunk
        let pauseThreshold: TimeInterval = 0.8

        var combined: [TranscriptionData] = []
        var currentText = ""
        var currentWordTimings: [WordTiming] = []
        var currentStartTime: TimeInterval = 0
        var currentEndTime: TimeInterval = 0

        for (index, item) in data.enumerated() {
            let itemText = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !itemText.isEmpty else { continue }

            if currentText.isEmpty {
                // Start new combined chunk
                currentText = itemText
                currentWordTimings = item.wordTimings
                currentStartTime = item.startTime
                currentEndTime = item.endTime
            } else {
                // Check if there's a significant pause since last chunk
                let gap = item.startTime - currentEndTime

                if gap > pauseThreshold {
                    // Significant pause - save current and start new
                    combined.append(TranscriptionData(
                        text: currentText,
                        startTime: currentStartTime,
                        endTime: currentEndTime,
                        wordTimings: currentWordTimings
                    ))

                    currentText = itemText
                    currentWordTimings = item.wordTimings
                    currentStartTime = item.startTime
                    currentEndTime = item.endTime
                } else {
                    // No significant pause - combine with current
                    currentText += " " + itemText
                    currentWordTimings += item.wordTimings
                    currentEndTime = item.endTime
                }
            }

            // Also save if this is the last item
            if index == data.count - 1 && !currentText.isEmpty {
                combined.append(TranscriptionData(
                    text: currentText,
                    startTime: currentStartTime,
                    endTime: currentEndTime,
                    wordTimings: currentWordTimings
                ))
            }
        }

        return combined
    }

    /// Convert transcription data to Segments, respecting subtitle character limits
    /// Uses AI segmentation for natural sentence boundary detection
    private func convertTranscriptionToSegments(
        _ transcriptionData: [TranscriptionData],
        fileDuration: TimeInterval
    ) async throws -> [Segment] {
        // First, combine small fragments into larger chunks based on pauses
        let combinedData = combineTranscriptionData(transcriptionData)

        // Get subtitle character limit for source language
        let maxChars = SubtitleStandards.maxCharactersPerEvent(for: sourceLocale)

        var segments: [Segment] = []

        for data in combinedData {
            let text = data.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            // Convert word timings
            let wordTimings = data.wordTimings.map { timing in
                WordTimingInfo(
                    text: timing.text,
                    startTime: timing.startTime,
                    endTime: timing.endTime
                )
            }

            // Always use AI segmentation for proper sentence boundary detection
            // AI will split at natural boundaries while respecting character limits
            let result = await intelligentSegmentationService.segmentTranscript(
                text: text,
                wordTimings: wordTimings,
                sourceLocale: sourceLocale,
                maxCharsPerSegment: maxChars
            )

            // Convert TimedSegments to Segments
            for timedSegment in result.segments {
                segments.append(Segment(
                    startTime: timedSegment.startTime,
                    endTime: timedSegment.endTime,
                    originalText: timedSegment.text,
                    sourceLocale: sourceLocale,
                    isFinal: true
                ))
            }

            // Track skipped texts for user notification
            if result.hasSkippedSegments {
                skippedSegmentTexts.append(contentsOf: result.skippedTexts)
            }
        }

        // If no segments, create placeholder
        if segments.isEmpty {
            segments.append(Segment(
                startTime: 0,
                endTime: min(fileDuration, 5.0),
                originalText: String(localized: "(No speech detected)"),
                sourceLocale: sourceLocale,
                isFinal: true
            ))
        }

        return segments
    }

    private func translateSegments(_ segments: [Segment]) async throws -> [Segment] {
        // Check if translation session is still available before starting
        guard translationService.hasSession else {
            throw MediaImportError.translationFailed("Translation session is no longer available. Please try again.")
        }

        var translatedSegments: [Segment] = []

        for segment in segments {
            // Check session before each translation (in case view disappeared during processing)
            guard translationService.hasSession else {
                throw MediaImportError.translationFailed("Translation session expired during processing.")
            }

            do {
                let translatedText = try await translationService.translate(
                    segment.originalText,
                    from: sourceLocale,
                    to: targetLocale
                )

                // Create a new segment with the translation
                let translatedSegment = Segment(
                    startTime: segment.startTime,
                    endTime: segment.endTime,
                    originalText: segment.originalText,
                    translatedText: translatedText,
                    sourceLocale: segment.sourceLocale,
                    targetLocale: targetLocale,
                    isFinal: segment.isFinal
                )
                translatedSegments.append(translatedSegment)
            } catch TranslationError.sessionInvalidated {
                // Session became invalid - propagate error to stop processing
                throw MediaImportError.translationFailed("Translation session expired. Please try again.")
            } catch TranslationError.noSession {
                // No session available - propagate error
                throw MediaImportError.translationFailed("Translation session is not available. Please try again.")
            } catch {
                // On other translation failures, keep original text
                let fallbackSegment = Segment(
                    startTime: segment.startTime,
                    endTime: segment.endTime,
                    originalText: segment.originalText,
                    translatedText: segment.originalText,
                    sourceLocale: segment.sourceLocale,
                    targetLocale: targetLocale,
                    isFinal: segment.isFinal
                )
                translatedSegments.append(fallbackSegment)
            }
        }

        return translatedSegments
    }

    private func generateSubtitles(from segments: [Segment], for file: MediaFile) async throws -> URL {
        // Generate output filename using the display filename (without UUID prefix)
        let baseName = (file.fileName as NSString).deletingPathExtension
        let outputFileName = "\(baseName).\(exportOptions.format.rawValue)"
        let outputURL = outputDirectory.appending(path: outputFileName)

        // Ensure output directory exists
        try? FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        // Use subtitle export service
        do {
            let tempURL = try await subtitleExportService.export(
                segments: segments,
                options: exportOptions
            )

            // Move to final destination
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: outputURL)

            return outputURL
        } catch {
            throw MediaImportError.exportFailed(error.localizedDescription)
        }
    }

    /// Extract original filename from a potentially UUID-prefixed filename
    /// Temp files from drag-drop are saved as "UUID_originalFilename"
    private func extractOriginalFilename(from filename: String) -> String {
        // UUID format: 8-4-4-4-12 = 36 characters, followed by underscore
        // Example: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890_original.mp4"
        let uuidPrefixLength = 37 // 36 chars + 1 underscore

        if filename.count > uuidPrefixLength {
            let potentialUUID = String(filename.prefix(36))
            // Check if it looks like a UUID (contains hyphens at expected positions)
            if potentialUUID.contains("-"),
               filename[filename.index(filename.startIndex, offsetBy: 36)] == "_" {
                return String(filename.dropFirst(uuidPrefixLength))
            }
        }

        // Not a UUID-prefixed filename, return as-is
        return filename
    }

}
