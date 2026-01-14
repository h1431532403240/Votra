//
//  SpeakerTests.swift
//  VotraTests
//
//  Unit tests for the Speaker model.
//

import Testing
import Foundation
import SwiftUI
import SwiftData
@testable import Votra

@Suite("Speaker Model Tests")
@MainActor
struct SpeakerTests {
    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    // MARK: - Initialization Tests

    @Test("Default initialization sets expected defaults")
    func testDefaultInitialization() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        #expect(speaker.displayName.isEmpty)
        #expect(speaker.sourceRawValue == "systemAudio")
        #expect(speaker.colorName == "blue")
        #expect(speaker.source == .systemAudio)
        #expect(speaker.color == .blue)
        #expect(speaker.isMe == false)
        #expect(speaker.sessions == nil)
        #expect(speaker.segments == nil)
    }

    @Test("Custom initialization with all parameters")
    func testCustomInitialization() {
        let context = container.mainContext
        let customID = UUID()
        let speaker = Speaker(
            id: customID,
            displayName: "Test Speaker",
            source: .microphone,
            color: .purple
        )
        context.insert(speaker)

        #expect(speaker.id == customID)
        #expect(speaker.displayName == "Test Speaker")
        #expect(speaker.sourceRawValue == "microphone")
        #expect(speaker.colorName == "purple")
        #expect(speaker.source == .microphone)
        #expect(speaker.color == .purple)
        #expect(speaker.isMe == true)
    }

    @Test("Initialization with each AudioSource value", arguments: [AudioSource.microphone, AudioSource.systemAudio])
    func testInitializationWithAudioSources(source: AudioSource) {
        let context = container.mainContext
        let speaker = Speaker(source: source)
        context.insert(speaker)

        #expect(speaker.source == source)
        #expect(speaker.sourceRawValue == source.rawValue)
    }

    @Test("Initialization with each SpeakerColor value", arguments: SpeakerColor.allCases)
    func testInitializationWithColors(color: SpeakerColor) {
        let context = container.mainContext
        let speaker = Speaker(color: color)
        context.insert(speaker)

        #expect(speaker.color == color)
        #expect(speaker.colorName == color.rawValue)
    }

    // MARK: - Factory Method Tests

    @Test("createMe factory creates microphone speaker with blue color")
    func testCreateMeFactory() {
        let context = container.mainContext
        let me = Speaker.createMe()
        context.insert(me)

        #expect(me.displayName == String(localized: "Me"))
        #expect(me.source == .microphone)
        #expect(me.sourceRawValue == "microphone")
        #expect(me.color == .blue)
        #expect(me.colorName == "blue")
        #expect(me.isMe == true)
    }

    @Test("createRemote factory creates system audio speaker with green color")
    func testCreateRemoteFactory() {
        let context = container.mainContext
        let remote = Speaker.createRemote()
        context.insert(remote)

        #expect(remote.displayName == String(localized: "Remote"))
        #expect(remote.source == .systemAudio)
        #expect(remote.sourceRawValue == "systemAudio")
        #expect(remote.color == .green)
        #expect(remote.colorName == "green")
        #expect(remote.isMe == false)
    }

    // MARK: - Computed Property Tests: source

    @Test("source getter returns correct AudioSource for valid raw values")
    func testSourceGetterValidValues() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        speaker.sourceRawValue = "microphone"
        #expect(speaker.source == .microphone)

        speaker.sourceRawValue = "systemAudio"
        #expect(speaker.source == .systemAudio)
    }

    @Test("source getter returns default systemAudio for invalid raw values")
    func testSourceGetterInvalidValue() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        // Set an invalid raw value directly
        speaker.sourceRawValue = "invalidSource"
        #expect(speaker.source == .systemAudio)

        speaker.sourceRawValue = ""
        #expect(speaker.source == .systemAudio)

        speaker.sourceRawValue = "MICROPHONE"  // Case sensitive
        #expect(speaker.source == .systemAudio)
    }

    @Test("source setter updates raw value correctly")
    func testSourceSetter() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        speaker.source = .microphone
        #expect(speaker.sourceRawValue == "microphone")

        speaker.source = .systemAudio
        #expect(speaker.sourceRawValue == "systemAudio")
    }

    // MARK: - Computed Property Tests: color

    @Test("color getter returns correct SpeakerColor for valid raw values")
    func testColorGetterValidValues() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        for testColor in SpeakerColor.allCases {
            speaker.colorName = testColor.rawValue
            #expect(speaker.color == testColor)
        }
    }

    @Test("color getter returns default blue for invalid raw values")
    func testColorGetterInvalidValue() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        // Set an invalid raw value directly
        speaker.colorName = "invalidColor"
        #expect(speaker.color == .blue)

        speaker.colorName = ""
        #expect(speaker.color == .blue)

        speaker.colorName = "BLUE"  // Case sensitive
        #expect(speaker.color == .blue)

        speaker.colorName = "red"  // Not a valid SpeakerColor
        #expect(speaker.color == .blue)
    }

    @Test("color setter updates raw value correctly")
    func testColorSetter() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        for testColor in SpeakerColor.allCases {
            speaker.color = testColor
            #expect(speaker.colorName == testColor.rawValue)
        }
    }

    // MARK: - Computed Property Tests: swiftUIColor

    @Test("swiftUIColor returns correct SwiftUI Color for each SpeakerColor", arguments: SpeakerColor.allCases)
    func testSwiftUIColorForAllColors(speakerColor: SpeakerColor) {
        let context = container.mainContext
        let speaker = Speaker(color: speakerColor)
        context.insert(speaker)

        #expect(speaker.swiftUIColor == speakerColor.swiftUIColor)
    }

    @Test("swiftUIColor matches expected SwiftUI colors")
    func testSwiftUIColorValues() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        speaker.color = .blue
        #expect(speaker.swiftUIColor == Color.blue)

        speaker.color = .green
        #expect(speaker.swiftUIColor == Color.green)

        speaker.color = .orange
        #expect(speaker.swiftUIColor == Color.orange)

        speaker.color = .purple
        #expect(speaker.swiftUIColor == Color.purple)

        speaker.color = .pink
        #expect(speaker.swiftUIColor == Color.pink)

        speaker.color = .teal
        #expect(speaker.swiftUIColor == Color.teal)
    }

    // MARK: - Computed Property Tests: isMe

    @Test("isMe returns true only for microphone source")
    func testIsMeProperty() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        speaker.source = .microphone
        #expect(speaker.isMe == true)

        speaker.source = .systemAudio
        #expect(speaker.isMe == false)
    }

    @Test("isMe is false when source has invalid raw value")
    func testIsMeWithInvalidSource() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        // Invalid source defaults to systemAudio, so isMe should be false
        speaker.sourceRawValue = "invalid"
        #expect(speaker.isMe == false)
    }

    // MARK: - Property Modification Tests

    @Test("displayName can be modified")
    func testDisplayNameModification() {
        let context = container.mainContext
        let speaker = Speaker(displayName: "Original")
        context.insert(speaker)

        #expect(speaker.displayName == "Original")

        speaker.displayName = "Modified"
        #expect(speaker.displayName == "Modified")

        speaker.displayName = ""
        #expect(speaker.displayName.isEmpty)
    }

    @Test("UUID is preserved through property changes")
    func testUUIDPreservation() {
        let context = container.mainContext
        let originalID = UUID()
        let speaker = Speaker(id: originalID)
        context.insert(speaker)

        // Modify other properties
        speaker.displayName = "Changed"
        speaker.source = .microphone
        speaker.color = .purple

        // ID should remain unchanged
        #expect(speaker.id == originalID)
    }

    // MARK: - Edge Cases

    @Test("Multiple speakers can have the same color")
    func testMultipleSpeakersWithSameColor() {
        let context = container.mainContext
        let speaker1 = Speaker(displayName: "Speaker 1", color: .blue)
        let speaker2 = Speaker(displayName: "Speaker 2", color: .blue)
        context.insert(speaker1)
        context.insert(speaker2)

        #expect(speaker1.color == speaker2.color)
        #expect(speaker1.id != speaker2.id)
    }

    @Test("Speakers have unique UUIDs when created without explicit ID")
    func testUniqueSpeakerIDs() {
        let context = container.mainContext
        let speaker1 = Speaker()
        let speaker2 = Speaker()
        context.insert(speaker1)
        context.insert(speaker2)

        #expect(speaker1.id != speaker2.id)
    }

    @Test("displayName supports special characters and Unicode")
    func testDisplayNameWithSpecialCharacters() {
        let context = container.mainContext

        let specialNames = [
            "John Smith",
            "John's Speaker",
            "Speaker #1",
            "Emoji Speaker",
            "Sprecher",
            "Speaker",
            "",
            "   ",
            "A very long speaker name that contains many characters"
        ]

        for name in specialNames {
            let speaker = Speaker(displayName: name)
            context.insert(speaker)
            #expect(speaker.displayName == name)
        }
    }

    // MARK: - Relationship Tests

    @Test("sessions relationship is initially nil")
    func testSessionsRelationshipInitiallyNil() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        #expect(speaker.sessions == nil)
    }

    @Test("segments relationship is initially nil")
    func testSegmentsRelationshipInitiallyNil() {
        let context = container.mainContext
        let speaker = Speaker()
        context.insert(speaker)

        #expect(speaker.segments == nil)
    }
}
