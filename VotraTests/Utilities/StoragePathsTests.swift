//
//  StoragePathsTests.swift
//  VotraTests
//
//  Tests for StoragePaths file storage path utilities.
//

import Foundation
import Testing
@testable import Votra

@Suite("Storage Paths Tests")
@MainActor
struct StoragePathsTests {

    // MARK: - Helper Methods

    /// Returns a decoded file path without percent encoding and without trailing slashes
    private func decodedPath(_ url: URL) -> String {
        var path = url.standardizedFileURL.path(percentEncoded: false)
        while path.hasSuffix("/") && path.count > 1 {
            path = String(path.dropLast())
        }
        return path
    }

    /// Compares two URLs by their normalized decoded paths to handle trailing slash differences
    private func urlsPointToSameLocation(_ url1: URL, _ url2: URL) -> Bool {
        decodedPath(url1) == decodedPath(url2)
    }

    // MARK: - Static URL Property Tests

    @Test("appSupport URL is within application support directory")
    func appSupportURLIsValid() {
        let appSupport = StoragePaths.appSupport

        // Check that the path contains the Application Support directory (decoded, with space)
        #expect(decodedPath(appSupport).contains("Application Support"))
        #expect(appSupport.lastPathComponent == "Votra")
    }

    @Test("recordings URL is within appSupport directory")
    func recordingsURLIsValid() {
        let recordings = StoragePaths.recordings

        #expect(recordings.path().hasPrefix(StoragePaths.appSupport.path()))
        #expect(recordings.lastPathComponent == "Recordings")
    }

    @Test("exports URL is within appSupport directory")
    func exportsURLIsValid() {
        let exports = StoragePaths.exports

        #expect(exports.path().hasPrefix(StoragePaths.appSupport.path()))
        #expect(exports.lastPathComponent == "Exports")
    }

    @Test("temp URL is within appSupport directory")
    func tempURLIsValid() {
        let temp = StoragePaths.temp

        #expect(temp.path().hasPrefix(StoragePaths.appSupport.path()))
        #expect(temp.lastPathComponent == "temp")
    }

    @Test("All static paths are file URLs")
    func allStaticPathsAreFileURLs() {
        #expect(StoragePaths.appSupport.isFileURL)
        #expect(StoragePaths.recordings.isFileURL)
        #expect(StoragePaths.exports.isFileURL)
        #expect(StoragePaths.temp.isFileURL)
    }

    // MARK: - Directory Creation Tests

    @Test("ensureDirectoriesExist creates all required directories")
    func ensureDirectoriesExistCreatesDirectories() {
        StoragePaths.ensureDirectoriesExist()

        let fileManager = FileManager.default

        #expect(fileManager.fileExists(atPath: decodedPath(StoragePaths.recordings)))
        #expect(fileManager.fileExists(atPath: decodedPath(StoragePaths.exports)))
        #expect(fileManager.fileExists(atPath: decodedPath(StoragePaths.temp)))
    }

    @Test("appSupport directory is created on first access")
    func appSupportDirectoryIsCreated() {
        let fileManager = FileManager.default

        // Accessing appSupport should trigger directory creation
        let appSupport = StoragePaths.appSupport

        #expect(fileManager.fileExists(atPath: decodedPath(appSupport)))
    }

    @Test("ensureDirectoriesExist is idempotent")
    func ensureDirectoriesExistIsIdempotent() {
        // Call multiple times - should not throw or cause issues
        StoragePaths.ensureDirectoriesExist()
        StoragePaths.ensureDirectoriesExist()
        StoragePaths.ensureDirectoriesExist()

        let fileManager = FileManager.default

        #expect(fileManager.fileExists(atPath: decodedPath(StoragePaths.recordings)))
        #expect(fileManager.fileExists(atPath: decodedPath(StoragePaths.exports)))
        #expect(fileManager.fileExists(atPath: decodedPath(StoragePaths.temp)))
    }

    // MARK: - recordingURL Tests

