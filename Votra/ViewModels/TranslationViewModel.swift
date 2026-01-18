//
//  TranslationViewModel.swift
//  Votra
//
//  Core ViewModel orchestrating the real-time translation pipeline:
//  Audio Capture → Speech Recognition → Translation → Speech Synthesis
//

import Foundation
import SwiftData

// MARK: - Supporting Types

/// State of the translation pipeline
nonisolated enum TranslationPipelineState: Equatable, Sendable {
    case idle
    case starting
    case active
    case paused
    case error(message: String)
}

/// A message in the conversation
nonisolated struct ConversationMessage: Identifiable, Sendable, Equatable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let sourceLocaleIdentifier: String
    let targetLocaleIdentifier: String
    let source: AudioSource
    let timestamp: Date
    let isFinal: Bool

    /// Source locale
    var sourceLocale: Locale {
        Locale(identifier: sourceLocaleIdentifier)
    }

    /// Target locale
    var targetLocale: Locale {
        Locale(identifier: targetLocaleIdentifier)
    }

    /// Whether this message is from the user (microphone)
    var isFromUser: Bool {
        source == .microphone
    }

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLocale: Locale,
        targetLocale: Locale,
        source: AudioSource,
        timestamp: Date,
        isFinal: Bool
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLocaleIdentifier = sourceLocale.identifier
        self.targetLocaleIdentifier = targetLocale.identifier
        self.source = source
        self.timestamp = timestamp
        self.isFinal = isFinal
    }
}

// MARK: - Message Grouping

extension Array where Element == ConversationMessage {
    /// Groups consecutive messages by speaker for visual grouping.
    /// Returns array of tuples: (stable group ID based on first message, messages in group)
    func groupedBySpeaker() -> [(String, [ConversationMessage])] {
        var groups: [(String, [ConversationMessage])] = []
        var currentGroup: [ConversationMessage] = []
        var currentSource: AudioSource?

        for message in self {
            if currentSource == message.source {
                currentGroup.append(message)
            } else {
                if !currentGroup.isEmpty, let firstMessage = currentGroup.first {
                    groups.append((firstMessage.id.uuidString, currentGroup))
                }
                currentGroup = [message]
                currentSource = message.source
            }
        }

        if !currentGroup.isEmpty, let firstMessage = currentGroup.first {
            groups.append((firstMessage.id.uuidString, currentGroup))
        }

        return groups
    }
}

/// Audio input mode for translation
nonisolated enum AudioInputMode: String, Sendable, CaseIterable {
    /// Only capture system audio (remote participants)
    case systemAudioOnly
    /// Only capture microphone (user's voice)
    case microphoneOnly
    /// Capture both sources (two-way conversation)
    case both

    var localizedName: String {
        switch self {
        case .systemAudioOnly:
            return String(localized: "System Audio Only")
        case .microphoneOnly:
            return String(localized: "Microphone Only")
        case .both:
            return String(localized: "Both")
        }
    }

    var description: String {
        switch self {
        case .systemAudioOnly:
            return String(localized: "Translate remote participants only")
        case .microphoneOnly:
            return String(localized: "Translate your voice only")
        case .both:
            return String(localized: "Two-way conversation translation")
        }
    }

    /// Audio sources to use for this mode
    var audioSources: Set<AudioSource> {
        switch self {
        case .systemAudioOnly:
            return [.systemAudio]
        case .microphoneOnly:
            return [.microphone]
        case .both:
            return [.microphone, .systemAudio]
        }
    }
}

