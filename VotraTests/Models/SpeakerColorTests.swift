//
//  SpeakerColorTests.swift
//  VotraTests
//
//  Unit tests for the SpeakerColor enumeration.
//

import Testing
import Foundation
import SwiftUI
@testable import Votra

struct SpeakerColorTests {

    // MARK: - Enum Cases

    @Test
    func testAllCasesExist() {
        let allCases = SpeakerColor.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.blue))
        #expect(allCases.contains(.green))
        #expect(allCases.contains(.orange))
        #expect(allCases.contains(.purple))
        #expect(allCases.contains(.pink))
        #expect(allCases.contains(.teal))
    }

    // MARK: - Raw Values

    @Test
    func testRawValues() {
        #expect(SpeakerColor.blue.rawValue == "blue")
        #expect(SpeakerColor.green.rawValue == "green")
        #expect(SpeakerColor.orange.rawValue == "orange")
        #expect(SpeakerColor.purple.rawValue == "purple")
        #expect(SpeakerColor.pink.rawValue == "pink")
        #expect(SpeakerColor.teal.rawValue == "teal")
    }

    @Test
    func testInitFromRawValue() {
        #expect(SpeakerColor(rawValue: "blue") == .blue)
        #expect(SpeakerColor(rawValue: "green") == .green)
        #expect(SpeakerColor(rawValue: "orange") == .orange)
        #expect(SpeakerColor(rawValue: "purple") == .purple)
        #expect(SpeakerColor(rawValue: "pink") == .pink)
        #expect(SpeakerColor(rawValue: "teal") == .teal)
        #expect(SpeakerColor(rawValue: "invalid") == nil)
    }

    // MARK: - SwiftUI Color

    @Test
    func testSwiftUIColorBlue() {
        #expect(SpeakerColor.blue.swiftUIColor == Color.blue)
    }

    @Test
    func testSwiftUIColorGreen() {
        #expect(SpeakerColor.green.swiftUIColor == Color.green)
    }

    @Test
    func testSwiftUIColorOrange() {
        #expect(SpeakerColor.orange.swiftUIColor == Color.orange)
    }

    @Test
    func testSwiftUIColorPurple() {
        #expect(SpeakerColor.purple.swiftUIColor == Color.purple)
    }

    @Test
    func testSwiftUIColorPink() {
        #expect(SpeakerColor.pink.swiftUIColor == Color.pink)
    }

    @Test
    func testSwiftUIColorTeal() {
        #expect(SpeakerColor.teal.swiftUIColor == Color.teal)
    }

    // MARK: - Display Name

    @Test
    func testDisplayNameBlue() {
        #expect(SpeakerColor.blue.displayName == "Blue")
    }

    @Test
    func testDisplayNameGreen() {
        #expect(SpeakerColor.green.displayName == "Green")
    }

    @Test
    func testDisplayNameOrange() {
        #expect(SpeakerColor.orange.displayName == "Orange")
    }

    @Test
    func testDisplayNamePurple() {
        #expect(SpeakerColor.purple.displayName == "Purple")
    }

    @Test
    func testDisplayNamePink() {
        #expect(SpeakerColor.pink.displayName == "Pink")
    }

    @Test
    func testDisplayNameTeal() {
        #expect(SpeakerColor.teal.displayName == "Teal")
    }

    @Test
    func testDisplayNameIsCapitalizedRawValue() {
        for color in SpeakerColor.allCases {
            #expect(color.displayName == color.rawValue.capitalized)
        }
    }

    // MARK: - Codable

    @Test
    func testEncode() throws {
        let encoder = JSONEncoder()
        for color in SpeakerColor.allCases {
            let data = try encoder.encode(color)
            let json = String(data: data, encoding: .utf8)
            #expect(json == "\"\(color.rawValue)\"")
        }
    }

    @Test
    func testDecode() throws {
        let decoder = JSONDecoder()
        for color in SpeakerColor.allCases {
            let json = "\"\(color.rawValue)\""
            // swiftlint:disable:next force_unwrapping
            let data = json.data(using: .utf8)!
            let decoded = try decoder.decode(SpeakerColor.self, from: data)
            #expect(decoded == color)
        }
    }

    @Test
    func testDecodeInvalidValue() {
        let decoder = JSONDecoder()
        let json = "\"invalid\""
        // swiftlint:disable:next force_unwrapping
        let data = json.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(SpeakerColor.self, from: data)
        }
    }

    // MARK: - Equatable

    @Test
    func testEquatable() {
        // swiftlint:disable identical_operands
        #expect(SpeakerColor.blue == SpeakerColor.blue)
        #expect(SpeakerColor.green == SpeakerColor.green)
        // swiftlint:enable identical_operands
        #expect(SpeakerColor.blue != SpeakerColor.green)
        #expect(SpeakerColor.orange != SpeakerColor.purple)
    }

    // MARK: - CaseIterable

    @Test
    func testCaseIterableOrder() {
        let allCases = SpeakerColor.allCases
        #expect(allCases[0] == .blue)
        #expect(allCases[1] == .green)
        #expect(allCases[2] == .orange)
        #expect(allCases[3] == .purple)
        #expect(allCases[4] == .pink)
        #expect(allCases[5] == .teal)
    }

    // MARK: - Sendable

    @Test
    func testSendable() async {
        let color = SpeakerColor.blue
        let result = await Task.detached {
            color
        }.value
        #expect(result == .blue)
    }
}
