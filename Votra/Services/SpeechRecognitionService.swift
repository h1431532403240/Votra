//
//  SpeechRecognitionService.swift
//  Votra
//
//  Service for real-time speech-to-text transcription using macOS 26 Speech framework.
//

@preconcurrency import AVFoundation
import CoreMedia
import Foundation
import Speech

// MARK: - Supporting Types

/// State of the speech recognition service
nonisolated enum SpeechRecognitionState: Equatable, Sendable {
    case idle
    case starting
    case listening
    case processing
    case error(message: String)
}

/// Result of a transcription operation
nonisolated struct TranscriptionResult: Sendable, Equatable {
    let id: UUID
    let text: String
    let segments: [TranscriptionSegment]
    let isFinal: Bool
    let confidence: Float
    let locale: Locale
    let timestamp: TimeInterval
}

/// A segment within a transcription result
nonisolated struct TranscriptionSegment: Sendable, Equatable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Float

    var duration: TimeInterval {
        endTime - startTime
    }
}

/// Language availability status for speech recognition
nonisolated enum LanguageAvailability: Sendable, Equatable {
    case available
    case downloadRequired(size: Int64)
    case downloading(progress: Double)
    case unsupported
}

/// Progress of a language model download
nonisolated struct DownloadProgress: Sendable {
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let isComplete: Bool

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesDownloaded) / Double(totalBytes)
    }
}

// MARK: - Errors

/// Errors that can occur during speech recognition
nonisolated enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case languageNotSupported(Locale)
    case languageNotDownloaded(Locale)
    case downloadFailed(underlying: Error)
    case recognitionFailed(underlying: Error)
    case noAudioInput
    case alreadyRunning

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return String(localized: "Speech recognition permission is required")
        case .languageNotSupported(let locale):
            return String(localized: "Speech recognition is not supported for \(locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "") ?? "this language")")
        case .languageNotDownloaded(let locale):
            return String(localized: "Language pack for \(locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "") ?? "this language") needs to be downloaded")
        case .downloadFailed:
            return String(localized: "Failed to download language pack")
        case .recognitionFailed:
            return String(localized: "Speech recognition failed")
        case .noAudioInput:
            return String(localized: "No audio input received")
        case .alreadyRunning:
            return String(localized: "Speech recognition is already active")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return String(localized: "Open System Settings > Privacy & Security > Speech Recognition and enable access for Votra")
        case .languageNotDownloaded:
            return String(localized: "Go to Settings > Languages to download the required language pack")
        case .downloadFailed:
            return String(localized: "Check your internet connection and try again")
        default:
            return nil
        }
    }
}

// MARK: - Protocol

/// Protocol for speech recognition services
@MainActor
protocol SpeechRecognitionServiceProtocol: Sendable {
    /// Current state of speech recognition
    var state: SpeechRecognitionState { get }

    /// Currently configured source language
    var sourceLocale: Locale { get }

    /// Start speech recognition for the specified locale
    /// - Parameters:
    ///   - locale: The language to recognize
    ///   - accurateMode: When true, uses more accurate but slower recognition
    /// - Returns: An async stream of transcription results
    func startRecognition(locale: Locale, accurateMode: Bool) async throws -> AsyncStream<TranscriptionResult>

    /// Stop speech recognition
    func stopRecognition() async

    /// Process an audio buffer (called by audio capture service)
    /// - Parameter buffer: The PCM buffer to process
    func processAudio(_ buffer: AVAudioPCMBuffer) async throws

    /// Check if a language is available for recognition
    func isLanguageAvailable(_ locale: Locale) async -> LanguageAvailability

    /// Download language model for offline use
    func downloadLanguage(_ locale: Locale) async throws -> AsyncStream<DownloadProgress>

    /// Get list of supported languages
    func supportedLanguages() async -> [Locale]
}

// MARK: - Factory

/// Factory function to create the appropriate SpeechRecognitionService
/// Uses StubSpeechRecognitionService on CI to avoid audio hardware access and process hangs
@MainActor
func createSpeechRecognitionService(identifier: String) -> any SpeechRecognitionServiceProtocol {
    // Detect CI environment (GitHub Actions sets CI=true)
    // This allows local tests to use real hardware, but CI uses stub
    if ProcessInfo.processInfo.environment["CI"] == "true" {
        return StubSpeechRecognitionService(identifier: identifier)
    }
    return SpeechRecognitionService(identifier: identifier)
}

// MARK: - Stub for CI/Testing

