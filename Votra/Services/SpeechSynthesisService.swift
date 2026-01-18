//
//  SpeechSynthesisService.swift
//  Votra
//
//  Service for text-to-speech using AVSpeechSynthesizer with Personal Voice support.
//

@preconcurrency import AVFoundation
import Foundation

// MARK: - Supporting Types

/// State of the speech synthesis service
nonisolated enum SpeechSynthesisState: Equatable, Sendable {
    case idle
    case speaking
    case paused
    case preparing
}

/// Voice preference for speech synthesis
nonisolated enum VoicePreference: Equatable, Sendable {
    case system          // Default system voice for locale
    case personalVoice   // User's Personal Voice (if authorized)
    case specific(id: String)  // Specific voice by identifier
}

/// Information about an available voice
nonisolated struct VoiceInfo: Identifiable, Sendable, Equatable {
    nonisolated enum VoiceQuality: Sendable {
        case `default`
        case enhanced
        case premium
    }

    let id: String
    let name: String
    let locale: Locale
    let quality: VoiceQuality
    let isPersonalVoice: Bool
}

/// Personal Voice authorization status
nonisolated enum PersonalVoiceAuthorizationStatus: Sendable {
    case authorized
    case denied
    case notDetermined
    case unsupported
}

// MARK: - Errors

/// Errors that can occur during speech synthesis
nonisolated enum SpeechSynthesisError: LocalizedError {
    case voiceNotAvailable(Locale)
    case personalVoiceNotAuthorized
    case synthesisFailed
    case alreadySpeaking

    var errorDescription: String? {
        switch self {
        case .voiceNotAvailable(let locale):
            let name = locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "") ?? "this language"
            return String(localized: "No voice available for \(name)")
        case .personalVoiceNotAuthorized:
            return String(localized: "Personal Voice is not authorized")
        case .synthesisFailed:
            return String(localized: "Speech synthesis failed")
        case .alreadySpeaking:
            return String(localized: "Speech is already in progress")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .voiceNotAvailable:
            return String(localized: "Try selecting a different language or download additional voices in System Settings")
        case .personalVoiceNotAuthorized:
            return String(localized: "Enable Personal Voice in System Settings > Accessibility > Personal Voice")
        default:
            return nil
        }
    }
}

// MARK: - Delegate Protocol

/// Delegate for receiving speech synthesis events
@MainActor
protocol SpeechSynthesisDelegate: AnyObject, Sendable {
    func speechDidStart()
    func speechDidFinish()
    func speechDidPause()
    func speechDidContinue()
    func speechDidCancel()
    func speechProgress(characterIndex: Int, characterLength: Int)
}

// MARK: - Protocol

/// Protocol for speech synthesis services
@MainActor
protocol SpeechSynthesisServiceProtocol: Sendable {
    /// Current state of speech synthesis
    var state: SpeechSynthesisState { get }

    /// Whether Personal Voice is authorized
    var isPersonalVoiceAuthorized: Bool { get }

    /// Whether speech is currently playing
    var isSpeaking: Bool { get }

    /// Current speech rate (0.0 - 1.0)
    var speechRate: Float { get set }

    /// Speak the given text in the specified language
    func speak(_ text: String, locale: Locale, voicePreference: VoicePreference) async

    /// Stop current speech
    func stopSpeaking() async

    /// Pause current speech
    func pauseSpeaking() async

    /// Continue paused speech
    func continueSpeaking() async

    /// Request Personal Voice authorization
    func requestPersonalVoiceAuthorization() async -> PersonalVoiceAuthorizationStatus

    /// Get available voices for a locale
    func availableVoices(for locale: Locale) -> [VoiceInfo]

    /// Queue text to be spoken after current utterance
    func enqueue(_ text: String, locale: Locale, voicePreference: VoicePreference) async
}

// MARK: - Factory

/// Factory function to create the appropriate SpeechSynthesisService
/// Uses StubSpeechSynthesisService on CI to avoid audio hardware access and process hangs
@MainActor
func createSpeechSynthesisService() -> any SpeechSynthesisServiceProtocol {
    // Detect CI environment (GitHub Actions sets CI=true)
    // This allows local tests to use real hardware, but CI uses stub
    if ProcessInfo.processInfo.environment["CI"] == "true" {
        return StubSpeechSynthesisService()
    }
    return SpeechSynthesisService()
}

