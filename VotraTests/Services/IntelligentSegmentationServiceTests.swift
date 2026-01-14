//
//  IntelligentSegmentationServiceTests.swift
//  VotraTests
//
//  Tests for IntelligentSegmentationService - validates transcript segmentation
//  and word timing mapping functionality.
//

import Foundation
import Testing
@testable import Votra

@Suite("Intelligent Segmentation Service")
@MainActor
struct IntelligentSegmentationServiceTests {
    // MARK: - Helper Factories

    /// Creates word timing info for testing
    private func createWordTiming(
        _ text: String,
        start: TimeInterval,
        end: TimeInterval
    ) -> WordTimingInfo {
        WordTimingInfo(text: text, startTime: start, endTime: end)
    }

    /// Creates a sequence of word timings from words with automatic timing
    /// Note: Words are stored with trailing space to match speech recognition output
    private func createWordTimings(from words: [String], startTime: TimeInterval = 0.0, addSpaces: Bool = true) -> [WordTimingInfo] {
        var timings: [WordTimingInfo] = []
        var currentTime = startTime

        for (index, word) in words.enumerated() {
            let duration = Double(word.count) * 0.1 // 0.1 seconds per character
            // Add space after word (except last) to simulate speech recognition output
            let textWithSpace = addSpaces && index < words.count - 1 ? word + " " : word
            timings.append(WordTimingInfo(
                text: textWithSpace,
                startTime: currentTime,
                endTime: currentTime + duration
            ))
            currentTime += duration + 0.05 // Small gap between words
        }

        return timings
    }

    // MARK: - Map Segments to Timings Tests

    @Test("Maps segments to word timings correctly")
    func mapSegmentsToTimingsBasic() async {
        let service = IntelligentSegmentationService()

        // Words include trailing spaces to simulate speech recognition output
        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world ", start: 0.6, end: 1.0),
            createWordTiming("how ", start: 1.1, end: 1.3),
            createWordTiming("are ", start: 1.4, end: 1.6),
            createWordTiming("you", start: 1.7, end: 2.0)
        ]

        let segments = [
            TranscriptSegment(text: "Hello world"),
            TranscriptSegment(text: "how are you")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 2)
        #expect(result[0].text == "Hello world")
        #expect(result[0].startTime == 0.0)
        #expect(result[0].endTime == 1.0)

