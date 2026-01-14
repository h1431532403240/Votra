//
//  SubtitleExportService.swift
//  Votra
//
//  Service for exporting subtitles in various formats.
//

import Foundation

// MARK: - Subtitle Format

/// Supported subtitle export formats
nonisolated enum SubtitleFormat: String, Sendable, CaseIterable {
    case srt
    case vtt
    case txt

    var fileExtension: String { rawValue }

    var displayName: String {
        switch self {
        case .srt:
            return "SubRip (SRT)"
        case .vtt:
            return "WebVTT"
        case .txt:
            return "Plain Text"
        }
    }

    var mimeType: String {
        switch self {
        case .srt:
            return "application/x-subrip"
        case .vtt:
            return "text/vtt"
        case .txt:
            return "text/plain"
        }
    }
}

// MARK: - Subtitle Export Error

/// Errors that can occur during subtitle export
enum SubtitleExportError: LocalizedError {
    case noSegments
    case noMessages
    case writeError(underlying: Error)
    case invalidFormat(format: SubtitleFormat)
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .noSegments:
            return String(localized: "No segments available for export")
        case .noMessages:
            return String(localized: "No messages available for export")
        case .writeError(let error):
            return String(localized: "Failed to write subtitle file: \(error.localizedDescription)")
        case .invalidFormat(let format):
            return String(localized: "Unsupported subtitle format: \(format.rawValue)")
        case .emptyContent:
            return String(localized: "No content to export")
        }
    }
}

// MARK: - Subtitle Export Options

/// Options for subtitle export
struct SubtitleExportOptions: Sendable {
    // MARK: - Type Properties

    static let `default` = SubtitleExportOptions(
        format: .srt,
        contentOption: .both,
        includeTimestamps: true,
        bilingualOrder: .translationFirst
    )

    // MARK: - Instance Properties

    var format: SubtitleFormat
    var contentOption: SubtitleContentOption
    var includeTimestamps: Bool
    var bilingualOrder: BilingualTextOrder
}

// MARK: - Subtitle Export Service Protocol

/// Protocol for subtitle export operations
@MainActor
protocol SubtitleExportServiceProtocol: AnyObject {
    /// Export segments as subtitle file
    /// - Parameters:
    ///   - segments: Speech segments to export
    ///   - options: Export options
    /// - Returns: URL to the exported file
    func export(
        segments: [Segment],
        options: SubtitleExportOptions
    ) async throws -> URL

    /// Export conversation messages as subtitle file
    /// - Parameters:
    ///   - messages: Conversation messages to export
    ///   - sessionStartTime: Start time of the session
    ///   - options: Export options
    /// - Returns: URL to the exported file
    func export(
        messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) async throws -> URL

    /// Generate subtitle content without writing to file
    /// - Parameters:
    ///   - segments: Speech segments
    ///   - options: Export options
    /// - Returns: Subtitle content as string
    func generateContent(
        from segments: [Segment],
        options: SubtitleExportOptions
    ) -> String

    /// Generate subtitle content from messages without writing to file
    /// - Parameters:
    ///   - messages: Conversation messages
    ///   - sessionStartTime: Start time of the session
    ///   - options: Export options
    /// - Returns: Subtitle content as string
    func generateContent(
        from messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) -> String
}

// MARK: - Subtitle Export Service Implementation

/// Service for exporting subtitles
@MainActor
@Observable
final class SubtitleExportService: SubtitleExportServiceProtocol {
    // MARK: - Export Methods

    func export(
        segments: [Segment],
        options: SubtitleExportOptions
    ) async throws -> URL {
        guard !segments.isEmpty else {
            throw SubtitleExportError.noSegments
        }

        let content = generateContent(from: segments, options: options)

        guard !content.isEmpty else {
            throw SubtitleExportError.emptyContent
        }

        return try writeToFile(content: content, format: options.format)
    }

    func export(
        messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) async throws -> URL {
        guard !messages.isEmpty else {
            throw SubtitleExportError.noMessages
        }

        let content = generateContent(
            from: messages,
            sessionStartTime: sessionStartTime,
            options: options
        )

        guard !content.isEmpty else {
            throw SubtitleExportError.emptyContent
        }

        return try writeToFile(content: content, format: options.format)
    }

    // MARK: - Content Generation

    func generateContent(
        from segments: [Segment],
        options: SubtitleExportOptions
    ) -> String {
        switch options.format {
        case .srt:
            return SRTFormatter.generate(
                from: segments,
                contentOption: options.contentOption,
                bilingualOrder: options.bilingualOrder
            )
        case .vtt:
            return generateVTT(
                from: segments,
                contentOption: options.contentOption,
                bilingualOrder: options.bilingualOrder
            )
        case .txt:
            return generatePlainText(
                from: segments,
                contentOption: options.contentOption,
                bilingualOrder: options.bilingualOrder
            )
        }
    }

    func generateContent(
        from messages: [ConversationMessage],
        sessionStartTime: Date,
        options: SubtitleExportOptions
    ) -> String {
        switch options.format {
        case .srt:
            return SRTFormatter.generate(
                from: messages,
                contentOption: options.contentOption,
                sessionStartTime: sessionStartTime,
                bilingualOrder: options.bilingualOrder
            )
        case .vtt:
            return generateVTT(
                from: messages,
                contentOption: options.contentOption,
                sessionStartTime: sessionStartTime,
                bilingualOrder: options.bilingualOrder
            )
        case .txt:
            return generatePlainText(
                from: messages,
                contentOption: options.contentOption,
                bilingualOrder: options.bilingualOrder
            )
        }
    }