// MARK: - Stub for CI/Testing

/// Stub implementation that doesn't access audio hardware
/// Used in CI environments and unit tests to prevent HALC polling hangs
@MainActor
@Observable
final class StubSpeechSynthesisService: SpeechSynthesisServiceProtocol {
    private(set) var state: SpeechSynthesisState = .idle
    private(set) var isPersonalVoiceAuthorized: Bool = false

    var speechRate: Float = 0.5

    var isSpeaking: Bool { state == .speaking }

    func speak(_ text: String, locale: Locale, voicePreference: VoicePreference) async {
        guard !text.isEmpty else { return }
        state = .speaking
        // Simulate speech completion without actual audio
        state = .idle
    }

    func stopSpeaking() async {
        state = .idle
    }

    func pauseSpeaking() async {
        if state == .speaking {
            state = .paused
        }
    }

    func continueSpeaking() async {
        if state == .paused {
            state = .speaking
            state = .idle
        }
    }

    func requestPersonalVoiceAuthorization() async -> PersonalVoiceAuthorizationStatus {
        .authorized
    }

    func availableVoices(for locale: Locale) -> [VoiceInfo] {
        // Return a minimal stub voice
        [VoiceInfo(
            id: "com.apple.voice.stub",
            name: "Stub Voice",
            locale: locale,
            quality: .default,
            isPersonalVoice: false
        )]
    }

    func enqueue(_ text: String, locale: Locale, voicePreference: VoicePreference) async {
        await speak(text, locale: locale, voicePreference: voicePreference)
    }
}

// MARK: - Implementation

/// Speech synthesis service using AVSpeechSynthesizer
@MainActor
@Observable
final class SpeechSynthesisService: NSObject, SpeechSynthesisServiceProtocol {
    private(set) var state: SpeechSynthesisState = .idle
    private(set) var isPersonalVoiceAuthorized: Bool = false

    var speechRate: Float = 0.5

    var isSpeaking: Bool {
        _synthesizer?.isSpeaking ?? false
    }

    weak var delegate: SpeechSynthesisDelegate?

    // Lazy initialization to avoid audio hardware access during tests
    @ObservationIgnored private var _synthesizer: AVSpeechSynthesizer?

    private var synthesizer: AVSpeechSynthesizer {
        if let existing = _synthesizer {
            return existing
        }
        let synth = AVSpeechSynthesizer()
        synth.delegate = self
        _synthesizer = synth
        return synth
    }

    private var speechQueue: [(text: String, locale: Locale, voicePreference: VoicePreference)] = []

    // MARK: - Initialization

    override init() {
        super.init()
        // Don't initialize synthesizer here - let it be created lazily
    }

    // MARK: - Public Methods

    func speak(_ text: String, locale: Locale, voicePreference: VoicePreference) async {
        guard !text.isEmpty else { return }

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        state = .preparing

        let utterance = createUtterance(text: text, locale: locale, voicePreference: voicePreference)
        synthesizer.speak(utterance)
    }

    func stopSpeaking() async {
        synthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        state = .idle
    }

