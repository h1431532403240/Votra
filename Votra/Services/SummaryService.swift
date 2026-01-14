//
//  SummaryService.swift
//  Votra
//
//  Service for generating AI-powered meeting summaries using Apple Intelligence.
//

import Foundation
import FoundationModels

// MARK: - Supporting Types

/// State of summary generation
nonisolated enum SummaryGenerationState: Equatable, Sendable {
    case idle
    case preparing
    case generating(progress: Double)
    case completed
    case error(message: String)
}

/// Sendable data transfer object for summary results
nonisolated struct SummaryResult: Sendable {
    let summaryText: String
    let keyPoints: [String]
    let actionItems: [String]
}

/// Input data for summary generation (Sendable)
nonisolated struct SummaryInput: Sendable {
    struct SegmentData: Sendable {
        let speakerName: String
        let text: String
    }

    let segments: [SegmentData]
    let totalWordCount: Int
}

/// Errors during summary generation
nonisolated enum SummaryError: Error, LocalizedError, Sendable {
    case modelUnavailable
    case insufficientContent
    case generationFailed(String)
    case parsingFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return String(localized: "Apple Intelligence is not available")
        case .insufficientContent:
            return String(localized: "Not enough content to summarize")
        case .generationFailed(let reason):
            return String(localized: "Summary generation failed: \(reason)")
        case .parsingFailed:
            return String(localized: "Failed to parse summary response")
        case .cancelled:
            return String(localized: "Summary generation was cancelled")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .modelUnavailable:
            return String(localized: "Enable Apple Intelligence in System Settings > Apple Intelligence & Siri")
        case .insufficientContent:
            return String(localized: "Record more conversation content before generating a summary")
        case .generationFailed:
            return String(localized: "Try again or check that Apple Intelligence is working properly")
        case .parsingFailed:
            return String(localized: "Try generating the summary again")
        case .cancelled:
            return String(localized: "Start the summary generation again when ready")
        }
    }
}

// MARK: - Summary Service Protocol

/// Protocol for summary generation services
@MainActor
protocol SummaryServiceProtocol {
    /// Current generation state
    var state: SummaryGenerationState { get }

    /// Whether Apple Intelligence is available
    var isAvailable: Bool { get }

    /// Availability message for UI display
    var availabilityMessage: String? { get }

    /// Generate a summary from input data
    func generateSummary(from input: SummaryInput) async throws -> SummaryResult

    /// Cancel ongoing generation
    func cancel()
}

// MARK: - Implementation

/// Summary service using Apple Intelligence (FoundationModels)
@MainActor
@Observable
final class SummaryService: SummaryServiceProtocol {
    // MARK: - State

    /// Current generation state
    private(set) var state: SummaryGenerationState = .idle

