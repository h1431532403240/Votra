//
//  Recording.swift
//  Votra
//
//  Recording model for audio recording with data stored using @Attribute(.externalStorage).
//

import Foundation
import SwiftData

@Model
final class Recording {
    // No @Attribute(.unique) - CloudKit incompatible
    var id = UUID()

    /// Audio data stored externally - syncs as CKAsset when CloudKit enabled
    /// SwiftData stores large data outside SQLite, CloudKit syncs as CKAsset
    @Attribute(.externalStorage)
    var audioData: Data?

    var duration: TimeInterval = 0
    var formatRawValue: String = "m4a"
    var createdAt = Date()

    /// Original filename for display/export purposes
    var originalFileName: String = ""

    // Optional relationship for CloudKit
    @Relationship var session: Session?

    // MARK: - Computed Properties

    var format: AudioFormat {
        get { AudioFormat(rawValue: formatRawValue) ?? .m4a }
        set { formatRawValue = newValue.rawValue }
    }

    var fileSize: Int64 {
        Int64(audioData?.count ?? 0)
    }

    var formattedDuration: String {
        Self.formatDuration(duration)
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var hasAudioData: Bool {
        guard let data = audioData else { return false }
        return !data.isEmpty
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        audioData: Data? = nil,
        duration: TimeInterval = 0,
        format: AudioFormat = .m4a,
        createdAt: Date = Date(),
        originalFileName: String = ""
    ) {
        self.id = id
        self.audioData = audioData
        self.duration = duration
        self.formatRawValue = format.rawValue
        self.createdAt = createdAt
        self.originalFileName = originalFileName
    }

    // MARK: - Static Methods

    /// Format a duration as HH:MM:SS with zero padding
    static func formatDuration(_ duration: TimeInterval, using formatter: DateComponentsFormatter? = nil) -> String {
        let dateFormatter = formatter ?? {
            let newFormatter = DateComponentsFormatter()
            newFormatter.allowedUnits = [.hour, .minute, .second]
            newFormatter.zeroFormattingBehavior = .pad
            return newFormatter
        }()
        return dateFormatter.string(from: duration) ?? "00:00:00"
    }

    // MARK: - Instance Methods

    /// Export audio data to a temporary file URL for playback/sharing
    @MainActor
    func exportToTemporaryFile() throws -> URL {
        guard let data = audioData else {
            throw RecordingError.noAudioData
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appending(path: "\(id.uuidString).\(format.fileExtension)")

        try data.write(to: tempURL)
        return tempURL
    }

    /// Load audio from a file URL (used during recording)
    func loadAudio(from url: URL) throws {
        audioData = try Data(contentsOf: url)
        originalFileName = url.lastPathComponent
    }
}

// MARK: - Recording Error

enum RecordingError: LocalizedError {
    case noAudioData

    var errorDescription: String? {
        switch self {
        case .noAudioData:
            return String(localized: "No audio data available")
        }
    }
}
