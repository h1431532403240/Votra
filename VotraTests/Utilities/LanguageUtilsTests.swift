//
//  LanguageUtilsTests.swift
//  VotraTests
//
//  Tests for Locale+Translation utilities.
//

import Foundation
import Testing
@testable import Votra

@Suite("Language Utilities")
@MainActor
struct LanguageUtilsTests {
    // MARK: - Supported Languages Tests

    @Test("Supported speech recognition languages contains expected count")
    func supportedSpeechRecognitionLanguagesCount() {
        let languages = Locale.supportedSpeechRecognitionLanguages
        #expect(languages.count == 10)
    }

    @Test("Supported speech recognition languages contains English")
    func supportedSpeechRecognitionLanguagesContainsEnglish() {
        let languages = Locale.supportedSpeechRecognitionLanguages
        let hasEnglish = languages.contains { $0.identifier == "en-US" }
        #expect(hasEnglish)
    }

    @Test("Supported speech recognition languages contains Chinese variants")
    func supportedSpeechRecognitionLanguagesContainsChinese() {
        let languages = Locale.supportedSpeechRecognitionLanguages
        let hasSimplified = languages.contains { $0.identifier == "zh-Hans" }
        let hasTraditional = languages.contains { $0.identifier == "zh-Hant" }
        #expect(hasSimplified)
        #expect(hasTraditional)
    }

    @Test("Supported speech recognition languages contains Japanese")
    func supportedSpeechRecognitionLanguagesContainsJapanese() {
        let languages = Locale.supportedSpeechRecognitionLanguages
        let hasJapanese = languages.contains { $0.identifier == "ja-JP" }
        #expect(hasJapanese)
    }

    @Test("Supported speech recognition languages contains Korean")
    func supportedSpeechRecognitionLanguagesContainsKorean() {
        let languages = Locale.supportedSpeechRecognitionLanguages
        let hasKorean = languages.contains { $0.identifier == "ko-KR" }
        #expect(hasKorean)
    }

    @Test("Supported speech recognition languages contains European languages")
    func supportedSpeechRecognitionLanguagesContainsEuropean() {
        let languages = Locale.supportedSpeechRecognitionLanguages
        let hasSpanish = languages.contains { $0.identifier == "es-ES" }
        let hasFrench = languages.contains { $0.identifier == "fr-FR" }
        let hasGerman = languages.contains { $0.identifier == "de-DE" }
        let hasItalian = languages.contains { $0.identifier == "it-IT" }
        let hasPortuguese = languages.contains { $0.identifier == "pt-BR" }
        #expect(hasSpanish)
        #expect(hasFrench)
        #expect(hasGerman)
        #expect(hasItalian)
        #expect(hasPortuguese)
    }

    @Test("Supported translation languages matches speech recognition languages")
    func supportedTranslationLanguagesMatchesSpeechRecognition() {
        let speechLanguages = Locale.supportedSpeechRecognitionLanguages
        let translationLanguages = Locale.supportedTranslationLanguages
        #expect(speechLanguages.count == translationLanguages.count)
        for language in speechLanguages {
            let found = translationLanguages.contains { $0.identifier == language.identifier }
            #expect(found)
        }
    }

    // MARK: - Display Name Tests

    @Test("Localized display name returns valid string")
    func localizedDisplayName() {
        let english = Locale(identifier: "en-US")
        let displayName = english.localizedDisplayName

        #expect(!displayName.isEmpty)
    }

    @Test("Localized display name differs between languages")
    func localizedDisplayNameDiffersBetweenLanguages() {
        let english = Locale(identifier: "en-US")
        let japanese = Locale(identifier: "ja-JP")

        // Display names should be different for different languages
        #expect(english.localizedDisplayName != japanese.localizedDisplayName)
    }

    @Test("Localized display name returns non-empty for all supported languages")
    func localizedDisplayNameForAllSupported() {
        for locale in Locale.supportedSpeechRecognitionLanguages {
            let displayName = locale.localizedDisplayName
            #expect(!displayName.isEmpty, "Display name should not be empty for \(locale.identifier)")
        }
    }

    @Test("Localized display name falls back to identifier for unknown locale")
    func localizedDisplayNameFallback() {
        let unknown = Locale(identifier: "xx-YY")
        let displayName = unknown.localizedDisplayName
        // Should return something (either the identifier or a system-provided name)
        #expect(!displayName.isEmpty)
    }

    // MARK: - Flag Emoji Tests

