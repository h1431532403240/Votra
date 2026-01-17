//
//  IntelligentSegmentationService.swift
//  Votra
//
//  Service for intelligent transcript segmentation using Apple Intelligence Foundation Models.
//  Segments transcribed text into natural sentences/phrases instead of pause-based splitting.
//

import Foundation
import FoundationModels

// MARK: - Segmentation Result

/// Result of segmentation including any skipped segments due to safety filters
struct SegmentationResult: Sendable {
    let segments: [TimedSegment]
    let skippedTexts: [String]

    var hasSkippedSegments: Bool {
        !skippedTexts.isEmpty
    }

    /// Create a successful result with no skipped segments
    static func success(_ segments: [TimedSegment]) -> SegmentationResult {
        SegmentationResult(segments: segments, skippedTexts: [])
    }

    /// Create a result with skipped text (fallback when AI fails)
    static func fallback(originalText: String, startTime: TimeInterval, endTime: TimeInterval) -> SegmentationResult {
        SegmentationResult(
            segments: [TimedSegment(text: originalText, startTime: startTime, endTime: endTime)],
            skippedTexts: [originalText]
        )
    }
}

// MARK: - Protocol

/// Protocol for intelligent segmentation service
@MainActor
protocol IntelligentSegmentationServiceProtocol: AnyObject {
    /// Segment transcript text into subtitle-appropriate chunks
    /// Returns a result containing segments and any texts that were skipped due to safety filters
    func segmentTranscript(
        text: String,
        wordTimings: [WordTimingInfo],
        sourceLocale: Locale,
        maxCharsPerSegment: Int?
    ) async -> SegmentationResult
}

// MARK: - Intelligent Segmentation Service

/// Service that uses Apple Intelligence to segment transcripts into natural sentences
@MainActor
final class IntelligentSegmentationService: IntelligentSegmentationServiceProtocol {

    // MARK: - Public Methods

    /// Segment transcript text into subtitle-appropriate chunks using Apple Intelligence
    /// - Parameters:
    ///   - text: The raw transcription text
    ///   - wordTimings: Word-level timing information from speech recognition
    ///   - sourceLocale: The language of the transcript
    ///   - maxCharsPerSegment: Maximum characters per subtitle segment (based on language standards)
    /// - Returns: SegmentationResult containing segments and any skipped texts due to safety filters
    func segmentTranscript(
        text: String,
        wordTimings: [WordTimingInfo],
        sourceLocale: Locale,
        maxCharsPerSegment: Int? = nil
    ) async -> SegmentationResult {
        // Use language-specific limit or provided limit
        let charLimit = maxCharsPerSegment ?? SubtitleStandards.maxCharactersPerEvent(for: sourceLocale)

        // Create session with instructions for segmentation
        let session = LanguageModelSession(
            instructions: """
            You are a subtitle segmentation assistant. Your task is to split transcribed speech \
            into segments suitable for video subtitles.

            Rules:
            1. Preserve the EXACT original text - do not paraphrase, modify, or add words
            2. Each segment MUST be \(charLimit) characters or less (this is critical for subtitle display)
            3. Split at natural sentence boundaries when possible (periods, question marks, complete thoughts)
            4. If a sentence is too long, split at natural phrase boundaries (commas, conjunctions, pauses)
            5. Keep related words together - don't split in the middle of a phrase
            6. Do not add punctuation that wasn't in the original text
            """
        )

        // Create the prompt
        let languageName = sourceLocale.localizedString(forLanguageCode: sourceLocale.language.languageCode?.identifier ?? "en") ?? "English"
        let prompt = """
        Split this \(languageName) transcript into subtitle segments. \
        Each segment must be \(charLimit) characters or less. \
        Return the segments in order, preserving the exact original text:

        \(text)
        """

        // Generate segmentation using Foundation Models
        let response: LanguageModelSession.Response<TranscriptSegmentation>
        do {
            response = try await session.respond(
                to: prompt,
                generating: TranscriptSegmentation.self
            )
        } catch {
            // Check for safety guardrails error - fallback to original text
            let errorMessage = String(describing: error)
            if errorMessage.contains("Safety guardrails") || errorMessage.contains("guardrails were triggered") {
                // Return original text as-is, marking it as skipped for user notification
                let startTime = wordTimings.first?.startTime ?? 0
                let endTime = wordTimings.last?.endTime ?? 0
                return .fallback(originalText: text, startTime: startTime, endTime: endTime)
            }
            // Other errors - also fallback but don't mark as skipped (not a safety issue)
            let startTime = wordTimings.first?.startTime ?? 0
            let endTime = wordTimings.last?.endTime ?? 0
            return SegmentationResult(
                segments: [TimedSegment(text: text, startTime: startTime, endTime: endTime)],
                skippedTexts: []
            )
        }

        let segments = response.content.segments

        // Check if segments is empty - this can happen when safety guardrails are triggered
        // but the framework returns empty result instead of throwing
        if segments.isEmpty {
            let startTime = wordTimings.first?.startTime ?? 0
            let endTime = wordTimings.last?.endTime ?? 0
            return .fallback(originalText: text, startTime: startTime, endTime: endTime)
        }

        // Check if AI response content is completely different from input
        // This can happen when guardrails are triggered but AI returns unrelated content
        let combinedOutput = segments.map(\.text).joined(separator: " ")
        let outputSimilarity = calculateSimilarity(
            normalizeForComparison(text),
            normalizeForComparison(combinedOutput)
        )
        if outputSimilarity < 0.2 {
            // AI returned something completely unrelated - likely guardrails triggered
            let startTime = wordTimings.first?.startTime ?? 0
            let endTime = wordTimings.last?.endTime ?? 0
            return .fallback(originalText: text, startTime: startTime, endTime: endTime)
        }

        // Validate segments - filter out any that look like AI instructions/hallucinations
        // Only keep segments whose text actually appears in the original input
        let normalizedInput = normalizeForComparison(text)
        let validatedSegments = segments.filter { segment in
            let normalizedSegment = normalizeForComparison(segment.text)
            // Check if this segment's content exists in the original text
            return normalizedInput.contains(normalizedSegment) ||
                   calculateSimilarity(normalizedSegment, normalizedInput) > 0.3
        }

        // Track if significant content was filtered (potential AI hallucination/guardrail issue)
        let filteredCount = segments.count - validatedSegments.count
        let hadSignificantFiltering = filteredCount > 0 && Double(filteredCount) / Double(segments.count) > 0.3

        // If all segments were filtered out, fallback to original text
        if validatedSegments.isEmpty {
            let startTime = wordTimings.first?.startTime ?? 0
            let endTime = wordTimings.last?.endTime ?? 0
            return .fallback(originalText: text, startTime: startTime, endTime: endTime)
        }

        // Map segments back to word timings
        let timedSegments = mapSegmentsToTimings(segments: validatedSegments, wordTimings: wordTimings)

        // If significant content was filtered, mark as having skipped content
        if hadSignificantFiltering {
            return SegmentationResult(segments: timedSegments, skippedTexts: [text])
        }

        return .success(timedSegments)
    }