    // MARK: - Private Methods

    private func writeToFile(content: String, format: SubtitleFormat) throws -> URL {
        let sessionId = UUID()
        let exportURL = StoragePaths.exportURL(sessionId: sessionId, format: format.fileExtension)

        do {
            try content.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            throw SubtitleExportError.writeError(underlying: error)
        }
    }

    // MARK: - VTT Generation

    private func generateVTT(
        from segments: [Segment],
        contentOption: SubtitleContentOption,
        bilingualOrder: BilingualTextOrder
    ) -> String {
        var lines = ["WEBVTT", ""]

        for (index, segment) in segments.enumerated() {
            let startTime = formatVTTTimestamp(segment.startTime)
            let segmentEndTime: TimeInterval
            if segment.endTime > segment.startTime {
                segmentEndTime = segment.endTime
            } else {
                segmentEndTime = estimateEndTime(from: segment.startTime, text: segment.originalText, locale: segment.sourceLocale)
            }
            let endTime = formatVTTTimestamp(segmentEndTime)

            let text: String
            switch contentOption {
            case .originalOnly:
                text = SRTFormatter.splitIntoLines(segment.originalText)
            case .translationOnly:
                text = SRTFormatter.splitIntoLines(segment.translatedText ?? segment.originalText)
            case .both:
                if let translated = segment.translatedText, !translated.isEmpty {
                    switch bilingualOrder {
                    case .translationFirst:
                        text = SRTFormatter.formatBilingualText(line1: translated, line2: segment.originalText)
                    case .originalFirst:
                        text = SRTFormatter.formatBilingualText(line1: segment.originalText, line2: translated)
                    }
                } else {
                    text = SRTFormatter.splitIntoLines(segment.originalText)
                }
            }

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            lines.append("\(index + 1)")
            lines.append("\(startTime) --> \(endTime)")
            lines.append(text)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func generateVTT(
        from messages: [ConversationMessage],
        contentOption: SubtitleContentOption,
        sessionStartTime: Date,
        bilingualOrder: BilingualTextOrder
    ) -> String {
        var lines = ["WEBVTT", ""]

        for (index, message) in messages.enumerated() {
            let startTime = message.timestamp.timeIntervalSince(sessionStartTime)
            let endTime: TimeInterval
            if index + 1 < messages.count {
                endTime = messages[index + 1].timestamp.timeIntervalSince(sessionStartTime) - 0.1
            } else {
                endTime = estimateEndTime(from: startTime, text: message.originalText, locale: message.sourceLocale)
            }

            let text: String
            switch contentOption {
            case .originalOnly:
                text = SRTFormatter.splitIntoLines(message.originalText)
            case .translationOnly:
                text = SRTFormatter.splitIntoLines(message.translatedText)
            case .both:
                switch bilingualOrder {
                case .translationFirst:
                    text = SRTFormatter.formatBilingualText(line1: message.translatedText, line2: message.originalText)
                case .originalFirst:
                    text = SRTFormatter.formatBilingualText(line1: message.originalText, line2: message.translatedText)
                }
            }

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            lines.append("\(index + 1)")
            lines.append("\(formatVTTTimestamp(startTime)) --> \(formatVTTTimestamp(endTime))")
            lines.append(text)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func formatVTTTimestamp(_ time: TimeInterval) -> String {
        let clampedTime = max(0, time)
        let hours = Int(clampedTime / 3600)
        let minutes = Int((clampedTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(clampedTime.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((clampedTime.truncatingRemainder(dividingBy: 1)) * 1000)

        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }

    // MARK: - Plain Text Generation

    private func generatePlainText(
        from segments: [Segment],
        contentOption: SubtitleContentOption,
        bilingualOrder: BilingualTextOrder
    ) -> String {
        segments
            .compactMap { segment -> String? in
                let text: String
                switch contentOption {
                case .originalOnly:
                    text = segment.originalText
                case .translationOnly:
                    text = segment.translatedText ?? segment.originalText
                case .both:
                    if let translated = segment.translatedText, !translated.isEmpty {
                        switch bilingualOrder {
                        case .translationFirst:
                            text = "\(translated)\n\(segment.originalText)"
                        case .originalFirst:
                            text = "\(segment.originalText)\n\(translated)"
                        }
                    } else {
                        text = segment.originalText
                    }
                }
                return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
            }
            .joined(separator: "\n\n")
    }

    private func generatePlainText(
        from messages: [ConversationMessage],
        contentOption: SubtitleContentOption,
        bilingualOrder: BilingualTextOrder
    ) -> String {
        messages
            .map { message -> String in
                switch contentOption {
                case .originalOnly:
                    return message.originalText
                case .translationOnly:
                    return message.translatedText
                case .both:
                    switch bilingualOrder {
                    case .translationFirst:
                        return "\(message.translatedText)\n\(message.originalText)"
                    case .originalFirst:
                        return "\(message.originalText)\n\(message.translatedText)"
                    }
                }
            }
            .joined(separator: "\n\n")
    }

    // MARK: - Helpers

    private func estimateEndTime(from startTime: TimeInterval, text: String, locale: Locale) -> TimeInterval {
        let duration = SubtitleStandards.estimatedDuration(for: text, locale: locale)
        return startTime + duration
    }
}
