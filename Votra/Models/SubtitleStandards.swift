//
//  SubtitleStandards.swift
//  Votra
//
//  Subtitle formatting standards based on Netflix Timed Text Style Guide.
//  Defines character limits per line for different languages/scripts.
//

import Foundation

/// Subtitle formatting standards for different languages
nonisolated enum SubtitleStandards {

    // MARK: - Type Properties

    /// Maximum lines per subtitle event (universal standard)
    static let maxLinesPerEvent = 2

    // MARK: - Type Methods

    /// Maximum characters per line based on language/script
    /// Based on Netflix Timed Text Style Guide
    static func maxCharactersPerLine(for locale: Locale) -> Int {
        let languageCode = locale.language.languageCode?.identifier ?? "en"

        switch languageCode {
        // CJK languages - 全形文字
        case "ja":
            return 13  // Japanese horizontal
        case "ko":
            return 16  // Korean
        case "zh":
            return 16  // Chinese (Simplified & Traditional)

        // Latin alphabet languages
        case "en", "es", "fr", "de", "it", "pt", "nl", "pl", "sv", "da", "no", "fi":
            return 42

        // Arabic script
        case "ar", "fa", "ur":
            return 42

        // Cyrillic languages
        case "ru", "uk", "bg":
            return 42

        // Thai, Vietnamese - similar to Latin
        case "th", "vi":
            return 42

        // Default fallback
        default:
            // Check if the script is CJK-like (uses ideographic characters)
            if isCJKScript(locale: locale) {
                return 16
            }
            return 42
        }
    }

    /// Maximum total characters per subtitle event
    static func maxCharactersPerEvent(for locale: Locale) -> Int {
        maxCharactersPerLine(for: locale) * maxLinesPerEvent
    }

    /// Check if a segment exceeds the subtitle limit for the given locale
    static func exceedsLimit(_ text: String, for locale: Locale) -> Bool {
        text.count > maxCharactersPerEvent(for: locale)
    }

    /// Estimate optimal reading duration for a subtitle (in seconds)
    /// Based on average reading speed of 4 CJK characters/second or ~15-17 English characters/second
    static func estimatedDuration(for text: String, locale: Locale) -> TimeInterval {
        let languageCode = locale.language.languageCode?.identifier ?? "en"

        let charsPerSecond: Double
        switch languageCode {
        case "ja", "ko", "zh":
            charsPerSecond = 4.0  // CJK: ~4 characters per second
        default:
            charsPerSecond = 17.0  // Latin: ~17 characters per second (~150 WPM)
        }

        let duration = Double(text.count) / charsPerSecond
        // Minimum 1 second, maximum 7 seconds per Netflix guidelines
        return min(max(duration, 1.0), 7.0)
    }

    // MARK: - Private

    /// Check if locale uses CJK (Chinese, Japanese, Korean) script
    private static func isCJKScript(locale: Locale) -> Bool {
        guard let scriptCode = locale.language.script?.identifier else {
            return false
        }
        // Han (Chinese), Hiragana, Katakana, Hangul
        return ["Hans", "Hant", "Hira", "Kana", "Hang", "Jpan", "Kore"].contains(scriptCode)
    }
}
