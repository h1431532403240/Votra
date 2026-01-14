//
//  MeetingSummary.swift
//  Votra
//
//  Meeting summary model for AI-generated conversation summaries.
//

import Foundation
import SwiftData

@Model
final class MeetingSummary {
    // No @Attribute(.unique) - CloudKit incompatible
    var id = UUID()

    var summaryText: String = ""

    /// Stored as JSON array
    var keyPointsJSON: String = "[]"

    /// Stored as JSON array
    var actionItemsJSON: String = "[]"

    var generatedAt = Date()

    // Optional relationship for CloudKit
    @Relationship var session: Session?

    // MARK: - Computed Properties

    var keyPoints: [String] {
        get {
            guard let data = keyPointsJSON.data(using: .utf8),
                  let points = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return points
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                keyPointsJSON = json
            }
        }
    }

    var actionItems: [String] {
        get {
            guard let data = actionItemsJSON.data(using: .utf8),
                  let items = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                actionItemsJSON = json
            }
        }
    }

    var markdownOutput: String {
        var output = "# Meeting Summary\n\n"
        output += "Generated: \(generatedAt.formatted())\n\n"
        output += "## Summary\n\n\(summaryText)\n\n"

        let points = keyPoints
        if !points.isEmpty {
            output += "## Key Points\n\n"
            for point in points {
                output += "- \(point)\n"
            }
            output += "\n"
        }

        let items = actionItems
        if !items.isEmpty {
            output += "## Action Items\n\n"
            for item in items {
                output += "- [ ] \(item)\n"
            }
        }

        return output
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        summaryText: String = "",
        keyPoints: [String] = [],
        actionItems: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.summaryText = summaryText
        self.generatedAt = generatedAt

        // Encode arrays as JSON
        self.keyPointsJSON = "[]"
        self.actionItemsJSON = "[]"
        self.keyPoints = keyPoints
        self.actionItems = actionItems
    }
}
