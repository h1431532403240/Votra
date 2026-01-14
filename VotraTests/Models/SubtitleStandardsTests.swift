//
//  SubtitleStandardsTests.swift
//  VotraTests
//
//  Tests for SubtitleStandards utility based on Netflix Timed Text Style Guide.
//

import Foundation
import Testing
@testable import Votra

@Suite("Subtitle Standards")
struct SubtitleStandardsTests {
    // MARK: - Max Characters Per Line Tests

    @Test("Japanese has 13 characters per line limit")
    func japaneseCharacterLimit() {
        let japanese = Locale(identifier: "ja")
        #expect(SubtitleStandards.maxCharactersPerLine(for: japanese) == 13)
    }

    @Test("Korean has 16 characters per line limit")
    func koreanCharacterLimit() {
        let korean = Locale(identifier: "ko")
        #expect(SubtitleStandards.maxCharactersPerLine(for: korean) == 16)
    }

    @Test("Chinese Simplified has 16 characters per line limit")
    func chineseSimplifiedCharacterLimit() {
        let chinese = Locale(identifier: "zh-Hans")
        #expect(SubtitleStandards.maxCharactersPerLine(for: chinese) == 16)
    }

    @Test("Chinese Traditional has 16 characters per line limit")
    func chineseTraditionalCharacterLimit() {
        let chinese = Locale(identifier: "zh-Hant")
        #expect(SubtitleStandards.maxCharactersPerLine(for: chinese) == 16)
    }

    @Test("English has 42 characters per line limit")
    func englishCharacterLimit() {
        let english = Locale(identifier: "en-US")
        #expect(SubtitleStandards.maxCharactersPerLine(for: english) == 42)
    }

    @Test("Spanish has 42 characters per line limit")
    func spanishCharacterLimit() {
        let spanish = Locale(identifier: "es")
        #expect(SubtitleStandards.maxCharactersPerLine(for: spanish) == 42)
    }

    @Test("Arabic has 42 characters per line limit")
    func arabicCharacterLimit() {
        let arabic = Locale(identifier: "ar")
        #expect(SubtitleStandards.maxCharactersPerLine(for: arabic) == 42)
    }

    @Test("Russian has 42 characters per line limit")
    func russianCharacterLimit() {
        let russian = Locale(identifier: "ru")
        #expect(SubtitleStandards.maxCharactersPerLine(for: russian) == 42)
    }

    // MARK: - Max Characters Per Event Tests

    @Test("Max characters per event is 2x line limit")
    func maxCharactersPerEventCalculation() {
        let japanese = Locale(identifier: "ja")
        let english = Locale(identifier: "en-US")

        // Japanese: 13 * 2 = 26
        #expect(SubtitleStandards.maxCharactersPerEvent(for: japanese) == 26)

        // English: 42 * 2 = 84
        #expect(SubtitleStandards.maxCharactersPerEvent(for: english) == 84)
    }

    @Test("Max lines per event is always 2")
    func maxLinesPerEvent() {
        #expect(SubtitleStandards.maxLinesPerEvent == 2)
    }

    // MARK: - Exceeds Limit Tests

    @Test("Short Japanese text does not exceed limit")
    func shortJapaneseTextWithinLimit() {
        let japanese = Locale(identifier: "ja")
        let shortText = "こんにちは" // 5 characters

        #expect(!SubtitleStandards.exceedsLimit(shortText, for: japanese))
    }

    @Test("Long Japanese text exceeds limit")
    func longJapaneseTextExceedsLimit() {
        let japanese = Locale(identifier: "ja")
        // 26 characters limit, create 30 character string
        let longText = String(repeating: "あ", count: 30)

        #expect(SubtitleStandards.exceedsLimit(longText, for: japanese))
    }

    @Test("Short English text does not exceed limit")
    func shortEnglishTextWithinLimit() {
        let english = Locale(identifier: "en-US")
        let shortText = "Hello, world!"

        #expect(!SubtitleStandards.exceedsLimit(shortText, for: english))
    }