    // MARK: - Internal Methods (exposed for testing)

    /// Map AI-generated segments back to word timings for accurate timestamps
    func mapSegmentsToTimings(
        segments: [TranscriptSegment],
        wordTimings: [WordTimingInfo]
    ) -> [TimedSegment] {
        guard !wordTimings.isEmpty else {
            // No timing info - return segments without timing
            return segments.map { segment in
                TimedSegment(text: segment.text, startTime: 0, endTime: 0)
            }
        }

        var timedSegments: [TimedSegment] = []
        var currentWordIndex = 0

        for segment in segments {
            let segmentText = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !segmentText.isEmpty else { continue }

            // Find matching words in the word timings
            let matchResult = findMatchingWordRange(
                for: segmentText,
                in: wordTimings,
                startingFrom: currentWordIndex
            )

            if let (startIdx, endIdx) = matchResult {
                let startTime = wordTimings[startIdx].startTime
                let endTime = wordTimings[endIdx].endTime

                timedSegments.append(TimedSegment(
                    text: segmentText,
                    startTime: startTime,
                    endTime: endTime
                ))

                currentWordIndex = endIdx + 1
            } else {
                // Fallback: use previous segment's end time or estimate
                let fallbackStart = timedSegments.last?.endTime ?? wordTimings.first?.startTime ?? 0
                let fallbackEnd = fallbackStart + estimateDuration(for: segmentText)

                timedSegments.append(TimedSegment(
                    text: segmentText,
                    startTime: fallbackStart,
                    endTime: fallbackEnd
                ))
            }
        }

        return timedSegments
    }

    /// Find the range of words that match a segment text
    func findMatchingWordRange(
        for segmentText: String,
        in wordTimings: [WordTimingInfo],
        startingFrom startIndex: Int
    ) -> (startIdx: Int, endIdx: Int)? {
        guard startIndex < wordTimings.count else { return nil }

        // Normalize segment text for comparison
        let normalizedSegment = normalizeForComparison(segmentText)

        // Try to find the best matching word range
        var bestMatch: (startIdx: Int, endIdx: Int)?
        var bestMatchScore = 0.0

        // Search forward from startIndex
        for searchStart in startIndex..<min(startIndex + 10, wordTimings.count) {
            var combinedText = ""

            for endIdx in searchStart..<wordTimings.count {
                let wordText = wordTimings[endIdx].text
                combinedText += wordText

                let normalizedCombined = normalizeForComparison(combinedText)

                // Check for exact or near match
                let similarity = calculateSimilarity(normalizedSegment, normalizedCombined)

                if similarity > bestMatchScore {
                    bestMatchScore = similarity
                    bestMatch = (searchStart, endIdx)
                }

                // If we've gone significantly past the segment length, stop
                if normalizedCombined.count > normalizedSegment.count * 2 {
                    break
                }

                // If we found a very good match, use it
                if similarity > 0.9 {
                    return (searchStart, endIdx)
                }
            }
        }

        // Accept match if it's reasonably good
        if bestMatchScore > 0.6, let match = bestMatch {
            return match
        }

        return nil
    }

    /// Normalize text for comparison (remove punctuation, lowercase, normalize whitespace)
    func normalizeForComparison(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Calculate similarity between two strings (0.0 to 1.0)
    func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        guard !str1.isEmpty && !str2.isEmpty else { return 0 }

        // Simple character-based similarity
        let set1 = Set(str1)
        let set2 = Set(str2)
        let intersection = set1.intersection(set2)

        // Also consider length similarity
        let lengthRatio = min(Double(str1.count), Double(str2.count)) / max(Double(str1.count), Double(str2.count))
        let charSimilarity = Double(intersection.count) / Double(max(set1.count, set2.count))

        // Check if str2 contains str1 or vice versa
        let containment = str1.localizedStandardContains(str2) || str2.localizedStandardContains(str1) ? 0.3 : 0

        return (charSimilarity * 0.4 + lengthRatio * 0.3 + containment)
    }

    /// Estimate duration for a text segment based on average speaking rate
    func estimateDuration(for text: String) -> TimeInterval {
        // Average speaking rate: ~150 words per minute = 2.5 words per second
        let wordCount = text.split(separator: " ").count
        return max(1.0, Double(wordCount) / 2.5)
    }
}
