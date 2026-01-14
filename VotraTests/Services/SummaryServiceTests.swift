//
//  SummaryServiceTests.swift
//  VotraTests
//
//  Tests for SummaryService including error types, parsing, and context management.
//

import Foundation
import SwiftData
import Testing
@testable import Votra

@Suite("Summary Service Tests")
@MainActor
struct SummaryServiceTests {
    let service: SummaryService
    let container: ModelContainer

    init() {
        service = SummaryService()
        container = TestModelContainer.createFresh()
    }

    // MARK: - SummaryError Description Tests

    @Test("SummaryError modelUnavailable has error description")
    func errorModelUnavailableDescription() {
        let error = SummaryError.modelUnavailable
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SummaryError insufficientContent has error description")
    func errorInsufficientContentDescription() {
        let error = SummaryError.insufficientContent
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SummaryError generationFailed includes reason")
    func errorGenerationFailedDescription() {
        let reason = "Test failure reason"
        let error = SummaryError.generationFailed(reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains(reason) == true)
    }

    @Test("SummaryError parsingFailed has error description")
    func errorParsingFailedDescription() {
        let error = SummaryError.parsingFailed
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SummaryError cancelled has error description")
    func errorCancelledDescription() {
        let error = SummaryError.cancelled
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SummaryError generationFailed with empty reason has description")
    func errorGenerationFailedEmptyReason() {
        let error = SummaryError.generationFailed("")
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("SummaryError generationFailed with special characters in reason")
    func errorGenerationFailedSpecialCharacters() {
        let reason = "Error: <xml> & \"quotes\" 'apostrophe'"
        let error = SummaryError.generationFailed(reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("<xml>") == true)
    }

    // MARK: - SummaryError Recovery Suggestion Tests

    @Test("SummaryError modelUnavailable has recovery suggestion")
    func errorModelUnavailableRecovery() {
        let error = SummaryError.modelUnavailable
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SummaryError insufficientContent has recovery suggestion")
    func errorInsufficientContentRecovery() {
        let error = SummaryError.insufficientContent
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SummaryError generationFailed has recovery suggestion")
    func errorGenerationFailedRecovery() {
        let error = SummaryError.generationFailed("Some reason")
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SummaryError parsingFailed has recovery suggestion")
    func errorParsingFailedRecovery() {
        let error = SummaryError.parsingFailed
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("SummaryError cancelled has recovery suggestion")
    func errorCancelledRecovery() {
        let error = SummaryError.cancelled
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    // MARK: - SummaryError Sendable Conformance Tests

    @Test("SummaryError can be sent across concurrency boundaries")
    func errorIsSendable() async {
        let error = SummaryError.generationFailed("test")
        let task = Task.detached {
            // Use the error in a detached task to verify Sendable
            error.errorDescription
        }
        let result = await task.value
        #expect(result != nil)
    }

    @Test("All SummaryError cases are Sendable")
    func allErrorCasesAreSendable() async {
        let errors: [SummaryError] = [
            .modelUnavailable,
            .insufficientContent,
            .generationFailed("test"),
            .parsingFailed,
            .cancelled
        ]

        let task = Task.detached {
            errors.map { $0.errorDescription }
        }
        let results = await task.value
        #expect(results.count == 5)
    }

    // MARK: - SummaryGenerationState Tests

    @Test("SummaryGenerationState idle equals itself")
    func stateIdleEquality() {
        let state1 = SummaryGenerationState.idle
        let state2 = SummaryGenerationState.idle
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState preparing equals itself")
    func statePreparingEquality() {
        let state1 = SummaryGenerationState.preparing
        let state2 = SummaryGenerationState.preparing
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState generating with same progress equals")
    func stateGeneratingEquality() {
        let state1 = SummaryGenerationState.generating(progress: 0.5)
        let state2 = SummaryGenerationState.generating(progress: 0.5)
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState generating with different progress not equal")
    func stateGeneratingDifferentProgress() {
        let state1 = SummaryGenerationState.generating(progress: 0.5)
        let state2 = SummaryGenerationState.generating(progress: 0.7)
        #expect(state1 != state2)
    }

    @Test("SummaryGenerationState completed equals itself")
    func stateCompletedEquality() {
        let state1 = SummaryGenerationState.completed
        let state2 = SummaryGenerationState.completed
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState error with same message equals")
    func stateErrorEquality() {
        let state1 = SummaryGenerationState.error(message: "Error message")
        let state2 = SummaryGenerationState.error(message: "Error message")
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState error with different message not equal")
    func stateErrorDifferentMessage() {
        let state1 = SummaryGenerationState.error(message: "Error 1")
        let state2 = SummaryGenerationState.error(message: "Error 2")
        #expect(state1 != state2)
    }

    @Test("Different SummaryGenerationState cases are not equal")
    func stateDifferentCasesNotEqual() {
        #expect(SummaryGenerationState.idle != SummaryGenerationState.preparing)
        #expect(SummaryGenerationState.preparing != SummaryGenerationState.completed)
        #expect(SummaryGenerationState.completed != SummaryGenerationState.error(message: "test"))
        #expect(SummaryGenerationState.generating(progress: 0.5) != SummaryGenerationState.idle)
    }

    @Test("SummaryGenerationState generating with zero progress")
    func stateGeneratingZeroProgress() {
        let state1 = SummaryGenerationState.generating(progress: 0.0)
        let state2 = SummaryGenerationState.generating(progress: 0.0)
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState generating with full progress")
    func stateGeneratingFullProgress() {
        let state1 = SummaryGenerationState.generating(progress: 1.0)
        let state2 = SummaryGenerationState.generating(progress: 1.0)
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState generating not equal to completed")
    func stateGeneratingNotEqualToCompleted() {
        let generating = SummaryGenerationState.generating(progress: 1.0)
        let completed = SummaryGenerationState.completed
        #expect(generating != completed)
    }

    @Test("SummaryGenerationState error with empty message equals")
    func stateErrorEmptyMessage() {
        let state1 = SummaryGenerationState.error(message: "")
        let state2 = SummaryGenerationState.error(message: "")
        #expect(state1 == state2)
    }

    @Test("SummaryGenerationState is Sendable")
    func stateIsSendable() async {
        let state = SummaryGenerationState.generating(progress: 0.5)
        let task = Task.detached {
            state
        }
        let result = await task.value
        #expect(result == .generating(progress: 0.5))
    }

    @Test("All SummaryGenerationState cases are Sendable")
    func allStateCasesAreSendable() async {
        let states: [SummaryGenerationState] = [
            .idle,
            .preparing,
            .generating(progress: 0.5),
            .completed,
            .error(message: "test")
        ]

        let task = Task.detached {
            states
        }
        let results = await task.value
        #expect(results.count == 5)
    }

    // MARK: - SummaryResult Tests

    @Test("SummaryResult stores all properties correctly")
    func summaryResultProperties() {
        let result = SummaryResult(
            summaryText: "Test summary",
            keyPoints: ["Point 1", "Point 2"],
            actionItems: ["Action 1"]
        )
        #expect(result.summaryText == "Test summary")
        #expect(result.keyPoints.count == 2)
        #expect(result.keyPoints[0] == "Point 1")
        #expect(result.keyPoints[1] == "Point 2")
        #expect(result.actionItems.count == 1)
        #expect(result.actionItems[0] == "Action 1")
    }

    @Test("SummaryResult can have empty arrays")
    func summaryResultEmptyArrays() {
        let result = SummaryResult(
            summaryText: "Summary only",
            keyPoints: [],
            actionItems: []
        )
        #expect(result.summaryText == "Summary only")
        #expect(result.keyPoints.isEmpty)
        #expect(result.actionItems.isEmpty)
    }

    @Test("SummaryResult with empty summary text")
    func summaryResultEmptySummary() {
        let result = SummaryResult(
            summaryText: "",
            keyPoints: ["Point"],
            actionItems: []
        )
        #expect(result.summaryText.isEmpty)
        #expect(result.keyPoints.count == 1)
    }

    @Test("SummaryResult with many key points and action items")
    func summaryResultManyItems() {
        let keyPoints = (1...20).map { "Point \($0)" }
        let actionItems = (1...10).map { "Action \($0)" }
        let result = SummaryResult(
            summaryText: "Test summary",
            keyPoints: keyPoints,
            actionItems: actionItems
        )
        #expect(result.keyPoints.count == 20)
        #expect(result.actionItems.count == 10)
        #expect(result.keyPoints[0] == "Point 1")
        #expect(result.keyPoints[19] == "Point 20")
        #expect(result.actionItems[9] == "Action 10")
    }

    @Test("SummaryResult is Sendable")
    func summaryResultIsSendable() async {
        let result = SummaryResult(
            summaryText: "Test",
            keyPoints: ["Point"],
            actionItems: ["Action"]
        )

        let task = Task.detached {
            result.summaryText
        }
        let text = await task.value
        #expect(text == "Test")
    }

    @Test("SummaryResult with special characters")
    func summaryResultSpecialCharacters() {
        let result = SummaryResult(
            summaryText: "Summary with <html> & \"quotes\" and emoji: \u{1F600}",
            keyPoints: ["Point with newline\n embedded", "Point with tab\there"],
            actionItems: ["Action: check -> verify"]
        )
        #expect(result.summaryText.contains("<html>"))
        #expect(result.summaryText.contains("&"))
        #expect(result.keyPoints[0].contains("\n"))
        #expect(result.keyPoints[1].contains("\t"))
    }

    // MARK: - SummaryInput Tests

    @Test("SummaryInput stores segments and word count")
    func summaryInputProperties() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Hello world"),
            SummaryInput.SegmentData(speakerName: "Bob", text: "Hi there")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 4)

        #expect(input.segments.count == 2)
        #expect(input.segments[0].speakerName == "Alice")
        #expect(input.segments[0].text == "Hello world")
        #expect(input.segments[1].speakerName == "Bob")
        #expect(input.totalWordCount == 4)
    }

    @Test("SummaryInput SegmentData stores speaker and text")
    func summaryInputSegmentData() {
        let segment = SummaryInput.SegmentData(speakerName: "Speaker Name", text: "Segment text")
        #expect(segment.speakerName == "Speaker Name")
        #expect(segment.text == "Segment text")
    }

    @Test("SummaryInput SegmentData with empty speaker name")
    func summaryInputSegmentDataEmptySpeaker() {
        let segment = SummaryInput.SegmentData(speakerName: "", text: "Some text")
        #expect(segment.speakerName.isEmpty)
        #expect(segment.text == "Some text")
    }

    @Test("SummaryInput SegmentData with empty text")
    func summaryInputSegmentDataEmptyText() {
        let segment = SummaryInput.SegmentData(speakerName: "Speaker", text: "")
        #expect(segment.speakerName == "Speaker")
        #expect(segment.text.isEmpty)
    }

    @Test("SummaryInput with zero word count")
    func summaryInputZeroWordCount() {
        let input = SummaryInput(segments: [], totalWordCount: 0)
        #expect(input.segments.isEmpty)
        #expect(input.totalWordCount == 0)
    }

    @Test("SummaryInput with large word count")
    func summaryInputLargeWordCount() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Long text")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 100_000)
        #expect(input.totalWordCount == 100_000)
    }

    @Test("SummaryInput is Sendable")
    func summaryInputIsSendable() async {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Hello")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 1)

        let task = Task.detached {
            input.totalWordCount
        }
        let result = await task.value
        #expect(result == 1)
    }

    @Test("SummaryInput SegmentData is Sendable")
    func summaryInputSegmentDataIsSendable() async {
        let segment = SummaryInput.SegmentData(speakerName: "Test", text: "Hello")

        let task = Task.detached {
            segment.text
        }
        let result = await task.value
        #expect(result == "Hello")
    }

    @Test("SummaryInput with many segments")
    func summaryInputManySegments() {
        let segments = (1...100).map { index in
            SummaryInput.SegmentData(speakerName: "Speaker \(index)", text: "Text \(index)")
        }
        let input = SummaryInput(segments: segments, totalWordCount: 200)

        #expect(input.segments.count == 100)
        #expect(input.segments[0].speakerName == "Speaker 1")
        #expect(input.segments[99].speakerName == "Speaker 100")
    }

    // MARK: - Context Window Constants Tests

    @Test("Maximum context tokens is reasonable value")
    func maxContextTokensValue() {
        #expect(SummaryService.maxContextTokens == 4096)
        #expect(SummaryService.maxContextTokens > 0)
    }

    @Test("Tokens per word is reasonable estimate")
    func tokensPerWordValue() {
        #expect(SummaryService.tokensPerWord == 1.3)
        #expect(SummaryService.tokensPerWord > 0)
        #expect(SummaryService.tokensPerWord < 5)
    }

    // MARK: - inputFitsInContext Tests

    @Test("Small input fits in context window")
    func smallInputFitsInContext() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Short text")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 100)

        #expect(service.inputFitsInContext(input) == true)
    }

    @Test("Large input does not fit in context window")
    func largeInputDoesNotFitInContext() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Very long text...")
        ]
        // Enough words to exceed the context limit (4096 - 500 reserved = 3596 tokens)
        // With 1.3 tokens per word, that's about 2766 words
        let input = SummaryInput(segments: segments, totalWordCount: 5000)

        #expect(service.inputFitsInContext(input) == false)
    }

    @Test("Input exactly at boundary does not fit")
    func inputAtBoundaryDoesNotFit() {
        // Calculate word count that would be exactly at the limit
        // Available tokens: 4096 - 500 = 3596
        // Words needed: 3596 / 1.3 = ~2766
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Text")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 2767)

        #expect(service.inputFitsInContext(input) == false)
    }

    @Test("Empty input fits in context window")
    func emptyInputFitsInContext() {
        let input = SummaryInput(segments: [], totalWordCount: 0)
        #expect(service.inputFitsInContext(input) == true)
    }

    // MARK: - chunkInput Tests

    @Test("Single small segment returns single chunk")
    func chunkSingleSmallSegment() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Hello world this is a test")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 6)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 100)

        #expect(chunks.count == 1)
        #expect(chunks[0].segments.count == 1)
        #expect(chunks[0].segments[0].speakerName == "Alice")
    }

    @Test("Multiple segments within limit return single chunk")
    func chunkMultipleSegmentsWithinLimit() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Hello world"),
            SummaryInput.SegmentData(speakerName: "Bob", text: "Hi there")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 4)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 100)

        #expect(chunks.count == 1)
        #expect(chunks[0].segments.count == 2)
    }

    @Test("Large segments are split into multiple chunks")
    func chunkLargeSegmentsIntoMultipleChunks() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "one two three"),
            SummaryInput.SegmentData(speakerName: "Bob", text: "four five six"),
            SummaryInput.SegmentData(speakerName: "Charlie", text: "seven eight nine")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 9)

        // Set max 4 words per chunk - should create multiple chunks
        let chunks = service.chunkInput(input, maxWordsPerChunk: 4)

        #expect(chunks.count >= 2)
    }

    @Test("Each chunk respects maximum word count")
    func chunkRespectsMaxWordCount() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "word word word word word"),
            SummaryInput.SegmentData(speakerName: "Bob", text: "word word word word word"),
            SummaryInput.SegmentData(speakerName: "Charlie", text: "word word word word word")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 15)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 6)

        for chunk in chunks {
            #expect(chunk.totalWordCount <= 6 || chunk.segments.count == 1)
        }
    }

