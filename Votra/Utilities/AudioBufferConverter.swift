//
//  AudioBufferConverter.swift
//  Votra
//
//  Utility for converting audio buffers for SpeechAnalyzer.
//

@preconcurrency import AVFoundation
import Foundation

/// Utility for converting audio buffers for speech recognition
/// Note: This utility is nonisolated to allow use from any context
nonisolated enum AudioBufferConverter {
    // MARK: - Channel Conversion

    /// Converts stereo audio to mono by averaging channels
    /// - Parameter buffer: A stereo AVAudioPCMBuffer
    /// - Returns: A mono AVAudioPCMBuffer
    static func convertToMono(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard buffer.format.channelCount > 1 else { return buffer }

        guard let monoFormat = AVAudioFormat(
            standardFormatWithSampleRate: buffer.format.sampleRate,
            channels: 1
        ) else {
            return nil
        }

        guard let monoBuffer = AVAudioPCMBuffer(
            pcmFormat: monoFormat,
            frameCapacity: buffer.frameCapacity
        ) else {
            return nil
        }

        monoBuffer.frameLength = buffer.frameLength

        guard let inputData = buffer.floatChannelData,
              let outputData = monoBuffer.floatChannelData else {
            return nil
        }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        for frame in 0..<frameLength {
            var sum: Float = 0
            for channel in 0..<channelCount {
                sum += inputData[channel][frame]
            }
            outputData[0][frame] = sum / Float(channelCount)
        }

        return monoBuffer
    }

    // MARK: - Speech Framework Format Conversion

    /// Converts an AVAudioPCMBuffer to the format required by SpeechAnalyzer
    /// Uses AVAudioConverter following Apple's recommended pattern from WWDC25
    /// Reference: https://developer.apple.com/videos/play/wwdc2025/277/
    /// - Parameters:
    ///   - buffer: The source buffer (any format)
    ///   - targetFormat: The target format from SpeechAnalyzer.bestAvailableAudioFormat
    ///   - converter: A reusable SpeechBufferConverter instance
    /// - Returns: A converted buffer suitable for AnalyzerInput
    static func convertToSpeechFormat(
        _ buffer: AVAudioPCMBuffer,
        targetFormat: AVAudioFormat,
        converter: SpeechBufferConverter
    ) throws -> AVAudioPCMBuffer {
        // Convert to mono first if needed
        let monoBuffer: AVAudioPCMBuffer
        if buffer.format.channelCount > 1 {
            guard let mono = convertToMono(buffer) else {
                throw SpeechBufferConverter.ConversionError.failedToCreateConversionBuffer
            }
            monoBuffer = mono
        } else {
            monoBuffer = buffer
        }

        return try converter.convertBuffer(monoBuffer, to: targetFormat)
    }

    // MARK: - Validation

    /// Validates that an AVAudioPCMBuffer contains valid audio
    /// - Parameter buffer: The buffer to validate
    /// - Returns: True if the buffer contains valid audio data
    static func isValid(_ buffer: AVAudioPCMBuffer) -> Bool {
        buffer.frameLength > 0 &&
        buffer.format.sampleRate > 0 &&
        buffer.format.channelCount > 0
    }
}

// MARK: - Speech Buffer Converter

/// Reusable buffer converter for SpeechAnalyzer following Apple's WWDC25 pattern
/// Reference: https://developer.apple.com/videos/play/wwdc2025/277/
nonisolated final class SpeechBufferConverter: @unchecked Sendable {
    nonisolated enum ConversionError: Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)
    }

    nonisolated(unsafe) private var converter: AVAudioConverter?

    /// Converts an audio buffer to the target format using AVAudioConverter
    /// - Parameters:
    ///   - buffer: The source buffer
    ///   - format: The target format (from SpeechAnalyzer.bestAvailableAudioFormat)
    /// - Returns: A converted buffer
    nonisolated func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format

        // If already in the correct format, return as-is
        guard inputFormat != format else {
            return buffer
        }

        // Create or update converter if needed
        if converter == nil || converter?.inputFormat != inputFormat || converter?.outputFormat != format {
            converter = AVAudioConverter(from: inputFormat, to: format)
            converter?.primeMethod = .none
        }

        guard let converter else {
            throw ConversionError.failedToCreateConverter
        }

        // Calculate output frame capacity based on sample rate ratio
        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))

        guard let conversionBuffer = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: frameCapacity
        ) else {
            throw ConversionError.failedToCreateConversionBuffer
        }

        var nsError: NSError?
        nonisolated(unsafe) var bufferProcessed = false

        // Convert using Apple's recommended input block pattern
        let status = converter.convert(to: conversionBuffer, error: &nsError) { _, inputStatusPointer in
            defer { bufferProcessed = true }
            inputStatusPointer.pointee = bufferProcessed ? .noDataNow : .haveData
            return bufferProcessed ? nil : buffer
        }

        guard status != .error else {
            throw ConversionError.conversionFailed(nsError)
        }

        return conversionBuffer
    }
}