/// Stub implementation that doesn't access audio hardware or speech framework
/// Used in CI environments to prevent HALC polling hangs
@MainActor
@Observable
final class StubSpeechRecognitionService: SpeechRecognitionServiceProtocol {
    private(set) var state: SpeechRecognitionState = .idle
    private(set) var sourceLocale: Locale = .current

    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }

    func startRecognition(locale: Locale, accurateMode: Bool) async throws -> AsyncStream<TranscriptionResult> {
        sourceLocale = locale
        state = .listening
        // Return an empty stream that finishes immediately
        return AsyncStream { $0.finish() }
    }

    func stopRecognition() async {
        state = .idle
    }

    func processAudio(_ buffer: AVAudioPCMBuffer) async throws {
        // No-op - don't process audio in stub
    }

    func isLanguageAvailable(_ locale: Locale) async -> LanguageAvailability {
        .available
    }

    func downloadLanguage(_ locale: Locale) async throws -> AsyncStream<DownloadProgress> {
        AsyncStream { continuation in
            continuation.yield(DownloadProgress(bytesDownloaded: 100, totalBytes: 100, isComplete: true))
            continuation.finish()
        }
    }

    func supportedLanguages() async -> [Locale] {
        [Locale(identifier: "en_US"), Locale(identifier: "zh-Hant_TW")]
    }
}

// MARK: - Implementation

/// Speech recognition service using macOS 26 Speech framework
@MainActor
@Observable
final class SpeechRecognitionService: SpeechRecognitionServiceProtocol {
    private(set) var state: SpeechRecognitionState = .idle
    private(set) var sourceLocale: Locale = .current

    /// Identifier for logging purposes
    let identifier: String

    private var speechAnalyzer: SpeechAnalyzer?
    private var speechTranscriber: SpeechTranscriber?
    private var recognitionContinuation: AsyncStream<TranscriptionResult>.Continuation?
    private var transcriptionTask: Task<Void, Never>?
    private var audioInputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var audioBufferCount: Int = 0

    /// The optimal audio format for the SpeechAnalyzer (from bestAvailableAudioFormat)
    private var analyzerFormat: AVAudioFormat?

    /// Reusable buffer converter for audio format conversion
    private let bufferConverter = SpeechBufferConverter()

    init(identifier: String = "default") {
        self.identifier = identifier
    }

    // MARK: - Public Methods

    func startRecognition(locale: Locale, accurateMode: Bool = false) async throws -> AsyncStream<TranscriptionResult> {
        print("[Votra] [\(identifier)] Starting speech recognition for locale: \(locale.identifier), accurateMode: \(accurateMode)")
        guard state == .idle else {
            throw SpeechRecognitionError.alreadyRunning
        }

        // Check permission
        let authorized = await requestPermission()
        guard authorized else {
            throw SpeechRecognitionError.permissionDenied
        }

        // Check language availability
        let availability = await isLanguageAvailable(locale)
        switch availability {
        case .unsupported:
            throw SpeechRecognitionError.languageNotSupported(locale)
        case .downloadRequired, .downloading:
            throw SpeechRecognitionError.languageNotDownloaded(locale)
        case .available:
            break
        }

        state = .starting
        sourceLocale = locale

        // Use built-in locale matching (Apple recommended approach)
        guard let actualLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            throw SpeechRecognitionError.languageNotSupported(locale)
        }

        // Create transcriber with appropriate preset based on accuracy mode
        // - .transcription: Basic, accurate transcription (better for accuracy)
        // - .progressiveTranscription: Immediate transcription (better for real-time)
        let preset: SpeechTranscriber.Preset = accurateMode ? .transcription : .progressiveTranscription
        let transcriber = SpeechTranscriber(
            locale: actualLocale,
            preset: preset
        )
        self.speechTranscriber = transcriber

