//
//  Speaker.swift
//  Votra
//
//  Speaker model representing an identified speaker in the conversation.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Speaker {
    // No @Attribute(.unique) - CloudKit incompatible
    var id = UUID()

    var displayName: String = ""
    var sourceRawValue: String = "systemAudio"  // AudioSource raw value
    var colorName: String = "blue"              // SpeakerColor raw value

    // Optional relationships for CloudKit
    @Relationship(inverse: \Session.speakers)
    var sessions: [Session]?

    @Relationship(inverse: \Segment.speaker)
    var segments: [Segment]?

    // MARK: - Computed Properties

    var source: AudioSource {
        get { AudioSource(rawValue: sourceRawValue) ?? .systemAudio }
        set { sourceRawValue = newValue.rawValue }
    }

    var color: SpeakerColor {
        get { SpeakerColor(rawValue: colorName) ?? .blue }
        set { colorName = newValue.rawValue }
    }

    @MainActor var swiftUIColor: Color {
        color.swiftUIColor
    }

    var isMe: Bool {
        source == .microphone
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        displayName: String = "",
        source: AudioSource = .systemAudio,
        color: SpeakerColor = .blue
    ) {
        self.id = id
        self.displayName = displayName
        self.sourceRawValue = source.rawValue
        self.colorName = color.rawValue
    }

    // MARK: - Factory Methods

    static func createMe() -> Speaker {
        Speaker(
            displayName: String(localized: "Me"),
            source: .microphone,
            color: .blue
        )
    }

    static func createRemote() -> Speaker {
        Speaker(
            displayName: String(localized: "Remote"),
            source: .systemAudio,
            color: .green
        )
    }
}