/// Configuration for the translation pipeline
nonisolated struct TranslationConfiguration: Sendable, Equatable {
    // MARK: - Type Properties

    static let `default` = TranslationConfiguration()

    /// Supported locales for translation
    private static let supportedLocales = Set([
        "en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de", "it", "pt"
    ])

    // MARK: - Instance Properties

    var sourceLocaleIdentifier: String
    var targetLocaleIdentifier: String
    var autoSpeak: Bool
    var speechRate: Float
    var voicePreference: VoicePreference
    var audioInputMode: AudioInputMode

    var sourceLocale: Locale {
        get { Locale(identifier: sourceLocaleIdentifier) }
        set { sourceLocaleIdentifier = newValue.identifier }
    }

    var targetLocale: Locale {
        get { Locale(identifier: targetLocaleIdentifier) }
        set { targetLocaleIdentifier = newValue.identifier }
    }

    // MARK: - Initialization

    init(
        sourceLocale: Locale? = nil,
        targetLocale: Locale? = nil,
        autoSpeak: Bool = false,
        speechRate: Float = 0.5,
        voicePreference: VoicePreference = .system,
        audioInputMode: AudioInputMode = .systemAudioOnly
    ) {
        let target = targetLocale ?? Self.systemTargetLocale()
        let source = sourceLocale ?? Self.defaultSourceLocale(targetLocale: target)

        self.sourceLocaleIdentifier = source.identifier
        self.targetLocaleIdentifier = target.identifier
        self.autoSpeak = autoSpeak
        self.speechRate = speechRate
        self.voicePreference = voicePreference
        self.audioInputMode = audioInputMode
    }

    // MARK: - Type Methods

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
}

// MARK: - TranslationViewModel

/// Core ViewModel orchestrating audio → speech → translation → synthesis pipeline
@MainActor
@Observable
final class TranslationViewModel {
    // MARK: - Published State

    /// Current state of the translation pipeline
    private(set) var state: TranslationPipelineState = .idle

    /// Current configuration
    var configuration: TranslationConfiguration = .default

    /// Messages in the current conversation
    private(set) var messages: [ConversationMessage] = []

    /// Current interim transcription (not yet final)
    private(set) var interimTranscription: String?

    /// Current interim translation (not yet final)
    private(set) var interimTranslation: String?

    /// Source of the current interim message
    private(set) var interimSource: AudioSource?

    /// Error that occurred during translation
    private(set) var lastError: Error?

    /// Required permission type when a permission error occurs
    var requiredPermissionType: PermissionType? {
        guard let error = lastError else { return nil }
        return extractPermissionType(from: error)
    }

    /// Whether the microphone is currently capturing
    var isMicrophoneActive: Bool {
        audioCaptureService.state == .capturingMicrophone ||
        audioCaptureService.state == .capturingBoth
    }

    /// Whether system audio is currently capturing
    var isSystemAudioActive: Bool {
        audioCaptureService.state == .capturingSystemAudio ||
        audioCaptureService.state == .capturingBoth
    }

    /// Whether the translation session is ready
    var hasTranslationSession: Bool {
        translationService.hasSession
    }

    /// Available audio sources for system audio capture
    var availableAudioSources: [AudioSourceInfo] {
        audioCaptureService.availableAudioSources
    }

    /// Currently selected audio source for system audio capture
    var selectedAudioSource: AudioSourceInfo {
        audioCaptureService.selectedAudioSource
    }

    // MARK: - Services

    private var audioCaptureService: any AudioCaptureServiceProtocol
    /// Speech recognition for microphone (user's voice in source language)
    private var microphoneSpeechService: any SpeechRecognitionServiceProtocol
    /// Speech recognition for system audio (remote participant in target language)
    private var systemAudioSpeechService: any SpeechRecognitionServiceProtocol
    private var translationService: any TranslationServiceProtocol
    private var speechSynthesisService: any SpeechSynthesisServiceProtocol

    // MARK: - Tasks

