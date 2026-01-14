//
//  UserPreferences.swift
//  Votra
//
//  User preferences stored in UserDefaults.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class UserPreferences {
    static let shared = UserPreferences()

    // MARK: - Sync Settings

    var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    // MARK: - Language Settings

    var defaultSourceLocale: Locale {
        get { storedLocale(forKey: "defaultSourceLocale") ?? Locale(identifier: "en-US") }
        set { UserDefaults.standard.set(newValue.identifier, forKey: "defaultSourceLocale") }
    }

    var defaultTargetLocale: Locale {
        get { storedLocale(forKey: "defaultTargetLocale") ?? Locale(identifier: "zh-Hant") }
        set { UserDefaults.standard.set(newValue.identifier, forKey: "defaultTargetLocale") }
    }

    // MARK: - Speech Settings

    /// When true, uses more accurate but slower speech recognition
    /// Uses `.transcription` preset instead of `.progressiveTranscription`
    var accurateRecognitionMode: Bool {
        get { UserDefaults.standard.bool(forKey: "accurateRecognitionMode") }
        set { UserDefaults.standard.set(newValue, forKey: "accurateRecognitionMode") }
    }

    var speechRate: Float {
        get {
            let value = UserDefaults.standard.float(forKey: "speechRate")
            return value > 0 ? min(max(value, 0.1), 1.0) : 0.5
        }
        set { UserDefaults.standard.set(newValue, forKey: "speechRate") }
    }

    var autoSpeak: Bool {
        get { UserDefaults.standard.bool(forKey: "autoSpeak") }
        set { UserDefaults.standard.set(newValue, forKey: "autoSpeak") }
    }

    var usePersonalVoice: Bool {
        get { UserDefaults.standard.bool(forKey: "usePersonalVoice") }
        set { UserDefaults.standard.set(newValue, forKey: "usePersonalVoice") }
    }

    // MARK: - UI Settings

    var floatingWindowOpacity: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "floatingWindowOpacity")
            return value > 0 ? min(max(value, 0.3), 1.0) : 0.9
        }
        set { UserDefaults.standard.set(newValue, forKey: "floatingWindowOpacity") }
    }

    var hasCompletedFirstRun: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedFirstRun") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedFirstRun") }
    }

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // MARK: - Recording Settings

    var recordingFormat: AudioFormat {
        get {
            let raw = UserDefaults.standard.string(forKey: "recordingFormat") ?? "m4a"
            return AudioFormat(rawValue: raw) ?? .m4a
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "recordingFormat") }
    }

    // MARK: - Crash Reporting

    var crashReportingEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "crashReportingEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "crashReportingEnabled") }
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Helpers

    private func storedLocale(forKey key: String) -> Locale? {
        guard let identifier = UserDefaults.standard.string(forKey: key) else { return nil }
        return Locale(identifier: identifier)
    }
}