    func pauseSpeaking() async {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            state = .paused
        }
    }

    func continueSpeaking() async {
        if state == .paused {
            synthesizer.continueSpeaking()
            state = .speaking
        }
    }

    func requestPersonalVoiceAuthorization() async -> PersonalVoiceAuthorizationStatus {
        let status = await AVSpeechSynthesizer.requestPersonalVoiceAuthorization()

        switch status {
        case .authorized:
            isPersonalVoiceAuthorized = true
            return .authorized
        case .denied:
            isPersonalVoiceAuthorized = false
            return .denied
        case .notDetermined:
            return .notDetermined
        case .unsupported:
            return .unsupported
        @unknown default:
            return .unsupported
        }
    }

    func availableVoices(for locale: Locale) -> [VoiceInfo] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let languageCode = locale.language.languageCode?.identifier ?? ""

        // For Chinese, filter by script/region to get correct variant
        let filteredVoices: [AVSpeechSynthesisVoice]
        if languageCode == "zh" {
            let script = locale.language.script?.identifier
            filteredVoices = allVoices.filter { voice in
                guard voice.language.hasPrefix("zh") else { return false }

                if script == "Hans" {
                    return voice.language.contains("CN") || voice.language.contains("SG") ||
                           voice.language.contains("Hans")
                }
                if script == "Hant" {
                    return voice.language.contains("TW") || voice.language.contains("HK") ||
                           voice.language.contains("MO") || voice.language.contains("Hant")
                }
                return true
            }
        } else {
            filteredVoices = allVoices.filter { $0.language.hasPrefix(languageCode) }
        }

        return filteredVoices.map { voice in
            VoiceInfo(
                id: voice.identifier,
                name: voice.name,
                locale: Locale(identifier: voice.language),
                quality: mapVoiceQuality(voice.quality),
                isPersonalVoice: voice.voiceTraits.contains(.isPersonalVoice)
            )
        }
    }

    func enqueue(_ text: String, locale: Locale, voicePreference: VoicePreference) async {
        guard !text.isEmpty else { return }

        if synthesizer.isSpeaking || state == .paused {
            speechQueue.append((text: text, locale: locale, voicePreference: voicePreference))
        } else {
            await speak(text, locale: locale, voicePreference: voicePreference)
        }
    }

    // MARK: - Private Methods

    private func createUtterance(text: String, locale: Locale, voicePreference: VoicePreference) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.voice = selectVoice(for: locale, preference: voicePreference)
        return utterance
    }

    private func selectVoice(for locale: Locale, preference: VoicePreference) -> AVSpeechSynthesisVoice? {
        switch preference {
        case .system:
            return selectBestSystemVoice(for: locale)

        case .personalVoice:
            if isPersonalVoiceAuthorized {
                let personalVoice = AVSpeechSynthesisVoice.speechVoices()
                    .first { $0.voiceTraits.contains(.isPersonalVoice) }
                return personalVoice ?? selectBestSystemVoice(for: locale)
            }
            return selectBestSystemVoice(for: locale)

        case .specific(let id):
            return AVSpeechSynthesisVoice(identifier: id) ?? selectBestSystemVoice(for: locale)
        }
    }

    private func selectBestSystemVoice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        let languageCode = locale.language.languageCode?.identifier ?? ""
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // For Chinese, filter by script/region to get correct variant
        let matchingVoices: [AVSpeechSynthesisVoice]
        if languageCode == "zh" {
            let script = locale.language.script?.identifier
            matchingVoices = allVoices.filter { voice in
                guard voice.language.hasPrefix("zh") else { return false }

                // Match zh-Hans with zh-CN, zh-SG, etc.
                if script == "Hans" {
                    return voice.language.contains("CN") || voice.language.contains("SG") ||
                           voice.language.contains("Hans")
                }
                // Match zh-Hant with zh-TW, zh-HK, zh-MO, etc.
                if script == "Hant" {
                    return voice.language.contains("TW") || voice.language.contains("HK") ||
                           voice.language.contains("MO") || voice.language.contains("Hant")
                }
                return true
            }
        } else {
            matchingVoices = allVoices.filter { $0.language.hasPrefix(languageCode) }
        }

        // Try to find enhanced or premium voice first
        if let enhancedVoice = matchingVoices.first(where: { $0.quality == .enhanced || $0.quality == .premium }) {
            return enhancedVoice
        }

        // Fall back to any matching voice
        if let anyVoice = matchingVoices.first {
            return anyVoice
        }

        // Last resort: try the BCP47 identifier directly
        return AVSpeechSynthesisVoice(language: locale.identifier(.bcp47))
    }

    private func mapVoiceQuality(_ quality: AVSpeechSynthesisVoiceQuality) -> VoiceInfo.VoiceQuality {
        switch quality {
        case .default:
            return .default
        case .enhanced:
            return .enhanced
        case .premium:
            return .premium
        @unknown default:
            return .default
        }
    }

    private func processNextInQueue() {
        guard !speechQueue.isEmpty else {
            state = .idle
            return
        }

        let next = speechQueue.removeFirst()
        Task {
            await speak(next.text, locale: next.locale, voicePreference: next.voicePreference)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .speaking
            self.delegate?.speechDidStart()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.delegate?.speechDidFinish()
            self.processNextInQueue()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .paused
            self.delegate?.speechDidPause()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .speaking
            self.delegate?.speechDidContinue()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .idle
            self.delegate?.speechDidCancel()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.delegate?.speechProgress(
                characterIndex: characterRange.location,
                characterLength: characterRange.length
            )
        }
    }
}
