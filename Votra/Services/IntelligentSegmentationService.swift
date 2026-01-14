//
//  IntelligentSegmentationService.swift
//  Votra
//
//  Service for intelligent transcript segmentation using Apple Intelligence Foundation Models.
//  Segments transcribed text into natural sentences/phrases instead of pause-based splitting.
//

import Foundation
import FoundationModels

// MARK: - Protocol

/// Protocol for intelligent segmentation service
@MainActor
protocol IntelligentSegmentationServiceProtocol: AnyObject {
    /// Segment transcript text into subtitle-appropriate chunks
    func segmentTranscript(
        text: String,
        wordTimings: [WordTimingInfo],
        sourceLocale: Locale,
        maxCharsPerSegment: Int?
    ) async throws -> [TimedSegment]
}

// MARK: - Intelligent Segmentation Service

/// Service that uses Apple Intelligence to segment transcripts into natural sentences
@MainActor
final class IntelligentSegmentationService: IntelligentSegmentationServiceProtocol {

    // MARK: - Errors

    enum SegmentationError: Error, LocalizedError {
        case segmentationFailed(String)
        case mappingFailed

        var errorDescription: String? {
            switch self {
            case .segmentationFailed(let reason):
                return String(localized: "Segmentation failed: \(reason)")
            case .mappingFailed:
                return String(localized: "Failed to map segments to timestamps")
            }
        }
    }

    // MARK: - Public Methods

    /// Segment transcript text into subtitle-appropriate chunks using Apple Intelligence
    /// - Parameters:
    ///   - text: The raw transcription text
    ///   - wordTimings: Word-level timing information from speech recognition
    ///   - sourceLocale: The language of the transcript
    ///   - maxCharsPerSegment: Maximum characters per subtitle segment (based on language standards)
    /// - Returns: Array of timed segments respecting subtitle length limits
    func segmentTranscript(
        text: String,
        wordTimings: [WordTimingInfo],
        sourceLocale: Locale,
        maxCharsPerSegment: Int? = nil
    ) async throws -> [TimedSegment] {
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
            throw SegmentationError.segmentationFailed(error.localizedDescription)
        }

        let segments = response.content.segments

        // Map segments back to word timings
        return mapSegmentsToTimings(segments: segments, wordTimings: wordTimings)
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
