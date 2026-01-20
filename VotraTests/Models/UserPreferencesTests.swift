//
//  UserPreferencesTests.swift
//  VotraTests
//
//  Unit tests for the UserPreferences model.
//

import Testing
import Foundation
@testable import Votra

@MainActor
struct UserPreferencesTests {
    /// Keys used by UserPreferences for storage
    private enum Keys {
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let defaultSourceLocale = "defaultSourceLocale"
        static let defaultTargetLocale = "defaultTargetLocale"
        static let speechRate = "speechRate"
        static let autoSpeak = "autoSpeak"
        static let usePersonalVoice = "usePersonalVoice"
        static let floatingWindowOpacity = "floatingWindowOpacity"
        static let hasCompletedFirstRun = "hasCompletedFirstRun"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let recordingFormat = "recordingFormat"
        static let crashReportingEnabled = "crashReportingEnabled"
    }

    /// Clears all UserDefaults keys used by UserPreferences
    private func clearUserDefaults() {
        let keys = [
            Keys.iCloudSyncEnabled,
            Keys.defaultSourceLocale,
            Keys.defaultTargetLocale,
            Keys.speechRate,
            Keys.autoSpeak,
            Keys.usePersonalVoice,
            Keys.floatingWindowOpacity,
            Keys.hasCompletedFirstRun,
            Keys.hasCompletedOnboarding,
            Keys.recordingFormat,
            Keys.crashReportingEnabled
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Singleton

    @Test
    func sharedInstanceExists() {
        let instance = UserPreferences.shared
        #expect(instance != nil)
    }

    @Test
    func sharedInstanceIsSameReference() {
        let instance1 = UserPreferences.shared
        let instance2 = UserPreferences.shared
        #expect(instance1 === instance2)
    }

    // MARK: - iCloud Sync Settings

    @Test
    func iCloudSyncEnabledDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.iCloudSyncEnabled == false)
    }

    @Test
    func iCloudSyncEnabledSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.iCloudSyncEnabled = true
        #expect(preferences.iCloudSyncEnabled == true)

