//
//  SummaryView.swift
//  Votra
//
//  View for displaying AI-generated meeting summaries.
//

import AppKit
import SwiftUI

/// Display data for a summary (UI-friendly struct)
struct SummaryDisplayData {
    let summaryText: String
    let keyPoints: [String]
    let actionItems: [String]
    let generatedAt: Date

    var markdownOutput: String {
        var output = "# Meeting Summary\n\n"
        output += "Generated: \(generatedAt.formatted())\n\n"
        output += "## Summary\n\n\(summaryText)\n\n"

        if !keyPoints.isEmpty {
            output += "## Key Points\n\n"
            for point in keyPoints {
                output += "- \(point)\n"
            }
            output += "\n"
        }

        if !actionItems.isEmpty {
            output += "## Action Items\n\n"
            for item in actionItems {
                output += "- [ ] \(item)\n"
            }
        }

        return output
    }

    /// Create from SummaryResult
    init(from result: SummaryResult, generatedAt: Date = Date()) {
        self.summaryText = result.summaryText
        self.keyPoints = result.keyPoints
        self.actionItems = result.actionItems
        self.generatedAt = generatedAt
    }

    /// Create from MeetingSummary model
    @MainActor
    init(from model: MeetingSummary) {
        self.summaryText = model.summaryText
        self.keyPoints = model.keyPoints
        self.actionItems = model.actionItems
        self.generatedAt = model.generatedAt
    }

    /// Direct initializer
    init(summaryText: String, keyPoints: [String], actionItems: [String], generatedAt: Date = Date()) {
        self.summaryText = summaryText
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.generatedAt = generatedAt
    }
}

/// View displaying a meeting summary with markdown output
struct SummaryView: View {
    let summary: SummaryDisplayData
    let onExport: () -> Void
    let onClose: () -> Void

    @State private var isCopied = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding()

            Divider()

            // Content
            ScrollView {
                summaryContent
                    .padding()
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer with actions
            footerSection
                .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Meeting Summary"))
                    .font(.title2)
                    .bold()

                Text(String(localized: "Generated \(summary.generatedAt, format: .relative(presentation: .named))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Summary Content

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Summary section
            summarySection

            // Key points section
            if !summary.keyPoints.isEmpty {
                keyPointsSection
            }

            // Action items section
            if !summary.actionItems.isEmpty {
                actionItemsSection
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Summary"), systemImage: "doc.text")
                .font(.headline)

            Text(summary.summaryText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))
        }
    }

    private var keyPointsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Key Points"), systemImage: "list.bullet")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.tint)
                            .padding(.top, 6)
                        Text(point)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
        }
    }

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Action Items"), systemImage: "checkmark.square")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.actionItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "square")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(item)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            // Copy to clipboard
            Button {
                copyToClipboard()
            } label: {
                Label(
                    isCopied ? String(localized: "Copied!") : String(localized: "Copy"),
                    systemImage: isCopied ? "checkmark" : "doc.on.doc"
                )
            }
            .buttonStyle(.bordered)

            Spacer()

            // Export button
            Button {
                onExport()
            } label: {
                Label(String(localized: "Export Markdown"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(summary.markdownOutput, forType: .string)

        isCopied = true

        // Reset after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }
}

// MARK: - Summary Generation View

/// View shown during summary generation
struct SummaryGenerationView: View {
    let state: SummaryGenerationState
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Status icon
            statusIcon
                .font(.system(size: 48))

            // Status text
            statusText

            // Progress (if generating)
            if case .generating(let progress) = state {
                ProgressView(value: progress)
                    .frame(width: 200)
            }

            // Cancel button
            if case .generating = state {
                Button(String(localized: "Cancel")) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .frame(minWidth: 300, minHeight: 200)
        .padding()
    }

    @ViewBuilder private var statusIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
        case .preparing:
            ProgressView()
                .controlSize(.large)
        case .generating:
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, options: .repeating)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder private var statusText: some View {
        switch state {
        case .idle:
            Text(String(localized: "Ready to generate summary"))
                .foregroundStyle(.secondary)
        case .preparing:
            Text(String(localized: "Preparing transcript..."))
        case .generating(let progress):
            Text(String(localized: "Generating summary... \(Int(progress * 100))%"))
        case .completed:
            Text(String(localized: "Summary complete!"))
                .foregroundStyle(.green)
        case .error(let message):
            VStack(spacing: 4) {
                Text(String(localized: "Generation failed"))
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Apple Intelligence Unavailable View

/// View shown when Apple Intelligence is not available
struct AppleIntelligenceUnavailableView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(String(localized: "Apple Intelligence Required"))
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(String(localized: "Open System Settings")) {
                openAppleIntelligenceSettings()
            }
            .buttonStyle(.bordered)
        }
        .frame(minWidth: 300, minHeight: 200)
        .padding()
    }

    private func openAppleIntelligenceSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.siri") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Summary View") {
    SummaryView(
        summary: SummaryDisplayData(
            summaryText: "The meeting discussed the Q4 roadmap and marketing strategy. Key decisions were made about feature prioritization and resource allocation.",
            keyPoints: [
                "Q4 focus on mobile platform improvements",
                "Marketing campaign to launch in November",
                "Budget approved for additional engineering resources"
            ],
            actionItems: [
                "Schedule follow-up meeting for next Tuesday",
                "Share roadmap document with stakeholders",
                "Review marketing materials by Friday"
            ]
        ),
        onExport: {},
        onClose: {}
    )
    .frame(width: 600, height: 500)
}

#Preview("Generating") {
    SummaryGenerationView(state: .generating(progress: 0.5)) {}
}

#Preview("Apple Intelligence Unavailable") {
    AppleIntelligenceUnavailableView(
        message: "Enable Apple Intelligence in System Settings > Apple Intelligence & Siri"
    )
}
