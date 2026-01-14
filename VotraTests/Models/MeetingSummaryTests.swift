//
//  MeetingSummaryTests.swift
//  VotraTests
//
//  Unit tests for the MeetingSummary model.
//

import Testing
import Foundation
import SwiftData
@testable import Votra

@MainActor
struct MeetingSummaryTests {
    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    // MARK: - Initialization Tests

    @Test
    func testDefaultInitialization() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        #expect(summary.id != UUID())
        #expect(summary.summaryText.isEmpty)
        #expect(summary.keyPointsJSON == "[]")
        #expect(summary.actionItemsJSON == "[]")
        #expect(summary.generatedAt <= Date())
        #expect(summary.session == nil)
    }

    @Test
    func testInitializationWithCustomValues() {
        let context = container.mainContext
        let customID = UUID()
        let customDate = Date(timeIntervalSince1970: 1000000)
        let summaryText = "This was a productive meeting about the project roadmap."
        let keyPoints = ["Discussed Q1 goals", "Reviewed budget", "Assigned tasks"]
        let actionItems = ["Send follow-up email", "Create project timeline"]

        let summary = MeetingSummary(
            id: customID,
            summaryText: summaryText,
            keyPoints: keyPoints,
            actionItems: actionItems,
            generatedAt: customDate
        )
        context.insert(summary)

        #expect(summary.id == customID)
        #expect(summary.summaryText == summaryText)
        #expect(summary.generatedAt == customDate)
        #expect(summary.keyPoints == keyPoints)
        #expect(summary.actionItems == actionItems)
    }

    // MARK: - Stored Property Tests

    @Test
    func testSummaryTextProperty() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.summaryText = "Updated summary text."
        #expect(summary.summaryText == "Updated summary text.")
    }

    @Test
    func testGeneratedAtProperty() {
        let context = container.mainContext
        let customDate = Date(timeIntervalSince1970: 500000)
        let summary = MeetingSummary(generatedAt: customDate)
        context.insert(summary)

        #expect(summary.generatedAt == customDate)
    }

    // MARK: - Key Points Computed Property Tests

    @Test
    func testKeyPointsGetterWithEmptyJSON() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        #expect(summary.keyPoints.isEmpty)
    }

    @Test
    func testKeyPointsGetterWithValidJSON() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.keyPointsJSON = "[\"Point 1\",\"Point 2\",\"Point 3\"]"
        #expect(summary.keyPoints == ["Point 1", "Point 2", "Point 3"])
    }

    @Test
    func testKeyPointsGetterWithInvalidJSON() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.keyPointsJSON = "invalid json"
        #expect(summary.keyPoints.isEmpty)
    }

    @Test
    func testKeyPointsSetter() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.keyPoints = ["New point 1", "New point 2"]

        #expect(summary.keyPoints == ["New point 1", "New point 2"])
        #expect(summary.keyPointsJSON.contains("New point 1"))
        #expect(summary.keyPointsJSON.contains("New point 2"))
    }

    @Test
    func testKeyPointsSetterWithEmptyArray() {
        let context = container.mainContext
        let summary = MeetingSummary(keyPoints: ["Existing point"])
        context.insert(summary)

        summary.keyPoints = []
        #expect(summary.keyPoints.isEmpty)
        #expect(summary.keyPointsJSON == "[]")
    }

    @Test
    func testKeyPointsWithSpecialCharacters() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        let pointsWithSpecialChars = [
            "Point with \"quotes\"",
            "Point with emoji: test",
            "Point with newline\ncharacter"
        ]
        summary.keyPoints = pointsWithSpecialChars

        #expect(summary.keyPoints == pointsWithSpecialChars)
    }

    // MARK: - Action Items Computed Property Tests

    @Test
    func testActionItemsGetterWithEmptyJSON() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        #expect(summary.actionItems.isEmpty)
    }

    @Test
    func testActionItemsGetterWithValidJSON() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.actionItemsJSON = "[\"Task 1\",\"Task 2\"]"
        #expect(summary.actionItems == ["Task 1", "Task 2"])
    }

    @Test
    func testActionItemsGetterWithInvalidJSON() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.actionItemsJSON = "not valid json"
        #expect(summary.actionItems.isEmpty)
    }

    @Test
    func testActionItemsSetter() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        summary.actionItems = ["Complete report", "Schedule meeting"]

        #expect(summary.actionItems == ["Complete report", "Schedule meeting"])
        #expect(summary.actionItemsJSON.contains("Complete report"))
        #expect(summary.actionItemsJSON.contains("Schedule meeting"))
    }

    @Test
    func testActionItemsSetterWithEmptyArray() {
        let context = container.mainContext
        let summary = MeetingSummary(actionItems: ["Existing task"])
        context.insert(summary)

        summary.actionItems = []
        #expect(summary.actionItems.isEmpty)
        #expect(summary.actionItemsJSON == "[]")
    }

    // MARK: - Markdown Output Tests

    @Test
    func testMarkdownOutputBasic() {
        let context = container.mainContext
        let summary = MeetingSummary(summaryText: "Basic summary text.")
        context.insert(summary)

        let markdown = summary.markdownOutput

        #expect(markdown.contains("# Meeting Summary"))
        #expect(markdown.contains("## Summary"))
        #expect(markdown.contains("Basic summary text."))
        #expect(markdown.contains("Generated:"))
    }

    @Test
    func testMarkdownOutputWithKeyPoints() {
        let context = container.mainContext
        let summary = MeetingSummary(
            summaryText: "Summary with key points.",
            keyPoints: ["Point A", "Point B"]
        )
        context.insert(summary)

        let markdown = summary.markdownOutput

        #expect(markdown.contains("## Key Points"))
        #expect(markdown.contains("- Point A"))
        #expect(markdown.contains("- Point B"))
    }

    @Test
    func testMarkdownOutputWithActionItems() {
        let context = container.mainContext
        let summary = MeetingSummary(
            summaryText: "Summary with action items.",
            actionItems: ["Task X", "Task Y"]
        )
        context.insert(summary)

        let markdown = summary.markdownOutput

        #expect(markdown.contains("## Action Items"))
        #expect(markdown.contains("- [ ] Task X"))
        #expect(markdown.contains("- [ ] Task Y"))
    }

    @Test
    func testMarkdownOutputWithAllSections() {
        let context = container.mainContext
        let summary = MeetingSummary(
            summaryText: "Complete meeting summary.",
            keyPoints: ["Key point 1", "Key point 2"],
            actionItems: ["Action 1", "Action 2"]
        )
        context.insert(summary)

        let markdown = summary.markdownOutput

        #expect(markdown.contains("# Meeting Summary"))
        #expect(markdown.contains("## Summary"))
        #expect(markdown.contains("Complete meeting summary."))
        #expect(markdown.contains("## Key Points"))
        #expect(markdown.contains("- Key point 1"))
        #expect(markdown.contains("- Key point 2"))
        #expect(markdown.contains("## Action Items"))
        #expect(markdown.contains("- [ ] Action 1"))
        #expect(markdown.contains("- [ ] Action 2"))
    }

    @Test
    func testMarkdownOutputWithoutKeyPoints() {
        let context = container.mainContext
        let summary = MeetingSummary(
            summaryText: "Summary without key points.",
            keyPoints: [],
            actionItems: ["Only action"]
        )
        context.insert(summary)

        let markdown = summary.markdownOutput

        #expect(!markdown.contains("## Key Points"))
        #expect(markdown.contains("## Action Items"))
    }

    @Test
    func testMarkdownOutputWithoutActionItems() {
        let context = container.mainContext
        let summary = MeetingSummary(
            summaryText: "Summary without action items.",
            keyPoints: ["Only key point"],
            actionItems: []
        )
        context.insert(summary)

        let markdown = summary.markdownOutput

        #expect(markdown.contains("## Key Points"))
        #expect(!markdown.contains("## Action Items"))
    }

    // MARK: - Session Relationship Tests

    @Test
    func testSessionRelationship() {
        let context = container.mainContext
        let session = Session()
        let summary = MeetingSummary(summaryText: "Meeting summary")

        context.insert(session)
        context.insert(summary)

        summary.session = session

        #expect(summary.session === session)
    }

    @Test
    func testSessionRelationshipIsOptional() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        #expect(summary.session == nil)
    }

    // MARK: - JSON Encoding/Decoding Round Trip Tests

    @Test
    func testKeyPointsRoundTrip() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        let originalPoints = ["First point", "Second point", "Third point"]
        summary.keyPoints = originalPoints

        let retrievedPoints = summary.keyPoints
        #expect(retrievedPoints == originalPoints)
    }

    @Test
    func testActionItemsRoundTrip() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        let originalItems = ["Do this", "Then that", "Finally this"]
        summary.actionItems = originalItems

        let retrievedItems = summary.actionItems
        #expect(retrievedItems == originalItems)
    }

    @Test
    func testLargeNumberOfKeyPoints() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        let manyPoints = (1...100).map { "Point \($0)" }
        summary.keyPoints = manyPoints

        #expect(summary.keyPoints.count == 100)
        #expect(summary.keyPoints.first == "Point 1")
        #expect(summary.keyPoints.last == "Point 100")
    }

    @Test
    func testLargeNumberOfActionItems() {
        let context = container.mainContext
        let summary = MeetingSummary()
        context.insert(summary)

        let manyItems = (1...100).map { "Action \($0)" }
        summary.actionItems = manyItems

        #expect(summary.actionItems.count == 100)
        #expect(summary.actionItems.first == "Action 1")
        #expect(summary.actionItems.last == "Action 100")
    }
}