    @Test("recordingURL generates URL with correct session ID")
    func recordingURLContainsSessionId() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)

        #expect(url.lastPathComponent.contains(sessionId.uuidString))
    }

    @Test("recordingURL generates URL within recordings directory")
    func recordingURLIsInRecordingsDirectory() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .wav)

        #expect(urlsPointToSameLocation(url.deletingLastPathComponent(), StoragePaths.recordings))
    }

    @Test("recordingURL generates URL with correct file extension for m4a")
    func recordingURLHasM4AExtension() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)

        #expect(url.pathExtension == "m4a")
    }

    @Test("recordingURL generates URL with correct file extension for wav")
    func recordingURLHasWAVExtension() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .wav)

        #expect(url.pathExtension == "wav")
    }

    @Test("recordingURL generates URL with correct file extension for mp3")
    func recordingURLHasMP3Extension() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .mp3)

        #expect(url.pathExtension == "mp3")
    }

    @Test("recordingURL generates URL with all audio formats")
    func recordingURLSupportsAllAudioFormats() {
        let sessionId = UUID()

        for format in AudioFormat.allCases {
            let url = StoragePaths.recordingURL(sessionId: sessionId, format: format)
            #expect(url.pathExtension == format.fileExtension)
        }
    }

    @Test("recordingURL generates unique URLs for different sessions")
    func recordingURLIsUniquePerSession() {
        let sessionId1 = UUID()
        let sessionId2 = UUID()

        let url1 = StoragePaths.recordingURL(sessionId: sessionId1, format: .m4a)
        let url2 = StoragePaths.recordingURL(sessionId: sessionId2, format: .m4a)

        #expect(url1 != url2)
    }

    @Test("recordingURL filename contains timestamp-like pattern")
    func recordingURLContainsTimestamp() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)
        let filename = url.deletingPathExtension().lastPathComponent

        // Filename should be sessionId_timestamp format
        #expect(filename.contains("_"))

        let components = filename.split(separator: "_")
        #expect(components.count == 2)
        #expect(String(components[0]) == sessionId.uuidString)

        // Second component should be a timestamp (digits only after removing colons/dashes)
        let timestampPart = String(components[1])
        #expect(!timestampPart.isEmpty)
    }

    // MARK: - tempRecordingURL Tests

    @Test("tempRecordingURL generates URL with correct session ID")
    func tempRecordingURLContainsSessionId() {
        let sessionId = UUID()
        let url = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)

        #expect(url.lastPathComponent.contains(sessionId.uuidString))
    }

    @Test("tempRecordingURL generates URL within temp directory")
    func tempRecordingURLIsInTempDirectory() {
        let sessionId = UUID()
        let url = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .wav)

        #expect(urlsPointToSameLocation(url.deletingLastPathComponent(), StoragePaths.temp))
    }

    @Test("tempRecordingURL includes temp suffix in filename")
    func tempRecordingURLIncludesTempSuffix() {
        let sessionId = UUID()
        let url = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)
        let filename = url.deletingPathExtension().lastPathComponent

        #expect(filename.hasSuffix("_temp"))
    }

    @Test("tempRecordingURL generates URL with correct file extension")
    func tempRecordingURLHasCorrectExtension() {
        let sessionId = UUID()

        for format in AudioFormat.allCases {
            let url = StoragePaths.tempRecordingURL(sessionId: sessionId, format: format)
            #expect(url.pathExtension == format.fileExtension)
        }
    }

    @Test("tempRecordingURL is consistent for same session")
    func tempRecordingURLIsConsistentForSameSession() {
        let sessionId = UUID()

        let url1 = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)
        let url2 = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)

        #expect(url1 == url2)
    }

    @Test("tempRecordingURL differs from recordingURL")
    func tempRecordingURLDiffersFromRecordingURL() {
        let sessionId = UUID()

        let tempURL = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)
        let recordingURL = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)

        #expect(tempURL != recordingURL)
        #expect(tempURL.deletingLastPathComponent() != recordingURL.deletingLastPathComponent())
    }

    // MARK: - exportURL Tests

    @Test("exportURL generates URL with correct session ID")
    func exportURLContainsSessionId() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "srt")

        #expect(url.lastPathComponent.contains(sessionId.uuidString))
    }

    @Test("exportURL generates URL within exports directory")
    func exportURLIsInExportsDirectory() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "txt")

        #expect(urlsPointToSameLocation(url.deletingLastPathComponent(), StoragePaths.exports))
    }

    @Test("exportURL generates URL with correct file extension for srt")
    func exportURLHasSRTExtension() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "srt")

        #expect(url.pathExtension == "srt")
    }

    @Test("exportURL generates URL with correct file extension for vtt")
    func exportURLHasVTTExtension() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "vtt")

        #expect(url.pathExtension == "vtt")
    }

    @Test("exportURL generates URL with correct file extension for txt")
    func exportURLHasTXTExtension() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "txt")

        #expect(url.pathExtension == "txt")
    }

    @Test("exportURL generates URL with correct file extension for json")
    func exportURLHasJSONExtension() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "json")

        #expect(url.pathExtension == "json")
    }

    @Test("exportURL generates unique URLs for different sessions")
    func exportURLIsUniquePerSession() {
        let sessionId1 = UUID()
        let sessionId2 = UUID()

        let url1 = StoragePaths.exportURL(sessionId: sessionId1, format: "srt")
        let url2 = StoragePaths.exportURL(sessionId: sessionId2, format: "srt")

        #expect(url1 != url2)
    }

    @Test("exportURL filename contains timestamp-like pattern")
    func exportURLContainsTimestamp() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "srt")
        let filename = url.deletingPathExtension().lastPathComponent

        // Filename should be sessionId_timestamp format
        #expect(filename.contains("_"))

        let components = filename.split(separator: "_")
        #expect(components.count == 2)
        #expect(String(components[0]) == sessionId.uuidString)
    }

    @Test("exportURL handles uppercase format string")
    func exportURLHandlesUppercaseFormat() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "SRT")

        #expect(url.pathExtension == "SRT")
    }

    @Test("exportURL handles mixed case format string")
    func exportURLHandlesMixedCaseFormat() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "Srt")

        #expect(url.pathExtension == "Srt")
    }

    // MARK: - Path Construction Edge Cases

    @Test("URLs handle special UUID characters correctly")
    func urlsHandleSpecialUUIDCharacters() {
        // UUIDs contain hyphens which should be preserved
        let sessionId = UUID()

        let recordingURL = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)
        let tempURL = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)
        let exportURL = StoragePaths.exportURL(sessionId: sessionId, format: "srt")

        // All URLs should contain the full UUID string with hyphens
        #expect(recordingURL.lastPathComponent.contains(sessionId.uuidString))
        #expect(tempURL.lastPathComponent.contains(sessionId.uuidString))
        #expect(exportURL.lastPathComponent.contains(sessionId.uuidString))
    }

    @Test("Empty format string creates URL without extension")
    func emptyFormatStringCreatesURLWithoutExtension() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: "")

        // With empty format, the extension should be empty
        #expect(url.pathExtension.isEmpty)
    }

    @Test("Format string with dot is handled")
    func formatStringWithDotIsHandled() {
        let sessionId = UUID()
        let url = StoragePaths.exportURL(sessionId: sessionId, format: ".srt")

        // The format should be used as-is, resulting in ".srt" extension
        #expect(url.lastPathComponent.hasSuffix("..srt"))
    }

    // MARK: - File URL Validity Tests

    @Test("Generated URLs are valid file URLs")
    func generatedURLsAreValidFileURLs() {
        let sessionId = UUID()

        let recordingURL = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)
        let tempURL = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)
        let exportURL = StoragePaths.exportURL(sessionId: sessionId, format: "srt")

        #expect(recordingURL.isFileURL)
        #expect(tempURL.isFileURL)
        #expect(exportURL.isFileURL)
    }

    @Test("Generated URLs have absolute paths")
    func generatedURLsHaveAbsolutePaths() {
        let sessionId = UUID()

        let recordingURL = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)
        let tempURL = StoragePaths.tempRecordingURL(sessionId: sessionId, format: .m4a)
        let exportURL = StoragePaths.exportURL(sessionId: sessionId, format: "srt")

        #expect(recordingURL.path().hasPrefix("/"))
        #expect(tempURL.path().hasPrefix("/"))
        #expect(exportURL.path().hasPrefix("/"))
    }

    // MARK: - Directory Hierarchy Tests

    @Test("Directory hierarchy is correct")
    func directoryHierarchyIsCorrect() {
        // All subdirectories should be children of appSupport
        let appSupportPath = decodedPath(StoragePaths.appSupport)

        #expect(decodedPath(StoragePaths.recordings).hasPrefix(appSupportPath))
        #expect(decodedPath(StoragePaths.exports).hasPrefix(appSupportPath))
        #expect(decodedPath(StoragePaths.temp).hasPrefix(appSupportPath))

        // They should be direct children (one level deep)
        let recordingsParent = StoragePaths.recordings.deletingLastPathComponent()
        let exportsParent = StoragePaths.exports.deletingLastPathComponent()
        let tempParent = StoragePaths.temp.deletingLastPathComponent()

        #expect(urlsPointToSameLocation(recordingsParent, StoragePaths.appSupport))
        #expect(urlsPointToSameLocation(exportsParent, StoragePaths.appSupport))
        #expect(urlsPointToSameLocation(tempParent, StoragePaths.appSupport))
    }

    @Test("Recording files are two levels below appSupport")
    func recordingFilesAreTwoLevelsBelowAppSupport() {
        let sessionId = UUID()
        let url = StoragePaths.recordingURL(sessionId: sessionId, format: .m4a)

        // file -> Recordings -> appSupport
        let grandparent = url.deletingLastPathComponent().deletingLastPathComponent()
        #expect(urlsPointToSameLocation(grandparent, StoragePaths.appSupport))
    }
}