    /// Whether Apple Intelligence is available
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Availability message for UI display
    var availabilityMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return String(localized: "This device doesn't support Apple Intelligence")
        case .unavailable(.appleIntelligenceNotEnabled):
            return String(localized: "Enable Apple Intelligence in System Settings > Apple Intelligence & Siri")
        case .unavailable(.modelNotReady):
            return String(localized: "Apple Intelligence is not ready yet. Please wait a moment and try again.")
        case .unavailable:
            return String(localized: "Apple Intelligence is not available on this device")
        @unknown default:
            return String(localized: "Apple Intelligence is not available")
        }
    }

    // MARK: - Private Properties

    private var currentTask: Task<SummaryResult, Error>?

    // MARK: - Public Methods

    /// Generate a summary from input data
    /// - Parameter input: Input data containing segment information
    /// - Returns: Generated summary result
    func generateSummary(from input: SummaryInput) async throws -> SummaryResult {
        // Check availability
        guard isAvailable else {
            state = .error(message: SummaryError.modelUnavailable.localizedDescription)
            throw SummaryError.modelUnavailable
        }

        // Check content
        guard !input.segments.isEmpty else {
            state = .error(message: SummaryError.insufficientContent.localizedDescription)
            throw SummaryError.insufficientContent
        }

        // Check minimum content (at least 50 words)
        guard input.totalWordCount >= 50 else {
            state = .error(message: SummaryError.insufficientContent.localizedDescription)
            throw SummaryError.insufficientContent
        }

        state = .preparing

        // Create the generation task
        currentTask = Task {
            try await performGeneration(input: input)
        }

        do {
            guard let task = currentTask else {
                throw SummaryError.generationFailed("Task was not created")
            }
            let result = try await task.value
            state = .completed
            return result
        } catch is CancellationError {
            state = .error(message: SummaryError.cancelled.localizedDescription)
            throw SummaryError.cancelled
        } catch let error as SummaryError {
            state = .error(message: error.localizedDescription)
            throw error
        } catch {
            state = .error(message: error.localizedDescription)
            throw SummaryError.generationFailed(error.localizedDescription)
        }
    }

    /// Cancel ongoing generation
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
    }

    // MARK: - Private Methods

    private func performGeneration(input: SummaryInput) async throws -> SummaryResult {
        await MainActor.run { state = .generating(progress: 0.1) }

        // Build transcript with speaker attribution
        let transcript = input.segments
            .map { segment in "\(segment.speakerName): \(segment.text)" }
            .joined(separator: "\n")

        await MainActor.run { state = .generating(progress: 0.2) }

        // Create prompt for summarization
        let prompt = """
        Summarize this conversation transcript. Provide:
        1. A brief summary (2-3 sentences)
        2. Key points (bullet list)
        3. Action items (if any)

        Format your response as:
        SUMMARY:
        [Your summary here]

        KEY POINTS:
        - [Point 1]
        - [Point 2]
        ...

        ACTION ITEMS:
        - [Item 1]
        - [Item 2]
        ...

        Transcript:
        \(transcript)
        """

        await MainActor.run { state = .generating(progress: 0.3) }

        // Create language model session
        let session = LanguageModelSession()

        await MainActor.run { state = .generating(progress: 0.5) }

        // Generate response
        let response = try await session.respond(to: prompt)

        await MainActor.run { state = .generating(progress: 0.8) }

        // Parse response
        let result = parseResponse(response.content)

        await MainActor.run { state = .generating(progress: 1.0) }

        return result
    }

    nonisolated private func parseResponse(_ content: String) -> SummaryResult {
        var summaryText = ""
        var keyPoints: [String] = []
        var actionItems: [String] = []

        var currentSection = ""

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.uppercased().hasPrefix("SUMMARY:") {
                currentSection = "summary"
                let remainder = trimmed.dropFirst("SUMMARY:".count).trimmingCharacters(in: .whitespaces)
                if !remainder.isEmpty {
                    summaryText = remainder
                }
            } else if trimmed.uppercased().hasPrefix("KEY POINTS:") {
                currentSection = "keypoints"
            } else if trimmed.uppercased().hasPrefix("ACTION ITEMS:") {
                currentSection = "actions"
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                let item = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !item.isEmpty {
                    switch currentSection {
                    case "keypoints":
                        keyPoints.append(item)
                    case "actions":
                        actionItems.append(item)
                    default:
                        break
                    }
                }
            } else if currentSection == "summary" && !trimmed.isEmpty {
                if !summaryText.isEmpty {
                    summaryText += " "
                }
                summaryText += trimmed
            }
        }

        // Fallback: if parsing failed, use entire content as summary
        if summaryText.isEmpty {
            summaryText = content.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }

        return SummaryResult(
            summaryText: summaryText,
            keyPoints: keyPoints,
            actionItems: actionItems
        )
    }
}

// MARK: - Context Window Management

extension SummaryService {
    /// Maximum tokens for the context window
    static let maxContextTokens = 4096

    /// Approximate tokens per word (for estimation)
    static let tokensPerWord: Double = 1.3

    /// Check if input fits within context window
    func inputFitsInContext(_ input: SummaryInput) -> Bool {
        let estimatedTokens = Int(Double(input.totalWordCount) * Self.tokensPerWord)
        return estimatedTokens < Self.maxContextTokens - 500 // Reserve 500 tokens for prompt and response
    }

    /// Split input into chunks that fit the context window
    func chunkInput(_ input: SummaryInput, maxWordsPerChunk: Int = 2000) -> [SummaryInput] {
        var chunks: [SummaryInput] = []
        var currentSegments: [SummaryInput.SegmentData] = []
        var currentWordCount = 0

        for segment in input.segments {
            let wordCount = segment.text.split(separator: " ").count

            if currentWordCount + wordCount > maxWordsPerChunk && !currentSegments.isEmpty {
                chunks.append(SummaryInput(segments: currentSegments, totalWordCount: currentWordCount))
                currentSegments = []
                currentWordCount = 0
            }

            currentSegments.append(segment)
            currentWordCount += wordCount
        }

        if !currentSegments.isEmpty {
            chunks.append(SummaryInput(segments: currentSegments, totalWordCount: currentWordCount))
        }

        return chunks
    }
}

// MARK: - Convenience Extension for Segments

extension SummaryInput {
    /// Create SummaryInput from an array of Segments (must be called on MainActor)
    @MainActor
    static func from(segments: [Segment]) -> SummaryInput {
        let segmentData = segments.map { segment in
            SegmentData(
                speakerName: segment.speaker?.displayName ?? String(localized: "Unknown"),
                text: segment.originalText
            )
        }
        let totalWords = segments.reduce(0) { $0 + $1.originalText.split(separator: " ").count }
        return SummaryInput(segments: segmentData, totalWordCount: totalWords)
    }
}
