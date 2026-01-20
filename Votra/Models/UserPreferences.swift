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

    var floatingPanelDisplayMode: FloatingPanelDisplayMode {
        get {
            let raw = UserDefaults.standard.string(forKey: "floatingPanelDisplayMode") ?? "subtitle"
            return FloatingPanelDisplayMode(rawValue: raw) ?? .subtitle
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "floatingPanelDisplayMode") }
    }

    /// Translation mode: subtitle (system audio only) or conversation (bidirectional)
    var translationMode: TranslationMode {
        get {
            let raw = UserDefaults.standard.string(forKey: "translationMode") ?? "subtitle"
            return TranslationMode(rawValue: raw) ?? .subtitle
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "translationMode") }
    }

    /// Number of recent messages to show in floating panel subtitle mode (1-5)
    var floatingPanelMessageCount: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: "floatingPanelMessageCount")
            return value > 0 ? min(max(value, 1), 5) : 2
        }
        set { UserDefaults.standard.set(min(max(newValue, 1), 5), forKey: "floatingPanelMessageCount") }
    }

    /// Whether to show original text in floating panel subtitle mode
    var floatingPanelShowOriginal: Bool {
        get { UserDefaults.standard.bool(forKey: "floatingPanelShowOriginal") }
        set { UserDefaults.standard.set(newValue, forKey: "floatingPanelShowOriginal") }
    }

    /// Text size for floating panel (12-24 points, default 16)
    var floatingPanelTextSize: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "floatingPanelTextSize")
            return value > 0 ? min(max(value, 12), 24) : 16
        }
        set { UserDefaults.standard.set(min(max(newValue, 12), 24), forKey: "floatingPanelTextSize") }
    }

    /// Calculated line height based on text size (text size + spacing)
    var floatingPanelLineHeight: Double {
        floatingPanelTextSize + 6
    }

    /// Calculated minimum height for floating panel based on settings
    var floatingPanelMinimumHeight: Double {
        let baseHeight: Double = 36 // Minimal padding for subtitle style
        let showOriginal = floatingPanelShowOriginal
        // Each message shows up to 2 lines of translated text
        // When original is also shown, that adds 1 more line (1 original + 2 translated = 3)
        let linesPerMessage = showOriginal ? 3.0 : 2.0
        let totalLines = Double(floatingPanelMessageCount) * linesPerMessage
        return baseHeight + (floatingPanelLineHeight * totalLines)
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