    private var microphonePipelineTask: Task<Void, Never>?
    private var systemAudioPipelineTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        audioCaptureService: (any AudioCaptureServiceProtocol)? = nil,
        microphoneSpeechService: (any SpeechRecognitionServiceProtocol)? = nil,
        systemAudioSpeechService: (any SpeechRecognitionServiceProtocol)? = nil,
        translationService: any TranslationServiceProtocol = TranslationService(),
        speechSynthesisService: (any SpeechSynthesisServiceProtocol)? = nil
    ) {
        // Use factories to get appropriate services (stubs in tests, real in production)
        self.audioCaptureService = audioCaptureService ?? createAudioCaptureService()
        self.microphoneSpeechService = microphoneSpeechService ?? SpeechRecognitionService(identifier: "MICROPHONE")
        self.systemAudioSpeechService = systemAudioSpeechService ?? SpeechRecognitionService(identifier: "SYSTEM_AUDIO")
        self.translationService = translationService
        self.speechSynthesisService = speechSynthesisService ?? createSpeechSynthesisService()
    }

    // MARK: - Public Methods

    /// Update the speech rate when configuration changes
    func updateSpeechRate() {
        speechSynthesisService.speechRate = configuration.speechRate
    }

    /// Start the translation pipeline using configured audio input mode
    /// Supports simultaneous microphone + system audio for real-time conversation translation
    func start() async throws {
        // Allow starting from idle, paused, or error states
        switch state {
        case .idle, .paused:
            break
        case .error:
            // Reset state to allow retry after error
            await stop()
        case .starting, .active:
            // Already running or starting
            return
        }

        state = .starting
        lastError = nil

        // Get audio sources based on configured mode
        let sources = configuration.audioInputMode.audioSources

        do {
            // Start pipelines for each requested source
            print("[Votra] Starting pipelines for mode: \(configuration.audioInputMode), sources: \(sources)")
            for source in sources {
                print("[Votra] === Starting pipeline for: \(source) ===")
                try await startPipeline(for: source)
                print("[Votra] === Pipeline started for: \(source) ===")
            }

            state = .active
            print("[Votra] All pipelines started, state is now active")
        } catch {
            // Ensure cleanup on error
            await stop()
            state = .error(message: error.localizedDescription)
            lastError = error
            throw error
        }
    }

    /// Stop the translation pipeline
    func stop() async {
        // Cancel all pipeline tasks
        microphonePipelineTask?.cancel()
        systemAudioPipelineTask?.cancel()
        microphonePipelineTask = nil
        systemAudioPipelineTask = nil

        // Stop all services - both speech recognition instances
        await microphoneSpeechService.stopRecognition()
        await systemAudioSpeechService.stopRecognition()
        await audioCaptureService.stopAllCapture()

        // Clear interim state
        interimTranscription = nil
        interimTranslation = nil
        interimSource = nil

        state = .idle
    }

    /// Pause the translation pipeline
    func pause() async {
        guard state == .active else { return }

        // Stop capturing but keep state
        await audioCaptureService.stopAllCapture()
        await microphoneSpeechService.stopRecognition()
        await systemAudioSpeechService.stopRecognition()

        state = .paused
    }

    /// Resume the translation pipeline
    func resume() async throws {
        guard state == .paused else { return }

        try await start()
    }

    /// Clear all messages from the conversation
    func clearMessages() {
        print("[Votra] clearMessages() called, current count: \(messages.count)")
        messages.removeAll()
        interimTranscription = nil
        interimTranslation = nil
        interimSource = nil
        print("[Votra] clearMessages() finished, new count: \(messages.count)")
    }

    // MARK: - Audio Source Selection

    /// Refresh the list of available audio sources
    func refreshAudioSources() async {
        await audioCaptureService.refreshAudioSources()
    }

    /// Select an audio source for system audio capture
    func selectAudioSource(_ source: AudioSourceInfo) {
        audioCaptureService.selectAudioSource(source)
    }

    /// Manually speak a message
    func speak(_ message: ConversationMessage) async {
        await speechSynthesisService.speak(
            message.translatedText,
            locale: message.targetLocale,
            voicePreference: configuration.voicePreference
        )
    }

    /// Stop speech synthesis
    func stopSpeaking() async {
        await speechSynthesisService.stopSpeaking()
    }

    /// Set the translation session (provided by SwiftUI translationTask)
    func setTranslationSession(_ session: Any) async {
        await translationService.setSession(session)
    }

    /// Request necessary permissions
    func requestPermissions() async -> AudioPermissionStatus {
        await audioCaptureService.requestPermissions()
    }

    /// Request Personal Voice authorization
    func requestPersonalVoiceAuthorization() async -> PersonalVoiceAuthorizationStatus {
        await speechSynthesisService.requestPersonalVoiceAuthorization()
    }

    /// Get supported source languages
    func supportedSourceLanguages() async -> [Locale] {
        await microphoneSpeechService.supportedLanguages()
    }

    /// Get available voices for the target language
    func availableVoices(for locale: Locale) -> [VoiceInfo] {
        speechSynthesisService.availableVoices(for: locale)
    }

    /// Check if a language pair is supported for translation
    func isLanguagePairSupported(source: Locale, target: Locale) async -> Bool {
        await translationService.isLanguagePairSupported(source: source, target: target)
    }

    // MARK: - Private Methods

    /// Recursively extract permission type from error (handles nested errors)
    private func extractPermissionType(from error: Error) -> PermissionType? {
        // Check for AudioCaptureError
        if let captureError = error as? AudioCaptureError {
            switch captureError {
            case .microphonePermissionDenied:
                return .microphone
            case .screenRecordingPermissionDenied:
                return .screenRecording
            case .engineStartFailed(let underlying):
                // Check the underlying error recursively
                return extractPermissionType(from: underlying)
            default:
                break
            }
        }

        // Check for SpeechRecognitionError
        if let speechError = error as? SpeechRecognitionError {
            switch speechError {
            case .permissionDenied:
                return .speechRecognition
            default:
                break
            }
        }

        // Check for VotraError
        if let votraError = error as? VotraError {
            switch votraError {
            case .microphonePermissionDenied:
                return .microphone
            case .screenRecordingPermissionDenied:
                return .screenRecording
            case .speechRecognitionPermissionDenied:
                return .speechRecognition
            default:
                break
            }
        }

        return nil
    }

    private func startPipeline(for source: AudioSource) async throws {
        // Determine locale and speech service for this source
        // Microphone: user speaks source language → translate to target
        // System Audio: remote speaks target language → translate to source
        let (speechLocale, speechService) = source == .microphone
            ? (configuration.sourceLocale, microphoneSpeechService)
            : (configuration.targetLocale, systemAudioSpeechService)

        print("[Votra] Starting pipeline for \(source), locale: \(speechLocale.identifier)")

        // Start audio capture (returns direct PCM buffers)
        let pcmStream = try await audioCaptureService.startCapture(from: source)
        print("[Votra] Audio capture started for \(source)")

        // Start speech recognition (returns transcription stream)
        // Use accurate mode setting from preferences for better recognition accuracy
        let accurateMode = UserPreferences.shared.accurateRecognitionMode
        let transcriptionStream = try await speechService.startRecognition(
            locale: speechLocale,
            accurateMode: accurateMode
        )
        print("[Votra] Speech recognition started for \(source), accurateMode: \(accurateMode)")

        // Create the pipeline task that:
        // 1. Feeds audio buffers to speech recognition
        // 2. Processes transcription results
        let pipelineTask = Task { [weak self] in
            guard let self else { return }

            // Start a task to feed audio directly to speech recognition (no AudioBuffer conversion)
            let audioFeedTask = Task {
                var audioBufferCount = 0
                for await pcmBuffer in pcmStream {
                    guard !Task.isCancelled else { break }
                    audioBufferCount += 1
                    if audioBufferCount % 100 == 1 {
                        print("[Votra] [\(source)] Fed \(audioBufferCount) PCM buffers to speech recognition")
                    }
                    // Feed PCM buffer directly to speech recognition
                    try? await speechService.processAudio(pcmBuffer)
                }
                print("[Votra] [\(source)] Audio feed task ended, total buffers: \(audioBufferCount)")
            }

            // Process transcription results
            var transcriptionCount = 0
            for await result in transcriptionStream {
                guard !Task.isCancelled else { break }
                transcriptionCount += 1
                print("[Votra] [\(source)] Transcription #\(transcriptionCount): '\(result.text)' (final: \(result.isFinal))")
                await self.processTranscriptionResult(result, source: source)
            }
            print("[Votra] [\(source)] Transcription stream ended, total: \(transcriptionCount)")

            audioFeedTask.cancel()
        }

        // Store the task reference
        switch source {
        case .microphone:
            microphonePipelineTask = pipelineTask
        case .systemAudio:
            systemAudioPipelineTask = pipelineTask
        }
    }

    private func processTranscriptionResult(_ result: TranscriptionResult, source: AudioSource) async {
        let sourceLabel = source == .microphone ? "ME (microphone)" : "REMOTE (system audio)"
        print("[Votra] [\(sourceLabel)] Processing transcription: '\(result.text)' (final: \(result.isFinal))")

        // Determine source and target locales based on audio source
        let sourceLocale: Locale
        let targetLocale: Locale

        if source == .microphone {
            // User speaking: translate from source language to target
            sourceLocale = configuration.sourceLocale
            targetLocale = configuration.targetLocale
        } else {
            // Remote participant: translate from target language to source
            sourceLocale = configuration.targetLocale
            targetLocale = configuration.sourceLocale
        }

        // Update interim state for non-final results
        if !result.isFinal {
            interimTranscription = result.text
            interimSource = source

            // Attempt interim translation
            if let translation = try? await translationService.translate(
                result.text,
                from: sourceLocale,
                to: targetLocale
            ) {
                interimTranslation = translation
            }
            return
        }

        // Clear interim state
        interimTranscription = nil
        interimTranslation = nil
        interimSource = nil

        // Skip empty results
        guard !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Translate the final result
        do {
            let translatedText = try await translationService.translate(
                result.text,
                from: sourceLocale,
                to: targetLocale
            )

            // Create the message
            let message = ConversationMessage(
                id: result.id,
                originalText: result.text,
                translatedText: translatedText,
                sourceLocale: sourceLocale,
                targetLocale: targetLocale,
                source: source,
                timestamp: Date(),
                isFinal: true
            )

            // Add to conversation
            messages.append(message)

            // Auto-speak if enabled and this is from system audio (remote participant)
            if configuration.autoSpeak && source == .systemAudio {
                await speechSynthesisService.speak(
                    translatedText,
                    locale: targetLocale,
                    voicePreference: configuration.voicePreference
                )
            }
        } catch {
            // Translation failed, add message with original text only
            let message = ConversationMessage(
                id: result.id,
                originalText: result.text,
                translatedText: result.text, // Use original as fallback
                sourceLocale: sourceLocale,
                targetLocale: targetLocale,
                source: source,
                timestamp: Date(),
                isFinal: true
            )
            messages.append(message)
            lastError = error
        }
    }
}

