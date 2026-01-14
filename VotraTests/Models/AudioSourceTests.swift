//
//  AudioSourceTests.swift
//  VotraTests
//
//  Unit tests for the AudioSource enumeration.
//

import Testing
import Foundation
@testable import Votra

struct AudioSourceTests {

    // MARK: - Enum Cases

    @Test
    func testMicrophoneCase() {
        let source = AudioSource.microphone
        #expect(source.rawValue == "microphone")
    }

    @Test
    func testSystemAudioCase() {
        let source = AudioSource.systemAudio
        #expect(source.rawValue == "systemAudio")
    }

    // MARK: - Display Name

    @Test
    func testMicrophoneDisplayNameIsNotEmpty() {
        let source = AudioSource.microphone
        #expect(!source.displayName.isEmpty)
    }

    @Test
    func testSystemAudioDisplayNameIsNotEmpty() {
        let source = AudioSource.systemAudio
        #expect(!source.displayName.isEmpty)
    }

    @Test
    func testDisplayNamesAreDifferent() {
        let micDisplayName = AudioSource.microphone.displayName
        let systemDisplayName = AudioSource.systemAudio.displayName
        #expect(micDisplayName != systemDisplayName)
    }

    // MARK: - Codable

    @Test
    func testEncodeMicrophone() throws {
        let source = AudioSource.microphone
        let encoder = JSONEncoder()
        let data = try encoder.encode(source)
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString == "\"microphone\"")
    }

    @Test
    func testEncodeSystemAudio() throws {
        let source = AudioSource.systemAudio
        let encoder = JSONEncoder()
        let data = try encoder.encode(source)
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString == "\"systemAudio\"")
    }

    @Test
    func testDecodeMicrophone() throws {
        let json = "\"microphone\""
        // swiftlint:disable:next force_unwrapping
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let source = try decoder.decode(AudioSource.self, from: data)
        #expect(source == .microphone)
    }

    @Test
    func testDecodeSystemAudio() throws {
        let json = "\"systemAudio\""
        // swiftlint:disable:next force_unwrapping
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let source = try decoder.decode(AudioSource.self, from: data)
        #expect(source == .systemAudio)
    }

    @Test
    func testRoundTripEncoding() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for source in [AudioSource.microphone, AudioSource.systemAudio] {
            let data = try encoder.encode(source)
            let decoded = try decoder.decode(AudioSource.self, from: data)
            #expect(source == decoded)
        }
    }

    // MARK: - Equatable

    @Test
    func testEquality() {
        // swiftlint:disable:next identical_operands
        #expect(AudioSource.microphone == AudioSource.microphone)
        // swiftlint:disable:next identical_operands
        #expect(AudioSource.systemAudio == AudioSource.systemAudio)
        #expect(AudioSource.microphone != AudioSource.systemAudio)
    }

    // MARK: - Raw Value Initialization

    @Test
    func testInitFromRawValueMicrophone() {
        let source = AudioSource(rawValue: "microphone")
        #expect(source == .microphone)
    }

    @Test
    func testInitFromRawValueSystemAudio() {
        let source = AudioSource(rawValue: "systemAudio")
        #expect(source == .systemAudio)
    }

    @Test
    func testInitFromInvalidRawValue() {
        let source = AudioSource(rawValue: "invalid")
        #expect(source == nil)
    }
}