    @Test("Long English text exceeds limit")
    func longEnglishTextExceedsLimit() {
        let english = Locale(identifier: "en-US")
        // 84 characters limit, create 100 character string
        let longText = String(repeating: "a", count: 100)

        #expect(SubtitleStandards.exceedsLimit(longText, for: english))
    }

    // MARK: - Estimated Duration Tests

    @Test("CJK duration uses 4 characters per second")
    func cjkDurationCalculation() {
        let japanese = Locale(identifier: "ja")
        // 8 characters at 4 chars/sec = 2 seconds
        let text = "こんにちは世界よ" // 8 characters

        let duration = SubtitleStandards.estimatedDuration(for: text, locale: japanese)
        #expect(duration == 2.0)
    }

    @Test("Latin duration uses 17 characters per second")
    func latinDurationCalculation() {
        let english = Locale(identifier: "en-US")
        // 34 characters at 17 chars/sec = 2 seconds
        let text = String(repeating: "a", count: 34)

        let duration = SubtitleStandards.estimatedDuration(for: text, locale: english)
        #expect(duration == 2.0)
    }

    @Test("Duration has minimum of 1 second")
    func durationMinimum() {
        let english = Locale(identifier: "en-US")
        let shortText = "Hi" // Very short

        let duration = SubtitleStandards.estimatedDuration(for: shortText, locale: english)
        #expect(duration == 1.0)
    }

    @Test("Duration has maximum of 7 seconds")
    func durationMaximum() {
        let english = Locale(identifier: "en-US")
        // 200 characters at 17 chars/sec = ~11.8 seconds, should cap at 7
        let longText = String(repeating: "a", count: 200)

        let duration = SubtitleStandards.estimatedDuration(for: longText, locale: english)
        #expect(duration == 7.0)
    }

    @Test("Korean uses CJK reading speed")
    func koreanUsesCjkSpeed() {
        let korean = Locale(identifier: "ko")
        // 8 characters at 4 chars/sec = 2 seconds
        let text = String(repeating: "가", count: 8)

        let duration = SubtitleStandards.estimatedDuration(for: text, locale: korean)
        #expect(duration == 2.0)
    }

    @Test("Chinese uses CJK reading speed")
    func chineseUsesCjkSpeed() {
        let chinese = Locale(identifier: "zh-Hans")
        // 12 characters at 4 chars/sec = 3 seconds
        let text = String(repeating: "中", count: 12)

        let duration = SubtitleStandards.estimatedDuration(for: text, locale: chinese)
        #expect(duration == 3.0)
    }

    // MARK: - Additional Latin Language Tests

    @Test("French has 42 characters per line limit")
    func frenchCharacterLimit() {
        let french = Locale(identifier: "fr")
        #expect(SubtitleStandards.maxCharactersPerLine(for: french) == 42)
    }

    @Test("German has 42 characters per line limit")
    func germanCharacterLimit() {
        let german = Locale(identifier: "de")
        #expect(SubtitleStandards.maxCharactersPerLine(for: german) == 42)
    }

    @Test("Italian has 42 characters per line limit")
    func italianCharacterLimit() {
        let italian = Locale(identifier: "it")
        #expect(SubtitleStandards.maxCharactersPerLine(for: italian) == 42)
    }

    @Test("Portuguese has 42 characters per line limit")
    func portugueseCharacterLimit() {
        let portuguese = Locale(identifier: "pt")
        #expect(SubtitleStandards.maxCharactersPerLine(for: portuguese) == 42)
    }

    @Test("Dutch has 42 characters per line limit")
    func dutchCharacterLimit() {
        let dutch = Locale(identifier: "nl")
        #expect(SubtitleStandards.maxCharactersPerLine(for: dutch) == 42)
    }

