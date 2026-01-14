//
//  Locale+Translation.swift
//  Votra
//
//  Extension providing translation-related utilities for Locale.
//

import Foundation
import Speech

extension Locale {
    // MARK: - Supported Languages

    /// Languages supported for speech recognition (with regional codes)
    static var supportedSpeechRecognitionLanguages: [Locale] {
        [
            Locale(identifier: "en-US"),
            Locale(identifier: "zh-Hans"),
            Locale(identifier: "zh-Hant"),
            Locale(identifier: "ja-JP"),
            Locale(identifier: "ko-KR"),
            Locale(identifier: "es-ES"),
            Locale(identifier: "fr-FR"),
            Locale(identifier: "de-DE"),
            Locale(identifier: "it-IT"),
            Locale(identifier: "pt-BR")
        ]
    }

    /// Languages available for UI language pickers (base language codes for translation)
    static let pickerLanguages: [Locale] = [
        Locale(identifier: "en"),
        Locale(identifier: "zh-Hans"),
        Locale(identifier: "zh-Hant"),
        Locale(identifier: "ja"),
        Locale(identifier: "ko"),
        Locale(identifier: "es"),
        Locale(identifier: "fr"),
        Locale(identifier: "de"),
        Locale(identifier: "it"),
        Locale(identifier: "pt")
    ]

    /// Languages supported for translation
    static var supportedTranslationLanguages: [Locale] {
        // Translation framework supports a wide range of languages
        supportedSpeechRecognitionLanguages
    }

    // MARK: - Display Name

    /// Get the localized display name for this locale
    var localizedDisplayName: String {
        localizedString(forIdentifier: identifier) ?? identifier
    }

    /// Get the flag emoji for this locale (if available)
    var flagEmoji: String? {
        guard let regionCode = language.region?.identifier else { return nil }
        return regionCode
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    // MARK: - Language Code Helpers

    /// Get the language code for speech recognition
    var speechRecognitionCode: String {
        // Speech recognition often requires specific locale codes
        switch identifier {
        case "zh-Hans":
            return "zh-CN"
        case "zh-Hant":
            return "zh-TW"
        default:
            return identifier
        }
    }

    /// Get the base language code (without region)
    var baseLanguageCode: String {
        language.languageCode?.identifier ?? identifier
    }

    // MARK: - Validation

    /// Check if this locale is supported for real-time translation
    var isSupportedForRealTimeTranslation: Bool {
        Locale.supportedSpeechRecognitionLanguages.contains { $0.identifier == identifier }
    }

    // MARK: - Translation Availability

    /// Check if translation is available for this locale pair
    func canTranslate(to target: Locale) -> Bool {
        // Translation framework handles language pair support
        // This is a simplified check - actual availability depends on Translation framework
        let supportedTargets = Locale.supportedTranslationLanguages
        return supportedTargets.contains { $0.identifier == target.identifier }
    }
}

// MARK: - Locale Comparison

extension Locale {
    /// Check if two locales refer to the same language (ignoring region)
    func isSameLanguage(as other: Locale) -> Bool {
        baseLanguageCode == other.baseLanguageCode
    }
}
