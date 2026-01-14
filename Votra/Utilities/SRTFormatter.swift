//
//  SRTFormatter.swift
//  Votra
//
//  SRT subtitle file formatter with timestamp accuracy ±0.5s (SC-005).
//

import Foundation

/// Entry in an SRT file representing a single subtitle
nonisolated struct SRTEntry: Identifiable, Sendable, Equatable {
    let id: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String

    var duration: TimeInterval {
        endTime - startTime
    }

    /// Format as SRT entry string
    func formatted() -> String {
        """
        \(id)
        \(SRTFormatter.formatTimestamp(startTime)) --> \(SRTFormatter.formatTimestamp(endTime))
        \(text)
        """
    }
}

/// Content options for subtitle export (FR-033)
nonisolated enum SubtitleContentOption: String, Sendable, CaseIterable {
    case originalOnly = "original"
    case translationOnly = "translation"
    case both = "both"

    var localizedName: String {
        switch self {
        case .originalOnly:
            return String(localized: "Transcription")
        case .translationOnly:
            return String(localized: "Translation")
        case .both:
            return String(localized: "Bilingual")
        }
    }
}

/// Order of text in bilingual subtitles
nonisolated enum BilingualTextOrder: String, Sendable, CaseIterable {
    case translationFirst
    case originalFirst

    var localizedName: String {
        switch self {
        case .translationFirst:
            return String(localized: "Translation First")
        case .originalFirst:
            return String(localized: "Original First")
        }
    }
}

