//
//  TranslationService.swift
//  Votra
//
//  Service for text translation using Apple's Translation framework.
//

import Foundation
@preconcurrency import Translation

// MARK: - Supporting Types

/// State of the translation service
nonisolated enum TranslationServiceState: Equatable, Sendable {
    case idle
    case ready
    case translating
    case error(message: String)
}

/// A pair of source and target languages for translation
nonisolated struct LanguagePair: Sendable, Equatable, Hashable {
    let source: Locale
    let target: Locale

    var reversed: LanguagePair {
        LanguagePair(source: target, target: source)
    }
}

/// Status of language download for translation
nonisolated enum LanguageDownloadStatus: Sendable {
    case installed
    case notInstalled
    case downloading(progress: Double)
    case unknown
}

// MARK: - Errors

/// Errors that can occur during translation
nonisolated enum TranslationError: LocalizedError {
    case noSession
    case languagePairNotSupported(source: Locale, target: Locale)
    case languageNotDownloaded(Locale)
    case translationFailed(underlying: Error)
    case emptyInput
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .noSession:
            return String(localized: "Translation session is not available")
        case let .languagePairNotSupported(source, target):
            let sourceName = source.localizedString(forLanguageCode: source.language.languageCode?.identifier ?? "") ?? "source"
            let targetName = target.localizedString(forLanguageCode: target.language.languageCode?.identifier ?? "") ?? "target"
            return String(localized: "Translation from \(sourceName) to \(targetName) is not supported")
        case .languageNotDownloaded(let locale):
            let name = locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "") ?? "this language"
            return String(localized: "Language pack for \(name) is not downloaded")
        case .translationFailed:
            return String(localized: "Translation failed")
        case .emptyInput:
            return String(localized: "Cannot translate empty text")
        case .rateLimited:
            return String(localized: "Too many translation requests")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noSession:
            return String(localized: "Please restart the application")
        case .languagePairNotSupported:
            return String(localized: "Try a different language combination")
        case .languageNotDownloaded:
            return String(localized: "Go to Settings > Languages to download the required language pack")
        case .rateLimited:
            return String(localized: "Please wait a moment and try again")
        default:
            return nil
        }
    }
}

// MARK: - Protocol

/// Protocol for translation services
@MainActor
protocol TranslationServiceProtocol: Sendable {
    /// Current state of the translation service
    var state: TranslationServiceState { get }

    /// Whether the service has an active session
    var hasSession: Bool { get }

    /// Translate text from source to target language
    func translate(_ text: String, from sourceLocale: Locale, to targetLocale: Locale) async throws -> String

    /// Translate multiple texts in batch
    func translateBatch(_ texts: [String], from sourceLocale: Locale, to targetLocale: Locale) async throws -> [String]

    /// Check if a language pair is supported
    func isLanguagePairSupported(source: Locale, target: Locale) async -> Bool

    /// Get all supported language pairs
    func supportedLanguagePairs() async -> [LanguagePair]

    /// Check language download status
    func languageStatus(for locale: Locale) async -> LanguageDownloadStatus

    /// Prepare languages for translation (trigger download if needed)
    func prepareLanguages(source: Locale, target: Locale) async throws

    /// Set the translation session (provided by SwiftUI translationTask)
    func setSession(_ session: Any) async
}

// MARK: - Implementation

/// Translation service using Apple's Translation framework
@MainActor
@Observable
final class TranslationService: TranslationServiceProtocol {
    private(set) var state: TranslationServiceState = .idle

    private var translationSession: TranslationSession?

    var hasSession: Bool {
        translationSession != nil
    }

    // MARK: - Session Management

    func setSession(_ session: Any) async {
        guard let session = session as? TranslationSession else { return }
        self.translationSession = session
        state = .ready
    }

    // MARK: - Translation Methods

    func translate(_ text: String, from sourceLocale: Locale, to targetLocale: Locale) async throws -> String {
        guard !text.isEmpty else {
            throw TranslationError.emptyInput
        }

        guard let session = translationSession else {
            throw TranslationError.noSession
        }

        state = .translating

        do {
            let response = try await session.translate(text)
            state = .ready
            return response.targetText
        } catch {
            state = .error(message: error.localizedDescription)
            throw TranslationError.translationFailed(underlying: error)
        }
    }

    func translateBatch(_ texts: [String], from sourceLocale: Locale, to targetLocale: Locale) async throws -> [String] {
        guard !texts.isEmpty else {
            return []
        }

        guard let session = translationSession else {
            throw TranslationError.noSession
        }

        state = .translating

        do {
            // Translate texts one at a time for simplicity
            // The Translation framework's batch API has Sendable issues
            var translatedTexts: [String] = []
            for text in texts {
                let response = try await session.translate(text)
                translatedTexts.append(response.targetText)
            }
            state = .ready
            return translatedTexts
        } catch {
            state = .error(message: error.localizedDescription)
            throw TranslationError.translationFailed(underlying: error)
        }
    }

    // MARK: - Language Support

    func isLanguagePairSupported(source: Locale, target: Locale) async -> Bool {
        let availability = Translation.LanguageAvailability()
        let sourceLanguage = source.language
        let targetLanguage = target.language

        let status = await availability.status(from: sourceLanguage, to: targetLanguage)

        switch status {
        case .installed, .supported:
            return true
        case .unsupported:
            return false
        @unknown default:
            return false
        }
    }

    func supportedLanguagePairs() async -> [LanguagePair] {
        let availability = Translation.LanguageAvailability()
        let supportedLanguages = await availability.supportedLanguages

        // Generate all possible pairs from supported languages
        var pairs: [LanguagePair] = []

        for source in supportedLanguages {
            for target in supportedLanguages where source != target {
                let sourceLocale = Locale(identifier: source.minimalIdentifier)
                let targetLocale = Locale(identifier: target.minimalIdentifier)

                // Check if this pair is actually supported
                let status = await availability.status(from: source, to: target)
                switch status {
                case .installed, .supported:
                    pairs.append(LanguagePair(source: sourceLocale, target: targetLocale))
                case .unsupported:
                    break
                @unknown default:
                    break
                }
            }
        }

        return pairs
    }

    func languageStatus(for locale: Locale) async -> LanguageDownloadStatus {
        let availability = Translation.LanguageAvailability()
        let sourceLanguage = locale.language
        let englishLanguage = Locale.Language(identifier: "en")

        let status = await availability.status(from: sourceLanguage, to: englishLanguage)

        switch status {
        case .installed:
            return .installed
        case .supported:
            return .notInstalled
        case .unsupported:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func prepareLanguages(source: Locale, target: Locale) async throws {
        // The Translation framework automatically downloads languages when needed
        // through the translationTask modifier. This method can trigger preparation
        // by attempting a test translation if a session is available.

        guard let session = translationSession else {
            throw TranslationError.noSession
        }

        // Try a minimal translation to trigger download if needed
        _ = try? await session.translate(" ")
    }

}

// MARK: - Translation Session Configuration Extension

extension TranslationService {
    /// Get a translation configuration for the given language pair
    /// Use this with SwiftUI's translationTask modifier
    static func configuration(source: Locale, target: Locale) -> TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: source.language,
            target: target.language
        )
    }
}