// MARK: - SwiftData Integration

extension TranslationViewModel {
    /// Save current conversation to a Session
    func saveSession(to modelContext: ModelContext) -> Session {
        let session = Session(
            sourceLocale: configuration.sourceLocale,
            targetLocale: configuration.targetLocale
        )

        // Create speakers for microphone and system audio
        let meSpeaker = Speaker.createMe()
        let otherSpeaker = Speaker.createRemote()

        for message in messages {
            let segment = Segment(
                startTime: message.timestamp.timeIntervalSinceReferenceDate - 1,
                endTime: message.timestamp.timeIntervalSinceReferenceDate,
                originalText: message.originalText,
                translatedText: message.translatedText,
                sourceLocale: message.sourceLocale,
                targetLocale: message.targetLocale,
                isFinal: message.isFinal,
                speaker: message.isFromUser ? meSpeaker : otherSpeaker
            )
            session.addSegment(segment)
        }

        if messages.contains(where: { $0.isFromUser }) {
            session.addSpeaker(meSpeaker)
        }
        if messages.contains(where: { !$0.isFromUser }) {
            session.addSpeaker(otherSpeaker)
        }

        modelContext.insert(session)
        return session
    }

    /// Load a session into the conversation
    func loadSession(_ session: Session) {
        messages = session.sortedSegments.map { segment in
            ConversationMessage(
                id: UUID(),
                originalText: segment.originalText,
                translatedText: segment.translatedText ?? segment.originalText,
                sourceLocale: segment.sourceLocale,
                targetLocale: segment.targetLocale ?? configuration.targetLocale,
                source: segment.speaker?.isMe == true ? .microphone : .systemAudio,
                timestamp: Date(timeIntervalSinceReferenceDate: segment.startTime),
                isFinal: segment.isFinal
            )
        }
    }
}