    @Test("Flag emoji returns valid emoji for US locale")
    func flagEmojiForUS() {
        let usLocale = Locale(identifier: "en-US")
        let flag = usLocale.flagEmoji
        #expect(flag == "🇺🇸")
    }

    @Test("Flag emoji returns valid emoji for Japanese locale")
    func flagEmojiForJapan() {
        let jpLocale = Locale(identifier: "ja-JP")
        let flag = jpLocale.flagEmoji
        #expect(flag == "🇯🇵")
    }

    @Test("Flag emoji returns valid emoji for Korean locale")
    func flagEmojiForKorea() {
        let krLocale = Locale(identifier: "ko-KR")
        let flag = krLocale.flagEmoji
        #expect(flag == "🇰🇷")
    }

    @Test("Flag emoji returns valid emoji for German locale")
    func flagEmojiForGermany() {
        let deLocale = Locale(identifier: "de-DE")
        let flag = deLocale.flagEmoji
        #expect(flag == "🇩🇪")
    }

    @Test("Flag emoji returns valid emoji for French locale")
    func flagEmojiForFrance() {
        let frLocale = Locale(identifier: "fr-FR")
        let flag = frLocale.flagEmoji
        #expect(flag == "🇫🇷")
    }

    @Test("Flag emoji returns valid emoji for Brazilian Portuguese locale")
    func flagEmojiForBrazil() {
        let brLocale = Locale(identifier: "pt-BR")
        let flag = brLocale.flagEmoji
        #expect(flag == "🇧🇷")
    }

    @Test("Flag emoji returns valid emoji for Spanish locale")
    func flagEmojiForSpain() {
        let esLocale = Locale(identifier: "es-ES")
        let flag = esLocale.flagEmoji
        #expect(flag == "🇪🇸")
    }

    @Test("Flag emoji returns valid emoji for Italian locale")
    func flagEmojiForItaly() {
        let itLocale = Locale(identifier: "it-IT")
        let flag = itLocale.flagEmoji
        #expect(flag == "🇮🇹")
    }

    @Test("Flag emoji returns nil for locale without region")
    func flagEmojiNilForNoRegion() {
        let noRegion = Locale(identifier: "en")
        let flag = noRegion.flagEmoji
        #expect(flag == nil)
    }

    @Test("Flag emoji returns nil for simplified Chinese locale")
    func flagEmojiNilForSimplifiedChinese() {
        // zh-Hans does not have a region code
        let zhHans = Locale(identifier: "zh-Hans")
        let flag = zhHans.flagEmoji
        #expect(flag == nil)
    }

    @Test("Flag emoji returns nil for traditional Chinese locale")
    func flagEmojiNilForTraditionalChinese() {
        // zh-Hant does not have a region code
        let zhHant = Locale(identifier: "zh-Hant")
        let flag = zhHant.flagEmoji
        #expect(flag == nil)
    }

    // MARK: - Speech Recognition Code Tests

    @Test("Speech recognition code maps zh-Hans to zh-CN")
    func speechRecognitionCodeSimplifiedChinese() {
        let locale = Locale(identifier: "zh-Hans")
        #expect(locale.speechRecognitionCode == "zh-CN")
    }

    @Test("Speech recognition code maps zh-Hant to zh-TW")
    func speechRecognitionCodeTraditionalChinese() {
        let locale = Locale(identifier: "zh-Hant")
        #expect(locale.speechRecognitionCode == "zh-TW")
    }

    @Test("Speech recognition code returns identifier for other locales")
    func speechRecognitionCodeDefault() {
        let locale = Locale(identifier: "en-US")
        #expect(locale.speechRecognitionCode == "en-US")
    }

    @Test("Speech recognition code returns identifier for Japanese")
    func speechRecognitionCodeJapanese() {
        let locale = Locale(identifier: "ja-JP")
        #expect(locale.speechRecognitionCode == "ja-JP")
    }

    @Test("Speech recognition code returns identifier for Korean")
    func speechRecognitionCodeKorean() {
        let locale = Locale(identifier: "ko-KR")
        #expect(locale.speechRecognitionCode == "ko-KR")
    }

    @Test("Speech recognition code returns identifier for European languages")
    func speechRecognitionCodeEuropean() {
        let spanish = Locale(identifier: "es-ES")
        let french = Locale(identifier: "fr-FR")
        let german = Locale(identifier: "de-DE")

        #expect(spanish.speechRecognitionCode == "es-ES")
        #expect(french.speechRecognitionCode == "fr-FR")
        #expect(german.speechRecognitionCode == "de-DE")
    }

