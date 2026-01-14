//
//  AudioFormatTests.swift
//  VotraTests
//
//  Unit tests for the AudioFormat enumeration.
//

import Foundation
import Testing
@testable import Votra

@Suite("AudioFormat")
struct AudioFormatTests {
    // MARK: - Enum Cases

    @Test("All expected cases exist")
    func allCasesExist() {
        let cases = AudioFormat.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.m4a))
        #expect(cases.contains(.wav))
        #expect(cases.contains(.mp3))
    }

    // MARK: - Raw Values

    @Test("M4A raw value is correct")
    func m4aRawValue() {
        #expect(AudioFormat.m4a.rawValue == "m4a")
    }

    @Test("WAV raw value is correct")
    func wavRawValue() {
        #expect(AudioFormat.wav.rawValue == "wav")
    }

    @Test("MP3 raw value is correct")
    func mp3RawValue() {
        #expect(AudioFormat.mp3.rawValue == "mp3")
    }

    // MARK: - File Extension

    @Test("M4A file extension matches raw value")
    func m4aFileExtension() {
        #expect(AudioFormat.m4a.fileExtension == "m4a")
    }

    @Test("WAV file extension matches raw value")
    func wavFileExtension() {
        #expect(AudioFormat.wav.fileExtension == "wav")
    }

    @Test("MP3 file extension matches raw value")
    func mp3FileExtension() {
        #expect(AudioFormat.mp3.fileExtension == "mp3")
    }

    // MARK: - MIME Types

    @Test("M4A MIME type is audio/mp4")
    func m4aMimeType() {
        #expect(AudioFormat.m4a.mimeType == "audio/mp4")
    }

    @Test("WAV MIME type is audio/wav")
    func wavMimeType() {
        #expect(AudioFormat.wav.mimeType == "audio/wav")
    }

    @Test("MP3 MIME type is audio/mpeg")
    func mp3MimeType() {
        #expect(AudioFormat.mp3.mimeType == "audio/mpeg")
    }

    // MARK: - Display Names

    @Test("M4A display name is uppercase")
    func m4aDisplayName() {
        #expect(AudioFormat.m4a.displayName == "M4A")
    }

    @Test("WAV display name is uppercase")
    func wavDisplayName() {
        #expect(AudioFormat.wav.displayName == "WAV")
    }

    @Test("MP3 display name is uppercase")
    func mp3DisplayName() {
        #expect(AudioFormat.mp3.displayName == "MP3")
    }

    // MARK: - Codable

    @Test("Encoding and decoding preserves value")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for format in AudioFormat.allCases {
            let data = try encoder.encode(format)
            let decoded = try decoder.decode(AudioFormat.self, from: data)
            #expect(decoded == format)
        }
    }

    @Test("Decodes from raw value string")
    func decodesFromRawValue() throws {
        let decoder = JSONDecoder()

        let m4aData = Data("\"m4a\"".utf8)
        let wavData = Data("\"wav\"".utf8)
        let mp3Data = Data("\"mp3\"".utf8)

        #expect(try decoder.decode(AudioFormat.self, from: m4aData) == .m4a)
        #expect(try decoder.decode(AudioFormat.self, from: wavData) == .wav)
        #expect(try decoder.decode(AudioFormat.self, from: mp3Data) == .mp3)
    }

    // MARK: - Equatable

    @Test("Same formats are equal")
    func equalityForSameFormats() {
        // swiftlint:disable:next identical_operands
        #expect(AudioFormat.m4a == AudioFormat.m4a)
        // swiftlint:disable:next identical_operands
        #expect(AudioFormat.wav == AudioFormat.wav)
        // swiftlint:disable:next identical_operands
        #expect(AudioFormat.mp3 == AudioFormat.mp3)
    }

    @Test("Different formats are not equal")
    func inequalityForDifferentFormats() {
        #expect(AudioFormat.m4a != AudioFormat.wav)
        #expect(AudioFormat.m4a != AudioFormat.mp3)
        #expect(AudioFormat.wav != AudioFormat.mp3)
    }

    // MARK: - Initialization from Raw Value

    @Test("Initializes from valid raw values")
    func initFromValidRawValues() {
        #expect(AudioFormat(rawValue: "m4a") == .m4a)
        #expect(AudioFormat(rawValue: "wav") == .wav)
        #expect(AudioFormat(rawValue: "mp3") == .mp3)
    }

    @Test("Returns nil for invalid raw values")
    func initFromInvalidRawValues() {
        #expect(AudioFormat(rawValue: "aac") == nil)
        #expect(AudioFormat(rawValue: "ogg") == nil)
        #expect(AudioFormat(rawValue: "flac") == nil)
        #expect(AudioFormat(rawValue: "M4A") == nil) // Case sensitive
        #expect(AudioFormat(rawValue: "") == nil)
    }
}