/// Formatter for SRT (SubRip) subtitle files
nonisolated enum SRTFormatter {
    // MARK: - Timestamp Formatting

    /// Format a time interval as SRT timestamp (hh:mm:ss,mmm)
    /// - Parameter time: Time interval in seconds
    /// - Returns: Formatted timestamp string
    static func formatTimestamp(_ time: TimeInterval) -> String {
        // Ensure non-negative
        let clampedTime = max(0, time)

        let hours = Int(clampedTime / 3600)
        let minutes = Int((clampedTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(clampedTime.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((clampedTime.truncatingRemainder(dividingBy: 1)) * 1000)

        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }

    /// Parse SRT timestamp to time interval
    /// - Parameter timestamp: SRT timestamp string (hh:mm:ss,mmm)
    /// - Returns: Time interval in seconds, or nil if invalid
    static func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        // Format: hh:mm:ss,mmm
        let pattern = #"(\d{2}):(\d{2}):(\d{2}),(\d{3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: timestamp,
                range: NSRange(timestamp.startIndex..., in: timestamp)
              ) else {
            return nil
        }

        // Extract matched groups - regex guarantees valid digit strings
        func extractInt(_ rangeIndex: Int) -> Int? {
            guard let range = Range(match.range(at: rangeIndex), in: timestamp) else {
                return nil
            }
            return Int(timestamp[range])
        }

        guard let hours = extractInt(1),
              let minutes = extractInt(2),
              let seconds = extractInt(3),
              let milliseconds = extractInt(4) else {
            return nil
        }

        return TimeInterval(hours * 3600 + minutes * 60 + seconds) + TimeInterval(milliseconds) / 1000.0
    }

    // MARK: - SRT Generation

    /// Generate SRT content from segments
    /// - Parameters:
    ///   - segments: Array of speech segments
    ///   - contentOption: What content to include in subtitles
    ///   - bilingualOrder: Order of text in bilingual mode
    /// - Returns: Complete SRT file content as string
    static func generate(
        from segments: [Segment],
        contentOption: SubtitleContentOption = .both,
        bilingualOrder: BilingualTextOrder = .translationFirst
    ) -> String {
        var entries: [SRTEntry] = []
        var entryId = 1

        for segment in segments {
            guard segment.startTime >= 0 else { continue }

            // Calculate end time (use segment duration or estimate from text)
            let endTime: TimeInterval
            if segment.endTime > segment.startTime {
                endTime = segment.endTime
            } else {
                endTime = estimateEndTime(from: segment.startTime, text: segment.originalText, locale: segment.sourceLocale)
            }

            // Skip very short segments (< 0.1s)
            guard endTime - segment.startTime >= 0.1 else { continue }

            let text: String
            switch contentOption {
            case .originalOnly:
                text = splitIntoLines(segment.originalText)
            case .translationOnly:
                text = splitIntoLines(segment.translatedText ?? segment.originalText)
            case .both:
                if let translated = segment.translatedText, !translated.isEmpty {
                    switch bilingualOrder {
                    case .translationFirst:
                        text = formatBilingualText(line1: translated, line2: segment.originalText)
                    case .originalFirst:
                        text = formatBilingualText(line1: segment.originalText, line2: translated)
                    }
                } else {
                    text = splitIntoLines(segment.originalText)
                }
            }

            // Skip empty text
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            let entry = SRTEntry(
                id: entryId,
                startTime: segment.startTime,
                endTime: endTime,
                text: text
            )
            entries.append(entry)
            entryId += 1
        }

        // Handle overlapping segments - adjust end times
        entries = resolveOverlaps(in: entries)

        return entries.map { $0.formatted() }.joined(separator: "\n\n")
    }

    /// Generate SRT from conversation messages
    /// - Parameters:
    ///   - messages: Array of conversation messages
    ///   - contentOption: What content to include in subtitles
    ///   - sessionStartTime: Start time of the session for calculating offsets
    ///   - bilingualOrder: Order of text in bilingual mode
    /// - Returns: Complete SRT file content as string
    static func generate(
        from messages: [ConversationMessage],
        contentOption: SubtitleContentOption = .both,
        sessionStartTime: Date,
        bilingualOrder: BilingualTextOrder = .translationFirst
    ) -> String {
        var entries: [SRTEntry] = []
        var entryId = 1

        for (index, message) in messages.enumerated() {
            let startTime = message.timestamp.timeIntervalSince(sessionStartTime)

            // Estimate end time from next message or add default duration
            let endTime: TimeInterval
            if index + 1 < messages.count {
                let nextStart = messages[index + 1].timestamp.timeIntervalSince(sessionStartTime)
                // End time is minimum of next start time minus small gap, or estimated from text
                endTime = min(
                    nextStart - 0.1,
                    estimateEndTime(from: startTime, text: message.originalText, locale: message.sourceLocale)
                )
            } else {
                endTime = estimateEndTime(from: startTime, text: message.originalText, locale: message.sourceLocale)
            }

            let text: String
            switch contentOption {
            case .originalOnly:
                text = splitIntoLines(message.originalText)
            case .translationOnly:
                text = splitIntoLines(message.translatedText)
            case .both:
                switch bilingualOrder {
                case .translationFirst:
                    text = formatBilingualText(line1: message.translatedText, line2: message.originalText)
                case .originalFirst:
                    text = formatBilingualText(line1: message.originalText, line2: message.translatedText)
                }
            }

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            let entry = SRTEntry(
                id: entryId,
                startTime: startTime,
                endTime: max(endTime, startTime + 0.5), // Minimum 0.5s duration
                text: text
            )
            entries.append(entry)
            entryId += 1
        }

        entries = resolveOverlaps(in: entries)

        return entries.map { $0.formatted() }.joined(separator: "\n\n")
    }

    // MARK: - Private Helpers

    /// Return text as-is without line wrapping
    /// Video players handle their own subtitle line wrapping based on screen size
    /// Adding manual line breaks in SRT files can cause display issues
    static func splitIntoLines(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Split bilingual text (two lines) into properly formatted subtitle
    /// - Parameters:
    ///   - line1: First line (e.g., translation)
    ///   - line2: Second line (e.g., original)
    /// - Returns: Formatted bilingual subtitle with appropriate line breaks
    static func formatBilingualText(line1: String, line2: String) -> String {
        let formatted1 = splitIntoLines(line1)
        let formatted2 = splitIntoLines(line2)
        return "\(formatted1)\n\(formatted2)"
    }

    /// Estimate end time based on text and locale using Netflix subtitle standards
    private static func estimateEndTime(from startTime: TimeInterval, text: String, locale: Locale) -> TimeInterval {
        let duration = SubtitleStandards.estimatedDuration(for: text, locale: locale)
        return startTime + duration
    }

    /// Resolve overlapping entries by adjusting end times
    private static func resolveOverlaps(in entries: [SRTEntry]) -> [SRTEntry] {
        guard entries.count > 1 else { return entries }

        var resolved: [SRTEntry] = []
        var previousEntry: SRTEntry?

        for entry in entries {
            if let previous = previousEntry {
                if previous.endTime > entry.startTime {
                    // Overlap detected - adjust previous entry's end time
                    let adjustedPrevious = SRTEntry(
                        id: previous.id,
                        startTime: previous.startTime,
                        endTime: entry.startTime - 0.001, // Gap of 1ms
                        text: previous.text
                    )
                    resolved.append(adjustedPrevious)
                } else {
                    resolved.append(previous)
                }
            }
            previousEntry = entry
        }

        // Don't forget the last entry
        if let last = previousEntry {
            resolved.append(last)
        }

        return resolved
    }
}

// MARK: - SRT Parser

extension SRTFormatter {
    /// Parse SRT file content into entries
    /// - Parameter content: SRT file content as string
    /// - Returns: Array of parsed SRT entries
    static func parse(_ content: String) -> [SRTEntry] {
        var entries: [SRTEntry] = []

        // Split by double newlines to get individual entries
        let blocks = content.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            guard lines.count >= 3 else { continue }

            // First line is ID
            guard let id = Int(lines[0]) else { continue }

            // Second line is timestamp range
            let timestampLine = lines[1]
            let timestampParts = timestampLine.components(separatedBy: " --> ")
            guard timestampParts.count == 2,
                  let startTime = parseTimestamp(timestampParts[0]),
                  let endTime = parseTimestamp(timestampParts[1]) else {
                continue
            }

            // Remaining lines are text
            let text = lines.dropFirst(2).joined(separator: "\n")

            let entry = SRTEntry(
                id: id,
                startTime: startTime,
                endTime: endTime,
                text: text
            )
            entries.append(entry)
        }

        return entries
    }
}