    // MARK: - Base Language Code Tests

    @Test("Base language code extracts language without region")
    func baseLanguageCode() {
        let usEnglish = Locale(identifier: "en-US")
        let gbEnglish = Locale(identifier: "en-GB")

        #expect(usEnglish.baseLanguageCode == gbEnglish.baseLanguageCode)
    }

    @Test("Base language code returns correct code for English")
    func baseLanguageCodeEnglish() {
        let locale = Locale(identifier: "en-US")
        #expect(locale.baseLanguageCode == "en")
    }

    @Test("Base language code returns correct code for Japanese")
    func baseLanguageCodeJapanese() {
        let locale = Locale(identifier: "ja-JP")
        #expect(locale.baseLanguageCode == "ja")
    }

    @Test("Base language code returns correct code for Korean")
    func baseLanguageCodeKorean() {
        let locale = Locale(identifier: "ko-KR")
        #expect(locale.baseLanguageCode == "ko")
    }

    @Test("Base language code returns correct code for Spanish")
    func baseLanguageCodeSpanish() {
        let locale = Locale(identifier: "es-ES")
        #expect(locale.baseLanguageCode == "es")
    }

    @Test("Base language code returns correct code for simplified Chinese")
    func baseLanguageCodeSimplifiedChinese() {
        let locale = Locale(identifier: "zh-Hans")
        #expect(locale.baseLanguageCode == "zh")
    }

    @Test("Base language code returns correct code for traditional Chinese")
    func baseLanguageCodeTraditionalChinese() {
        let locale = Locale(identifier: "zh-Hant")
        #expect(locale.baseLanguageCode == "zh")
    }

    @Test("Base language code matches for same language different regions")
    func baseLanguageCodeMatchesForSameLanguage() {
        let ptBR = Locale(identifier: "pt-BR")
        let ptPT = Locale(identifier: "pt-PT")
        #expect(ptBR.baseLanguageCode == ptPT.baseLanguageCode)
    }

    // MARK: - Real-Time Translation Support Tests

    @Test("English US is supported for real-time translation")
    func isSupportedEnglishUS() {
        let locale = Locale(identifier: "en-US")
        #expect(locale.isSupportedForRealTimeTranslation)
    }

    @Test("Japanese is supported for real-time translation")
    func isSupportedJapanese() {
        let locale = Locale(identifier: "ja-JP")
        #expect(locale.isSupportedForRealTimeTranslation)
    }

    @Test("Korean is supported for real-time translation")
    func isSupportedKorean() {
        let locale = Locale(identifier: "ko-KR")
        #expect(locale.isSupportedForRealTimeTranslation)
    }

    @Test("Simplified Chinese is supported for real-time translation")
    func isSupportedSimplifiedChinese() {
        let locale = Locale(identifier: "zh-Hans")
        #expect(locale.isSupportedForRealTimeTranslation)
    }

    @Test("Traditional Chinese is supported for real-time translation")
    func isSupportedTraditionalChinese() {
        let locale = Locale(identifier: "zh-Hant")
        #expect(locale.isSupportedForRealTimeTranslation)
    }

    @Test("European languages are supported for real-time translation")
    func isSupportedEuropeanLanguages() {
        let spanish = Locale(identifier: "es-ES")
        let french = Locale(identifier: "fr-FR")
        let german = Locale(identifier: "de-DE")
        let italian = Locale(identifier: "it-IT")
        let portuguese = Locale(identifier: "pt-BR")

        #expect(spanish.isSupportedForRealTimeTranslation)
        #expect(french.isSupportedForRealTimeTranslation)
        #expect(german.isSupportedForRealTimeTranslation)
        #expect(italian.isSupportedForRealTimeTranslation)
        #expect(portuguese.isSupportedForRealTimeTranslation)
    }

    @Test("Unsupported locale returns false for real-time translation")
    func isNotSupportedUnsupportedLocale() {
        let unsupported = Locale(identifier: "xx-YY")
        #expect(!unsupported.isSupportedForRealTimeTranslation)
    }

    @Test("English GB is not supported (only en-US is in the list)")
    func isNotSupportedEnglishGB() {
        let locale = Locale(identifier: "en-GB")
        #expect(!locale.isSupportedForRealTimeTranslation)
    }

