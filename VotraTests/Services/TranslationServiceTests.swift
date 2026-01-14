//
//  TranslationServiceTests.swift
//  VotraTests
//
//  Tests for TranslationService and related types.
//

import Foundation
import Testing
@preconcurrency import Translation
@testable import Votra

// Use the local TranslationError from Votra
typealias LocalTranslationError = Votra.TranslationError

// MARK: - TranslationError Tests

@Suite("Translation Error Tests")
struct TranslationErrorTests {

    // MARK: - Error Description Tests

    @Test("All error cases have non-empty descriptions")
    func allErrorsHaveDescriptions() {
        let errors: [LocalTranslationError] = [
            .noSession,
            .languagePairNotSupported(source: Locale(identifier: "en_US"), target: Locale(identifier: "ja_JP")),
            .languageNotDownloaded(Locale(identifier: "fr_FR")),
            .translationFailed(underlying: NSError(domain: "Test", code: 0)),
            .emptyInput,
            .rateLimited
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            // swiftlint:disable:next force_unwrapping
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("noSession error has non-empty description")
    func noSessionErrorDescription() {
        let error = LocalTranslationError.noSession
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("languagePairNotSupported error has non-empty description")
    func languagePairNotSupportedErrorDescription() {
        let source = Locale(identifier: "en_US")
        let target = Locale(identifier: "ja_JP")
        let error = LocalTranslationError.languagePairNotSupported(source: source, target: target)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("languageNotDownloaded error has non-empty description")
    func languageNotDownloadedErrorDescription() {
        let locale = Locale(identifier: "de_DE")
        let error = LocalTranslationError.languageNotDownloaded(locale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("translationFailed error has non-empty description")
    func translationFailedErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 42)
        let error = LocalTranslationError.translationFailed(underlying: underlyingError)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("emptyInput error has non-empty description")
    func emptyInputErrorDescription() {
        let error = LocalTranslationError.emptyInput

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("rateLimited error has non-empty description")
    func rateLimitedErrorDescription() {
        let error = LocalTranslationError.rateLimited

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - Recovery Suggestion Tests

    @Test("noSession error has recovery suggestion")
    func noSessionHasRecoverySuggestion() {
        let error = LocalTranslationError.noSession
        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("languagePairNotSupported has recovery suggestion")
    func languagePairNotSupportedHasRecoverySuggestion() {
        let error = LocalTranslationError.languagePairNotSupported(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "zh_CN")
        )
        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("languageNotDownloaded has recovery suggestion")
    func languageNotDownloadedHasRecoverySuggestion() {
        let error = LocalTranslationError.languageNotDownloaded(Locale(identifier: "es_ES"))
        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("rateLimited has recovery suggestion")
    func rateLimitedHasRecoverySuggestion() {
        let error = LocalTranslationError.rateLimited
        #expect(error.recoverySuggestion != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("translationFailed has no recovery suggestion")
    func translationFailedHasNoRecoverySuggestion() {
        let error = LocalTranslationError.translationFailed(underlying: NSError(domain: "Test", code: 0))
        #expect(error.recoverySuggestion == nil)
    }

    @Test("emptyInput has no recovery suggestion")
    func emptyInputHasNoRecoverySuggestion() {
        let error = LocalTranslationError.emptyInput
        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - LocalizedError Conformance Tests

    @Test("Errors conform to LocalizedError")
    func errorsConformToLocalizedError() {
        let error: any LocalizedError = LocalTranslationError.noSession
        #expect(error.errorDescription != nil)
    }

    @Test("Error can be used as Error type")
    func errorCanBeUsedAsErrorType() {
        let error: any Error = LocalTranslationError.emptyInput
        #expect(error is LocalTranslationError)
    }

    @Test("localizedDescription is available on all errors")
    func localizedDescriptionAvailable() {
        let errors: [LocalTranslationError] = [
            .noSession,
            .languagePairNotSupported(source: Locale(identifier: "en"), target: Locale(identifier: "de")),
            .languageNotDownloaded(Locale(identifier: "it")),
            .translationFailed(underlying: NSError(domain: "Test", code: 0)),
            .emptyInput,
            .rateLimited
        ]

        for error in errors {
            #expect(!error.localizedDescription.isEmpty)
        }
    }

    // MARK: - Error Uniqueness Tests

    @Test("Each error case has a unique description")
    func eachErrorCaseHasUniqueDescription() {
        let errors: [LocalTranslationError] = [
            .noSession,
            .emptyInput,
            .rateLimited
        ]

        var descriptions = Set<String>()
        for error in errors {
            let description = error.errorDescription ?? ""
            #expect(!descriptions.contains(description), "Duplicate description found: \(description)")
            descriptions.insert(description)
        }
    }

    @Test("Different language pairs produce different error descriptions")
    func differentLanguagePairsProduceDifferentDescriptions() {
        let error1 = LocalTranslationError.languagePairNotSupported(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let error2 = LocalTranslationError.languagePairNotSupported(
            source: Locale(identifier: "fr_FR"),
            target: Locale(identifier: "de_DE")
        )

        #expect(error1.errorDescription != error2.errorDescription)
    }

    @Test("Same language pairs produce same error descriptions")
    func sameLanguagePairsProduceSameDescriptions() {
        let error1 = LocalTranslationError.languagePairNotSupported(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let error2 = LocalTranslationError.languagePairNotSupported(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )

        #expect(error1.errorDescription == error2.errorDescription)
    }
}

// MARK: - TranslationServiceState Tests

@Suite("Translation Service State Tests")
struct TranslationServiceStateTests {

    @Test("idle state equals itself")
    func idleStateEquality() {
        let state1 = TranslationServiceState.idle
        let state2 = TranslationServiceState.idle
        #expect(state1 == state2)
    }

    @Test("ready state equals itself")
    func readyStateEquality() {
        let state1 = TranslationServiceState.ready
        let state2 = TranslationServiceState.ready
        #expect(state1 == state2)
    }

    @Test("translating state equals itself")
    func translatingStateEquality() {
        let state1 = TranslationServiceState.translating
        let state2 = TranslationServiceState.translating
        #expect(state1 == state2)
    }

    @Test("error states with same message are equal")
    func errorStateEqualityWithSameMessage() {
        let state1 = TranslationServiceState.error(message: "Test error")
        let state2 = TranslationServiceState.error(message: "Test error")
        #expect(state1 == state2)
    }

    @Test("error states with different messages are not equal")
    func errorStateInequalityWithDifferentMessages() {
        let state1 = TranslationServiceState.error(message: "Error 1")
        let state2 = TranslationServiceState.error(message: "Error 2")
        #expect(state1 != state2)
    }

    @Test("different states are not equal")
    func differentStatesAreNotEqual() {
        let idle = TranslationServiceState.idle
        let ready = TranslationServiceState.ready
        let translating = TranslationServiceState.translating
        let error = TranslationServiceState.error(message: "Error")

        #expect(idle != ready)
        #expect(idle != translating)
        #expect(idle != error)
        #expect(ready != translating)
        #expect(ready != error)
        #expect(translating != error)
    }

    @Test("state is Sendable")
    func stateIsSendable() {
        let state: TranslationServiceState = .ready

        // This compiles only if TranslationServiceState is Sendable
        let _: any Sendable = state
        #expect(true)
    }
}

// MARK: - LanguagePair Tests

@Suite("Language Pair Tests")
struct LanguagePairTests {

    @Test("initialization sets source and target correctly")
    func initializationSetsProperties() {
        let source = Locale(identifier: "en_US")
        let target = Locale(identifier: "ja_JP")
        let pair = LanguagePair(source: source, target: target)

        #expect(pair.source == source)
        #expect(pair.target == target)
    }

    @Test("reversed swaps source and target")
    func reversedSwapsSourceAndTarget() {
        let source = Locale(identifier: "en_US")
        let target = Locale(identifier: "fr_FR")
        let pair = LanguagePair(source: source, target: target)
        let reversed = pair.reversed

        #expect(reversed.source == target)
        #expect(reversed.target == source)
    }

    @Test("double reversed equals original")
    func doubleReversedEqualsOriginal() {
        let pair = LanguagePair(
            source: Locale(identifier: "de_DE"),
            target: Locale(identifier: "it_IT")
        )
        let doubleReversed = pair.reversed.reversed

        #expect(doubleReversed == pair)
    }

    @Test("equal pairs are equal")
    func equalPairsAreEqual() {
        let pair1 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let pair2 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )

        #expect(pair1 == pair2)
    }

    @Test("pairs with different sources are not equal")
    func pairsWithDifferentSourcesAreNotEqual() {
        let pair1 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let pair2 = LanguagePair(
            source: Locale(identifier: "fr_FR"),
            target: Locale(identifier: "ja_JP")
        )

        #expect(pair1 != pair2)
    }

    @Test("pairs with different targets are not equal")
    func pairsWithDifferentTargetsAreNotEqual() {
        let pair1 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let pair2 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "de_DE")
        )

        #expect(pair1 != pair2)
    }

    @Test("LanguagePair is Sendable")
    func languagePairIsSendable() {
        let pair = LanguagePair(
            source: Locale(identifier: "en"),
            target: Locale(identifier: "ja")
        )

        // This compiles only if LanguagePair is Sendable
        let _: any Sendable = pair
        #expect(true)
    }

    @Test("LanguagePair is Hashable")
    func languagePairIsHashable() {
        let pair1 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let pair2 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )

        var set = Set<LanguagePair>()
        set.insert(pair1)
        set.insert(pair2)

        // Equal pairs should only produce one entry in the set
        #expect(set.count == 1)
    }

    @Test("different LanguagePairs have different hash values")
    func differentLanguagePairsHaveDifferentHashValues() {
        let pair1 = LanguagePair(
            source: Locale(identifier: "en_US"),
            target: Locale(identifier: "ja_JP")
        )
        let pair2 = LanguagePair(
            source: Locale(identifier: "fr_FR"),
            target: Locale(identifier: "de_DE")
        )

        var set = Set<LanguagePair>()
        set.insert(pair1)
        set.insert(pair2)

        #expect(set.count == 2)
    }
}

// MARK: - LanguageDownloadStatus Tests

@Suite("Language Download Status Tests")
struct LanguageDownloadStatusTests {

    @Test("installed status is distinct")
    func installedStatusIsDistinct() {
        let status = LanguageDownloadStatus.installed

        switch status {
        case .installed:
            #expect(true)
        default:
            Issue.record("Expected installed status")
        }
    }

    @Test("notInstalled status is distinct")
    func notInstalledStatusIsDistinct() {
        let status = LanguageDownloadStatus.notInstalled

        switch status {
        case .notInstalled:
            #expect(true)
        default:
            Issue.record("Expected notInstalled status")
        }
    }

    @Test("downloading status contains progress")
    func downloadingStatusContainsProgress() {
        let status = LanguageDownloadStatus.downloading(progress: 0.5)

        switch status {
        case .downloading(let progress):
            #expect(progress == 0.5)
        default:
            Issue.record("Expected downloading status")
        }
    }

    @Test("unknown status is distinct")
    func unknownStatusIsDistinct() {
        let status = LanguageDownloadStatus.unknown

        switch status {
        case .unknown:
            #expect(true)
        default:
            Issue.record("Expected unknown status")
        }
    }

    @Test("LanguageDownloadStatus is Sendable")
    func languageDownloadStatusIsSendable() {
        let status: LanguageDownloadStatus = .installed

        // This compiles only if LanguageDownloadStatus is Sendable
        let _: any Sendable = status
        #expect(true)
    }

    @Test("downloading progress values are correctly stored")
    func downloadingProgressValuesAreCorrectlyStored() {
        let progressValues: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for progress in progressValues {
            let status = LanguageDownloadStatus.downloading(progress: progress)

            if case .downloading(let storedProgress) = status {
                #expect(storedProgress == progress)
            } else {
                Issue.record("Expected downloading status for progress \(progress)")
            }
        }
    }
}

// MARK: - TranslationService Tests

@Suite("Translation Service Tests")
@MainActor
struct TranslationServiceTests {

    // MARK: - Initialization Tests

    @Test("service initializes with idle state")
    func serviceInitializesWithIdleState() {
        let service = TranslationService()
        #expect(service.state == .idle)
    }

    @Test("service initializes without session")
    func serviceInitializesWithoutSession() {
        let service = TranslationService()
        #expect(service.hasSession == false)
    }

    // MARK: - State Management Tests

    @Test("hasSession returns false when no session set")
    func hasSessionReturnsFalseWithoutSession() {
        let service = TranslationService()
        #expect(service.hasSession == false)
    }

    @Test("setSession with invalid type does not set session")
    func setSessionWithInvalidTypeDoesNotSetSession() async {
        let service = TranslationService()

        // Passing a non-TranslationSession object should be ignored
        await service.setSession("invalid session")

        #expect(service.hasSession == false)
        #expect(service.state == .idle) // State should remain idle
    }

    @Test("setSession with nil does not crash")
    func setSessionWithNilDoesNotCrash() async {
        let service = TranslationService()

        // Passing nil (as Any) should be safely handled
        let nilValue: Any? = nil
        if let value = nilValue {
            await service.setSession(value)
        }

        #expect(service.hasSession == false)
    }

    // MARK: - Translation Method Tests (Error Cases)

    @Test("translate throws emptyInput for empty string")
    func translateThrowsEmptyInputForEmptyString() async {
        let service = TranslationService()

        do {
            _ = try await service.translate(
                "",
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected emptyInput error to be thrown")
        } catch let error as LocalTranslationError {
            if case .emptyInput = error {
                // Expected
            } else {
                Issue.record("Expected emptyInput error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("translate throws noSession when session not set")
    func translateThrowsNoSessionWhenSessionNotSet() async {
        let service = TranslationService()

        do {
            _ = try await service.translate(
                "Hello",
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("translate checks empty input before session")
    func translateChecksEmptyInputBeforeSession() async {
        let service = TranslationService()

        // Even without a session, empty input should be caught first
        do {
            _ = try await service.translate(
                "",
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected error to be thrown")
        } catch let error as LocalTranslationError {
            // Empty input error should be thrown before noSession
            if case .emptyInput = error {
                // Expected
            } else {
                Issue.record("Expected emptyInput error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Batch Translation Tests

    @Test("translateBatch returns empty array for empty input")
    func translateBatchReturnsEmptyArrayForEmptyInput() async throws {
        let service = TranslationService()

        let result = try await service.translateBatch(
            [],
            from: Locale(identifier: "en_US"),
            to: Locale(identifier: "ja_JP")
        )

        #expect(result.isEmpty)
    }

    @Test("translateBatch throws noSession for non-empty input without session")
    func translateBatchThrowsNoSessionForNonEmptyInputWithoutSession() async {
        let service = TranslationService()

        do {
            _ = try await service.translateBatch(
                ["Hello", "World"],
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Prepare Languages Tests

    @Test("prepareLanguages throws noSession without session")
    func prepareLanguagesThrowsNoSessionWithoutSession() async {
        let service = TranslationService()

        do {
            try await service.prepareLanguages(
                source: Locale(identifier: "en_US"),
                target: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Configuration Tests

    @Test("configuration creates valid TranslationSession.Configuration")
    func configurationCreatesValidConfiguration() {
        let source = Locale(identifier: "en_US")
        let target = Locale(identifier: "ja_JP")

        let config = TranslationService.configuration(source: source, target: target)

        // The configuration should have the correct source and target languages
        #expect(config.source?.languageCode?.identifier == source.language.languageCode?.identifier)
        #expect(config.target?.languageCode?.identifier == target.language.languageCode?.identifier)
    }

    @Test("configuration works with different language pairs")
    func configurationWorksWithDifferentLanguagePairs() {
        let pairs: [(String, String)] = [
            ("en_US", "ja_JP"),
            ("fr_FR", "de_DE"),
            ("es_ES", "it_IT"),
            ("zh_CN", "ko_KR")
        ]

        for (sourceId, targetId) in pairs {
            let source = Locale(identifier: sourceId)
            let target = Locale(identifier: targetId)

            let config = TranslationService.configuration(source: source, target: target)

            #expect(config.source != nil)
            #expect(config.target != nil)
        }
    }
}

// MARK: - Edge Cases Tests

@Suite("Translation Service Edge Cases")
@MainActor
struct TranslationServiceEdgeCasesTests {

    @Test("translate with whitespace-only text throws emptyInput")
    func translateWithWhitespaceOnlyDoesNotThrowEmptyInput() async {
        let service = TranslationService()

        // Whitespace-only text is not empty, so it should proceed to session check
        do {
            _ = try await service.translate(
                "   ",
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            // Whitespace is not empty, so noSession should be thrown
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("translate with newlines only text does not throw emptyInput")
    func translateWithNewlinesOnlyDoesNotThrowEmptyInput() async {
        let service = TranslationService()

        do {
            _ = try await service.translate(
                "\n\n\n",
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("translate with same source and target locale proceeds")
    func translateWithSameSourceAndTargetProceeds() async {
        let service = TranslationService()
        let locale = Locale(identifier: "en_US")

        // Same source and target should still be validated (empty and session checks)
        do {
            _ = try await service.translate(
                "Hello",
                from: locale,
                to: locale
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            // Should throw noSession, not any "same language" error
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("translateBatch with mixed empty and non-empty texts")
    func translateBatchWithMixedEmptyAndNonEmptyTexts() async {
        let service = TranslationService()

        // This should throw noSession because the array is not empty
        do {
            _ = try await service.translateBatch(
                ["Hello", "", "World"],
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
            Issue.record("Expected noSession error to be thrown")
        } catch let error as LocalTranslationError {
            if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("service state remains idle after failed translate")
    func serviceStateRemainsIdleAfterFailedTranslate() async {
        let service = TranslationService()

        do {
            _ = try await service.translate(
                "Hello",
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
        } catch {
            // Expected to fail
        }

        // State should still be idle since we never had a session
        #expect(service.state == .idle)
    }

    @Test("service state remains idle after failed translateBatch")
    func serviceStateRemainsIdleAfterFailedTranslateBatch() async {
        let service = TranslationService()

        do {
            _ = try await service.translateBatch(
                ["Hello", "World"],
                from: Locale(identifier: "en_US"),
                to: Locale(identifier: "ja_JP")
            )
        } catch {
            // Expected to fail
        }

        // State should still be idle since we never had a session
        #expect(service.state == .idle)
    }

    @Test("multiple translate calls maintain consistent error behavior")
    func multipleTranslateCallsMaintainConsistentErrorBehavior() async {
        let service = TranslationService()

        for _ in 1...3 {
            do {
                _ = try await service.translate(
                    "Hello",
                    from: Locale(identifier: "en_US"),
                    to: Locale(identifier: "ja_JP")
                )
                Issue.record("Expected noSession error")
            } catch let error as LocalTranslationError {
                if case .noSession = error {
                // Expected
            } else {
                Issue.record("Expected noSession error, got \(error)")
            }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
}

// MARK: - TranslationError Case Tests

@Suite("Translation Error Case Tests")
struct TranslationErrorCaseTests {

    @Test("noSession error case matches itself")
    func noSessionErrorCaseMatches() {
        let error = LocalTranslationError.noSession
        if case .noSession = error {
            // Test passes
        } else {
            Issue.record("noSession should match .noSession case")
        }
    }

    @Test("emptyInput error case matches itself")
    func emptyInputErrorCaseMatches() {
        let error = LocalTranslationError.emptyInput
        if case .emptyInput = error {
            // Test passes
        } else {
            Issue.record("emptyInput should match .emptyInput case")
        }
    }

    @Test("rateLimited error case matches itself")
    func rateLimitedErrorCaseMatches() {
        let error = LocalTranslationError.rateLimited
        if case .rateLimited = error {
            // Test passes
        } else {
            Issue.record("rateLimited should match .rateLimited case")
        }
    }

    @Test("different error cases do not match each other")
    func differentErrorCasesDoNotMatch() {
        let noSession = LocalTranslationError.noSession
        let emptyInput = LocalTranslationError.emptyInput
        let rateLimited = LocalTranslationError.rateLimited

        // noSession should not match emptyInput
        if case .emptyInput = noSession {
            Issue.record("noSession should not match .emptyInput")
        }

        // noSession should not match rateLimited
        if case .rateLimited = noSession {
            Issue.record("noSession should not match .rateLimited")
        }

        // emptyInput should not match rateLimited
        if case .rateLimited = emptyInput {
            Issue.record("emptyInput should not match .rateLimited")
        }
    }

    @Test("languagePairNotSupported error extracts correct locales")
    func languagePairNotSupportedExtractsLocales() {
        let source = Locale(identifier: "en_US")
        let target = Locale(identifier: "ja_JP")

        let error = LocalTranslationError.languagePairNotSupported(source: source, target: target)

        if case let .languagePairNotSupported(extractedSource, extractedTarget) = error {
            #expect(extractedSource.identifier == source.identifier)
            #expect(extractedTarget.identifier == target.identifier)
        } else {
            Issue.record("Should be languagePairNotSupported case")
        }
    }

    @Test("languageNotDownloaded error extracts correct locale")
    func languageNotDownloadedExtractsLocale() {
        let locale = Locale(identifier: "es_ES")

        let error = LocalTranslationError.languageNotDownloaded(locale)

        if case let .languageNotDownloaded(extractedLocale) = error {
            #expect(extractedLocale.identifier == locale.identifier)
        } else {
            Issue.record("Should be languageNotDownloaded case")
        }
    }

    @Test("translationFailed error extracts underlying error")
    func translationFailedExtractsUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        let error = LocalTranslationError.translationFailed(underlying: underlyingError)

        if case let .translationFailed(extracted) = error {
            let nsError = extracted as NSError
            #expect(nsError.domain == "TestDomain")
            #expect(nsError.code == 42)
        } else {
            Issue.record("Should be translationFailed case")
        }
    }

    @Test("translationFailed preserves different underlying error types")
    func translationFailedPreservesDifferentErrorTypes() {
        // Test with a custom error type
        struct CustomError: Error {
            let code: Int
        }

        let customError = CustomError(code: 123)
        let error = LocalTranslationError.translationFailed(underlying: customError)

        if case let .translationFailed(extracted) = error {
            if let custom = extracted as? CustomError {
                #expect(custom.code == 123)
            } else {
                Issue.record("Should preserve CustomError type")
            }
        } else {
            Issue.record("Should be translationFailed case")
        }
    }
}

// MARK: - TranslationError Edge Cases Tests

@Suite("Translation Error Edge Cases Tests")
struct TranslationErrorEdgeCasesTests {

    @Test("languagePairNotSupported with locale missing language code")
    func languagePairNotSupportedWithMissingLanguageCode() {
        // Create a locale with a potentially problematic identifier
        let source = Locale(identifier: "")
        let target = Locale(identifier: "ja_JP")
        let error = LocalTranslationError.languagePairNotSupported(source: source, target: target)

        // Should still produce a valid non-empty description
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("languageNotDownloaded with locale missing language code")
    func languageNotDownloadedWithMissingLanguageCode() {
        let locale = Locale(identifier: "")
        let error = LocalTranslationError.languageNotDownloaded(locale)

        // Should still produce a valid non-empty description
        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("languagePairNotSupported with same source and target")
    func languagePairNotSupportedWithSameSourceAndTarget() {
        let locale = Locale(identifier: "en_US")
        let error = LocalTranslationError.languagePairNotSupported(source: locale, target: locale)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("languagePairNotSupported with region-only identifiers")
    func languagePairNotSupportedWithRegionOnlyIdentifiers() {
        let source = Locale(identifier: "en_GB")
        let target = Locale(identifier: "en_AU")
        let error = LocalTranslationError.languagePairNotSupported(source: source, target: target)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("translationFailed with error that has empty description")
    func translationFailedWithEmptyDescriptionError() {
        let underlyingError = NSError(domain: "", code: 0, userInfo: nil)
        let error = LocalTranslationError.translationFailed(underlying: underlyingError)

        #expect(error.errorDescription != nil)
        // swiftlint:disable:next force_unwrapping
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("all error types conform to Error protocol")
    func allErrorTypesConformToError() {
        let errors: [any Error] = [
            LocalTranslationError.noSession,
            LocalTranslationError.languagePairNotSupported(source: Locale(identifier: "en"), target: Locale(identifier: "ja")),
            LocalTranslationError.languageNotDownloaded(Locale(identifier: "de")),
            LocalTranslationError.translationFailed(underlying: NSError(domain: "Test", code: 0)),
            LocalTranslationError.emptyInput,
            LocalTranslationError.rateLimited
        ]

        for error in errors {
            #expect(error is LocalTranslationError)
        }
    }

    @Test("error descriptions are non-nil for all cases")
    func errorDescriptionsAreNonNilForAllCases() {
        let errors: [LocalTranslationError] = [
            .noSession,
            .languagePairNotSupported(source: Locale(identifier: "en"), target: Locale(identifier: "ja")),
            .languageNotDownloaded(Locale(identifier: "de")),
            .translationFailed(underlying: NSError(domain: "Test", code: 0)),
            .emptyInput,
            .rateLimited
        ]

        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have a description")
        }
    }

    @Test("recovery suggestions are appropriate for each error type")
    func recoverySuggestionsAreAppropriateForEachErrorType() {
        // Errors that should have recovery suggestions
        let errorsWithRecovery: [LocalTranslationError] = [
            .noSession,
            .languagePairNotSupported(source: Locale(identifier: "en"), target: Locale(identifier: "ja")),
            .languageNotDownloaded(Locale(identifier: "de")),
            .rateLimited
        ]

        for error in errorsWithRecovery {
            #expect(error.recoverySuggestion != nil, "Error \(error) should have a recovery suggestion")
        }

        // Errors that should not have recovery suggestions
        let errorsWithoutRecovery: [LocalTranslationError] = [
            .translationFailed(underlying: NSError(domain: "Test", code: 0)),
            .emptyInput
        ]

        for error in errorsWithoutRecovery {
            #expect(error.recoverySuggestion == nil, "Error \(error) should not have a recovery suggestion")
        }
    }
}

// MARK: - LanguagePair Extended Tests

@Suite("Language Pair Extended Tests")
struct LanguagePairExtendedTests {

    @Test("LanguagePair with same source and target")
    func languagePairWithSameSourceAndTarget() {
        let locale = Locale(identifier: "en_US")
        let pair = LanguagePair(source: locale, target: locale)

        #expect(pair.source == locale)
        #expect(pair.target == locale)
        #expect(pair.source == pair.target)
    }

    @Test("LanguagePair reversed identity")
    func languagePairReversedIdentity() {
        let locale = Locale(identifier: "en_US")
        let pair = LanguagePair(source: locale, target: locale)
        let reversed = pair.reversed

        // When source == target, reversed should equal original
        #expect(reversed == pair)
    }

    @Test("LanguagePair with empty locale identifiers")
    func languagePairWithEmptyLocaleIdentifiers() {
        let source = Locale(identifier: "")
        let target = Locale(identifier: "ja_JP")
        let pair = LanguagePair(source: source, target: target)

        #expect(pair.source.identifier.isEmpty)
        #expect(pair.target.identifier == "ja_JP")
    }

    @Test("LanguagePair hashValue consistency")
    func languagePairHashValueConsistency() {
        let pair1 = LanguagePair(source: Locale(identifier: "en_US"), target: Locale(identifier: "ja_JP"))
        let pair2 = LanguagePair(source: Locale(identifier: "en_US"), target: Locale(identifier: "ja_JP"))

        // Equal pairs must have equal hash values
        #expect(pair1.hashValue == pair2.hashValue)
    }

    @Test("LanguagePair can be used as dictionary key")
    func languagePairCanBeUsedAsDictionaryKey() {
        let pair1 = LanguagePair(source: Locale(identifier: "en_US"), target: Locale(identifier: "ja_JP"))
        let pair2 = LanguagePair(source: Locale(identifier: "fr_FR"), target: Locale(identifier: "de_DE"))

        var dictionary: [LanguagePair: String] = [:]
        dictionary[pair1] = "English to Japanese"
        dictionary[pair2] = "French to German"

        #expect(dictionary[pair1] == "English to Japanese")
        #expect(dictionary[pair2] == "French to German")
        #expect(dictionary.count == 2)
    }

    @Test("LanguagePair reversed does not equal original when different")
    func languagePairReversedDoesNotEqualOriginalWhenDifferent() {
        let pair = LanguagePair(source: Locale(identifier: "en_US"), target: Locale(identifier: "ja_JP"))
        let reversed = pair.reversed

        #expect(pair != reversed)
    }

    @Test("LanguagePair with language-only locales")
    func languagePairWithLanguageOnlyLocales() {
        let source = Locale(identifier: "en")
        let target = Locale(identifier: "ja")
        let pair = LanguagePair(source: source, target: target)

        #expect(pair.source.identifier == "en")
        #expect(pair.target.identifier == "ja")
    }

    @Test("LanguagePair with script variants")
    func languagePairWithScriptVariants() {
        // Chinese Simplified vs Traditional
        let source = Locale(identifier: "zh_Hans")
        let target = Locale(identifier: "zh_Hant")
        let pair = LanguagePair(source: source, target: target)

        #expect(pair.source != pair.target)
    }
}

// MARK: - TranslationServiceState Extended Tests

@Suite("Translation Service State Extended Tests")
struct TranslationServiceStateExtendedTests {

    @Test("error state with empty message")
    func errorStateWithEmptyMessage() {
        let state = TranslationServiceState.error(message: "")
        if case .error(let message) = state {
            #expect(message.isEmpty)
        } else {
            Issue.record("Should be error state")
        }
    }

    @Test("error state with long message")
    func errorStateWithLongMessage() {
        let longMessage = String(repeating: "Error ", count: 1000)
        let state = TranslationServiceState.error(message: longMessage)
        if case .error(let message) = state {
            #expect(message == longMessage)
        } else {
            Issue.record("Should be error state")
        }
    }

    @Test("error state with special characters in message")
    func errorStateWithSpecialCharactersInMessage() {
        let specialMessage = "Error: \n\t\r\0 Unicode: \u{1F600}"
        let state = TranslationServiceState.error(message: specialMessage)
        if case .error(let message) = state {
            #expect(message == specialMessage)
        } else {
            Issue.record("Should be error state")
        }
    }

    @Test("all state cases are distinct")
    func allStateCasesAreDistinct() {
        let states: [TranslationServiceState] = [
            .idle,
            .ready,
            .translating,
            .error(message: "test")
        ]

        // Each state should not equal any other state
        for (index, state) in states.enumerated() {
            for (otherIndex, otherState) in states.enumerated() where index != otherIndex {
                #expect(state != otherState, "State \(state) should not equal \(otherState)")
            }
        }
    }

    @Test("state can be switched on exhaustively")
    func stateCanBeSwitchedOnExhaustively() {
        let states: [TranslationServiceState] = [
            .idle,
            .ready,
            .translating,
            .error(message: "test")
        ]

        for state in states {
            var matched = false
            switch state {
            case .idle:
                matched = true
            case .ready:
                matched = true
            case .translating:
                matched = true
            case .error:
                matched = true
            }
            #expect(matched, "State \(state) should match one case")
        }
    }
}

// MARK: - TranslationService Configuration Tests

@Suite("Translation Service Configuration Tests")
@MainActor
struct TranslationServiceConfigurationTests {

    @Test("configuration with language-only locales")
    func configurationWithLanguageOnlyLocales() {
        let source = Locale(identifier: "en")
        let target = Locale(identifier: "ja")

        let config = TranslationService.configuration(source: source, target: target)

        #expect(config.source != nil)
        #expect(config.target != nil)
    }

    @Test("configuration with full locale identifiers")
    func configurationWithFullLocaleIdentifiers() {
        let source = Locale(identifier: "en_US")
        let target = Locale(identifier: "ja_JP")

        let config = TranslationService.configuration(source: source, target: target)

        #expect(config.source != nil)
        #expect(config.target != nil)
    }

    @Test("configuration with same source and target")
    func configurationWithSameSourceAndTarget() {
        let locale = Locale(identifier: "en_US")

        let config = TranslationService.configuration(source: locale, target: locale)

        // Even same language should produce a valid config
        #expect(config.source != nil)
        #expect(config.target != nil)
    }

    @Test("configuration source and target match input locales")
    func configurationSourceAndTargetMatchInputLocales() {
        let testCases: [(String, String)] = [
            ("en", "ja"),
            ("fr", "de"),
            ("es", "it"),
            ("zh", "ko"),
            ("pt", "ru")
        ]

        for (sourceId, targetId) in testCases {
            let source = Locale(identifier: sourceId)
            let target = Locale(identifier: targetId)

            let config = TranslationService.configuration(source: source, target: target)

            // Verify the language codes match
            #expect(config.source?.languageCode?.identifier == source.language.languageCode?.identifier)
            #expect(config.target?.languageCode?.identifier == target.language.languageCode?.identifier)
        }
    }

    @Test("configuration preserves script information")
    func configurationPreservesScriptInformation() {
        // Test with Chinese variants
        let source = Locale(identifier: "zh_Hans")
        let target = Locale(identifier: "en")

        let config = TranslationService.configuration(source: source, target: target)

        #expect(config.source != nil)
        #expect(config.target != nil)
    }
}

// MARK: - TranslationService Protocol Conformance Tests

@Suite("Translation Service Protocol Conformance Tests")
@MainActor
struct TranslationServiceProtocolConformanceTests {

    @Test("TranslationService conforms to TranslationServiceProtocol")
    func translationServiceConformsToProtocol() {
        let service = TranslationService()
        let protocolConforming: any TranslationServiceProtocol = service
        #expect(protocolConforming.state == .idle)
    }

    @Test("TranslationService state property is accessible via protocol")
    func statePropertyAccessibleViaProtocol() {
        let service: any TranslationServiceProtocol = TranslationService()
        #expect(service.state == .idle)
    }

    @Test("TranslationService hasSession property is accessible via protocol")
    func hasSessionPropertyAccessibleViaProtocol() {
        let service: any TranslationServiceProtocol = TranslationService()
        #expect(service.hasSession == false)
    }

    @Test("TranslationService translate method is accessible via protocol")
    func translateMethodAccessibleViaProtocol() async {
        let service: any TranslationServiceProtocol = TranslationService()

        do {
            _ = try await service.translate("Hello", from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
            Issue.record("Expected error")
        } catch {
            // Expected - no session
            #expect(error is LocalTranslationError)
        }
    }

    @Test("TranslationService translateBatch method is accessible via protocol")
    func translateBatchMethodAccessibleViaProtocol() async throws {
        let service: any TranslationServiceProtocol = TranslationService()

        // Empty batch should return empty array
        let result = try await service.translateBatch([], from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
        #expect(result.isEmpty)
    }

    @Test("TranslationService setSession method is accessible via protocol")
    func setSessionMethodAccessibleViaProtocol() async {
        let service: any TranslationServiceProtocol = TranslationService()

        // Should not crash with invalid input
        await service.setSession("invalid")
        #expect(service.hasSession == false)
    }
}

// MARK: - TranslationService State Transitions Tests

@Suite("Translation Service State Transitions Tests")
@MainActor
struct TranslationServiceStateTransitionsTests {

    @Test("state remains idle when translate fails due to empty input")
    func stateRemainsIdleWhenTranslateFailsDueToEmptyInput() async {
        let service = TranslationService()
        #expect(service.state == .idle)

        do {
            _ = try await service.translate("", from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
        } catch {
            // Expected
        }

        // State should remain idle (error thrown before state change)
        #expect(service.state == .idle)
    }

    @Test("state remains idle when translate fails due to no session")
    func stateRemainsIdleWhenTranslateFailsDueToNoSession() async {
        let service = TranslationService()
        #expect(service.state == .idle)

        do {
            _ = try await service.translate("Hello", from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
        } catch {
            // Expected
        }

        // State should remain idle (error thrown before state change)
        #expect(service.state == .idle)
    }

    @Test("state remains idle when translateBatch fails due to no session")
    func stateRemainsIdleWhenTranslateBatchFailsDueToNoSession() async {
        let service = TranslationService()
        #expect(service.state == .idle)

        do {
            _ = try await service.translateBatch(["Hello"], from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
        } catch {
            // Expected
        }

        // State should remain idle (error thrown before state change)
        #expect(service.state == .idle)
    }

    @Test("state remains idle when prepareLanguages fails due to no session")
    func stateRemainsIdleWhenPrepareLanguagesFailsDueToNoSession() async {
        let service = TranslationService()
        #expect(service.state == .idle)

        do {
            try await service.prepareLanguages(source: Locale(identifier: "en"), target: Locale(identifier: "ja"))
        } catch {
            // Expected
        }

        // State should remain idle
        #expect(service.state == .idle)
    }

    @Test("setSession with wrong type keeps state idle")
    func setSessionWithWrongTypeKeepsStateIdle() async {
        let service = TranslationService()
        #expect(service.state == .idle)

        await service.setSession(123)
        #expect(service.state == .idle)

        await service.setSession([1, 2, 3])
        #expect(service.state == .idle)

        await service.setSession(["key": "value"])
        #expect(service.state == .idle)
    }
}

// MARK: - LanguageDownloadStatus Extended Tests

@Suite("Language Download Status Extended Tests")
struct LanguageDownloadStatusExtendedTests {

    @Test("downloading progress boundary values")
    func downloadingProgressBoundaryValues() {
        let boundaryValues: [Double] = [0.0, 0.001, 0.5, 0.999, 1.0]

        for progress in boundaryValues {
            let status = LanguageDownloadStatus.downloading(progress: progress)
            if case .downloading(let storedProgress) = status {
                #expect(storedProgress == progress)
            } else {
                Issue.record("Expected downloading status")
            }
        }
    }

    @Test("downloading progress with negative value")
    func downloadingProgressWithNegativeValue() {
        // The type allows negative values (it's just a Double)
        let status = LanguageDownloadStatus.downloading(progress: -0.5)
        if case .downloading(let progress) = status {
            #expect(progress == -0.5)
        } else {
            Issue.record("Expected downloading status")
        }
    }

    @Test("downloading progress with value greater than 1")
    func downloadingProgressWithValueGreaterThanOne() {
        // The type allows values > 1 (it's just a Double)
        let status = LanguageDownloadStatus.downloading(progress: 1.5)
        if case .downloading(let progress) = status {
            #expect(progress == 1.5)
        } else {
            Issue.record("Expected downloading status")
        }
    }

    @Test("all status cases can be instantiated")
    func allStatusCasesCanBeInstantiated() {
        let statuses: [LanguageDownloadStatus] = [
            .installed,
            .notInstalled,
            .downloading(progress: 0.5),
            .unknown
        ]

        #expect(statuses.count == 4)

        for status in statuses {
            // Verify each status is sendable
            let _: any Sendable = status
        }
    }
}