        preferences.iCloudSyncEnabled = false
        #expect(preferences.iCloudSyncEnabled == false)
    }

    // MARK: - Language Settings

    @Test
    func defaultSourceLocaleDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.defaultSourceLocale.identifier == "en-US")
    }

    @Test
    func defaultSourceLocaleSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        let japaneseLocale = Locale(identifier: "ja-JP")
        preferences.defaultSourceLocale = japaneseLocale
        #expect(preferences.defaultSourceLocale.identifier == "ja-JP")

        let germanLocale = Locale(identifier: "de-DE")
        preferences.defaultSourceLocale = germanLocale
        #expect(preferences.defaultSourceLocale.identifier == "de-DE")
    }

    @Test
    func defaultTargetLocaleDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.defaultTargetLocale.identifier == "zh-Hant")
    }

    @Test
    func defaultTargetLocaleSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        let frenchLocale = Locale(identifier: "fr-FR")
        preferences.defaultTargetLocale = frenchLocale
        #expect(preferences.defaultTargetLocale.identifier == "fr-FR")

        let spanishLocale = Locale(identifier: "es-ES")
        preferences.defaultTargetLocale = spanishLocale
        #expect(preferences.defaultTargetLocale.identifier == "es-ES")
    }

    // MARK: - Speech Settings

    @Test
    func speechRateDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.speechRate == 0.5)
    }

    @Test
    func speechRateSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.speechRate = 0.7
        #expect(preferences.speechRate == 0.7)

        preferences.speechRate = 0.3
        #expect(preferences.speechRate == 0.3)
    }

    @Test
    func speechRateClampsToMinimum() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Set a value below minimum (0.1)
        preferences.speechRate = 0.05
        #expect(preferences.speechRate == 0.1)

        // Set zero
        preferences.speechRate = 0
        // Zero triggers default of 0.5
        #expect(preferences.speechRate == 0.5)
    }

    @Test
    func speechRateClampsToMaximum() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Set a value above maximum (1.0)
        preferences.speechRate = 1.5
        #expect(preferences.speechRate == 1.0)

        preferences.speechRate = 2.0
        #expect(preferences.speechRate == 1.0)
    }

    @Test
    func speechRateBoundaryValues() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Test minimum boundary
        preferences.speechRate = 0.1
        #expect(preferences.speechRate == 0.1)

        // Test maximum boundary
        preferences.speechRate = 1.0
        #expect(preferences.speechRate == 1.0)
    }

    @Test
    func autoSpeakDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.autoSpeak == false)
    }

    @Test
    func autoSpeakSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.autoSpeak = true
        #expect(preferences.autoSpeak == true)

        preferences.autoSpeak = false
        #expect(preferences.autoSpeak == false)
    }

    @Test
    func usePersonalVoiceDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.usePersonalVoice == false)
    }

    @Test
    func usePersonalVoiceSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.usePersonalVoice = true
        #expect(preferences.usePersonalVoice == true)

        preferences.usePersonalVoice = false
        #expect(preferences.usePersonalVoice == false)
    }

    // MARK: - UI Settings

    @Test
    func floatingWindowOpacityDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.floatingWindowOpacity == 0.9)
    }

    @Test
    func floatingWindowOpacitySetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.floatingWindowOpacity = 0.7
        #expect(preferences.floatingWindowOpacity == 0.7)

        preferences.floatingWindowOpacity = 0.5
        #expect(preferences.floatingWindowOpacity == 0.5)
    }

    @Test
    func floatingWindowOpacityClampsToMinimum() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Set a value below minimum (0.3)
        preferences.floatingWindowOpacity = 0.2
        #expect(preferences.floatingWindowOpacity == 0.3)

        // Set zero triggers default
        preferences.floatingWindowOpacity = 0
        #expect(preferences.floatingWindowOpacity == 0.9)
    }

    @Test
    func floatingWindowOpacityClampsToMaximum() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Set a value above maximum (1.0)
        preferences.floatingWindowOpacity = 1.5
        #expect(preferences.floatingWindowOpacity == 1.0)

        preferences.floatingWindowOpacity = 2.0
        #expect(preferences.floatingWindowOpacity == 1.0)
    }

    @Test
    func floatingWindowOpacityBoundaryValues() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Test minimum boundary
        preferences.floatingWindowOpacity = 0.3
        #expect(preferences.floatingWindowOpacity == 0.3)

        // Test maximum boundary
        preferences.floatingWindowOpacity = 1.0
        #expect(preferences.floatingWindowOpacity == 1.0)
    }

    @Test
    func hasCompletedFirstRunDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.hasCompletedFirstRun == false)
    }

    @Test
    func hasCompletedFirstRunSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.hasCompletedFirstRun = true
        #expect(preferences.hasCompletedFirstRun == true)

        preferences.hasCompletedFirstRun = false
        #expect(preferences.hasCompletedFirstRun == false)
    }

    @Test
    func hasCompletedOnboardingDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.hasCompletedOnboarding == false)
    }

    @Test
    func hasCompletedOnboardingSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.hasCompletedOnboarding = true
        #expect(preferences.hasCompletedOnboarding == true)

        preferences.hasCompletedOnboarding = false
        #expect(preferences.hasCompletedOnboarding == false)
    }

    // MARK: - Recording Settings

    @Test
    func recordingFormatDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.recordingFormat == .m4a)
    }

    @Test
    func recordingFormatSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.recordingFormat = .wav
        #expect(preferences.recordingFormat == .wav)

        preferences.recordingFormat = .mp3
        #expect(preferences.recordingFormat == .mp3)

        preferences.recordingFormat = .m4a
        #expect(preferences.recordingFormat == .m4a)
    }

    @Test
    func recordingFormatHandlesInvalidValue() {
        clearUserDefaults()
        // Set an invalid raw value directly in UserDefaults
        UserDefaults.standard.set("invalid_format", forKey: Keys.recordingFormat)

        let preferences = UserPreferences.shared
        // Should fall back to default .m4a
        #expect(preferences.recordingFormat == .m4a)
    }

    // MARK: - Crash Reporting

    @Test
    func crashReportingEnabledDefaultValue() {
        clearUserDefaults()
        let preferences = UserPreferences.shared
        #expect(preferences.crashReportingEnabled == false)
    }

    @Test
    func crashReportingEnabledSetAndGet() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        preferences.crashReportingEnabled = true
        #expect(preferences.crashReportingEnabled == true)

        preferences.crashReportingEnabled = false
        #expect(preferences.crashReportingEnabled == false)
    }

    // MARK: - UserDefaults Persistence

    @Test
    func valuesPersistedToUserDefaults() {
        clearUserDefaults()
        let preferences = UserPreferences.shared

        // Set various values
        preferences.iCloudSyncEnabled = true
        preferences.defaultSourceLocale = Locale(identifier: "ko-KR")
        preferences.speechRate = 0.8
        preferences.floatingWindowOpacity = 0.6
        preferences.recordingFormat = .wav

        // Verify directly in UserDefaults
        #expect(UserDefaults.standard.bool(forKey: Keys.iCloudSyncEnabled) == true)
        #expect(UserDefaults.standard.string(forKey: Keys.defaultSourceLocale) == "ko-KR")
        #expect(UserDefaults.standard.float(forKey: Keys.speechRate) == 0.8)
        #expect(UserDefaults.standard.double(forKey: Keys.floatingWindowOpacity) == 0.6)
        #expect(UserDefaults.standard.string(forKey: Keys.recordingFormat) == "wav")
    }

    @Test
    func valuesReadFromUserDefaults() {
        clearUserDefaults()

        // Set values directly in UserDefaults
        UserDefaults.standard.set(true, forKey: Keys.crashReportingEnabled)
        UserDefaults.standard.set("it-IT", forKey: Keys.defaultTargetLocale)
        UserDefaults.standard.set(0.4, forKey: Keys.speechRate)
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.set("mp3", forKey: Keys.recordingFormat)

        // Verify UserPreferences reads them correctly
        let preferences = UserPreferences.shared
        #expect(preferences.crashReportingEnabled == true)
        #expect(preferences.defaultTargetLocale.identifier == "it-IT")
        #expect(preferences.speechRate == 0.4)
        #expect(preferences.hasCompletedOnboarding == true)
        #expect(preferences.recordingFormat == .mp3)
    }
}
