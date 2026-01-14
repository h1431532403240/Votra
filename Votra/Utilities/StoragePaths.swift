//
//  StoragePaths.swift
//  Votra
//
//  File storage path utilities for recordings and exports.
//

import Foundation

/// Utility for managing file storage paths
enum StoragePaths {
    static let appSupport: URL = {
        let url = URL.applicationSupportDirectory.appending(path: "Votra")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static let recordings = appSupport.appending(path: "Recordings")
    static let exports = appSupport.appending(path: "Exports")
    static let temp = appSupport.appending(path: "temp")

    static func ensureDirectoriesExist() {
        let directories = [recordings, exports, temp]
        for dir in directories {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    static func recordingURL(sessionId: UUID, format: AudioFormat) -> URL {
        let timestamp = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false))
            .replacing("-", with: "")
            .replacing(":", with: "")
        return recordings.appending(path: "\(sessionId.uuidString)_\(timestamp).\(format.fileExtension)")
    }

    static func tempRecordingURL(sessionId: UUID, format: AudioFormat) -> URL {
        temp.appending(path: "\(sessionId.uuidString)_temp.\(format.fileExtension)")
    }

    static func exportURL(sessionId: UUID, format: String) -> URL {
        let timestamp = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false))
            .replacing("-", with: "")
            .replacing(":", with: "")
        return exports.appending(path: "\(sessionId.uuidString)_\(timestamp).\(format)")
    }
}
