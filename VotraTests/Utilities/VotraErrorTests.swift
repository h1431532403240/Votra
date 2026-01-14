//
//  VotraErrorTests.swift
//  VotraTests
//
//  Tests for VotraError centralized error handling.
//

import Foundation
import Testing
@testable import Votra

@Suite("Votra Error Tests")
@MainActor
struct VotraErrorTests {

    // MARK: - Error Description Tests

    @Test("All permission errors have non-empty descriptions")
    func permissionErrorDescriptions() {
        let permissionErrors: [VotraError] = [
            .microphonePermissionDenied,
            .screenRecordingPermissionDenied,
            .speechRecognitionPermissionDenied
        ]

        for error in permissionErrors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("All service errors have non-empty descriptions")
    func serviceErrorDescriptions() {
        let serviceErrors: [VotraError] = [
            .translationFailed,
            .speechRecognitionFailed,
            .recordingFailed,
            .summaryGenerationFailed
        ]

        for error in serviceErrors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("All resource errors have non-empty descriptions")
    func resourceErrorDescriptions() {
        let resourceErrors: [VotraError] = [
            .appleIntelligenceUnavailable,
            .deviceNotSupported,
            .diskFull,
            .networkUnavailable
        ]

        for error in resourceErrors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("Language not downloaded error has non-empty description")
    func languageNotDownloadedErrorDescription() {
        let locale = Locale(identifier: "en_US")
        let error = VotraError.languageNotDownloaded(locale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Language not downloaded error with invalid locale uses fallback")
    func languageNotDownloadedErrorWithInvalidLocale() {
        // Use a locale with an empty or invalid language code to trigger the fallback
        let invalidLocale = Locale(identifier: "")
        let error = VotraError.languageNotDownloaded(invalidLocale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Language pair not supported error has non-empty description")
    func languagePairNotSupportedErrorDescription() {
        let sourceLocale = Locale(identifier: "en_US")
        let targetLocale = Locale(identifier: "ja_JP")
        let error = VotraError.languagePairNotSupported(source: sourceLocale, target: targetLocale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("Language pair not supported error with invalid locales uses fallback")
    func languagePairNotSupportedErrorWithInvalidLocales() {
        // Use locales with empty or invalid language codes to trigger the fallback
        let invalidSourceLocale = Locale(identifier: "")
        let invalidTargetLocale = Locale(identifier: "")
        let error = VotraError.languagePairNotSupported(source: invalidSourceLocale, target: invalidTargetLocale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - Recovery Suggestion Tests

    @Test("Permission errors have recovery suggestions")
    func permissionErrorsHaveRecoverySuggestions() {
        let permissionErrors: [VotraError] = [
            .microphonePermissionDenied,
            .screenRecordingPermissionDenied,
            .speechRecognitionPermissionDenied
        ]

        for error in permissionErrors {
            #expect(error.recoverySuggestion != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }

    @Test("Language errors have recovery suggestions")
    func languageErrorsHaveRecoverySuggestions() {
        let locale = Locale(identifier: "es_ES")
        let languageErrors: [VotraError] = [
            .languageNotDownloaded(locale),
            .languagePairNotSupported(source: Locale(identifier: "en_US"), target: Locale(identifier: "zh_CN"))
        ]

        for error in languageErrors {
            #expect(error.recoverySuggestion != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }

    @Test("Apple Intelligence unavailable has recovery suggestion")
    func appleIntelligenceUnavailableHasRecoverySuggestion() {
        let error = VotraError.appleIntelligenceUnavailable
        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("Disk full has recovery suggestion")
    func diskFullHasRecoverySuggestion() {
        let error = VotraError.diskFull
        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("Service errors have no recovery suggestions")
    func serviceErrorsHaveNoRecoverySuggestions() {
        let serviceErrors: [VotraError] = [
            .translationFailed,
            .speechRecognitionFailed,
            .recordingFailed,
            .summaryGenerationFailed,
            .deviceNotSupported,
            .networkUnavailable
        ]

        for error in serviceErrors {
            #expect(error.recoverySuggestion == nil)
        }
    }

    // MARK: - LocalizedError Conformance Tests

    @Test("Errors conform to LocalizedError")
    func errorsConformToLocalizedError() {
        let error: any LocalizedError = VotraError.microphonePermissionDenied

        // LocalizedError provides errorDescription property
        #expect(error.errorDescription != nil)
    }

    @Test("Error can be used as Error type")
    func errorCanBeUsedAsErrorType() {
        let error: any Error = VotraError.translationFailed

        // Cast back to VotraError should work
        #expect(error is VotraError)
    }

    @Test("LocalizedDescription is available on all errors")
    func localizedDescriptionAvailable() {
        let allErrors: [VotraError] = [
            .microphonePermissionDenied,
            .screenRecordingPermissionDenied,
            .speechRecognitionPermissionDenied,
            .languageNotDownloaded(Locale(identifier: "fr_FR")),
            .languagePairNotSupported(source: Locale(identifier: "de_DE"), target: Locale(identifier: "it_IT")),
            .translationFailed,
            .speechRecognitionFailed,
            .recordingFailed,
            .summaryGenerationFailed,
            .appleIntelligenceUnavailable,
            .deviceNotSupported,
            .diskFull,
            .networkUnavailable
        ]

        for error in allErrors {
            // localizedDescription should not be empty (provided by LocalizedError)
            #expect(!error.localizedDescription.isEmpty)
        }
    }

    // MARK: - Error Equality Tests

    @Test("Same error cases are equal")
    func sameErrorCasesAreEqual() {
        let error1 = VotraError.microphonePermissionDenied
        let error2 = VotraError.microphonePermissionDenied

        // Enum cases without associated values should be equal
        #expect(error1.errorDescription == error2.errorDescription)
    }

    @Test("Different error cases have different descriptions")
    func differentErrorCasesHaveDifferentDescriptions() {
        let error1 = VotraError.microphonePermissionDenied
        let error2 = VotraError.speechRecognitionPermissionDenied

        #expect(error1.errorDescription != error2.errorDescription)
    }

    @Test("Language errors with same locale have same description")
    func languageErrorsWithSameLocaleHaveSameDescription() {
        let locale = Locale(identifier: "ko_KR")
        let error1 = VotraError.languageNotDownloaded(locale)
        let error2 = VotraError.languageNotDownloaded(locale)

        #expect(error1.errorDescription == error2.errorDescription)
    }

    @Test("Language errors with different locales have different descriptions")
    func languageErrorsWithDifferentLocalesHaveDifferentDescriptions() {
        let error1 = VotraError.languageNotDownloaded(Locale(identifier: "en_US"))
        let error2 = VotraError.languageNotDownloaded(Locale(identifier: "ja_JP"))

        // The descriptions should differ because they mention different languages
        #expect(error1.errorDescription != error2.errorDescription)
    }

    // MARK: - Error Description Uniqueness Tests

    @Test("Each error case has a unique description")
    func eachErrorCaseHasUniqueDescription() {
        let allErrors: [VotraError] = [
            .microphonePermissionDenied,
            .screenRecordingPermissionDenied,
            .speechRecognitionPermissionDenied,
            .translationFailed,
            .speechRecognitionFailed,
            .recordingFailed,
            .summaryGenerationFailed,
            .appleIntelligenceUnavailable,
            .deviceNotSupported,
            .diskFull,
            .networkUnavailable
        ]

        var descriptions = Set<String>()
        for error in allErrors {
            let description = error.errorDescription ?? ""
            #expect(!descriptions.contains(description), "Duplicate description found: \(description)")
            descriptions.insert(description)
        }
    }

    @Test("Error descriptions are not just the case name")
    func errorDescriptionsAreUserFriendly() {
        let error = VotraError.microphonePermissionDenied
        let description = error.errorDescription ?? ""

        // User-friendly description should not just be the enum case name
        #expect(!description.contains("microphonePermissionDenied"))
    }
}