    @Test("Spanish Mexico is not supported (only es-ES is in the list)")
    func isNotSupportedSpanishMexico() {
        let locale = Locale(identifier: "es-MX")
        #expect(!locale.isSupportedForRealTimeTranslation)
    }

    @Test("Portuguese Portugal is not supported (only pt-BR is in the list)")
    func isNotSupportedPortuguesePortugal() {
        let locale = Locale(identifier: "pt-PT")
        #expect(!locale.isSupportedForRealTimeTranslation)
    }

    // MARK: - Translation Availability Tests

    @Test("Can translate from English to Japanese")
    func canTranslateEnglishToJapanese() {
        let english = Locale(identifier: "en-US")
        let japanese = Locale(identifier: "ja-JP")
        #expect(english.canTranslate(to: japanese))
    }

    @Test("Can translate from Japanese to English")
    func canTranslateJapaneseToEnglish() {
        let japanese = Locale(identifier: "ja-JP")
        let english = Locale(identifier: "en-US")
        #expect(japanese.canTranslate(to: english))
    }

    @Test("Can translate from English to Chinese")
    func canTranslateEnglishToChinese() {
        let english = Locale(identifier: "en-US")
        let chinese = Locale(identifier: "zh-Hans")
        #expect(english.canTranslate(to: chinese))
    }

    @Test("Can translate from Korean to Spanish")
    func canTranslateKoreanToSpanish() {
        let korean = Locale(identifier: "ko-KR")
        let spanish = Locale(identifier: "es-ES")
        #expect(korean.canTranslate(to: spanish))
    }

    @Test("Cannot translate to unsupported locale")
    func cannotTranslateToUnsupported() {
        let english = Locale(identifier: "en-US")
        let unsupported = Locale(identifier: "xx-YY")
        #expect(!english.canTranslate(to: unsupported))
    }

    @Test("Cannot translate from unsupported locale still checks target support")
    func translateFromUnsupportedChecksTarget() {
        let unsupported = Locale(identifier: "xx-YY")
        let english = Locale(identifier: "en-US")
        // The canTranslate method only checks if target is supported
        #expect(unsupported.canTranslate(to: english))
    }

    @Test("Can translate between all supported language pairs")
    func canTranslateBetweenAllSupported() {
        let languages = Locale.supportedTranslationLanguages
        for source in languages {
            for target in languages {
                #expect(source.canTranslate(to: target), "Should be able to translate from \(source.identifier) to \(target.identifier)")
            }
        }
    }

    // MARK: - Locale Comparison Tests

    @Test("Same language comparison ignores region")
    func isSameLanguageIgnoresRegion() {
        let usEnglish = Locale(identifier: "en-US")
        let gbEnglish = Locale(identifier: "en-GB")

        #expect(usEnglish.isSameLanguage(as: gbEnglish))
    }

    @Test("Different languages are not same")
    func differentLanguagesNotSame() {
        let english = Locale(identifier: "en-US")
        let chinese = Locale(identifier: "zh-Hans")

        #expect(!english.isSameLanguage(as: chinese))
    }

    @Test("Same locale is same language")
    func sameLocaleIsSameLanguage() {
        let locale1 = Locale(identifier: "en-US")
        let locale2 = Locale(identifier: "en-US")
        #expect(locale1.isSameLanguage(as: locale2))
    }

    @Test("Portuguese variants are same language")
    func portugueseVariantsAreSameLanguage() {
        let ptBR = Locale(identifier: "pt-BR")
        let ptPT = Locale(identifier: "pt-PT")
        #expect(ptBR.isSameLanguage(as: ptPT))
    }

    @Test("Spanish variants are same language")
    func spanishVariantsAreSameLanguage() {
        let esES = Locale(identifier: "es-ES")
        let esMX = Locale(identifier: "es-MX")
        #expect(esES.isSameLanguage(as: esMX))
    }

    @Test("Chinese variants are same language")
    func chineseVariantsAreSameLanguage() {
        let zhHans = Locale(identifier: "zh-Hans")
        let zhHant = Locale(identifier: "zh-Hant")
        #expect(zhHans.isSameLanguage(as: zhHant))
    }

    @Test("Japanese and Korean are different languages")
    func japaneseAndKoreanAreDifferent() {
        let japanese = Locale(identifier: "ja-JP")
        let korean = Locale(identifier: "ko-KR")
        #expect(!japanese.isSameLanguage(as: korean))
    }
}