    @Test("Polish has 42 characters per line limit")
    func polishCharacterLimit() {
        let polish = Locale(identifier: "pl")
        #expect(SubtitleStandards.maxCharactersPerLine(for: polish) == 42)
    }

    @Test("Swedish has 42 characters per line limit")
    func swedishCharacterLimit() {
        let swedish = Locale(identifier: "sv")
        #expect(SubtitleStandards.maxCharactersPerLine(for: swedish) == 42)
    }

    @Test("Danish has 42 characters per line limit")
    func danishCharacterLimit() {
        let danish = Locale(identifier: "da")
        #expect(SubtitleStandards.maxCharactersPerLine(for: danish) == 42)
    }

    @Test("Norwegian has 42 characters per line limit")
    func norwegianCharacterLimit() {
        let norwegian = Locale(identifier: "no")
        #expect(SubtitleStandards.maxCharactersPerLine(for: norwegian) == 42)
    }

    @Test("Finnish has 42 characters per line limit")
    func finnishCharacterLimit() {
        let finnish = Locale(identifier: "fi")
        #expect(SubtitleStandards.maxCharactersPerLine(for: finnish) == 42)
    }

    // MARK: - Additional Arabic Script Language Tests

    @Test("Persian has 42 characters per line limit")
    func persianCharacterLimit() {
        let persian = Locale(identifier: "fa")
        #expect(SubtitleStandards.maxCharactersPerLine(for: persian) == 42)
    }

    @Test("Urdu has 42 characters per line limit")
    func urduCharacterLimit() {
        let urdu = Locale(identifier: "ur")
        #expect(SubtitleStandards.maxCharactersPerLine(for: urdu) == 42)
    }

    // MARK: - Additional Cyrillic Language Tests

    @Test("Ukrainian has 42 characters per line limit")
    func ukrainianCharacterLimit() {
        let ukrainian = Locale(identifier: "uk")
        #expect(SubtitleStandards.maxCharactersPerLine(for: ukrainian) == 42)
    }

    @Test("Bulgarian has 42 characters per line limit")
    func bulgarianCharacterLimit() {
        let bulgarian = Locale(identifier: "bg")
        #expect(SubtitleStandards.maxCharactersPerLine(for: bulgarian) == 42)
    }

    // MARK: - Thai and Vietnamese Tests

    @Test("Thai has 42 characters per line limit")
    func thaiCharacterLimit() {
        let thai = Locale(identifier: "th")
        #expect(SubtitleStandards.maxCharactersPerLine(for: thai) == 42)
    }

    @Test("Vietnamese has 42 characters per line limit")
    func vietnameseCharacterLimit() {
        let vietnamese = Locale(identifier: "vi")
        #expect(SubtitleStandards.maxCharactersPerLine(for: vietnamese) == 42)
    }

    // MARK: - Fallback Tests