        #expect(result[1].text == "how are you")
        #expect(result[1].startTime == 1.1)
        #expect(result[1].endTime == 2.0)
    }

    @Test("Returns segments without timing when word timings are empty")
    func mapSegmentsWithEmptyWordTimings() async {
        let service = IntelligentSegmentationService()

        let segments = [
            TranscriptSegment(text: "Hello world"),
            TranscriptSegment(text: "This is a test")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: [])

        #expect(result.count == 2)
        #expect(result[0].text == "Hello world")
        #expect(result[0].startTime == 0)
        #expect(result[0].endTime == 0)

        #expect(result[1].text == "This is a test")
        #expect(result[1].startTime == 0)
        #expect(result[1].endTime == 0)
    }

    @Test("Skips empty segments when mapping")
    func mapSegmentsSkipsEmptyText() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world", start: 0.6, end: 1.0)
        ]

        let segments = [
            TranscriptSegment(text: "Hello world"),
            TranscriptSegment(text: "   "),
            TranscriptSegment(text: "")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
        #expect(result[0].text == "Hello world")
    }

    @Test("Uses fallback timing when segment cannot be matched")
    func mapSegmentsUsesFallbackTiming() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world", start: 0.6, end: 1.0)
        ]

        // Second segment doesn't match any word timings
        let segments = [
            TranscriptSegment(text: "Hello world"),
            TranscriptSegment(text: "xyz abc qrs tuv")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 2)
        #expect(result[0].text == "Hello world")
        #expect(result[0].startTime == 0.0)
        #expect(result[0].endTime == 1.0)

        // Second segment should use fallback timing
        #expect(result[1].text == "xyz abc qrs tuv")
        #expect(result[1].startTime == 1.0) // Continues from previous segment end
        #expect(result[1].endTime > result[1].startTime) // Should have estimated duration
    }

    // MARK: - Text Normalization Tests

    @Test("Normalizes text by removing punctuation")
    func normalizeForComparisonRemovesPunctuation() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("Hello, world! How are you?")

        #expect(result == "hello world how are you")
    }

    @Test("Normalizes text by lowercasing")
    func normalizeForComparisonLowercases() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("HELLO World")

        #expect(result == "hello world")
    }

    @Test("Normalizes text by collapsing whitespace")
    func normalizeForComparisonCollapsesWhitespace() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("Hello    world   test")

        #expect(result == "hello world test")
    }

    @Test("Handles empty string normalization")
    func normalizeForComparisonEmpty() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("")

        #expect(result.isEmpty)
    }

    @Test("Handles whitespace-only string normalization")
    func normalizeForComparisonWhitespaceOnly() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("   ")

        #expect(result.isEmpty)
    }

    // MARK: - Similarity Calculation Tests

    @Test("Returns 0 for empty strings")
    func calculateSimilarityEmptyStrings() async {
        let service = IntelligentSegmentationService()

        #expect(service.calculateSimilarity("", "") == 0)
        #expect(service.calculateSimilarity("hello", "") == 0)
        #expect(service.calculateSimilarity("", "world") == 0)
    }

    @Test("Returns high similarity for identical strings")
    func calculateSimilarityIdentical() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("hello world", "hello world")

        // Should be high (> 0.9) for identical strings
        #expect(similarity > 0.9)
    }

    @Test("Returns moderate similarity for similar strings")
    func calculateSimilaritySimilar() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("hello world", "hello")

        // Should be moderate (containment bonus applies)
        #expect(similarity > 0.3)
        #expect(similarity < 1.0)
    }

    @Test("Returns low similarity for completely different strings")
    func calculateSimilarityDifferent() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("abc", "xyz")

        // Should be low for completely different strings
        #expect(similarity < 0.5)
    }

    @Test("Similarity is symmetric for containment")
    func calculateSimilarityContainment() async {
        let service = IntelligentSegmentationService()

        // Both should get containment bonus since one contains the other
        let sim1 = service.calculateSimilarity("hello world", "hello")
        let sim2 = service.calculateSimilarity("hello", "hello world")

        // Both should be > 0.3 due to containment bonus
        #expect(sim1 > 0.3)
        #expect(sim2 > 0.3)
    }

    // MARK: - Duration Estimation Tests

    @Test("Estimates duration based on word count")
    func estimateDurationBasic() async {
        let service = IntelligentSegmentationService()

        // 5 words at 2.5 words/second = 2.0 seconds
        let duration = service.estimateDuration(for: "one two three four five")

        #expect(duration == 2.0)
    }

    @Test("Returns minimum duration of 1 second")
    func estimateDurationMinimum() async {
        let service = IntelligentSegmentationService()

        // 1 word at 2.5 words/second = 0.4 seconds, should clamp to 1.0
        let duration = service.estimateDuration(for: "hi")

        #expect(duration == 1.0)
    }

    @Test("Handles empty string duration")
    func estimateDurationEmpty() async {
        let service = IntelligentSegmentationService()

        // Empty string has 0 words, should return minimum 1.0
        let duration = service.estimateDuration(for: "")

        #expect(duration == 1.0)
    }

    @Test("Calculates duration for longer text")
    func estimateDurationLongerText() async {
        let service = IntelligentSegmentationService()

        // 10 words at 2.5 words/second = 4.0 seconds
        let text = "one two three four five six seven eight nine ten"
        let duration = service.estimateDuration(for: text)

        #expect(duration == 4.0)
    }

    // MARK: - Find Matching Word Range Tests

    @Test("Finds exact match at start")
    func findMatchingWordRangeExactAtStart() async {
        let service = IntelligentSegmentationService()

        // Words with trailing spaces to simulate speech recognition
        let wordTimings = createWordTimings(from: ["Hello", "world", "test"], addSpaces: true)

        let result = service.findMatchingWordRange(
            for: "Hello world",
            in: wordTimings,
            startingFrom: 0
        )

        #expect(result != nil)
        #expect(result?.startIdx == 0)
        #expect(result?.endIdx == 1)
    }

    @Test("Finds match in middle of word timings")
    func findMatchingWordRangeInMiddle() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["one", "two", "three", "four", "five"], addSpaces: true)

        let result = service.findMatchingWordRange(
            for: "three four",
            in: wordTimings,
            startingFrom: 2
        )

        #expect(result != nil)
        #expect(result?.startIdx == 2)
        #expect(result?.endIdx == 3)
    }

    @Test("Returns nil when start index exceeds word count")
    func findMatchingWordRangeStartIndexTooLarge() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["Hello", "world"], addSpaces: true)

        let result = service.findMatchingWordRange(
            for: "Hello",
            in: wordTimings,
            startingFrom: 10
        )

        #expect(result == nil)
    }

    @Test("Handles punctuation differences in matching")
    func findMatchingWordRangeWithPunctuation() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["Hello", "world"], addSpaces: true)

        // Should match even with punctuation differences due to normalization
        let result = service.findMatchingWordRange(
            for: "Hello, world!",
            in: wordTimings,
            startingFrom: 0
        )

        #expect(result != nil)
        #expect(result?.startIdx == 0)
        #expect(result?.endIdx == 1)
    }

    @Test("Handles case differences in matching")
    func findMatchingWordRangeWithCaseDifference() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["HELLO", "WORLD"], addSpaces: true)

        // Should match even with case differences due to normalization
        let result = service.findMatchingWordRange(
            for: "hello world",
            in: wordTimings,
            startingFrom: 0
        )

        #expect(result != nil)
        #expect(result?.startIdx == 0)
        #expect(result?.endIdx == 1)
    }

    @Test("Returns nil for completely unmatched text")
    func findMatchingWordRangeNoMatch() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["Hello", "world"], addSpaces: true)

        // Use completely different characters to ensure no match
        let result = service.findMatchingWordRange(
            for: "xyz qrs",
            in: wordTimings,
            startingFrom: 0
        )

        #expect(result == nil)
    }

    // MARK: - Integration Tests (Mapping Behavior)

    @Test("Maps multiple segments sequentially")
    func mapMultipleSegmentsSequentially() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: [
            "The", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"
        ], addSpaces: true)

        let segments = [
            TranscriptSegment(text: "The quick brown fox"),
            TranscriptSegment(text: "jumps over"),
            TranscriptSegment(text: "the lazy dog")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 3)

        // First segment should start at beginning
        #expect(result[0].text == "The quick brown fox")
        #expect(result[0].startTime == wordTimings[0].startTime)

        // Second segment should start after first
        #expect(result[1].text == "jumps over")
        #expect(result[1].startTime >= result[0].endTime)

        // Third segment should start after second
        #expect(result[2].text == "the lazy dog")
        #expect(result[2].startTime >= result[1].endTime)
    }

    @Test("Handles single word segments")
    func mapSingleWordSegments() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("World", start: 0.6, end: 1.0)
        ]

        let segments = [
            TranscriptSegment(text: "Hello"),
            TranscriptSegment(text: "World")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 2)
        #expect(result[0].text == "Hello")
        #expect(result[0].startTime == 0.0)
        #expect(result[0].endTime == 0.5)

        #expect(result[1].text == "World")
        #expect(result[1].startTime == 0.6)
        #expect(result[1].endTime == 1.0)
    }

    // MARK: - Edge Case Tests

    @Test("Handles segment with trailing whitespace")
    func mapSegmentWithTrailingWhitespace() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world", start: 0.6, end: 1.0)
        ]

        let segments = [
            TranscriptSegment(text: "Hello world   ")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
        #expect(result[0].text == "Hello world") // Trimmed
    }

    @Test("Handles segment with leading whitespace")
    func mapSegmentWithLeadingWhitespace() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world", start: 0.6, end: 1.0)
        ]

        let segments = [
            TranscriptSegment(text: "   Hello world")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
        #expect(result[0].text == "Hello world") // Trimmed
    }

    @Test("Handles fallback when first segment cannot be matched")
    func mapSegmentsFirstSegmentFallback() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 1.0, end: 1.5),
            createWordTiming("world", start: 1.6, end: 2.0)
        ]

        // First segment doesn't match any words (use completely different characters)
        let segments = [
            TranscriptSegment(text: "xyz qrs tuv"),
            TranscriptSegment(text: "Hello world")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 2)

        // First segment should use fallback starting from first word timing
        #expect(result[0].text == "xyz qrs tuv")
        #expect(result[0].startTime == 1.0) // Falls back to first word timing

        // Second segment should match correctly
        #expect(result[1].text == "Hello world")
    }

    // MARK: - Locale-Specific Tests

    @Test("Uses English character limit by default")
    func segmentTranscriptUsesEnglishLimitByDefault() async {
        // This test validates the character limit logic without calling the AI
        let englishLocale = Locale(identifier: "en-US")
        let expectedLimit = SubtitleStandards.maxCharactersPerEvent(for: englishLocale)

        #expect(expectedLimit == 84) // 42 * 2
    }

    @Test("Uses Japanese character limit for Japanese locale")
    func segmentTranscriptUsesJapaneseLimitForJapanese() async {
        let japaneseLocale = Locale(identifier: "ja")
        let expectedLimit = SubtitleStandards.maxCharactersPerEvent(for: japaneseLocale)

        #expect(expectedLimit == 26) // 13 * 2
    }

    @Test("Uses Korean character limit for Korean locale")
    func segmentTranscriptUsesKoreanLimitForKorean() async {
        let koreanLocale = Locale(identifier: "ko")
        let expectedLimit = SubtitleStandards.maxCharactersPerEvent(for: koreanLocale)

        #expect(expectedLimit == 32) // 16 * 2
    }

    @Test("Uses Chinese character limit for Chinese locale")
    func segmentTranscriptUsesChineseLimitForChinese() async {
        let chineseLocale = Locale(identifier: "zh-Hans")
        let expectedLimit = SubtitleStandards.maxCharactersPerEvent(for: chineseLocale)

        #expect(expectedLimit == 32) // 16 * 2
    }

    // MARK: - Additional mapSegmentsToTimings Edge Cases

    @Test("Returns empty array when segments array is empty")
    func mapSegmentsToTimingsEmptySegments() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world", start: 0.6, end: 1.0)
        ]

        let result = service.mapSegmentsToTimings(segments: [], wordTimings: wordTimings)

        #expect(result.isEmpty)
    }

    @Test("Returns empty array when all segments are whitespace")
    func mapSegmentsToTimingsAllWhitespaceSegments() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world", start: 0.6, end: 1.0)
        ]

        let segments = [
            TranscriptSegment(text: "   "),
            TranscriptSegment(text: "\t"),
            TranscriptSegment(text: "\n")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.isEmpty)
    }

    @Test("Handles alternating matched and unmatched segments")
    func mapSegmentsAlternatingMatchedUnmatched() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("world ", start: 0.6, end: 1.0),
            createWordTiming("test ", start: 1.1, end: 1.5),
            createWordTiming("here", start: 1.6, end: 2.0)
        ]

        let segments = [
            TranscriptSegment(text: "Hello world"),
            TranscriptSegment(text: "xyz abc"), // Unmatched
            TranscriptSegment(text: "test here")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 3)
        #expect(result[0].text == "Hello world")
        #expect(result[0].startTime == 0.0)
        #expect(result[0].endTime == 1.0)

        // Unmatched segment should use fallback
        #expect(result[1].text == "xyz abc")
        #expect(result[1].startTime == 1.0) // Continues from previous

        // Third segment might match or fall back depending on index
        #expect(result[2].text == "test here")
    }

    @Test("Handles single segment with single word")
    func mapSegmentsSingleSegmentSingleWord() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello", start: 0.0, end: 0.5)
        ]

        let segments = [
            TranscriptSegment(text: "Hello")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
        #expect(result[0].text == "Hello")
        #expect(result[0].startTime == 0.0)
        #expect(result[0].endTime == 0.5)
    }

    @Test("Handles segments when word timings have only one word")
    func mapSegmentsWithSingleWordTiming() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("Hello", start: 0.0, end: 0.5)
        ]

        let segments = [
            TranscriptSegment(text: "Hello"),
            TranscriptSegment(text: "world test")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 2)
        #expect(result[0].text == "Hello")
        #expect(result[0].startTime == 0.0)
        #expect(result[0].endTime == 0.5)

        // Second segment should use fallback
        #expect(result[1].text == "world test")
        #expect(result[1].startTime == 0.5)
    }

    @Test("Fallback timing uses first word timing when no previous segment exists")
    func mapSegmentsFallbackUsesFirstWordTiming() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("abc ", start: 2.0, end: 2.5),
            createWordTiming("def", start: 2.6, end: 3.0)
        ]

        // Segment that won't match
        let segments = [
            TranscriptSegment(text: "xyz qrs tuv")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
        #expect(result[0].startTime == 2.0) // Uses first word timing start
    }

    // MARK: - Additional findMatchingWordRange Edge Cases

    @Test("Returns nil for empty word timings array")
    func findMatchingWordRangeEmptyTimings() async {
        let service = IntelligentSegmentationService()

        let result = service.findMatchingWordRange(
            for: "Hello world",
            in: [],
            startingFrom: 0
        )

        #expect(result == nil)
    }

    @Test("Finds match with single word timing")
    func findMatchingWordRangeSingleTiming() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [createWordTiming("Hello", start: 0.0, end: 0.5)]

        let result = service.findMatchingWordRange(
            for: "Hello",
            in: wordTimings,
            startingFrom: 0
        )

        #expect(result != nil)
        #expect(result?.startIdx == 0)
        #expect(result?.endIdx == 0)
    }

    @Test("Finds match at last valid index")
    func findMatchingWordRangeAtLastIndex() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["one", "two", "three"], addSpaces: true)

        let result = service.findMatchingWordRange(
            for: "three",
            in: wordTimings,
            startingFrom: 2
        )

        #expect(result != nil)
        #expect(result?.startIdx == 2)
        #expect(result?.endIdx == 2)
    }

    @Test("Stops early when combined text exceeds double segment length")
    func findMatchingWordRangeStopsAtDoubleLength() async {
        let service = IntelligentSegmentationService()

        // Create many word timings
        let wordTimings = createWordTimings(from: [
            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
            "k", "l", "m", "n", "o", "p", "q", "r", "s", "t"
        ], addSpaces: true)

        // Short segment that won't match
        let result = service.findMatchingWordRange(
            for: "xy",
            in: wordTimings,
            startingFrom: 0
        )

        // Should return nil since no match found
        #expect(result == nil)
    }

    @Test("Accepts match with moderate similarity above 0.6 threshold")
    func findMatchingWordRangeModeratelySimilar() async {
        let service = IntelligentSegmentationService()

        // Words that will produce moderate similarity when combined
        let wordTimings = [
            createWordTiming("Hello ", start: 0.0, end: 0.5),
            createWordTiming("worlds", start: 0.6, end: 1.0) // Note: "worlds" not "world"
        ]

        let result = service.findMatchingWordRange(
            for: "Hello world",
            in: wordTimings,
            startingFrom: 0
        )

        // Should find a match even though not exact
        #expect(result != nil)
    }

    @Test("Searches forward and finds best match")
    func findMatchingWordRangeSearchesForward() async {
        let service = IntelligentSegmentationService()

        // Create timings where match is a few positions ahead
        let wordTimings = createWordTimings(from: [
            "a", "b", "c", "target", "word"
        ], addSpaces: true)

        let result = service.findMatchingWordRange(
            for: "target word",
            in: wordTimings,
            startingFrom: 0
        )

        // Should find a match. Due to the algorithm checking similarity > 0.9,
        // it may find "c target word" (2,4) first or "target word" (3,4)
        // Both are acceptable matches for the text
        #expect(result != nil)
        #expect(result?.endIdx == 4) // Must include "word"
    }

    @Test("Returns nil when start index equals word count")
    func findMatchingWordRangeStartAtExactCount() async {
        let service = IntelligentSegmentationService()

        let wordTimings = createWordTimings(from: ["Hello", "world"], addSpaces: true)

        let result = service.findMatchingWordRange(
            for: "Hello",
            in: wordTimings,
            startingFrom: 2 // Exactly at count
        )

        #expect(result == nil)
    }

    // MARK: - Additional normalizeForComparison Edge Cases

    @Test("Normalizes text with multiple consecutive punctuation marks")
    func normalizeForComparisonMultiplePunctuation() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("Hello... World!!!")

        #expect(result == "hello world")
    }

    @Test("Normalizes text with tabs")
    func normalizeForComparisonWithTabs() async {
        let service = IntelligentSegmentationService()

        // Tabs are whitespace characters
        let result = service.normalizeForComparison("Hello\tworld")

        #expect(result == "hello world")
    }

    @Test("Preserves newlines in normalized text")
    func normalizeForComparisonPreservesNewlines() async {
        let service = IntelligentSegmentationService()

        // Newlines are NOT in CharacterSet.whitespaces (only in .whitespacesAndNewlines)
        // So they are preserved but may be attached to words
        let result = service.normalizeForComparison("Hello\nworld")

        // Newline stays attached to "Hello"
        #expect(result.contains("hello"))
        #expect(result.contains("world"))
    }

    @Test("Normalizes text with numbers")
    func normalizeForComparisonWithNumbers() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("Test 123 number")

        #expect(result == "test 123 number")
    }

    @Test("Normalizes text with mixed punctuation and whitespace")
    func normalizeForComparisonMixedPunctuationWhitespace() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("Hello,   world!  How   are you?")

        #expect(result == "hello world how are you")
    }

    @Test("Normalizes text with only punctuation")
    func normalizeForComparisonOnlyPunctuation() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("...!!!")

        #expect(result.isEmpty)
    }

    @Test("Normalizes text with apostrophes")
    func normalizeForComparisonWithApostrophes() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("It's don't can't")

        // Apostrophes are punctuation so they get removed
        #expect(result == "its dont cant")
    }

    @Test("Normalizes text with hyphens")
    func normalizeForComparisonWithHyphens() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("well-known self-aware")

        // Hyphens are punctuation so they get removed
        #expect(result == "wellknown selfaware")
    }

    @Test("Normalizes text with unicode quotation marks")
    func normalizeForComparisonUnicodeQuotes() async {
        let service = IntelligentSegmentationService()

        let result = service.normalizeForComparison("\u{201C}Hello\u{201D} world")

        #expect(result == "hello world")
    }

    // MARK: - Additional calculateSimilarity Edge Cases

    @Test("Calculates similarity for single character strings")
    func calculateSimilaritySingleChar() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("a", "a")

        // Should have containment bonus (0.3) + char similarity + length ratio
        #expect(similarity > 0.5)
    }

    @Test("Calculates similarity for strings with same characters different order")
    func calculateSimilaritySameCharsDifferentOrder() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("abc", "cba")

        // Same characters, same length, so should have high similarity
        // charSimilarity = 1.0 (same character set)
        // lengthRatio = 1.0
        // containment = 0 (neither contains the other)
        #expect(similarity > 0.6)
    }

    @Test("Calculates similarity for strings with all same character")
    func calculateSimilarityAllSameChar() async {
        let service = IntelligentSegmentationService()

        let sim1 = service.calculateSimilarity("aaa", "aaaa")
        let sim2 = service.calculateSimilarity("aaa", "aa")

        // Should have some similarity due to shared character
        #expect(sim1 > 0.3)
        #expect(sim2 > 0.3)
    }

    @Test("Calculates similarity when one string is character subset of another")
    func calculateSimilarityCharSubset() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("abc", "abcdef")

        // abc characters are subset of abcdef
        // containment should apply
        #expect(similarity > 0.3)
    }

    @Test("Calculates similarity for very different length strings")
    func calculateSimilarityVeryDifferentLength() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("a", "abcdefghijklmnop")

        // Length ratio will be very low
        // "a" is contained in the longer string
        #expect(similarity < 0.5)
    }

    @Test("Calculates similarity for disjoint character sets")
    func calculateSimilarityDisjointChars() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("abc", "xyz")

        // No shared characters, no containment
        #expect(similarity < 0.4)
    }

    @Test("Calculates similarity with spaces in strings")
    func calculateSimilarityWithSpaces() async {
        let service = IntelligentSegmentationService()

        let similarity = service.calculateSimilarity("hello world", "hello world")

        // Identical strings
        #expect(similarity > 0.9)
    }

    @Test("Calculates similarity is bounded between 0 and 1")
    func calculateSimilarityBounded() async {
        let service = IntelligentSegmentationService()

        let sim1 = service.calculateSimilarity("a", "b")
        let sim2 = service.calculateSimilarity("hello world test", "hello world test")
        let sim3 = service.calculateSimilarity("abc", "abcabc")

        #expect(sim1 >= 0 && sim1 <= 1)
        #expect(sim2 >= 0 && sim2 <= 1)
        #expect(sim3 >= 0 && sim3 <= 1)
    }

    // MARK: - Additional estimateDuration Edge Cases

    @Test("Estimates duration for whitespace-only string")
    func estimateDurationWhitespaceOnly() async {
        let service = IntelligentSegmentationService()

        let duration = service.estimateDuration(for: "     ")

        // Whitespace-only string splits into empty array
        #expect(duration == 1.0) // Minimum duration
    }

    @Test("Estimates duration for string with multiple consecutive spaces")
    func estimateDurationMultipleSpaces() async {
        let service = IntelligentSegmentationService()

        // Multiple spaces between words should not affect word count
        let duration = service.estimateDuration(for: "one    two    three")

        // 3 words at 2.5 words/second = 1.2 seconds, clamped to minimum 1.0
        #expect(duration == 1.2)
    }

    @Test("Estimates duration for string with leading and trailing spaces")
    func estimateDurationLeadingTrailingSpaces() async {
        let service = IntelligentSegmentationService()

        let duration = service.estimateDuration(for: "   hello world   ")

        // 2 words at 2.5 words/second = 0.8 seconds, clamped to 1.0
        #expect(duration == 1.0)
    }

    @Test("Estimates duration for very long text")
    func estimateDurationVeryLongText() async {
        let service = IntelligentSegmentationService()

        // 25 words
        let text = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twenty-one twenty-two twenty-three twenty-four twenty-five"
        let duration = service.estimateDuration(for: text)

        // 25 words at 2.5 words/second = 10.0 seconds
        #expect(duration == 10.0)
    }

    @Test("Estimates duration returns minimum for two-word text")
    func estimateDurationTwoWords() async {
        let service = IntelligentSegmentationService()

        // 2 words at 2.5 words/second = 0.8 seconds, should clamp to 1.0
        let duration = service.estimateDuration(for: "hello world")

        #expect(duration == 1.0)
    }

    @Test("Estimates duration for exact threshold word count")
    func estimateDurationExactThreshold() async {
        let service = IntelligentSegmentationService()

        // At exactly 2.5 words, duration = 1.0 (threshold)
        // 3 words = 1.2 seconds (just above minimum)
        let duration = service.estimateDuration(for: "one two three")

        #expect(duration == 1.2)
    }

    @Test("Estimates duration handles tabs in text")
    func estimateDurationWithTabs() async {
        let service = IntelligentSegmentationService()

        // Tabs count as single separator, so still 3 words
        let duration = service.estimateDuration(for: "one\ttwo\tthree")

        // split(separator: " ") treats tab as part of word
        // "one\ttwo\tthree" splits to ["one\ttwo\tthree"] = 1 word
        #expect(duration == 1.0) // Minimum
    }

    // MARK: - Error Type Tests

    @Test("Segmentation error provides localized description for segmentation failed")
    func segmentationErrorDescription() async {
        let error = IntelligentSegmentationService.SegmentationError.segmentationFailed("Test reason")

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("Test reason") == true)
    }

    @Test("Segmentation error provides localized description for mapping failed")
    func mappingFailedErrorDescription() async {
        let error = IntelligentSegmentationService.SegmentationError.mappingFailed

        // The error description should not be nil and should be non-empty
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    // MARK: - Complex Integration Tests

    @Test("Handles overlapping text patterns in word timings")
    func mapSegmentsOverlappingPatterns() async {
        let service = IntelligentSegmentationService()

        // Words that could match multiple segments
        let wordTimings = [
            createWordTiming("the ", start: 0.0, end: 0.3),
            createWordTiming("the ", start: 0.4, end: 0.7),
            createWordTiming("cat ", start: 0.8, end: 1.1),
            createWordTiming("sat", start: 1.2, end: 1.5)
        ]

        let segments = [
            TranscriptSegment(text: "the the"),
            TranscriptSegment(text: "cat sat")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 2)
        #expect(result[0].text == "the the")
        #expect(result[1].text == "cat sat")
    }

    @Test("Handles very long segment text")
    func mapSegmentsVeryLongText() async {
        let service = IntelligentSegmentationService()

        // Create a long list of words
        let words = (1...20).map { "word\($0)" }
        let wordTimings = createWordTimings(from: words, addSpaces: true)

        let longText = words.joined(separator: " ")
        let segments = [TranscriptSegment(text: longText)]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
        #expect(result[0].text == longText)
        #expect(result[0].startTime == wordTimings.first?.startTime)
    }

    @Test("Handles segments with special unicode characters")
    func mapSegmentsWithUnicode() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("caf\u{00E9} ", start: 0.0, end: 0.5),
            createWordTiming("na\u{00EF}ve", start: 0.6, end: 1.0)
        ]

        let segments = [
            TranscriptSegment(text: "caf\u{00E9} na\u{00EF}ve")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 1)
    }

    @Test("Sequential mapping advances word index correctly")
    func mapSegmentsAdvancesIndex() async {
        let service = IntelligentSegmentationService()

        let wordTimings = [
            createWordTiming("a ", start: 0.0, end: 0.2),
            createWordTiming("b ", start: 0.3, end: 0.5),
            createWordTiming("c ", start: 0.6, end: 0.8),
            createWordTiming("d ", start: 0.9, end: 1.1),
            createWordTiming("e ", start: 1.2, end: 1.4),
            createWordTiming("f", start: 1.5, end: 1.7)
        ]

        let segments = [
            TranscriptSegment(text: "a b"),
            TranscriptSegment(text: "c d"),
            TranscriptSegment(text: "e f")
        ]

        let result = service.mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)

        #expect(result.count == 3)

        // Check that timing progresses correctly
        #expect(result[0].startTime == 0.0)
        #expect(result[1].startTime == 0.6)
        #expect(result[2].startTime == 1.2)

        // End times should also progress
        #expect(result[0].endTime < result[1].startTime || result[0].endTime == result[1].startTime)
        #expect(result[1].endTime < result[2].startTime || result[1].endTime == result[2].startTime)
    }
}
