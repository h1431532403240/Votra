//
//  TestTags.swift
//  VotraTests
//
//  Defines custom tags for organizing and filtering tests.
//

import Testing

extension Tag {
    /// Tests that require audio hardware (microphone, speakers, system audio).
    /// These tests should be skipped in CI environments without audio hardware.
    @Tag static var requiresHardware: Self
}
