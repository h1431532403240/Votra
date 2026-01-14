//
//  TranscriptSegmentation.swift
//  Votra
//
//  Models for intelligent transcript segmentation using Apple Intelligence Foundation Models.
//

import Foundation
import FoundationModels

// MARK: - Generable Types for AI Segmentation

/// A single segment of transcribed text with natural sentence boundaries
@Generable(description: "A segment of transcribed speech representing a complete thought or sentence")
struct TranscriptSegment: Sendable, Hashable {
    @Guide(description: "The exact text of this segment, preserving original wording")
    var text: String
}

/// Result of intelligent transcript segmentation
@Generable(description: "A transcript split into logical segments at natural sentence boundaries")
struct TranscriptSegmentation: Sendable {
    @Guide(description: "The transcript split into complete sentences or logical phrases", .minimumCount(1))
    var segments: [TranscriptSegment]
}

// MARK: - Word Timing for Mapping

/// Word timing information extracted from speech recognition
struct WordTimingInfo: Sendable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

// MARK: - Segmented Result

/// A segment with timing information mapped from word timings
struct TimedSegment: Sendable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}
