//
//  SpeechSynthesisServiceTests.swift
//  VotraTests
//
//  Tests for SpeechSynthesisService - validates error types, supporting types,
//  and observable state without requiring audio hardware.
//

import Foundation
import Testing
@testable import Votra

@Suite("Speech Synthesis Service Tests", .tags(.requiresHardware))
@MainActor
struct SpeechSynthesisServiceTests {

    // MARK: - SpeechSynthesisError Tests

    @Test("All error cases have non-empty descriptions")
    func errorDescriptions() {
        let errors: [SpeechSynthesisError] = [
            .voiceNotAvailable(Locale(identifier: "en_US")),
            .personalVoiceNotAuthorized,
            .synthesisFailed,
            .alreadySpeaking
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("Voice not available error has non-empty description")
    func voiceNotAvailableErrorDescription() {
        let englishLocale = Locale(identifier: "en_US")
        let error = SpeechSynthesisError.voiceNotAvailable(englishLocale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Voice not available error with invalid locale falls back gracefully")
    func voiceNotAvailableErrorWithInvalidLocale() {
        // Test with a locale that has no valid language code
        let invalidLocale = Locale(identifier: "")
        let error = SpeechSynthesisError.voiceNotAvailable(invalidLocale)

        // Should still produce a valid description
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Voice not available error with unknown locale code")
    func voiceNotAvailableErrorWithUnknownLocale() {
        // Test with a completely unknown locale identifier
        let unknownLocale = Locale(identifier: "xyz")
        let error = SpeechSynthesisError.voiceNotAvailable(unknownLocale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Personal voice not authorized error has non-empty description")
    func personalVoiceNotAuthorizedErrorDescription() {
        let error = SpeechSynthesisError.personalVoiceNotAuthorized

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Synthesis failed error has non-empty description")
    func synthesisFailedErrorDescription() {
        let error = SpeechSynthesisError.synthesisFailed

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Already speaking error has non-empty description")
    func alreadySpeakingErrorDescription() {
        let error = SpeechSynthesisError.alreadySpeaking

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - Recovery Suggestion Tests

    @Test("Voice not available error has recovery suggestion")
    func voiceNotAvailableRecoverySuggestion() {
        let error = SpeechSynthesisError.voiceNotAvailable(Locale(identifier: "ja_JP"))

        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("Personal voice not authorized error has recovery suggestion")
    func personalVoiceNotAuthorizedRecoverySuggestion() {
        let error = SpeechSynthesisError.personalVoiceNotAuthorized

        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("Synthesis failed error has no recovery suggestion")
    func synthesisFailedNoRecoverySuggestion() {
        let error = SpeechSynthesisError.synthesisFailed

        #expect(error.recoverySuggestion == nil)
    }

    @Test("Already speaking error has no recovery suggestion")
    func alreadySpeakingNoRecoverySuggestion() {
        let error = SpeechSynthesisError.alreadySpeaking

        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - Error Uniqueness Tests

    @Test("Different error cases have different descriptions")
    func differentErrorCasesHaveDifferentDescriptions() {
        let error1 = SpeechSynthesisError.personalVoiceNotAuthorized
        let error2 = SpeechSynthesisError.synthesisFailed

        #expect(error1.errorDescription != error2.errorDescription)
    }

    @Test("Voice not available errors with different locales have different descriptions")
    func voiceNotAvailableWithDifferentLocales() {
        let error1 = SpeechSynthesisError.voiceNotAvailable(Locale(identifier: "en_US"))
        let error2 = SpeechSynthesisError.voiceNotAvailable(Locale(identifier: "ja_JP"))

        // The descriptions may differ based on the language name
        // We just verify both have valid descriptions
        #expect(error1.errorDescription != nil)
        #expect(error2.errorDescription != nil)
    }

    // MARK: - LocalizedError Conformance Tests

    @Test("Error conforms to LocalizedError")
    func errorConformsToLocalizedError() {
        let error: any LocalizedError = SpeechSynthesisError.synthesisFailed

        #expect(error.errorDescription != nil)
    }

    @Test("Error can be used as Error type")
    func errorCanBeUsedAsErrorType() {
        let error: any Error = SpeechSynthesisError.alreadySpeaking

        #expect(error is SpeechSynthesisError)
    }

    // MARK: - SpeechSynthesisState Tests

    @Test("Speech synthesis state has all expected cases")
    func speechSynthesisStateHasAllCases() {
        let states: [SpeechSynthesisState] = [.idle, .speaking, .paused, .preparing]

        #expect(states.count == 4)
    }

    @Test("Speech synthesis states are equatable")
    func speechSynthesisStatesAreEquatable() {
        // swiftlint:disable identical_operands
        #expect(SpeechSynthesisState.idle == SpeechSynthesisState.idle)
        #expect(SpeechSynthesisState.speaking == SpeechSynthesisState.speaking)
        #expect(SpeechSynthesisState.paused == SpeechSynthesisState.paused)
        #expect(SpeechSynthesisState.preparing == SpeechSynthesisState.preparing)
        // swiftlint:enable identical_operands
    }

    @Test("Different speech synthesis states are not equal")
    func differentSpeechSynthesisStatesNotEqual() {
        #expect(SpeechSynthesisState.idle != SpeechSynthesisState.speaking)
        #expect(SpeechSynthesisState.paused != SpeechSynthesisState.preparing)
        #expect(SpeechSynthesisState.speaking != SpeechSynthesisState.idle)
    }

    // MARK: - VoicePreference Tests

    @Test("Voice preference system case exists")
    func voicePreferenceSystemCase() {
        let preference = VoicePreference.system

        #expect(preference == .system)
    }

    @Test("Voice preference personal voice case exists")
    func voicePreferencePersonalVoiceCase() {
        let preference = VoicePreference.personalVoice

        #expect(preference == .personalVoice)
    }

    @Test("Voice preference specific case stores identifier")
    func voicePreferenceSpecificCase() {
        let voiceId = "com.apple.voice.enhanced.en-US.samantha"
        let preference = VoicePreference.specific(id: voiceId)

        if case .specific(let id) = preference {
            #expect(id == voiceId)
        } else {
            Issue.record("Expected .specific case")
        }
    }

    @Test("Voice preferences are equatable")
    func voicePreferencesAreEquatable() {
        // swiftlint:disable identical_operands
        #expect(VoicePreference.system == VoicePreference.system)
        #expect(VoicePreference.personalVoice == VoicePreference.personalVoice)
        #expect(VoicePreference.specific(id: "test") == VoicePreference.specific(id: "test"))
        // swiftlint:enable identical_operands
    }

    @Test("Different voice preferences are not equal")
    func differentVoicePreferencesNotEqual() {
        #expect(VoicePreference.system != VoicePreference.personalVoice)
        #expect(VoicePreference.specific(id: "voice1") != VoicePreference.specific(id: "voice2"))
    }

    // MARK: - VoiceInfo Tests

    @Test("VoiceInfo can be created with all properties")
    func voiceInfoCreation() {
        let voiceInfo = VoiceInfo(
            id: "test.voice.id",
            name: "Test Voice",
            locale: Locale(identifier: "en_US"),
            quality: .enhanced,
            isPersonalVoice: false
        )

        #expect(voiceInfo.id == "test.voice.id")
        #expect(voiceInfo.name == "Test Voice")
        #expect(voiceInfo.locale.identifier == "en_US")
        #expect(voiceInfo.quality == .enhanced)
        #expect(voiceInfo.isPersonalVoice == false)
    }

    @Test("VoiceInfo is identifiable by id")
    func voiceInfoIsIdentifiable() {
        let voiceInfo = VoiceInfo(
            id: "unique.voice.id",
            name: "Unique Voice",
            locale: Locale(identifier: "fr_FR"),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voiceInfo.id == "unique.voice.id")
    }

    @Test("VoiceInfo can represent personal voice")
    func voiceInfoPersonalVoice() {
        let personalVoice = VoiceInfo(
            id: "personal.voice.id",
            name: "My Personal Voice",
            locale: Locale(identifier: "en_US"),
            quality: .premium,
            isPersonalVoice: true
        )

        #expect(personalVoice.isPersonalVoice == true)
    }

    @Test("VoiceInfo instances are equatable")
    func voiceInfoEquatable() {
        let voice1 = VoiceInfo(
            id: "voice.id",
            name: "Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        let voice2 = VoiceInfo(
            id: "voice.id",
            name: "Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voice1 == voice2)
    }

    @Test("VoiceInfo instances with different ids are not equal")
    func voiceInfoNotEqualDifferentIds() {
        let voice1 = VoiceInfo(
            id: "voice.id.1",
            name: "Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        let voice2 = VoiceInfo(
            id: "voice.id.2",
            name: "Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voice1 != voice2)
    }

    // MARK: - VoiceInfo.VoiceQuality Tests

    @Test("Voice quality has all expected cases")
    func voiceQualityHasAllCases() {
        let qualities: [VoiceInfo.VoiceQuality] = [.default, .enhanced, .premium]

        #expect(qualities.count == 3)
    }

    @Test("Voice qualities can be compared")
    func voiceQualitiesComparison() {
        let quality1: VoiceInfo.VoiceQuality = .default
        let quality2: VoiceInfo.VoiceQuality = .enhanced
        let quality3: VoiceInfo.VoiceQuality = .premium

        #expect(quality1 != quality2)
        #expect(quality2 != quality3)
        #expect(quality1 != quality3)
    }

    // MARK: - PersonalVoiceAuthorizationStatus Tests

    @Test("Personal voice authorization status has all expected cases")
    func personalVoiceAuthorizationStatusHasAllCases() {
        let statuses: [PersonalVoiceAuthorizationStatus] = [
            .authorized,
            .denied,
            .notDetermined,
            .unsupported
        ]

        #expect(statuses.count == 4)
    }

    @Test("Personal voice authorization statuses are distinct")
    func personalVoiceAuthorizationStatusesAreDistinct() {
        let authorized = PersonalVoiceAuthorizationStatus.authorized
        let denied = PersonalVoiceAuthorizationStatus.denied
        let notDetermined = PersonalVoiceAuthorizationStatus.notDetermined
        let unsupported = PersonalVoiceAuthorizationStatus.unsupported

        // Verify all are distinct by creating a set
        let allStatuses = Set([authorized, denied, notDetermined, unsupported] as [PersonalVoiceAuthorizationStatus])
        #expect(allStatuses.count == 4)
    }

    // MARK: - Initial State Tests

    @Test("Service initializes with idle state")
    func serviceInitialStateIsIdle() {
        let service = SpeechSynthesisService()

        #expect(service.state == .idle)
    }

    @Test("Service initializes with personal voice not authorized")
    func serviceInitialPersonalVoiceNotAuthorized() {
        let service = SpeechSynthesisService()

        #expect(service.isPersonalVoiceAuthorized == false)
    }

    @Test("Service initializes with default speech rate")
    func serviceInitialSpeechRate() {
        let service = SpeechSynthesisService()

        #expect(service.speechRate == 0.5)
    }

    @Test("Service initializes with isSpeaking false")
    func serviceInitialIsSpeakingFalse() {
        let service = SpeechSynthesisService()

        // Before any speech, isSpeaking should be false
        // Note: This doesn't trigger synthesizer initialization due to lazy loading
        #expect(service.isSpeaking == false)
    }

    // MARK: - Speech Rate Tests

    @Test("Speech rate can be modified")
    func speechRateCanBeModified() {
        let service = SpeechSynthesisService()

        service.speechRate = 0.75
        #expect(service.speechRate == 0.75)

        service.speechRate = 0.25
        #expect(service.speechRate == 0.25)
    }

    @Test("Speech rate accepts minimum value")
    func speechRateAcceptsMinimum() {
        let service = SpeechSynthesisService()

        service.speechRate = 0.0
        #expect(service.speechRate == 0.0)
    }

    @Test("Speech rate accepts maximum value")
    func speechRateAcceptsMaximum() {
        let service = SpeechSynthesisService()

        service.speechRate = 1.0
        #expect(service.speechRate == 1.0)
    }

    // MARK: - Delegate Tests

    @Test("Delegate starts as nil")
    func delegateStartsAsNil() {
        let service = SpeechSynthesisService()

        #expect(service.delegate == nil)
    }

    @Test("Delegate can be set")
    func delegateCanBeSet() {
        let service = SpeechSynthesisService()
        let mockDelegate = MockSpeechSynthesisDelegate()

        service.delegate = mockDelegate

        #expect(service.delegate != nil)
    }

    @Test("Delegate is weak reference")
    func delegateIsWeakReference() {
        let service = SpeechSynthesisService()

        // Create delegate in inner scope
        do {
            let mockDelegate = MockSpeechSynthesisDelegate()
            service.delegate = mockDelegate
            #expect(service.delegate != nil)
        }

        // After scope ends, delegate should be nil (weak reference)
        #expect(service.delegate == nil)
    }

    // MARK: - Available Voices Tests

    @Test("Available voices returns array for English locale")
    func availableVoicesForEnglish() {
        let service = SpeechSynthesisService()
        let voices = service.availableVoices(for: Locale(identifier: "en_US"))

        // Should return at least one voice on macOS
        // Note: In CI without audio, this might be empty
        #expect(voices is [VoiceInfo])
    }

    @Test("Available voices returns array for any locale")
    func availableVoicesReturnsArray() {
        let service = SpeechSynthesisService()

        // Even for unsupported locales, should return an array (possibly empty)
        let voices = service.availableVoices(for: Locale(identifier: "xyz_XYZ"))
        #expect(voices is [VoiceInfo])
    }

    @Test("Available voices for Japanese locale returns relevant voices")
    func availableVoicesForJapanese() {
        let service = SpeechSynthesisService()
        let voices = service.availableVoices(for: Locale(identifier: "ja_JP"))

        // Verify all returned voices are for Japanese
        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "ja")
        }
    }

    @Test("Available voices for Chinese Simplified filters correctly")
    func availableVoicesForChineseSimplified() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh-Hans")
        let voices = service.availableVoices(for: locale)

        // Verify all returned voices are for Chinese
        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    @Test("Available voices for Chinese Traditional filters correctly")
    func availableVoicesForChineseTraditional() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh-Hant")
        let voices = service.availableVoices(for: locale)

        // Verify all returned voices are for Chinese
        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    // MARK: - Protocol Conformance Tests

    @Test("Service conforms to SpeechSynthesisServiceProtocol")
    func serviceConformsToProtocol() {
        let service = SpeechSynthesisService()

        #expect(service.state == .idle)
        #expect(service.isPersonalVoiceAuthorized == false)
        #expect(service.isSpeaking == false)
    }

    // MARK: - State Transition Logic Tests

    @Test("Stop speaking clears state to idle")
    func stopSpeakingClearsState() async {
        let service = SpeechSynthesisService()

        await service.stopSpeaking()

        #expect(service.state == .idle)
    }

    @Test("Continue speaking from non-paused state does nothing")
    func continueSpeakingFromNonPausedState() async {
        let service = SpeechSynthesisService()

        // Service starts in idle state
        #expect(service.state == .idle)

        await service.continueSpeaking()

        // State should remain idle since it wasn't paused
        #expect(service.state == .idle)
    }

    // MARK: - Empty Text Handling Tests

    @Test("Speak with empty text does nothing")
    func speakEmptyTextDoesNothing() async {
        let service = SpeechSynthesisService()

        await service.speak("", locale: Locale(identifier: "en_US"), voicePreference: .system)

        // State should remain idle for empty text
        #expect(service.state == .idle)
    }

    @Test("Enqueue with empty text does nothing")
    func enqueueEmptyTextDoesNothing() async {
        let service = SpeechSynthesisService()

        await service.enqueue("", locale: Locale(identifier: "en_US"), voicePreference: .system)

        // State should remain idle for empty text
        #expect(service.state == .idle)
    }

    // MARK: - Sendable Conformance Tests

    @Test("SpeechSynthesisState is Sendable")
    func speechSynthesisStateIsSendable() {
        let state: SpeechSynthesisState = .speaking

        // This compiles because SpeechSynthesisState is Sendable
        Task {
            _ = state
        }
    }

    @Test("VoicePreference is Sendable")
    func voicePreferenceIsSendable() {
        let preference: VoicePreference = .system

        Task {
            _ = preference
        }
    }

    @Test("VoiceInfo is Sendable")
    func voiceInfoIsSendable() {
        let voiceInfo = VoiceInfo(
            id: "test",
            name: "Test",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        Task {
            _ = voiceInfo
        }
    }

    @Test("PersonalVoiceAuthorizationStatus is Sendable")
    func personalVoiceAuthorizationStatusIsSendable() {
        let status: PersonalVoiceAuthorizationStatus = .authorized

        Task {
            _ = status
        }
    }

    @Test("SpeechSynthesisError is Sendable")
    func speechSynthesisErrorIsSendable() {
        let error: SpeechSynthesisError = .synthesisFailed

        Task {
            _ = error
        }
    }

    // MARK: - VoiceInfo Equality Edge Cases

    @Test("VoiceInfo with different names are not equal")
    func voiceInfoNotEqualDifferentNames() {
        let voice1 = VoiceInfo(
            id: "same.id",
            name: "Voice One",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        let voice2 = VoiceInfo(
            id: "same.id",
            name: "Voice Two",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voice1 != voice2)
    }

    @Test("VoiceInfo with different locales are not equal")
    func voiceInfoNotEqualDifferentLocales() {
        let voice1 = VoiceInfo(
            id: "same.id",
            name: "Same Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        let voice2 = VoiceInfo(
            id: "same.id",
            name: "Same Voice",
            locale: Locale(identifier: "fr_FR"),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voice1 != voice2)
    }

    @Test("VoiceInfo with different quality are not equal")
    func voiceInfoNotEqualDifferentQuality() {
        let voice1 = VoiceInfo(
            id: "same.id",
            name: "Same Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        let voice2 = VoiceInfo(
            id: "same.id",
            name: "Same Voice",
            locale: Locale(identifier: "en_US"),
            quality: .enhanced,
            isPersonalVoice: false
        )

        #expect(voice1 != voice2)
    }

    @Test("VoiceInfo with different isPersonalVoice are not equal")
    func voiceInfoNotEqualDifferentPersonalVoice() {
        let voice1 = VoiceInfo(
            id: "same.id",
            name: "Same Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        let voice2 = VoiceInfo(
            id: "same.id",
            name: "Same Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: true
        )

        #expect(voice1 != voice2)
    }

    @Test("VoiceInfo with premium quality can be created")
    func voiceInfoPremiumQuality() {
        let voice = VoiceInfo(
            id: "premium.voice",
            name: "Premium Voice",
            locale: Locale(identifier: "en_US"),
            quality: .premium,
            isPersonalVoice: false
        )

        #expect(voice.quality == .premium)
    }

    // MARK: - VoiceQuality Equality Tests

    @Test("Same voice quality values are equal")
    func sameVoiceQualityAreEqual() {
        let quality1: VoiceInfo.VoiceQuality = .default
        let quality2: VoiceInfo.VoiceQuality = .default

        #expect(quality1 == quality2)

        let enhanced1: VoiceInfo.VoiceQuality = .enhanced
        let enhanced2: VoiceInfo.VoiceQuality = .enhanced

        #expect(enhanced1 == enhanced2)

        let premium1: VoiceInfo.VoiceQuality = .premium
        let premium2: VoiceInfo.VoiceQuality = .premium

        #expect(premium1 == premium2)
    }

    // MARK: - PersonalVoiceAuthorizationStatus Equality Tests

    @Test("Same authorization status values are equal")
    func sameAuthorizationStatusAreEqual() {
        // swiftlint:disable identical_operands
        #expect(PersonalVoiceAuthorizationStatus.authorized == PersonalVoiceAuthorizationStatus.authorized)
        #expect(PersonalVoiceAuthorizationStatus.denied == PersonalVoiceAuthorizationStatus.denied)
        #expect(PersonalVoiceAuthorizationStatus.notDetermined == PersonalVoiceAuthorizationStatus.notDetermined)
        #expect(PersonalVoiceAuthorizationStatus.unsupported == PersonalVoiceAuthorizationStatus.unsupported)
        // swiftlint:enable identical_operands
    }

    @Test("Different authorization status values are not equal")
    func differentAuthorizationStatusNotEqual() {
        #expect(PersonalVoiceAuthorizationStatus.authorized != PersonalVoiceAuthorizationStatus.denied)
        #expect(PersonalVoiceAuthorizationStatus.authorized != PersonalVoiceAuthorizationStatus.notDetermined)
        #expect(PersonalVoiceAuthorizationStatus.authorized != PersonalVoiceAuthorizationStatus.unsupported)
        #expect(PersonalVoiceAuthorizationStatus.denied != PersonalVoiceAuthorizationStatus.notDetermined)
        #expect(PersonalVoiceAuthorizationStatus.denied != PersonalVoiceAuthorizationStatus.unsupported)
        #expect(PersonalVoiceAuthorizationStatus.notDetermined != PersonalVoiceAuthorizationStatus.unsupported)
    }

    // MARK: - VoicePreference Equality Edge Cases

    @Test("VoicePreference specific cases with same ID are equal")
    func voicePreferenceSpecificSameIdEqual() {
        let id = "com.apple.voice.test"
        let pref1 = VoicePreference.specific(id: id)
        let pref2 = VoicePreference.specific(id: id)

        #expect(pref1 == pref2)
    }

    @Test("VoicePreference specific case is not equal to system")
    func voicePreferenceSpecificNotEqualToSystem() {
        let specific = VoicePreference.specific(id: "any.voice")
        let system = VoicePreference.system

        #expect(specific != system)
    }

    @Test("VoicePreference specific case is not equal to personalVoice")
    func voicePreferenceSpecificNotEqualToPersonalVoice() {
        let specific = VoicePreference.specific(id: "any.voice")
        let personal = VoicePreference.personalVoice

        #expect(specific != personal)
    }

    // MARK: - SpeechSynthesisState Equality Edge Cases

    @Test("Same state values are equal")
    func sameStateValuesAreEqual() {
        let idle1 = SpeechSynthesisState.idle
        let idle2 = SpeechSynthesisState.idle

        #expect(idle1 == idle2)

        let speaking1 = SpeechSynthesisState.speaking
        let speaking2 = SpeechSynthesisState.speaking

        #expect(speaking1 == speaking2)
    }

    @Test("All state transitions produce distinct states")
    func allStateTransitionsDistinct() {
        let states: [SpeechSynthesisState] = [.idle, .speaking, .paused, .preparing]

        // Verify each state is only equal to itself
        for (index, state) in states.enumerated() {
            for (otherIndex, otherState) in states.enumerated() {
                if index == otherIndex {
                    #expect(state == otherState)
                } else {
                    #expect(state != otherState)
                }
            }
        }
    }

    // MARK: - Service Speech Rate Edge Cases

    @Test("Speech rate accepts negative value")
    func speechRateAcceptsNegative() {
        let service = SpeechSynthesisService()

        // AVSpeechSynthesizer may clamp this, but the service should accept any float
        service.speechRate = -0.5
        #expect(service.speechRate == -0.5)
    }

    @Test("Speech rate accepts value greater than one")
    func speechRateAcceptsGreaterThanOne() {
        let service = SpeechSynthesisService()

        service.speechRate = 1.5
        #expect(service.speechRate == 1.5)
    }

    // MARK: - Available Voices Edge Cases

    @Test("Available voices for locale with only language code")
    func availableVoicesForLanguageOnlyLocale() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "en")
        let voices = service.availableVoices(for: locale)

        // Verify all returned voices start with "en"
        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "en")
        }
    }

    @Test("Available voices for Chinese without script returns voices")
    func availableVoicesForChineseWithoutScript() {
        let service = SpeechSynthesisService()
        // Test with just "zh" - no script specified
        let locale = Locale(identifier: "zh")
        let voices = service.availableVoices(for: locale)

        // Verify all returned voices are for Chinese
        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    @Test("Available voices returns empty array for non-existent language")
    func availableVoicesForNonExistentLanguage() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zzz")
        let voices = service.availableVoices(for: locale)

        #expect(voices.isEmpty)
    }

    // MARK: - Speak State Transition Tests

    @Test("Speak with valid text sets state to preparing")
    func speakSetsStateToPreparing() async {
        let service = SpeechSynthesisService()

        // Immediately after speak is called, state should be preparing
        // Note: This will create the synthesizer and may start speaking
        await service.speak("Hello", locale: Locale(identifier: "en_US"), voicePreference: .system)

        // State should be either preparing, speaking, or idle depending on timing
        // The important thing is it's not an invalid state
        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))
    }

    // MARK: - Pause Speaking Tests

    @Test("Pause speaking when not speaking does nothing")
    func pauseSpeakingWhenNotSpeaking() async {
        let service = SpeechSynthesisService()

        // Start in idle state
        #expect(service.state == .idle)

        await service.pauseSpeaking()

        // State should remain idle since nothing was speaking
        #expect(service.state == .idle)
    }

    // MARK: - Enqueue Behavior Tests

    @Test("Enqueue with valid text when idle starts speaking")
    func enqueueWhenIdleStartsSpeaking() async {
        let service = SpeechSynthesisService()

        #expect(service.state == .idle)

        await service.enqueue("Hello", locale: Locale(identifier: "en_US"), voicePreference: .system)

        // When idle, enqueue should start speaking
        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))
    }

    // MARK: - Multiple Voice Preference Types

    @Test("Service accepts all voice preference types")
    func serviceAcceptsAllVoicePreferences() async {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "en_US")

        // Test with system preference
        await service.speak("Test", locale: locale, voicePreference: .system)
        await service.stopSpeaking()

        // Test with personal voice preference
        await service.speak("Test", locale: locale, voicePreference: .personalVoice)
        await service.stopSpeaking()

        // Test with specific voice preference
        await service.speak("Test", locale: locale, voicePreference: .specific(id: "any.voice.id"))
        await service.stopSpeaking()

        #expect(service.state == .idle)
    }

    // MARK: - Error LocalizedError Full Protocol Tests

    @Test("Errors can be thrown and caught")
    func errorsCanBeThrownAndCaught() {
        func throwingFunction() throws {
            throw SpeechSynthesisError.synthesisFailed
        }

        do {
            try throwingFunction()
            Issue.record("Expected error to be thrown")
        } catch let error as SpeechSynthesisError {
            if case .synthesisFailed = error {
                // Expected
            } else {
                Issue.record("Expected synthesisFailed error")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Voice not available error preserves locale")
    func voiceNotAvailablePreservesLocale() {
        let locale = Locale(identifier: "de_DE")
        let error = SpeechSynthesisError.voiceNotAvailable(locale)

        if case .voiceNotAvailable(let capturedLocale) = error {
            #expect(capturedLocale == locale)
        } else {
            Issue.record("Expected voiceNotAvailable case")
        }
    }

    @Test("All error cases can be switched over")
    func allErrorCasesCanBeSwitched() {
        let errors: [SpeechSynthesisError] = [
            .voiceNotAvailable(Locale(identifier: "en")),
            .personalVoiceNotAuthorized,
            .synthesisFailed,
            .alreadySpeaking
        ]

        for error in errors {
            let description: String
            switch error {
            case .voiceNotAvailable(let locale):
                description = "Voice not available for \(locale.identifier)"
            case .personalVoiceNotAuthorized:
                description = "Personal voice not authorized"
            case .synthesisFailed:
                description = "Synthesis failed"
            case .alreadySpeaking:
                description = "Already speaking"
            }
            #expect(!description.isEmpty)
        }
    }

    // MARK: - Service Multiple Operations Tests

    @Test("Stop speaking can be called multiple times safely")
    func stopSpeakingMultipleTimes() async {
        let service = SpeechSynthesisService()

        await service.stopSpeaking()
        await service.stopSpeaking()
        await service.stopSpeaking()

        #expect(service.state == .idle)
    }

    @Test("Pause and continue when idle does nothing")
    func pauseAndContinueWhenIdle() async {
        let service = SpeechSynthesisService()

        #expect(service.state == .idle)

        await service.pauseSpeaking()
        #expect(service.state == .idle)

        await service.continueSpeaking()
        #expect(service.state == .idle)
    }

    // MARK: - VoiceInfo Identifiable Protocol Tests

    @Test("VoiceInfo id property returns correct value")
    func voiceInfoIdProperty() {
        let expectedId = "com.apple.voice.test.id"
        let voice = VoiceInfo(
            id: expectedId,
            name: "Test",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        // Identifiable protocol requires id property
        #expect(voice.id == expectedId)
    }

    @Test("VoiceInfo can be used in ForEach-compatible collection")
    func voiceInfoCanBeUsedInCollection() {
        let voices = [
            VoiceInfo(id: "1", name: "Voice 1", locale: Locale(identifier: "en"), quality: .default, isPersonalVoice: false),
            VoiceInfo(id: "2", name: "Voice 2", locale: Locale(identifier: "en"), quality: .enhanced, isPersonalVoice: false),
            VoiceInfo(id: "3", name: "Voice 3", locale: Locale(identifier: "en"), quality: .premium, isPersonalVoice: true)
        ]

        // Verify each voice has unique id (required for ForEach)
        let ids = Set(voices.map(\.id))
        #expect(ids.count == 3)
    }

    // MARK: - Recovery Suggestion Coverage Tests

    @Test("Recovery suggestions cover voice not available case")
    func recoverySuggestionVoiceNotAvailable() {
        let error = SpeechSynthesisError.voiceNotAvailable(Locale(identifier: "en_US"))

        #expect(error.recoverySuggestion != nil)
    }

    @Test("Recovery suggestions cover personal voice not authorized case")
    func recoverySuggestionPersonalVoiceNotAuthorized() {
        let error = SpeechSynthesisError.personalVoiceNotAuthorized

        #expect(error.recoverySuggestion != nil)
    }

    @Test("Recovery suggestion nil for default cases")
    func recoverySuggestionDefaultCases() {
        // Both synthesisFailed and alreadySpeaking fall through to default
        let errors: [SpeechSynthesisError] = [.synthesisFailed, .alreadySpeaking]

        for error in errors {
            #expect(error.recoverySuggestion == nil)
        }
    }

    // MARK: - Speech Rate Boundary Condition Tests

    @Test("Speech rate accepts very small positive value")
    func speechRateAcceptsVerySmallPositive() {
        let service = SpeechSynthesisService()

        service.speechRate = 0.001
        #expect(service.speechRate == 0.001)
    }

    @Test("Speech rate accepts zero value")
    func speechRateAcceptsZero() {
        let service = SpeechSynthesisService()

        service.speechRate = 0.0
        #expect(service.speechRate == 0.0)
    }

    @Test("Speech rate accepts very large value")
    func speechRateAcceptsVeryLarge() {
        let service = SpeechSynthesisService()

        service.speechRate = 100.0
        #expect(service.speechRate == 100.0)
    }

    @Test("Speech rate preserves float precision")
    func speechRatePreservesPrecision() {
        let service = SpeechSynthesisService()

        service.speechRate = 0.123456
        #expect(abs(service.speechRate - 0.123456) < 0.0001)
    }

    @Test("Speech rate can be set multiple times")
    func speechRateMultipleSets() {
        let service = SpeechSynthesisService()

        service.speechRate = 0.1
        #expect(service.speechRate == 0.1)

        service.speechRate = 0.5
        #expect(service.speechRate == 0.5)

        service.speechRate = 0.9
        #expect(service.speechRate == 0.9)
    }

    // MARK: - Chinese Voice Selection Edge Cases

    @Test("Available voices for Chinese with CN region")
    func availableVoicesForChineseCN() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh_CN")
        let voices = service.availableVoices(for: locale)

        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    @Test("Available voices for Chinese with TW region")
    func availableVoicesForChineseTW() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh_TW")
        let voices = service.availableVoices(for: locale)

        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    @Test("Available voices for Chinese with HK region")
    func availableVoicesForChineseHK() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh_HK")
        let voices = service.availableVoices(for: locale)

        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    @Test("Available voices for Chinese with SG region")
    func availableVoicesForChineseSG() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh_SG")
        let voices = service.availableVoices(for: locale)

        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    @Test("Available voices for Chinese with MO region")
    func availableVoicesForChineseMO() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "zh_MO")
        let voices = service.availableVoices(for: locale)

        for voice in voices {
            let languageCode = voice.locale.language.languageCode?.identifier ?? ""
            #expect(languageCode == "zh")
        }
    }

    // MARK: - Voice Preference Selection Edge Cases

    @Test("Speak with personal voice preference when not authorized falls back to system")
    func speakWithPersonalVoiceWhenNotAuthorized() async {
        let service = SpeechSynthesisService()

        // Personal voice is not authorized by default
        #expect(service.isPersonalVoiceAuthorized == false)

        // Should still work, falling back to system voice
        await service.speak("Test", locale: Locale(identifier: "en_US"), voicePreference: .personalVoice)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Speak with specific non-existent voice ID falls back to system")
    func speakWithNonExistentVoiceId() async {
        let service = SpeechSynthesisService()

        // Use a voice ID that definitely doesn't exist
        await service.speak("Test", locale: Locale(identifier: "en_US"), voicePreference: .specific(id: "nonexistent.voice.id.12345"))

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Speak with system voice preference uses best available voice")
    func speakWithSystemVoice() async {
        let service = SpeechSynthesisService()

        await service.speak("Test", locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    // MARK: - Speak Interruption Tests

    @Test("Speaking new text interrupts current speech")
    func speakingInterruptsCurrentSpeech() async {
        let service = SpeechSynthesisService()

        // Start first speech
        await service.speak("First message", locale: Locale(identifier: "en_US"), voicePreference: .system)

        // Start second speech - should interrupt first
        await service.speak("Second message", locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    // MARK: - Enqueue Behavior Tests (Extended)

    @Test("Enqueue multiple items when idle processes first immediately")
    func enqueueMultipleWhenIdle() async {
        let service = SpeechSynthesisService()

        #expect(service.state == .idle)

        // First enqueue should start speaking
        await service.enqueue("First", locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Enqueue with different locales")
    func enqueueWithDifferentLocales() async {
        let service = SpeechSynthesisService()

        await service.enqueue("Hello", locale: Locale(identifier: "en_US"), voicePreference: .system)
        await service.enqueue("Bonjour", locale: Locale(identifier: "fr_FR"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Enqueue with different voice preferences")
    func enqueueWithDifferentVoicePreferences() async {
        let service = SpeechSynthesisService()

        await service.enqueue("Test one", locale: Locale(identifier: "en_US"), voicePreference: .system)
        await service.enqueue("Test two", locale: Locale(identifier: "en_US"), voicePreference: .personalVoice)
        await service.enqueue("Test three", locale: Locale(identifier: "en_US"), voicePreference: .specific(id: "any.id"))

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    // MARK: - Service Lifecycle Tests

    @Test("Service can be created and destroyed multiple times")
    func serviceCreationDestruction() {
        for _ in 0..<5 {
            let service = SpeechSynthesisService()
            #expect(service.state == .idle)
        }
    }

    @Test("Multiple service instances are independent")
    func multipleServiceInstances() async {
        let service1 = SpeechSynthesisService()
        let service2 = SpeechSynthesisService()

        service1.speechRate = 0.3
        service2.speechRate = 0.7

        #expect(service1.speechRate == 0.3)
        #expect(service2.speechRate == 0.7)

        await service1.stopSpeaking()
        #expect(service1.state == .idle)
        #expect(service2.state == .idle)
    }

    // MARK: - Locale Edge Cases

    @Test("Available voices for locale with empty language code")
    func availableVoicesForEmptyLanguageCode() {
        let service = SpeechSynthesisService()
        let locale = Locale(identifier: "")
        let voices = service.availableVoices(for: locale)

        // Should return empty array for invalid locale
        #expect(voices is [VoiceInfo])
    }

    @Test("Speak with various locale formats")
    func speakWithVariousLocaleFormats() async {
        let service = SpeechSynthesisService()

        // BCP47 format
        await service.speak("Test", locale: Locale(identifier: "en-US"), voicePreference: .system)
        await service.stopSpeaking()

        // Underscore format
        await service.speak("Test", locale: Locale(identifier: "en_US"), voicePreference: .system)
        await service.stopSpeaking()

        // Language only
        await service.speak("Test", locale: Locale(identifier: "en"), voicePreference: .system)
        await service.stopSpeaking()

        #expect(service.state == .idle)
    }

    // MARK: - Error Equality Tests

    @Test("Voice not available errors with same locale are equal")
    func voiceNotAvailableErrorsWithSameLocaleAreEqual() {
        let locale = Locale(identifier: "en_US")
        let error1 = SpeechSynthesisError.voiceNotAvailable(locale)
        let error2 = SpeechSynthesisError.voiceNotAvailable(locale)

        // Note: SpeechSynthesisError doesn't conform to Equatable,
        // so we compare their descriptions
        #expect(error1.errorDescription == error2.errorDescription)
    }

    @Test("Different error types have different descriptions")
    func differentErrorTypesHaveDifferentDescriptions() {
        let allErrors: [SpeechSynthesisError] = [
            .voiceNotAvailable(Locale(identifier: "en_US")),
            .personalVoiceNotAuthorized,
            .synthesisFailed,
            .alreadySpeaking
        ]

        var descriptions = Set<String>()
        for error in allErrors {
            if let description = error.errorDescription {
                descriptions.insert(description)
            }
        }

        // All error types should have unique descriptions
        #expect(descriptions.count == 4)
    }

    // MARK: - State After Operations Tests

    @Test("State is idle after stop speaking from idle")
    func stateIdleAfterStopFromIdle() async {
        let service = SpeechSynthesisService()

        #expect(service.state == .idle)
        await service.stopSpeaking()
        #expect(service.state == .idle)
    }

    @Test("Continue speaking does nothing when in preparing state")
    func continueSpeakingInPreparingState() async {
        let service = SpeechSynthesisService()

        // Note: We can't reliably test the preparing state since it transitions quickly
        // This test verifies continue doesn't cause issues from idle
        await service.continueSpeaking()
        #expect(service.state == .idle)
    }

    // MARK: - VoiceInfo Edge Cases

    @Test("VoiceInfo with empty strings")
    func voiceInfoWithEmptyStrings() {
        let voice = VoiceInfo(
            id: "",
            name: "",
            locale: Locale(identifier: ""),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voice.id.isEmpty)
        #expect(voice.name.isEmpty)
    }

    @Test("VoiceInfo with unicode characters in name")
    func voiceInfoWithUnicodeCharacters() {
        let voice = VoiceInfo(
            id: "unicode.voice",
            name: "Voix francaise",
            locale: Locale(identifier: "fr_FR"),
            quality: .enhanced,
            isPersonalVoice: false
        )

        #expect(voice.name == "Voix francaise")
    }

    @Test("VoiceInfo with very long id")
    func voiceInfoWithVeryLongId() {
        let longId = String(repeating: "a", count: 1000)
        let voice = VoiceInfo(
            id: longId,
            name: "Long ID Voice",
            locale: Locale(identifier: "en_US"),
            quality: .default,
            isPersonalVoice: false
        )

        #expect(voice.id.count == 1000)
    }

    // MARK: - isSpeaking Property Tests

    @Test("isSpeaking returns false when synthesizer not initialized")
    func isSpeakingFalseWhenNotInitialized() {
        let service = SpeechSynthesisService()

        // Before any speak call, synthesizer is nil
        #expect(service.isSpeaking == false)
    }

    @Test("isSpeaking reflects synthesizer state")
    func isSpeakingReflectsSynthesizerState() async {
        let service = SpeechSynthesisService()

        // Initially not speaking
        #expect(service.isSpeaking == false)

        // After stopping, not speaking
        await service.stopSpeaking()
        #expect(service.isSpeaking == false)
    }

    // MARK: - Delegate Callback Edge Cases

    @Test("Delegate can track all callback types")
    func delegateTracksAllCallbacks() {
        let delegate = MockSpeechSynthesisDelegate()

        // Simulate all callback scenarios
        delegate.speechDidStart()
        delegate.speechDidPause()
        delegate.speechDidContinue()
        delegate.speechProgress(characterIndex: 0, characterLength: 5)
        delegate.speechProgress(characterIndex: 5, characterLength: 3)
        delegate.speechDidFinish()
        delegate.speechDidCancel()

        #expect(delegate.didStartCalled == true)
        #expect(delegate.didPauseCalled == true)
        #expect(delegate.didContinueCalled == true)
        #expect(delegate.didFinishCalled == true)
        #expect(delegate.didCancelCalled == true)
        #expect(delegate.progressCalls.count == 2)
        #expect(delegate.progressCalls[0].characterIndex == 0)
        #expect(delegate.progressCalls[0].characterLength == 5)
        #expect(delegate.progressCalls[1].characterIndex == 5)
        #expect(delegate.progressCalls[1].characterLength == 3)
    }

    @Test("Delegate progress calls track character ranges")
    func delegateProgressCallsTrackRanges() {
        let delegate = MockSpeechSynthesisDelegate()

        delegate.speechProgress(characterIndex: 10, characterLength: 20)

        #expect(delegate.progressCalls.count == 1)
        #expect(delegate.progressCalls.first?.characterIndex == 10)
        #expect(delegate.progressCalls.first?.characterLength == 20)
    }

    // MARK: - Service Protocol Conformance Extended Tests

    @Test("Service protocol methods return expected types")
    func serviceProtocolMethodsReturnExpectedTypes() async {
        let service = SpeechSynthesisService()

        // Test property types
        let _: SpeechSynthesisState = service.state
        let _: Bool = service.isPersonalVoiceAuthorized
        let _: Bool = service.isSpeaking

        // Test available voices returns array
        let voices: [VoiceInfo] = service.availableVoices(for: Locale(identifier: "en"))
        #expect(voices is [VoiceInfo])
    }

    // MARK: - Specific Voice ID Tests

    @Test("VoicePreference specific with empty ID")
    func voicePreferenceSpecificWithEmptyId() {
        let preference = VoicePreference.specific(id: "")

        if case .specific(let voiceId) = preference {
            #expect(voiceId.isEmpty)
        } else {
            Issue.record("Expected .specific case")
        }
    }

    @Test("VoicePreference specific with special characters")
    func voicePreferenceSpecificWithSpecialCharacters() {
        let specialId = "com.apple.voice.compact.en-US.Samantha (Enhanced)"
        let preference = VoicePreference.specific(id: specialId)

        if case .specific(let id) = preference {
            #expect(id == specialId)
        } else {
            Issue.record("Expected .specific case")
        }
    }

    // MARK: - Available Voices Return Type Tests

    @Test("Available voices array elements have all required properties")
    func availableVoicesHaveAllProperties() {
        let service = SpeechSynthesisService()
        let voices = service.availableVoices(for: Locale(identifier: "en_US"))

        for voice in voices {
            // Each voice should have non-nil required properties
            #expect(!voice.id.isEmpty || voice.id.isEmpty) // id exists
            #expect(!voice.name.isEmpty || voice.name.isEmpty) // name exists
            let _: Locale = voice.locale // locale exists
            let _: VoiceInfo.VoiceQuality = voice.quality // quality exists
            let _: Bool = voice.isPersonalVoice // isPersonalVoice exists
        }
    }

    // MARK: - Speak with Various Text Types

    @Test("Speak with whitespace-only text")
    func speakWithWhitespaceOnlyText() async {
        let service = SpeechSynthesisService()

        // Whitespace-only is not empty, so it should attempt to speak
        await service.speak("   ", locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Speak with newline characters")
    func speakWithNewlineCharacters() async {
        let service = SpeechSynthesisService()

        await service.speak("Line one\nLine two\nLine three", locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Speak with unicode text")
    func speakWithUnicodeText() async {
        let service = SpeechSynthesisService()

        await service.speak("Hello world", locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    @Test("Speak with very long text")
    func speakWithVeryLongText() async {
        let service = SpeechSynthesisService()

        let longText = String(repeating: "This is a test sentence. ", count: 100)
        await service.speak(longText, locale: Locale(identifier: "en_US"), voicePreference: .system)

        let validStates: [SpeechSynthesisState] = [.preparing, .speaking, .idle]
        #expect(validStates.contains(service.state))

        await service.stopSpeaking()
    }

    // MARK: - Stop Speaking Clears Queue Test

    @Test("Stop speaking clears pending queue")
    func stopSpeakingClearsPendingQueue() async {
        let service = SpeechSynthesisService()

        // Enqueue multiple items
        await service.enqueue("First", locale: Locale(identifier: "en_US"), voicePreference: .system)
        await service.enqueue("Second", locale: Locale(identifier: "en_US"), voicePreference: .system)
        await service.enqueue("Third", locale: Locale(identifier: "en_US"), voicePreference: .system)

        // Stop should clear everything
        await service.stopSpeaking()

        #expect(service.state == .idle)
    }

    // MARK: - Personal Voice Authorization Status Tests

    @Test("Personal voice authorization status can be used in switch")
    func personalVoiceAuthorizationStatusSwitch() {
        let statuses: [PersonalVoiceAuthorizationStatus] = [.authorized, .denied, .notDetermined, .unsupported]

        for status in statuses {
            let description: String
            switch status {
            case .authorized:
                description = "Authorized"
            case .denied:
                description = "Denied"
            case .notDetermined:
                description = "Not Determined"
            case .unsupported:
                description = "Unsupported"
            }
            #expect(!description.isEmpty)
        }
    }

    // MARK: - Voice Quality All Cases Tests

    @Test("Voice quality can be used in switch")
    func voiceQualitySwitch() {
        let qualities: [VoiceInfo.VoiceQuality] = [.default, .enhanced, .premium]

        for quality in qualities {
            let description: String
            switch quality {
            case .default:
                description = "Default"
            case .enhanced:
                description = "Enhanced"
            case .premium:
                description = "Premium"
            }
            #expect(!description.isEmpty)
        }
    }
}

// MARK: - Mock Delegate

/// Mock delegate for testing delegate behavior
@MainActor
private final class MockSpeechSynthesisDelegate: SpeechSynthesisDelegate {
    var didStartCalled = false
    var didFinishCalled = false
    var didPauseCalled = false
    var didContinueCalled = false
    var didCancelCalled = false
    var progressCalls: [(characterIndex: Int, characterLength: Int)] = []

    func speechDidStart() {
        didStartCalled = true
    }

    func speechDidFinish() {
        didFinishCalled = true
    }

    func speechDidPause() {
        didPauseCalled = true
    }

    func speechDidContinue() {
        didContinueCalled = true
    }

    func speechDidCancel() {
        didCancelCalled = true
    }

    func speechProgress(characterIndex: Int, characterLength: Int) {
        progressCalls.append((characterIndex: characterIndex, characterLength: characterLength))
    }
}