    @Test("Unknown language defaults to 42 characters per line")
    func unknownLanguageDefaultsToLatin() {
        let unknown = Locale(identifier: "xx-XX")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknown) == 42)
    }

    @Test("Unknown language with CJK script defaults to 16 characters per line")
    func unknownLanguageWithCJKScriptDefaultsToCJK() {
        // Create a locale with an unknown language code but Han script
        let unknownWithHanScript = Locale(identifier: "und-Hans")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithHanScript) == 16)
    }

    @Test("Unknown language with Traditional Han script defaults to 16 characters per line")
    func unknownLanguageWithTraditionalHanScriptDefaultsToCJK() {
        let unknownWithHantScript = Locale(identifier: "und-Hant")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithHantScript) == 16)
    }

    @Test("Unknown language with Hangul script defaults to 16 characters per line")
    func unknownLanguageWithHangulScriptDefaultsToCJK() {
        let unknownWithHangScript = Locale(identifier: "und-Hang")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithHangScript) == 16)
    }

    @Test("Unknown language with Japanese script defaults to 16 characters per line")
    func unknownLanguageWithJapaneseScriptDefaultsToCJK() {
        let unknownWithJpanScript = Locale(identifier: "und-Jpan")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithJpanScript) == 16)
    }

    @Test("Unknown language with Korean script defaults to 16 characters per line")
    func unknownLanguageWithKoreanScriptDefaultsToCJK() {
        let unknownWithKoreScript = Locale(identifier: "und-Kore")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithKoreScript) == 16)
    }

    @Test("Unknown language with Hiragana script defaults to 16 characters per line")
    func unknownLanguageWithHiraganaScriptDefaultsToCJK() {
        let unknownWithHiraScript = Locale(identifier: "und-Hira")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithHiraScript) == 16)
    }

    @Test("Unknown language with Katakana script defaults to 16 characters per line")
    func unknownLanguageWithKatakanaScriptDefaultsToCJK() {
        let unknownWithKanaScript = Locale(identifier: "und-Kana")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithKanaScript) == 16)
    }

    @Test("Unknown language with non-CJK script defaults to 42 characters per line")
    func unknownLanguageWithNonCJKScriptDefaultsToLatin() {
        // Cyrillic script with unknown language
        let unknownWithCyrlScript = Locale(identifier: "und-Cyrl")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownWithCyrlScript) == 42)
    }

    @Test("Locale without script code defaults to 42 characters per line")
    func localeWithoutScriptCodeDefaultsToLatin() {
        // A locale with no script specified and unknown language
        let unknownNoScript = Locale(identifier: "xx")
        #expect(SubtitleStandards.maxCharactersPerLine(for: unknownNoScript) == 42)
    }

    @Test("Empty locale identifier defaults to 42 characters per line")
    func emptyLocaleIdentifierDefaultsToLatin() {
        // Empty locale identifier has nil language code, triggers fallback to "en"
        let emptyLocale = Locale(identifier: "")
        #expect(SubtitleStandards.maxCharactersPerLine(for: emptyLocale) == 42)
    }

    // MARK: - Estimated Duration Additional Tests

    @Test("Non-CJK language uses Latin reading speed")
    func nonCJKLanguageUsesLatinSpeed() {
        let german = Locale(identifier: "de")
        // 34 characters at 17 chars/sec = 2 seconds
        let text = String(repeating: "a", count: 34)

        let duration = SubtitleStandards.estimatedDuration(for: text, locale: german)
        #expect(duration == 2.0)
    }

    @Test("CJK duration maximum of 7 seconds")
    func cjkDurationMaximum() {
        let japanese = Locale(identifier: "ja")
        // 100 characters at 4 chars/sec = 25 seconds, should cap at 7
        let longText = String(repeating: "あ", count: 100)

        let duration = SubtitleStandards.estimatedDuration(for: longText, locale: japanese)
        #expect(duration == 7.0)
    }

    @Test("CJK duration minimum of 1 second")
    func cjkDurationMinimum() {
        let japanese = Locale(identifier: "ja")
        // 1 character at 4 chars/sec = 0.25 seconds, should be minimum 1
        let shortText = "あ"

        let duration = SubtitleStandards.estimatedDuration(for: shortText, locale: japanese)
        #expect(duration == 1.0)
    }

    @Test("Empty text has minimum duration of 1 second")
    func emptyTextMinimumDuration() {
        let english = Locale(identifier: "en-US")
        let emptyText = ""

        let duration = SubtitleStandards.estimatedDuration(for: emptyText, locale: english)
        #expect(duration == 1.0)
    }

    @Test("Duration for locale without language code uses Latin speed")
    func durationForLocaleWithoutLanguageCode() {
        // Create a locale that might not have a language code
        let unknownLocale = Locale(identifier: "")
        // 34 characters at 17 chars/sec = 2 seconds
        let text = String(repeating: "a", count: 34)

        let duration = SubtitleStandards.estimatedDuration(for: text, locale: unknownLocale)
        #expect(duration == 2.0)
    }
}