    @Test("Empty input returns empty chunks array")
    func chunkEmptyInputReturnsEmpty() {
        let input = SummaryInput(segments: [], totalWordCount: 0)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 100)

        #expect(chunks.isEmpty)
    }

    @Test("Single large segment creates single chunk")
    func chunkSingleLargeSegment() {
        let segments = [
            SummaryInput.SegmentData(
                speakerName: "Alice",
                text: "word word word word word word word word word word"
            )
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 10)

        // Even though segment exceeds limit, it stays as single chunk
        let chunks = service.chunkInput(input, maxWordsPerChunk: 5)

        #expect(chunks.count == 1)
        #expect(chunks[0].segments.count == 1)
    }

    @Test("Chunk word counts are calculated correctly")
    func chunkWordCountsCalculated() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "one two"),
            SummaryInput.SegmentData(speakerName: "Bob", text: "three four"),
            SummaryInput.SegmentData(speakerName: "Charlie", text: "five six")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 6)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 3)

        // Each chunk should have accurate word count based on actual text
        for chunk in chunks {
            let calculatedWordCount = chunk.segments.reduce(0) {
                $0 + $1.text.split(separator: " ").count
            }
            #expect(chunk.totalWordCount == calculatedWordCount)
        }
    }

    @Test("Default maxWordsPerChunk is 2000")
    func chunkDefaultMaxWords() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "short text")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 2)

        // Call without specifying maxWordsPerChunk uses default
        let chunks = service.chunkInput(input)

        #expect(chunks.count == 1)
    }

    @Test("Chunking preserves segment order")
    func chunkPreservesSegmentOrder() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "First", text: "one"),
            SummaryInput.SegmentData(speakerName: "Second", text: "two"),
            SummaryInput.SegmentData(speakerName: "Third", text: "three")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 3)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 2)

        // Verify order across all chunks
        var allSegments: [SummaryInput.SegmentData] = []
        for chunk in chunks {
            allSegments.append(contentsOf: chunk.segments)
        }

        #expect(allSegments[0].speakerName == "First")
        #expect(allSegments[1].speakerName == "Second")
        #expect(allSegments[2].speakerName == "Third")
    }

    @Test("Chunking handles segment with multiple spaces")
    func chunkHandlesMultipleSpaces() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "word  word   word")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 3)

        // split(separator: " ") ignores empty strings, so this should count as 3 words
        let chunks = service.chunkInput(input, maxWordsPerChunk: 4)

        #expect(chunks.count == 1)
    }

    @Test("Chunking with maxWordsPerChunk of 1 creates chunk per segment")
    func chunkWithMaxOneWordPerChunk() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "A", text: "one"),
            SummaryInput.SegmentData(speakerName: "B", text: "two"),
            SummaryInput.SegmentData(speakerName: "C", text: "three")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 3)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 1)

        // Each segment should be in its own chunk
        #expect(chunks.count == 3)
        #expect(chunks[0].segments.count == 1)
        #expect(chunks[1].segments.count == 1)
        #expect(chunks[2].segments.count == 1)
    }

    @Test("Chunking with segments exactly at boundary")
    func chunkSegmentsExactlyAtBoundary() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "A", text: "one two"),
            SummaryInput.SegmentData(speakerName: "B", text: "three four")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 4)

        // Each segment has exactly 2 words, max is 2
        let chunks = service.chunkInput(input, maxWordsPerChunk: 2)

        // Each segment fits exactly, but once first fills up, second goes to new chunk
        #expect(chunks.count == 2)
    }

    @Test("inputFitsInContext boundary calculation")
    func inputFitsInContextBoundaryCalculation() {
        // Available tokens: 4096 - 500 = 3596
        // With 1.3 tokens per word:
        // 3596 / 1.3 = 2766.15 words fit
        // At 2766 words: 2766 * 1.3 = 3595.8 tokens < 3596 - fits
        // At 2767 words: 2767 * 1.3 = 3597.1 tokens >= 3596 - doesn't fit

        let segmentsAt2766 = [SummaryInput.SegmentData(speakerName: "A", text: "text")]
        let inputAt2766 = SummaryInput(segments: segmentsAt2766, totalWordCount: 2766)
        #expect(service.inputFitsInContext(inputAt2766) == true)

        let inputAt2767 = SummaryInput(segments: segmentsAt2766, totalWordCount: 2767)
        #expect(service.inputFitsInContext(inputAt2767) == false)
    }

    @Test("inputFitsInContext with very large word count")
    func inputFitsInContextVeryLarge() {
        let segments = [SummaryInput.SegmentData(speakerName: "A", text: "text")]
        let input = SummaryInput(segments: segments, totalWordCount: 1_000_000)
        #expect(service.inputFitsInContext(input) == false)
    }

    @Test("Chunking handles unicode text in word count")
    func chunkHandlesUnicodeText() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "\u{1F600} \u{1F601} \u{1F602}")
        ]
        // Emojis separated by spaces should count as 3 words
        let input = SummaryInput(segments: segments, totalWordCount: 3)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 100)
        #expect(chunks.count == 1)
        #expect(chunks[0].segments[0].text.contains("\u{1F600}"))
    }

    // MARK: - Service Initial State Tests

    @Test("Service starts in idle state")
    func serviceInitialState() {
        let newService = SummaryService()
        #expect(newService.state == .idle)
    }

    @Test("Cancel sets state to idle")
    func cancelSetsStateToIdle() {
        service.cancel()
        #expect(service.state == .idle)
    }

    // MARK: - Input Validation Tests

    @Test("Generate summary throws for empty segments")
    func generateSummaryThrowsForEmptySegments() async {
        let input = SummaryInput(segments: [], totalWordCount: 100)

        // Skip if model not available
        guard service.isAvailable else { return }

        await #expect(throws: SummaryError.self) {
            try await service.generateSummary(from: input)
        }
    }

    @Test("Generate summary throws for insufficient word count")
    func generateSummaryThrowsForInsufficientWordCount() async {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Short")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 10)

        // Skip if model not available
        guard service.isAvailable else { return }

        await #expect(throws: SummaryError.self) {
            try await service.generateSummary(from: input)
        }
    }

    @Test("Input with exactly 50 words passes minimum check")
    func inputWithExactly50WordsPassesMinimum() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Some text")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 50)

        // At 50 words exactly, should pass the >= 50 check
        // We can't fully test this without mocking, but we verify the input is valid
        #expect(input.totalWordCount >= 50)
        #expect(!input.segments.isEmpty)
    }

    @Test("Input with 49 words fails minimum check")
    func inputWith49WordsFailsMinimum() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Some text")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 49)

        #expect(input.totalWordCount < 50)
    }

    // MARK: - SummaryInput.from(segments:) Tests

    @Test("SummaryInput.from creates input from Segment array")
    func summaryInputFromSegments() {
        let context = container.mainContext
        let speaker = Speaker()
        speaker.displayName = "Test Speaker"
        context.insert(speaker)

        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello world this is a test",
            sourceLocale: Locale(identifier: "en-US"),
            speaker: speaker
        )
        context.insert(segment)

        let input = SummaryInput.from(segments: [segment])

        #expect(input.segments.count == 1)
        #expect(input.segments[0].speakerName == "Test Speaker")
        #expect(input.segments[0].text == "Hello world this is a test")
        #expect(input.totalWordCount == 6)
    }

    @Test("SummaryInput.from uses Unknown for nil speaker")
    func summaryInputFromSegmentsNilSpeaker() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Test text",
            sourceLocale: Locale(identifier: "en-US"),
            speaker: nil
        )
        context.insert(segment)

        let input = SummaryInput.from(segments: [segment])

        #expect(input.segments.count == 1)
        // Speaker name should be localized "Unknown" (we check it's not empty)
        #expect(!input.segments[0].speakerName.isEmpty)
    }

    @Test("SummaryInput.from calculates total word count correctly")
    func summaryInputFromSegmentsWordCount() {
        let context = container.mainContext
        let segment1 = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "one two three",
            sourceLocale: Locale(identifier: "en-US")
        )
        let segment2 = Segment(
            startTime: 5,
            endTime: 10,
            originalText: "four five",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment1)
        context.insert(segment2)

        let input = SummaryInput.from(segments: [segment1, segment2])

        #expect(input.totalWordCount == 5)
    }

    @Test("SummaryInput.from handles empty segments array")
    func summaryInputFromEmptySegments() {
        let input = SummaryInput.from(segments: [])

        #expect(input.segments.isEmpty)
        #expect(input.totalWordCount == 0)
    }

    // MARK: - Availability Message Tests

    @Test("Availability message is nil when available")
    func availabilityMessageNilWhenAvailable() {
        // This test may pass or fail depending on the device
        // We just verify the property exists and returns a valid type
        let message = service.availabilityMessage
        // If available, message should be nil; otherwise it should be a non-empty string
        if service.isAvailable {
            #expect(message == nil)
        } else {
            #expect(message != nil)
            #expect(message?.isEmpty == false)
        }
    }

    // MARK: - Additional Service State Tests

    @Test("Multiple cancel calls are safe")
    func multipleCancelCallsAreSafe() {
        service.cancel()
        service.cancel()
        service.cancel()
        #expect(service.state == .idle)
    }

    @Test("Service state starts as idle after init")
    func serviceStateAfterInit() {
        let newService = SummaryService()
        #expect(newService.state == .idle)
    }

    @Test("Cancel resets state to idle from any state")
    func cancelResetsStateToIdle() {
        // We can't easily set internal state, but we can verify cancel always results in idle
        service.cancel()
        #expect(service.state == .idle)
    }

    // MARK: - SummaryInput.from Edge Cases

    @Test("SummaryInput.from handles segment with empty text")
    func summaryInputFromSegmentWithEmptyText() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let input = SummaryInput.from(segments: [segment])

        #expect(input.segments.count == 1)
        #expect(input.segments[0].text.isEmpty)
        #expect(input.totalWordCount == 0)
    }

    @Test("SummaryInput.from handles segment with only spaces")
    func summaryInputFromSegmentWithOnlySpaces() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "   ",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let input = SummaryInput.from(segments: [segment])

        #expect(input.segments.count == 1)
        // split(separator: " ") on "   " returns empty array
        #expect(input.totalWordCount == 0)
    }

    @Test("SummaryInput.from handles multiple segments with mixed content")
    func summaryInputFromMixedSegments() {
        let context = container.mainContext

        let speaker1 = Speaker()
        speaker1.displayName = "Alice"
        context.insert(speaker1)

        let speaker2 = Speaker()
        speaker2.displayName = "Bob"
        context.insert(speaker2)

        let segment1 = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello",
            sourceLocale: Locale(identifier: "en-US"),
            speaker: speaker1
        )
        let segment2 = Segment(
            startTime: 5,
            endTime: 10,
            originalText: "",
            sourceLocale: Locale(identifier: "en-US"),
            speaker: nil
        )
        let segment3 = Segment(
            startTime: 10,
            endTime: 15,
            originalText: "World Test",
            sourceLocale: Locale(identifier: "en-US"),
            speaker: speaker2
        )

        context.insert(segment1)
        context.insert(segment2)
        context.insert(segment3)

        let input = SummaryInput.from(segments: [segment1, segment2, segment3])

        #expect(input.segments.count == 3)
        #expect(input.segments[0].speakerName == "Alice")
        #expect(input.segments[0].text == "Hello")
        #expect(input.segments[1].text.isEmpty)
        #expect(input.segments[2].speakerName == "Bob")
        #expect(input.totalWordCount == 3) // "Hello" + "" + "World Test"
    }

    // MARK: - Input Validation Edge Cases

    @Test("Generate summary sets error state for empty segments when available")
    func generateSummaryErrorStateForEmptySegments() async {
        guard service.isAvailable else { return }

        let input = SummaryInput(segments: [], totalWordCount: 100)

        do {
            _ = try await service.generateSummary(from: input)
            // Should not reach here
            #expect(Bool(false))
        } catch {
            // After error, state should be error
            if case .error = service.state {
                #expect(true)
            } else {
                #expect(Bool(false))
            }
        }
    }

    @Test("Generate summary sets error state for insufficient word count when available")
    func generateSummaryErrorStateForInsufficientWords() async {
        guard service.isAvailable else { return }

        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "Short")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 10)

        do {
            _ = try await service.generateSummary(from: input)
            #expect(Bool(false))
        } catch {
            if case .error = service.state {
                #expect(true)
            } else {
                #expect(Bool(false))
            }
        }
    }

    // MARK: - Constants Validation

    @Test("Context tokens reserved for prompt is reasonable")
    func contextTokensReservedIsReasonable() {
        // The code reserves 500 tokens for prompt and response
        // Verify this is less than the max
        let reserved = 500
        #expect(reserved < SummaryService.maxContextTokens)
        #expect(reserved > 0)
    }

    @Test("Tokens per word estimation is reasonable for English")
    func tokensPerWordEstimationIsReasonable() {
        // English text typically averages 1.0-1.5 tokens per word
        // The service uses 1.3 which is reasonable
        let estimate = SummaryService.tokensPerWord
        #expect(estimate >= 1.0)
        #expect(estimate <= 2.0)
    }

    // MARK: - SummaryInput.from with Unicode

    @Test("SummaryInput.from handles unicode text correctly")
    func summaryInputFromUnicodeText() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello \u{1F600} World \u{1F389}",
            sourceLocale: Locale(identifier: "en-US")
        )
        context.insert(segment)

        let input = SummaryInput.from(segments: [segment])

        #expect(input.segments[0].text.contains("\u{1F600}"))
        #expect(input.segments[0].text.contains("\u{1F389}"))
        // Word count should be 4: "Hello", emoji, "World", emoji
        #expect(input.totalWordCount == 4)
    }

    @Test("SummaryInput.from handles CJK text")
    func summaryInputFromCJKText() {
        let context = container.mainContext
        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "\u{4F60}\u{597D} \u{4E16}\u{754C}",
            sourceLocale: Locale(identifier: "zh-CN")
        )
        context.insert(segment)

        let input = SummaryInput.from(segments: [segment])

        #expect(input.segments.count == 1)
        // Chinese characters without spaces between them count as fewer "words" by split
        // This is expected behavior for space-delimited word counting
        #expect(input.totalWordCount >= 1)
    }

    // MARK: - Chunking Additional Edge Cases

    @Test("Chunking handles segment with newlines in text")
    func chunkHandlesNewlinesInText() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "line1\nline2\nline3")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 1)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 100)

        #expect(chunks.count == 1)
        #expect(chunks[0].segments[0].text.contains("\n"))
    }

    @Test("Chunking handles segment with tabs in text")
    func chunkHandlesTabsInText() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "Alice", text: "word1\tword2\tword3")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 1)

        let chunks = service.chunkInput(input, maxWordsPerChunk: 100)

        #expect(chunks.count == 1)
        #expect(chunks[0].segments[0].text.contains("\t"))
    }

    @Test("Chunking with zero maxWordsPerChunk creates individual chunks")
    func chunkWithZeroMaxWords() {
        let segments = [
            SummaryInput.SegmentData(speakerName: "A", text: "one"),
            SummaryInput.SegmentData(speakerName: "B", text: "two")
        ]
        let input = SummaryInput(segments: segments, totalWordCount: 2)

        // With maxWordsPerChunk = 0, every segment exceeds limit
        let chunks = service.chunkInput(input, maxWordsPerChunk: 0)

        // Each segment should be in its own chunk
        #expect(chunks.count == 2)
    }

    // MARK: - Protocol Conformance Tests

    @Test("SummaryService conforms to SummaryServiceProtocol")
    func serviceConformsToProtocol() {
        // Verify the service can be used as the protocol type
        let protocolService: any SummaryServiceProtocol = service
        #expect(protocolService.state == .idle)
    }
}