        // Download model if needed
        if let downloader = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try? await downloader.downloadAndInstall()
        }

        // Create analyzer with the transcriber module
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.speechAnalyzer = analyzer

        // Note: analyzerFormat will be lazily initialized in processAudio()
        // using bestAvailableAudioFormat(considering:) with the actual source format

        // Create audio input stream using makeStream (Apple recommended pattern)
        let (audioInputStream, audioInputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
        self.audioInputBuilder = audioInputBuilder

        // Start the analyzer with the audio stream
        Task {
            do {
                try await analyzer.start(inputSequence: audioInputStream)
            } catch {
                print("[Votra] [\(identifier)] Analyzer start failed: \(error)")
            }
        }

        return AsyncStream { continuation in
            self.recognitionContinuation = continuation

            // Start listening to transcription results
            self.transcriptionTask = Task {
                self.state = .listening

                do {
                    var transcriptionCount = 0
                    for try await result in transcriber.results {
                        // Extract text from AttributedString
                        let textString = String(result.text.characters)
                        transcriptionCount += 1

                        print("[Votra] [\(self.identifier)] Transcription #\(transcriptionCount): '\(textString)' (final: \(result.isFinal))")

                        // Create a single segment from the range
                        let startTime = CMTimeGetSeconds(result.range.start)
                        let endTime = CMTimeGetSeconds(result.range.end)

                        let segment = TranscriptionSegment(
                            text: textString,
                            startTime: startTime,
                            endTime: endTime,
                            confidence: 1.0  // SpeechTranscriber doesn't provide confidence
                        )

                        let transcriptionResult = TranscriptionResult(
                            id: UUID(),
                            text: textString,
                            segments: [segment],
                            isFinal: result.isFinal,
                            confidence: 1.0,  // SpeechTranscriber doesn't provide confidence
                            locale: locale,
                            timestamp: Date().timeIntervalSinceReferenceDate
                        )
                        continuation.yield(transcriptionResult)
                    }
                    print("[Votra] [\(self.identifier)] Transcription stream ended, total: \(transcriptionCount)")
                } catch {
                    // Recognition ended, possibly due to error
                    print("[Votra] [\(self.identifier)] Transcription error: \(error)")
                }

                continuation.finish()
            }

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    await self?.stopRecognition()
                }
            }
        }
    }

    func stopRecognition() async {
        // Finish the audio input stream
        audioInputBuilder?.finish()
        audioInputBuilder = nil

        // Finalize the analyzer
        try? await speechAnalyzer?.finalizeAndFinishThroughEndOfInput()

        transcriptionTask?.cancel()
        transcriptionTask = nil
        recognitionContinuation?.finish()
        recognitionContinuation = nil

        speechAnalyzer = nil
        speechTranscriber = nil
        analyzerFormat = nil
        audioBufferCount = 0

        state = .idle
    }

    func processAudio(_ buffer: AVAudioPCMBuffer) async throws {
        guard audioInputBuilder != nil else {
            throw SpeechRecognitionError.noAudioInput
        }

        guard state == .listening else {
            return
        }

        guard let transcriber = speechTranscriber else {
            throw SpeechRecognitionError.noAudioInput
        }

        // Lazily initialize analyzerFormat on first buffer using source format (Apple recommended)
        // This allows the system to choose the optimal target format based on the actual source
        if analyzerFormat == nil {
            let sourceFormat = buffer.format
            analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                compatibleWith: [transcriber],
                considering: sourceFormat
            )
            print("[Votra] [\(identifier)] Analyzer format initialized (considering source: \(sourceFormat)): \(String(describing: analyzerFormat))")
        }

        guard let analyzerFormat else {
            throw SpeechRecognitionError.noAudioInput
        }

        audioBufferCount += 1
        if audioBufferCount % 100 == 1 {
            print("[Votra] [\(identifier)] Processed \(audioBufferCount) audio buffers (direct)")
        }

        // Convert directly to the optimal format - no intermediate AudioBuffer conversion
        let convertedBuffer = try AudioBufferConverter.convertToSpeechFormat(
            buffer,
            targetFormat: analyzerFormat,
            converter: bufferConverter
        )

        // Create AnalyzerInput and feed to the analyzer
        let analyzerInput = AnalyzerInput(buffer: convertedBuffer)
        audioInputBuilder?.yield(analyzerInput)
    }

    func isLanguageAvailable(_ locale: Locale) async -> LanguageAvailability {
        // Check if locale is supported using built-in method (Apple recommended)
        guard let actualLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            return .unsupported
        }

        // Quick check: is locale already installed?
        let installedLocales = await SpeechTranscriber.installedLocales
        let isInstalled = installedLocales.contains { installed in
            installed.identifier == actualLocale.identifier
        }

        if isInstalled {
            return .available
        }

        // Not installed - use AssetInventory to get accurate download size
        let transcriber = SpeechTranscriber(locale: actualLocale, preset: .progressiveTranscription)
        if let downloader = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            let size = downloader.progress.totalUnitCount
            return .downloadRequired(size: size > 0 ? size : 100_000_000)
        }

        return .downloadRequired(size: 100_000_000)
    }

    func downloadLanguage(_ locale: Locale) async throws -> AsyncStream<DownloadProgress> {
        // Find the actual supported locale using built-in method (Apple recommended)
        let actualLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) ?? locale

        // Create a transcriber for the locale to use with AssetInventory
        let transcriber = SpeechTranscriber(locale: actualLocale, preset: .progressiveTranscription)

        return AsyncStream { continuation in
            Task {
                do {
                    guard let downloader = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) else {
                        // Already installed
                        continuation.yield(DownloadProgress(bytesDownloaded: 1, totalBytes: 1, isComplete: true))
                        continuation.finish()
                        return
                    }

                    // Start download and monitor progress
                    let progress = downloader.progress

                    // Poll progress changes
                    Task {
                        while !progress.isFinished {
                            let downloadProgress = DownloadProgress(
                                bytesDownloaded: progress.completedUnitCount,
                                totalBytes: progress.totalUnitCount,
                                isComplete: progress.isFinished
                            )
                            continuation.yield(downloadProgress)
                            try? await Task.sleep(for: .milliseconds(100))
                        }

                        continuation.yield(DownloadProgress(
                            bytesDownloaded: progress.totalUnitCount,
                            totalBytes: progress.totalUnitCount,
                            isComplete: true
                        ))
                    }

                    try await downloader.downloadAndInstall()
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    func supportedLanguages() async -> [Locale] {
        await SpeechTranscriber.supportedLocales
    }

    // MARK: - Private Methods

    private func requestPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()

        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }
}
