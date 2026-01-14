//
//  AudioBufferConverterTests.swift
//  VotraTests
//
//  Tests for AudioBufferConverter utility.
//

@preconcurrency import AVFoundation
import Testing
@testable import Votra

@Suite("AudioBufferConverter Tests")
@MainActor
struct AudioBufferConverterTests {
    // MARK: - Mono Conversion

    @Test("Convert stereo to mono produces valid mono buffer")
    func convertStereoToMono() {
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let stereoBuffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 1024) else {
            Issue.record("Failed to create test buffer")
            return
        }

        // Fill with test data - left channel has positive values, right has negative
        stereoBuffer.frameLength = 512
        if let channelData = stereoBuffer.floatChannelData {
            for frame in 0..<512 {
                channelData[0][frame] = 0.6  // Left channel
                channelData[1][frame] = 0.4  // Right channel
            }
        }

        guard let monoBuffer = AudioBufferConverter.convertToMono(stereoBuffer) else {
            Issue.record("Failed to convert to mono")
            return
        }

        #expect(monoBuffer.format.channelCount == 1)
        #expect(monoBuffer.frameLength == stereoBuffer.frameLength)

        // Verify averaging: (0.6 + 0.4) / 2 = 0.5
        if let monoData = monoBuffer.floatChannelData {
            #expect(abs(monoData[0][0] - 0.5) < 0.001)
        }
    }

    @Test("Convert mono to mono returns same buffer")
    func convertMonoToMonoReturnsSame() {
        guard let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 1024) else {
            Issue.record("Failed to create test buffer")
            return
        }

        monoBuffer.frameLength = 512

        let result = AudioBufferConverter.convertToMono(monoBuffer)

        // Should return the same buffer for mono input
        #expect(result === monoBuffer)
    }

    @Test("Convert stereo to mono verifies channel averaging loop")
    func convertStereoToMonoVerifiesAveraging() {
        // Test stereo with varying sample values across frames to verify the averaging loop
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let stereoBuffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 1024) else {
            Issue.record("Failed to create stereo test buffer")
            return
        }

        stereoBuffer.frameLength = 256
        if let channelData = stereoBuffer.floatChannelData {
            for frame in 0..<256 {
                // Vary values per frame to test the entire loop
                let frameFloat = Float(frame)
                channelData[0][frame] = frameFloat / 512  // Left: 0.0 to ~0.5
                channelData[1][frame] = 1.0 - frameFloat / 512  // Right: 1.0 to ~0.5
            }
        }

        guard let monoBuffer = AudioBufferConverter.convertToMono(stereoBuffer) else {
            Issue.record("Failed to convert stereo to mono")
            return
        }

        #expect(monoBuffer.format.channelCount == 1)
        #expect(monoBuffer.frameLength == stereoBuffer.frameLength)

        // Verify averaging at multiple points
        if let monoData = monoBuffer.floatChannelData {
            // Frame 0: (0.0 + 1.0) / 2 = 0.5
            #expect(abs(monoData[0][0] - 0.5) < 0.001)
            // Frame 128: (0.25 + 0.75) / 2 = 0.5
            #expect(abs(monoData[0][128] - 0.5) < 0.001)
            // Frame 255: (255/512 + 1-255/512) / 2 = 0.5
            #expect(abs(monoData[0][255] - 0.5) < 0.001)
        }
    }

    @Test("Convert stereo with zero frame length produces valid buffer")
    func convertStereoZeroFrameLength() {
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let stereoBuffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 1024) else {
            Issue.record("Failed to create test buffer")
            return
        }

        // Set frame length to 0 - this tests the edge case where the averaging loop runs 0 times
        stereoBuffer.frameLength = 0

        guard let monoBuffer = AudioBufferConverter.convertToMono(stereoBuffer) else {
            Issue.record("Failed to convert to mono")
            return
        }

        #expect(monoBuffer.format.channelCount == 1)
        #expect(monoBuffer.frameLength == 0)
    }

    // MARK: - Validation

    @Test("Validate valid PCM buffer returns true")
    func validateValidBuffer() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            Issue.record("Failed to create test buffer")
            return
        }

        buffer.frameLength = 512

        #expect(AudioBufferConverter.isValid(buffer))
    }

    @Test("Validate empty PCM buffer returns false")
    func validateEmptyBuffer() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            Issue.record("Failed to create test buffer")
            return
        }

        buffer.frameLength = 0

        #expect(!AudioBufferConverter.isValid(buffer))
    }

    @Test("Validate single frame buffer returns true")
    func validateSingleFrameBuffer() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1) else {
            Issue.record("Failed to create test buffer")
            return
        }

        buffer.frameLength = 1

        #expect(AudioBufferConverter.isValid(buffer))
    }

    // MARK: - SpeechBufferConverter

    @Test("SpeechBufferConverter converts to different sample rate")
    func speechBufferConverterSampleRateConversion() throws {
        guard let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: 4410) else {
            Issue.record("Failed to create test formats/buffer")
            return
        }

        buffer.frameLength = 4410
        if let channelData = buffer.floatChannelData {
            for frame in 0..<4410 {
                channelData[0][frame] = sin(Float(frame) / 100)
            }
        }

        let converter = SpeechBufferConverter()
        let converted = try converter.convertBuffer(buffer, to: targetFormat)

        #expect(converted.format.sampleRate == 16000)
        #expect(converted.format.channelCount == 1)
        // Frame count should be approximately 4410 * (16000/44100) = ~1600
        #expect(converted.frameLength > 0)
    }

    @Test("SpeechBufferConverter returns same buffer when formats match")
    func speechBufferConverterSameFormat() throws {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            Issue.record("Failed to create test buffer")
            return
        }

        buffer.frameLength = 512

        let converter = SpeechBufferConverter()
        let result = try converter.convertBuffer(buffer, to: format)

        // Should return the same buffer for matching formats
        #expect(result === buffer)
    }

    @Test("SpeechBufferConverter reuses converter for multiple conversions with same formats")
    func speechBufferConverterReusesConverter() throws {
        guard let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let buffer1 = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: 4800),
              let buffer2 = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: 4800) else {
            Issue.record("Failed to create test formats/buffers")
            return
        }

        buffer1.frameLength = 4800
        buffer2.frameLength = 4800

        let converter = SpeechBufferConverter()

        // First conversion creates the internal converter
        let converted1 = try converter.convertBuffer(buffer1, to: targetFormat)
        #expect(converted1.format.sampleRate == 16000)

        // Second conversion should reuse the same internal converter
        let converted2 = try converter.convertBuffer(buffer2, to: targetFormat)
        #expect(converted2.format.sampleRate == 16000)
    }

    @Test("SpeechBufferConverter recreates converter when formats change")
    func speechBufferConverterRecreatesConverterOnFormatChange() throws {
        guard let sourceFormat1 = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let sourceFormat2 = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let buffer1 = AVAudioPCMBuffer(pcmFormat: sourceFormat1, frameCapacity: 4410),
              let buffer2 = AVAudioPCMBuffer(pcmFormat: sourceFormat2, frameCapacity: 4800) else {
            Issue.record("Failed to create test formats/buffers")
            return
        }

        buffer1.frameLength = 4410
        buffer2.frameLength = 4800

        let converter = SpeechBufferConverter()

        // First conversion with 44100 Hz source
        let converted1 = try converter.convertBuffer(buffer1, to: targetFormat)
        #expect(converted1.format.sampleRate == 16000)

        // Second conversion with different source format (48000 Hz) should recreate converter
        let converted2 = try converter.convertBuffer(buffer2, to: targetFormat)
        #expect(converted2.format.sampleRate == 16000)
    }

    @Test("SpeechBufferConverter handles upsampling conversion")
    func speechBufferConverterUpsampling() throws {
        guard let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: 1600) else {
            Issue.record("Failed to create test formats/buffer")
            return
        }

        buffer.frameLength = 1600
        if let channelData = buffer.floatChannelData {
            for frame in 0..<1600 {
                channelData[0][frame] = sin(Float(frame) / 50)
            }
        }

        let converter = SpeechBufferConverter()
        let converted = try converter.convertBuffer(buffer, to: targetFormat)

        #expect(converted.format.sampleRate == 44100)
        #expect(converted.format.channelCount == 1)
        // Frame count should be approximately 1600 * (44100/16000) = ~4410
        #expect(converted.frameLength > 0)
    }

    @Test("SpeechBufferConverter handles target format change")
    func speechBufferConverterTargetFormatChange() throws {
        guard let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let targetFormat1 = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let targetFormat2 = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: 4410) else {
            Issue.record("Failed to create test formats/buffer")
            return
        }

        buffer.frameLength = 4410

        let converter = SpeechBufferConverter()

        // First conversion
        let converted1 = try converter.convertBuffer(buffer, to: targetFormat1)
        #expect(converted1.format.sampleRate == 16000)

        // Second conversion with different target format should recreate converter
        let converted2 = try converter.convertBuffer(buffer, to: targetFormat2)
        #expect(converted2.format.sampleRate == 22050)
    }

    // MARK: - convertToSpeechFormat Integration

    @Test("convertToSpeechFormat handles stereo to mono conversion")
    func convertToSpeechFormatStereoToMono() throws {
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let stereoBuffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 4410) else {
            Issue.record("Failed to create test formats/buffer")
            return
        }

        stereoBuffer.frameLength = 4410
        if let channelData = stereoBuffer.floatChannelData {
            for channel in 0..<2 {
                for frame in 0..<4410 {
                    channelData[channel][frame] = sin(Float(frame) / 100)
                }
            }
        }

        let converter = SpeechBufferConverter()
        let converted = try AudioBufferConverter.convertToSpeechFormat(
            stereoBuffer,
            targetFormat: targetFormat,
            converter: converter
        )

        #expect(converted.format.sampleRate == 16000)
        #expect(converted.format.channelCount == 1)
        #expect(converted.frameLength > 0)
    }

    @Test("convertToSpeechFormat handles mono input without extra conversion")
    func convertToSpeechFormatMonoInput() throws {
        guard let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 4410) else {
            Issue.record("Failed to create test formats/buffer")
            return
        }

        monoBuffer.frameLength = 4410
        if let channelData = monoBuffer.floatChannelData {
            for frame in 0..<4410 {
                channelData[0][frame] = sin(Float(frame) / 100)
            }
        }

        let converter = SpeechBufferConverter()
        let converted = try AudioBufferConverter.convertToSpeechFormat(
            monoBuffer,
            targetFormat: targetFormat,
            converter: converter
        )

        #expect(converted.format.sampleRate == 16000)
        #expect(converted.format.channelCount == 1)
        #expect(converted.frameLength > 0)
    }

    @Test("convertToSpeechFormat preserves audio quality during conversion")
    func convertToSpeechFormatPreservesQuality() throws {
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let stereoBuffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 4800) else {
            Issue.record("Failed to create test formats/buffer")
            return
        }

        // Create a simple sine wave for both channels
        stereoBuffer.frameLength = 4800
        if let channelData = stereoBuffer.floatChannelData {
            for channel in 0..<2 {
                for frame in 0..<4800 {
                    channelData[channel][frame] = sin(Float(frame) / 50)
                }
            }
        }

        let converter = SpeechBufferConverter()
        let converted = try AudioBufferConverter.convertToSpeechFormat(
            stereoBuffer,
            targetFormat: targetFormat,
            converter: converter
        )

        #expect(converted.format.sampleRate == 16000)
        #expect(converted.format.channelCount == 1)
        // Frame count should be approximately 4800 * (16000/48000) = ~1600
        #expect(converted.frameLength > 0)
        #expect(converted.frameLength <= 1700)  // Allow some tolerance
    }

    // MARK: - ConversionError Tests

    @Test("ConversionError cases are distinct")
    func conversionErrorCasesAreDistinct() {
        let error1 = SpeechBufferConverter.ConversionError.failedToCreateConverter
        let error2 = SpeechBufferConverter.ConversionError.failedToCreateConversionBuffer
        let error3 = SpeechBufferConverter.ConversionError.conversionFailed(nil)
        let error4 = SpeechBufferConverter.ConversionError.conversionFailed(NSError(domain: "test", code: 1))

        // Verify each error case exists and is usable
        switch error1 {
        case .failedToCreateConverter:
            #expect(true)
        case .failedToCreateConversionBuffer, .conversionFailed:
            Issue.record("Unexpected error case")
        }

        switch error2 {
        case .failedToCreateConversionBuffer:
            #expect(true)
        case .failedToCreateConverter, .conversionFailed:
            Issue.record("Unexpected error case")
        }

        switch error3 {
        case .conversionFailed(let nsError):
            #expect(nsError == nil)
        case .failedToCreateConverter, .failedToCreateConversionBuffer:
            Issue.record("Unexpected error case")
        }

        switch error4 {
        case .conversionFailed(let nsError):
            #expect(nsError != nil)
            #expect(nsError?.domain == "test")
        case .failedToCreateConverter, .failedToCreateConversionBuffer:
            Issue.record("Unexpected error case")
        }
    }
}
