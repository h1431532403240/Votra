//
//  VotraError.swift
//  Votra
//
//  Centralized error handling for the Votra application.
//

import Foundation

/// Application-wide errors with user-friendly messages
enum VotraError: LocalizedError {
    // Permission errors
    case microphonePermissionDenied
    case screenRecordingPermissionDenied
    case speechRecognitionPermissionDenied

    // Language errors
    case languageNotDownloaded(Locale)
    case languagePairNotSupported(source: Locale, target: Locale)

    // Service errors
    case translationFailed
    case speechRecognitionFailed
    case recordingFailed
    case summaryGenerationFailed

    // Resource errors
    case appleIntelligenceUnavailable
    case deviceNotSupported
    case diskFull
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return String(localized: "Microphone access is required for voice translation")
        case .screenRecordingPermissionDenied:
            return String(localized: "Screen Recording permission is required to capture system audio")
        case .speechRecognitionPermissionDenied:
            return String(localized: "Speech recognition permission is required")
        case .languageNotDownloaded(let locale):
            let languageName = locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "") ?? "this language"
            return String(localized: "Language pack for \(languageName) is not downloaded")
        case let .languagePairNotSupported(source, target):
            let sourceName = source.localizedString(forLanguageCode: source.language.languageCode?.identifier ?? "") ?? "source"
            let targetName = target.localizedString(forLanguageCode: target.language.languageCode?.identifier ?? "") ?? "target"
            return String(localized: "Translation from \(sourceName) to \(targetName) is not supported")
        case .translationFailed:
            return String(localized: "Translation failed. Please try again.")
        case .speechRecognitionFailed:
            return String(localized: "Speech recognition failed. Please try again.")
        case .recordingFailed:
            return String(localized: "Recording failed. Please check your microphone.")
        case .summaryGenerationFailed:
            return String(localized: "Failed to generate summary.")
        case .appleIntelligenceUnavailable:
            return String(localized: "Apple Intelligence is not available on this device")
        case .deviceNotSupported:
            return String(localized: "This feature is not supported on your device")
        case .diskFull:
            return String(localized: "Not enough disk space available")
        case .networkUnavailable:
            return String(localized: "Network connection is unavailable")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return String(localized: "Open System Settings > Privacy & Security > Microphone and enable access for Votra")
        case .screenRecordingPermissionDenied:
            return String(localized: "Open System Settings > Privacy & Security > Screen Recording and enable access for Votra")
        case .speechRecognitionPermissionDenied:
            return String(localized: "Open System Settings > Privacy & Security > Speech Recognition and enable access for Votra")
        case .languageNotDownloaded:
            return String(localized: "Go to Settings > Languages to download the required language pack")
        case .languagePairNotSupported:
            return String(localized: "Try a different language combination")
        case .appleIntelligenceUnavailable:
            return String(localized: "Enable Apple Intelligence in System Settings > Apple Intelligence & Siri")
        case .diskFull:
            return String(localized: "Free up disk space and try again")
        default:
            return nil
        }
    }
}
