//
//  AudioCaptureService.swift
//  Votra
//
//  Audio capture service for microphone and system audio sources.
//

@preconcurrency import AVFoundation
import Foundation
import ScreenCaptureKit

// MARK: - Supporting Types

/// State of the audio capture service
nonisolated enum AudioCaptureState: Equatable, Sendable {
    case idle
    case capturingMicrophone
    case capturingSystemAudio
    case capturingBoth
}

/// Represents an audio input device
nonisolated struct AudioDevice: Identifiable, Equatable, Sendable, Hashable {
    let id: String
    let name: String
    let isDefault: Bool
}

/// Permission status for audio capture
nonisolated struct AudioPermissionStatus: Sendable {
    nonisolated enum PermissionState: Sendable {
        case authorized
        case denied
        case notDetermined
    }

    let microphone: PermissionState
    let screenRecording: PermissionState

    var canCaptureMicrophone: Bool {
        microphone == .authorized
    }

    var canCaptureSystemAudio: Bool {
        screenRecording == .authorized
    }
}

// MARK: - Errors

/// Errors that can occur during audio capture
nonisolated enum AudioCaptureError: LocalizedError {
    case microphonePermissionDenied
    case screenRecordingPermissionDenied
    case deviceNotFound
    case captureAlreadyActive
    case engineStartFailed(underlying: Error)
    case invalidAudioFormat

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return String(localized: "Microphone access is required for voice translation")
        case .screenRecordingPermissionDenied:
            return String(localized: "Screen Recording permission is required to capture system audio")
        case .deviceNotFound:
            return String(localized: "Selected audio device is not available")
        case .captureAlreadyActive:
            return String(localized: "Audio capture is already running")
        case .engineStartFailed:
            return String(localized: "Failed to start audio capture engine")
        case .invalidAudioFormat:
            return String(localized: "Audio format is not supported")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return String(localized: "Open System Settings > Privacy & Security > Microphone and enable access for Votra")
        case .screenRecordingPermissionDenied:
            return String(localized: "Open System Settings > Privacy & Security > Screen Recording and enable access for Votra")
        case .deviceNotFound:
            return String(localized: "Please select a different audio input device")
        default:
            return nil
        }
    }
}

// MARK: - Protocol

/// Protocol for audio capture services
@MainActor
protocol AudioCaptureServiceProtocol: Sendable {
    /// Current state of the audio capture
    var state: AudioCaptureState { get }

    /// Currently selected microphone device
    var selectedMicrophone: AudioDevice? { get }

    /// Available microphone devices
    var availableMicrophones: [AudioDevice] { get }

    /// Currently selected audio source for system audio capture
    var selectedAudioSource: AudioSourceInfo { get }

    /// Available audio sources for system audio capture
    var availableAudioSources: [AudioSourceInfo] { get }

    /// Start capturing audio from the specified source (returns raw PCM buffers)
    func startCapture(from source: AudioSource) async throws -> AsyncStream<AVAudioPCMBuffer>

    /// Stop capturing audio from the specified source
    func stopCapture(from source: AudioSource) async

    /// Stop all audio capture
    func stopAllCapture() async

    /// Select a specific microphone device
    func selectMicrophone(_ device: AudioDevice) async throws

    /// Request necessary permissions for audio capture
    func requestPermissions() async -> AudioPermissionStatus

    /// Refresh the list of available audio sources
    func refreshAudioSources() async

    /// Select an audio source for system audio capture
    func selectAudioSource(_ source: AudioSourceInfo)
}

// MARK: - Factory

/// Factory function to create the appropriate AudioCaptureService
/// Uses StubAudioCaptureService on CI to avoid hardware access and process hangs
@MainActor
func createAudioCaptureService() -> any AudioCaptureServiceProtocol {
    // Detect CI environment (GitHub Actions sets CI=true)
    // This allows local tests to use real hardware, but CI uses stub
    if ProcessInfo.processInfo.environment["CI"] == "true" {
        return StubAudioCaptureService()
    }
    return AudioCaptureService()
}

// MARK: - Stub for CI/Testing

/// Stub implementation that doesn't access audio hardware
/// Used in CI environments and unit tests to prevent hangs
@MainActor
@Observable
final class StubAudioCaptureService: AudioCaptureServiceProtocol {
    private(set) var state: AudioCaptureState = .idle
    private(set) var selectedMicrophone: AudioDevice?
    private(set) var availableMicrophones: [AudioDevice] = []
    private(set) var selectedAudioSource: AudioSourceInfo = .allSystemAudio
    private(set) var availableAudioSources: [AudioSourceInfo] = [.allSystemAudio]

    func startCapture(from source: AudioSource) async throws -> AsyncStream<AVAudioPCMBuffer> {
        // Update state without accessing hardware
        switch (state, source) {
        case (.idle, .microphone):
            state = .capturingMicrophone
        case (.idle, .systemAudio):
            state = .capturingSystemAudio
        case (.capturingMicrophone, .systemAudio), (.capturingSystemAudio, .microphone):
            state = .capturingBoth
        default:
            break
        }
        // Return an empty stream that never yields
        return AsyncStream { $0.finish() }
    }

    func stopCapture(from source: AudioSource) async {
        switch (state, source) {
        case (.capturingMicrophone, .microphone), (.capturingSystemAudio, .systemAudio):
            state = .idle
        case (.capturingBoth, .microphone):
            state = .capturingSystemAudio
        case (.capturingBoth, .systemAudio):
            state = .capturingMicrophone
        default:
            break
        }
    }

    func stopAllCapture() async {
        state = .idle
    }

    func selectMicrophone(_ device: AudioDevice) async throws {
        selectedMicrophone = device
    }

    func requestPermissions() async -> AudioPermissionStatus {
        // Return authorized in test environment
        AudioPermissionStatus(microphone: .authorized, screenRecording: .authorized)
    }

    func refreshAudioSources() async {
        // No-op in stub - don't access ScreenCaptureKit
    }

    func selectAudioSource(_ source: AudioSourceInfo) {
        // Match real implementation: only select if source is available
        guard availableAudioSources.contains(source) else { return }
        selectedAudioSource = source
    }
}

// MARK: - Implementation

/// Main audio capture service combining microphone and system audio capture
@MainActor
@Observable
final class AudioCaptureService: AudioCaptureServiceProtocol {
    private(set) var state: AudioCaptureState = .idle
    private(set) var selectedMicrophone: AudioDevice?
    private(set) var availableMicrophones: [AudioDevice] = []

    /// Currently selected audio source for system audio capture
    private(set) var selectedAudioSource: AudioSourceInfo = .allSystemAudio

    /// Available audio sources (applications) for system audio capture
    private(set) var availableAudioSources: [AudioSourceInfo] = [.allSystemAudio]

    // Use optionals with explicit initialization to avoid audio hardware access during tests
    @ObservationIgnored private var _microphoneCapture: MicrophoneAudioCapture?
    @ObservationIgnored private var _systemAudioCapture: SystemAudioCapture?

    private var microphoneCapture: MicrophoneAudioCapture {
        if let existing = _microphoneCapture {
            return existing
        }
        let capture = MicrophoneAudioCapture()
        _microphoneCapture = capture
        return capture
    }

    private var systemAudioCapture: SystemAudioCapture {
        if let existing = _systemAudioCapture {
            return existing
        }
        let capture = SystemAudioCapture()
        _systemAudioCapture = capture
        return capture
    }

    private var hasRefreshedMicrophones = false

    init() {
        // Don't automatically refresh microphones - let caller trigger this
        // to avoid audio hardware access during initialization
    }

    /// Ensure microphone list is loaded (call before using availableMicrophones)
    func ensureMicrophonesLoaded() async {
        guard !hasRefreshedMicrophones else { return }
        hasRefreshedMicrophones = true
        await refreshMicrophoneList()
    }

    func startCapture(from source: AudioSource) async throws -> AsyncStream<AVAudioPCMBuffer> {
        switch source {
        case .microphone:
            return try await startMicrophoneCapture()
        case .systemAudio:
            return try await startSystemAudioCapture()
        }
    }

    func stopCapture(from source: AudioSource) async {
        switch source {
        case .microphone:
            await stopMicrophoneCapture()
        case .systemAudio:
            await stopSystemAudioCapture()
        }
    }

    func stopAllCapture() async {
        await stopMicrophoneCapture()
        await stopSystemAudioCapture()
    }

    func selectMicrophone(_ device: AudioDevice) async throws {
        guard availableMicrophones.contains(device) else {
            throw AudioCaptureError.deviceNotFound
        }
        selectedMicrophone = device
        try await microphoneCapture.selectDevice(device.id)
    }

    func requestPermissions() async -> AudioPermissionStatus {
        let micStatus = await requestMicrophonePermission()
        let screenStatus = await checkScreenRecordingPermission()

        return AudioPermissionStatus(
            microphone: micStatus,
            screenRecording: screenStatus
        )
    }

    // MARK: - Audio Source Selection

    /// Refresh the list of available audio sources
    func refreshAudioSources() async {
        do {
            availableAudioSources = try await systemAudioCapture.getAvailableAudioSources()
            // Ensure selected source is still valid
            if !availableAudioSources.contains(selectedAudioSource) {
                selectedAudioSource = .allSystemAudio
            }
        } catch {
            // Keep current list if refresh fails
            availableAudioSources = [.allSystemAudio]
        }
    }

    /// Select an audio source for system audio capture
    func selectAudioSource(_ source: AudioSourceInfo) {
        guard availableAudioSources.contains(source) else { return }
        selectedAudioSource = source
        systemAudioCapture.selectedSource = source.isAllSystemAudio ? nil : source
    }

    // MARK: - Private Methods

    private func startMicrophoneCapture() async throws -> AsyncStream<AVAudioPCMBuffer> {
        let permissions = await requestPermissions()
        guard permissions.canCaptureMicrophone else {
            throw AudioCaptureError.microphonePermissionDenied
        }

        updateState(addingSource: .microphone)

        // Return the raw PCM stream directly
        return try await microphoneCapture.startCapture()
    }

    private func startSystemAudioCapture() async throws -> AsyncStream<AVAudioPCMBuffer> {
        let permissions = await requestPermissions()
        guard permissions.canCaptureSystemAudio else {
            throw AudioCaptureError.screenRecordingPermissionDenied
        }

        updateState(addingSource: .systemAudio)

        // Return the raw PCM stream directly
        return try await systemAudioCapture.startCapture()
    }

    private func stopMicrophoneCapture() async {
        await microphoneCapture.stopCapture()
        updateState(removingSource: .microphone)
    }

    private func stopSystemAudioCapture() async {
        await systemAudioCapture.stopCapture()
        updateState(removingSource: .systemAudio)
    }

    private func updateState(addingSource source: AudioSource) {
        switch (state, source) {
        case (.idle, .microphone):
            state = .capturingMicrophone
        case (.idle, .systemAudio):
            state = .capturingSystemAudio
        case (.capturingMicrophone, .systemAudio), (.capturingSystemAudio, .microphone):
            state = .capturingBoth
        default:
            break
        }
    }

    private func updateState(removingSource source: AudioSource) {
        switch (state, source) {
        case (.capturingMicrophone, .microphone), (.capturingSystemAudio, .systemAudio):
            state = .idle
        case (.capturingBoth, .microphone):
            state = .capturingSystemAudio
        case (.capturingBoth, .systemAudio):
            state = .capturingMicrophone
        default:
            break
        }
    }

    private func refreshMicrophoneList() async {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        ).devices

        availableMicrophones = devices.map { device in
            AudioDevice(
                id: device.uniqueID,
                name: device.localizedName,
                isDefault: device.uniqueID == AVCaptureDevice.default(for: .audio)?.uniqueID
            )
        }

        if selectedMicrophone == nil {
            selectedMicrophone = availableMicrophones.first { $0.isDefault }
        }
    }

    private func requestMicrophonePermission() async -> AudioPermissionStatus.PermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            return granted ? .authorized : .denied
        @unknown default:
            return .notDetermined
        }
    }

    private func checkScreenRecordingPermission() async -> AudioPermissionStatus.PermissionState {
        if CGPreflightScreenCaptureAccess() {
            return .authorized
        }

        // Try to request access
        let granted = CGRequestScreenCaptureAccess()
        return granted ? .authorized : .denied
    }
}

// MARK: - Microphone Tap Handler

/// Completely isolated handler for AVAudioEngine tap callbacks
/// This class has NO Swift concurrency involvement to avoid actor isolation checks
/// on the realtime audio thread
private final class MicrophoneTapHandler: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var _continuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    nonisolated(unsafe) private var _bufferCount: Int = 0

    nonisolated func setContinuation(_ cont: AsyncStream<AVAudioPCMBuffer>.Continuation?) {
        lock.lock()
        defer { lock.unlock() }
        _continuation = cont
    }

    /// The tap callback - completely synchronous, no actor isolation
    /// This is called on the realtime audio thread
    /// MUST be nonisolated to avoid actor isolation checks
    nonisolated func handleBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        lock.lock()
        _bufferCount += 1
        let count = _bufferCount
        let cont = _continuation
        lock.unlock()

        if count % 50 == 1 {
            print("[Votra] [MICROPHONE] Buffer count: \(count), frames: \(buffer.frameLength)")
        }

        cont?.yield(buffer)
    }

    nonisolated func finish() {
        lock.lock()
        _continuation?.finish()
        _continuation = nil
        lock.unlock()
    }
}

// MARK: - Microphone Audio Capture

/// Internal class for microphone audio capture using AVAudioEngine
/// NOT MainActor - audio tap callbacks run on realtime audio threads
final class MicrophoneAudioCapture: @unchecked Sendable {
    private var engine: AVAudioEngine?
    private var isCapturing = false
    private var selectedDeviceID: String?
    private var tapHandler: MicrophoneTapHandler?

    func selectDevice(_ deviceID: String) async throws {
        selectedDeviceID = deviceID
    }

    func startCapture() async throws -> AsyncStream<AVAudioPCMBuffer> {
        guard !isCapturing else {
            throw AudioCaptureError.captureAlreadyActive
        }

        // Reset any existing engine
        if let existingEngine = engine, existingEngine.isRunning {
            existingEngine.stop()
        }
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        tapHandler = nil

        // Small delay to ensure audio system is ready
        try? await Task.sleep(for: .milliseconds(100))

        // Create a fresh engine for each capture session
        let audioEngine = AVAudioEngine()
        self.engine = audioEngine

        // Access inputNode and format
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        print("[Votra] Microphone input format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")

        // Validate input format
        guard recordingFormat.channelCount > 0, recordingFormat.sampleRate > 0 else {
            throw AudioCaptureError.deviceNotFound
        }

        // Create the tap handler - completely isolated from Swift concurrency
        let handler = MicrophoneTapHandler()
        self.tapHandler = handler

        // Install tap using the isolated handler
        // The handler's callback is pure synchronous code with no actor checks
        // Mark closure as @Sendable to prevent actor isolation inference
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { @Sendable [handler] buffer, time in
            handler.handleBuffer(buffer, time: time)
        }

        // Prepare engine
        audioEngine.prepare()

        // Start engine
        do {
            try audioEngine.start()
            print("[Votra] Audio engine started successfully")
        } catch {
            print("[Votra] Failed to start audio engine: \(error)")
            inputNode.removeTap(onBus: 0)
            self.engine = nil
            self.tapHandler = nil
            throw AudioCaptureError.engineStartFailed(underlying: error)
        }

        isCapturing = true

        // Create AsyncStream with unbounded buffering
        return AsyncStream<AVAudioPCMBuffer>(bufferingPolicy: .unbounded) { continuation in
            handler.setContinuation(continuation)

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    await self?.stopCapture()
                }
            }
        }
    }

    func stopCapture() async {
        guard isCapturing else { return }
        isCapturing = false

        tapHandler?.finish()

        if let engine = engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            print("[Votra] Audio engine stopped")
        }

        engine = nil
        tapHandler = nil
    }
}

// MARK: - System Audio Capture

/// Internal class for system audio capture using ScreenCaptureKit
@MainActor
final class SystemAudioCapture: @unchecked Sendable {
    private var stream: SCStream?
    private var isCapturing = false
    private var streamOutput: AudioStreamOutputHandler?
    private var videoOutput: VideoStreamOutputHandler?
    private var streamDelegate: StreamDelegate?

    /// Dedicated serial queue for audio processing - MUST be serial, not concurrent
    private let audioQueue = DispatchQueue(label: "app.votra.systemAudioCapture")

    /// Currently selected audio source (nil means all system audio)
    var selectedSource: AudioSourceInfo?

    /// Get available audio sources (windows with meaningful titles)
    func getAvailableAudioSources() async throws -> [AudioSourceInfo] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        var sources: [AudioSourceInfo] = [.allSystemAudio]

        // Get our own bundle ID to exclude
        let ourBundleId = Bundle.main.bundleIdentifier

        // Build a map of apps by bundle ID for quick lookup
        var appsByBundleId: [String: SCRunningApplication] = [:]
        for app in content.applications {
            appsByBundleId[app.bundleIdentifier] = app
        }

        // Add windows that have meaningful titles (these are typically main windows)
        for window in content.windows {
            guard let owningApp = window.owningApplication else { continue }

            // Skip our own app
            if owningApp.bundleIdentifier == ourBundleId {
                continue
            }

            // Skip windows without titles or with empty titles (usually utility windows)
            guard let title = window.title, !title.isEmpty else { continue }

            // Skip very small windows (likely status bar items or popups)
            guard window.frame.width > 100 && window.frame.height > 100 else { continue }

            let app = appsByBundleId[owningApp.bundleIdentifier]
            sources.append(AudioSourceInfo.from(window, app: app))
        }

        return sources
    }

    func startCapture() async throws -> AsyncStream<AVAudioPCMBuffer> {
        guard !isCapturing else {
            throw AudioCaptureError.captureAlreadyActive
        }

        isCapturing = true

        // Get shareable content
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            print("[Votra] Got shareable content: \(content.displays.count) displays, \(content.applications.count) apps")
        } catch {
            print("[Votra] Failed to get shareable content: \(error)")
            isCapturing = false
            throw AudioCaptureError.screenRecordingPermissionDenied
        }

        let filter: SCContentFilter

        if let source = selectedSource, !source.isAllSystemAudio {
            if let windowID = source.windowID {
                // Window-specific filter
                if let window = content.windows.first(where: { $0.windowID == windowID }) {
                    filter = SCContentFilter(desktopIndependentWindow: window)
                    print("[Votra] Created filter for window: \(source.displayName) (ID: \(windowID))")
                } else {
                    print("[Votra] Window not found: \(windowID)")
                    isCapturing = false
                    throw AudioCaptureError.deviceNotFound
                }
            } else if let bundleId = source.bundleIdentifier {
                // App-level filter (fallback for older sources)
                if let app = content.applications.first(where: { $0.bundleIdentifier == bundleId }) {
                    if let display = content.displays.first {
                        filter = SCContentFilter(display: display, including: [app], exceptingWindows: [])
                        print("[Votra] Created filter for app: \(app.applicationName)")
                    } else {
                        print("[Votra] No display found for app filter")
                        isCapturing = false
                        throw AudioCaptureError.deviceNotFound
                    }
                } else {
                    print("[Votra] App not found: \(bundleId)")
                    isCapturing = false
                    throw AudioCaptureError.deviceNotFound
                }
            } else {
                print("[Votra] Invalid source: no windowID or bundleIdentifier")
                isCapturing = false
                throw AudioCaptureError.deviceNotFound
            }
        } else {
            // Capture all system audio
            guard let display = content.displays.first else {
                print("[Votra] No display available")
                isCapturing = false
                throw AudioCaptureError.deviceNotFound
            }
            filter = SCContentFilter(display: display, excludingWindows: [])
            print("[Votra] Created filter for all system audio on display: \(display.displayID)")
        }

        // Configure the stream for audio-only capture
        // Based on: https://github.com/O4FDev/electron-system-audio-recorder
        let config = SCStreamConfiguration()

        // Minimal video settings (we need a video handler to avoid warnings)
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(seconds: 3600, preferredTimescale: 1) // 1 frame per hour
        config.showsCursor = false

        // Audio settings
        config.capturesAudio = true
        config.sampleRate = 48000  // Standard sample rate
        config.channelCount = 2     // Stereo
        config.excludesCurrentProcessAudio = true

        // Create delegate for error handling
        let delegate = StreamDelegate()
        self.streamDelegate = delegate

        // Create the stream with delegate
        let stream = SCStream(filter: filter, configuration: config, delegate: delegate)
        self.stream = stream

        // Create output handler with continuation holder
        let continuationHolder = ContinuationHolder<AVAudioPCMBuffer>()
        let output = AudioStreamOutputHandler { buffer in
            continuationHolder.continuation?.yield(buffer)
        }
        self.streamOutput = output

        // Add audio output - use nil for default queue as per Apple docs
        do {
            try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: nil)
            print("[Votra] Added audio output handler")
        } catch {
            print("[Votra] Failed to add stream output: \(error)")
            isCapturing = false
            throw AudioCaptureError.engineStartFailed(underlying: error)
        }

        // Add video output handler to prevent "stream output NOT found" warnings
        // This handler discards all video frames since we only need audio
        let videoHandler = VideoStreamOutputHandler()
        self.videoOutput = videoHandler
        do {
            try stream.addStreamOutput(videoHandler, type: .screen, sampleHandlerQueue: nil)
            print("[Votra] Added video output handler (discarding frames)")
        } catch {
            // Video output is not critical - continue without it
            print("[Votra] Failed to add video output handler: \(error)")
        }

        // Start capture
        do {
            try await stream.startCapture()
            print("[Votra] Stream capture started successfully")
        } catch {
            print("[Votra] Failed to start stream capture: \(error)")
            isCapturing = false
            self.stream = nil
            self.streamOutput = nil

            let nsError = error as NSError
            if nsError.domain == "CoreGraphicsErrorDomain" && nsError.code == 1003 {
                print("[Votra] Error 1003 - try removing and re-adding app from Screen Recording permissions")
                throw AudioCaptureError.screenRecordingPermissionDenied
            }
            throw AudioCaptureError.engineStartFailed(underlying: error)
        }

        // Create and return the AsyncStream
        return AsyncStream<AVAudioPCMBuffer> { continuation in
            continuationHolder.continuation = continuation

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    await self?.stopCapture()
                }
            }
        }
    }

    func stopCapture() async {
        guard isCapturing else { return }
        isCapturing = false

        if let stream = stream {
            if let output = streamOutput {
                do {
                    try stream.removeStreamOutput(output, type: .audio)
                } catch {
                    // Ignore removal errors
                }
            }

            if let videoOutput = videoOutput {
                do {
                    try stream.removeStreamOutput(videoOutput, type: .screen)
                } catch {
                    // Ignore removal errors
                }
            }

            do {
                try await stream.stopCapture()
            } catch {
                // Ignore stop errors
            }
        }

        stream = nil
        streamOutput = nil
        videoOutput = nil
        streamDelegate = nil
        print("[Votra] System audio capture stopped")
    }
}

// MARK: - Stream Delegate

/// Delegate for SCStream error and state change handling
final class StreamDelegate: NSObject, SCStreamDelegate, @unchecked Sendable {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("[Votra] SCStream stopped with error: \(error)")
    }
}

/// Thread-safe holder for AsyncStream continuation
private final class ContinuationHolder<T: Sendable>: @unchecked Sendable {
    nonisolated(unsafe) var continuation: AsyncStream<T>.Continuation?
}

// MARK: - Audio Stream Output

/// SCStreamOutput implementation for handling audio samples
/// Uses simple, synchronous processing to avoid queue issues
final class AudioStreamOutputHandler: NSObject, SCStreamOutput, @unchecked Sendable {
    // MARK: - Subtypes

    /// Audio format description for conversion
    private struct AudioFormatInfo {
        let isFloat: Bool
        let isInterleaved: Bool
        let bytesPerSample: Int
    }

    // MARK: - Instance Properties

    private let handler: @Sendable (AVAudioPCMBuffer) -> Void
    nonisolated(unsafe) private var hasLoggedFormat = false
    nonisolated(unsafe) private var bufferCount = 0

    // MARK: - Initializers

    init(handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        self.handler = handler
        super.init()
    }

    // MARK: - Instance Methods

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Only process audio samples
        guard type == .audio else { return }

        // Convert and process synchronously
        guard let pcmBuffer = convertToPCMBuffer(sampleBuffer) else {
            return
        }

        bufferCount += 1
        if bufferCount % 50 == 1 {
            print("[Votra] [SYSTEM_AUDIO] Buffer count: \(bufferCount), frames: \(pcmBuffer.frameLength)")
        }

        handler(pcmBuffer)
    }

    /// Convert CMSampleBuffer to AVAudioPCMBuffer
    /// ScreenCaptureKit outputs interleaved audio, but AVAudioPCMBuffer uses planar format
    nonisolated private func convertToPCMBuffer(_ sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        // Validate and extract format description
        guard CMSampleBufferDataIsReady(sampleBuffer),
              let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return nil
        }

        let asbd = asbdPtr.pointee
        logAudioFormatOnce(asbd)

        // Get sample count and data
        let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard frameCount > 0,
              let srcData = extractAudioData(from: sampleBuffer, asbd: asbd, frameCount: frameCount) else {
            return nil
        }

        // Create output buffer
        let channelCount = Int(asbd.mChannelsPerFrame)
        guard let pcmBuffer = createOutputBuffer(sampleRate: asbd.mSampleRate, channelCount: channelCount, frameCount: frameCount),
              let floatChannelData = pcmBuffer.floatChannelData else {
            return nil
        }

        // Convert based on source format
        let formatInfo = AudioFormatInfo(
            isFloat: (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0,
            isInterleaved: (asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0,
            bytesPerSample: Int(asbd.mBitsPerChannel / 8)
        )

        let success = convertAudioSamples(
            srcData: srcData,
            floatChannelData: floatChannelData,
            frameCount: frameCount,
            channelCount: channelCount,
            format: formatInfo
        )

        return success ? pcmBuffer : nil
    }

    /// Log audio format details once
    nonisolated private func logAudioFormatOnce(_ asbd: AudioStreamBasicDescription) {
        guard !hasLoggedFormat else { return }
        hasLoggedFormat = true

        let isFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        let isInterleaved = (asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0
        let isPacked = (asbd.mFormatFlags & kAudioFormatFlagIsPacked) != 0
        let isBigEndian = (asbd.mFormatFlags & kAudioFormatFlagIsBigEndian) != 0

        print("[Votra] System audio format details:")
        print("  - Sample rate: \(asbd.mSampleRate)Hz")
        print("  - Channels: \(asbd.mChannelsPerFrame)")
        print("  - Bits per channel: \(asbd.mBitsPerChannel)")
        print("  - Bytes per frame: \(asbd.mBytesPerFrame)")
        print("  - Bytes per packet: \(asbd.mBytesPerPacket)")
        print("  - Frames per packet: \(asbd.mFramesPerPacket)")
        print("  - Format flags: 0x\(String(asbd.mFormatFlags, radix: 16))")
        print("  - Is float: \(isFloat), interleaved: \(isInterleaved), packed: \(isPacked), big endian: \(isBigEndian)")
    }

    /// Extract raw audio data from sample buffer
    nonisolated private func extractAudioData(
        from sampleBuffer: CMSampleBuffer,
        asbd: AudioStreamBasicDescription,
        frameCount: Int
    ) -> UnsafeMutablePointer<CChar>? {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }

        var length = 0
        var dataPointer: UnsafeMutablePointer<CChar>?
        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr, let srcData = dataPointer else { return nil }

        // Verify data length matches expected
        let expectedLength = frameCount * Int(asbd.mBytesPerFrame)
        if length != expectedLength && bufferCount < 5 {
            print("[Votra] Warning: Data length mismatch - got \(length), expected \(expectedLength)")
        }

        return srcData
    }

    /// Create output PCM buffer with standard planar float format
    nonisolated private func createOutputBuffer(
        sampleRate: Float64,
        channelCount: Int,
        frameCount: Int
    ) -> AVAudioPCMBuffer? {
        guard let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: AVAudioChannelCount(channelCount)
        ) else {
            return nil
        }

        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            return nil
        }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)
        return pcmBuffer
    }

    /// Convert audio samples from source format to planar float
    nonisolated private func convertAudioSamples(
        srcData: UnsafeMutablePointer<CChar>,
        floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameCount: Int,
        channelCount: Int,
        format: AudioFormatInfo
    ) -> Bool {
        if format.isFloat && format.bytesPerSample == 4 {
            convertFloat32Samples(srcData, floatChannelData, frameCount, channelCount, format.isInterleaved)
            return true
        } else if !format.isFloat && format.bytesPerSample == 2 {
            convertInt16Samples(srcData, floatChannelData, frameCount, channelCount, format.isInterleaved)
            return true
        } else if !format.isFloat && format.bytesPerSample == 4 {
            convertInt32Samples(srcData, floatChannelData, frameCount, channelCount, format.isInterleaved)
            return true
        } else {
            print("[Votra] Unknown audio format: isFloat=\(format.isFloat), bytesPerSample=\(format.bytesPerSample)")
            return false
        }
    }

    /// Convert 32-bit float samples
    nonisolated private func convertFloat32Samples(
        _ srcData: UnsafeMutablePointer<CChar>,
        _ floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>,
        _ frameCount: Int,
        _ channelCount: Int,
        _ isInterleaved: Bool
    ) {
        let srcFloatPtr = UnsafeRawPointer(srcData).assumingMemoryBound(to: Float.self)
        if isInterleaved {
            for frame in 0..<frameCount {
                for channel in 0..<channelCount {
                    floatChannelData[channel][frame] = srcFloatPtr[frame * channelCount + channel]
                }
            }
        } else {
            for channel in 0..<channelCount {
                memcpy(floatChannelData[channel], srcFloatPtr + channel * frameCount, frameCount * MemoryLayout<Float>.size)
            }
        }
    }

    /// Convert 16-bit integer samples to float
    nonisolated private func convertInt16Samples(
        _ srcData: UnsafeMutablePointer<CChar>,
        _ floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>,
        _ frameCount: Int,
        _ channelCount: Int,
        _ isInterleaved: Bool
    ) {
        let srcInt16Ptr = UnsafeRawPointer(srcData).assumingMemoryBound(to: Int16.self)
        let scale = Float(Int16.max)
        if isInterleaved {
            for frame in 0..<frameCount {
                for channel in 0..<channelCount {
                    floatChannelData[channel][frame] = Float(srcInt16Ptr[frame * channelCount + channel]) / scale
                }
            }
        } else {
            for channel in 0..<channelCount {
                for frame in 0..<frameCount {
                    floatChannelData[channel][frame] = Float(srcInt16Ptr[channel * frameCount + frame]) / scale
                }
            }
        }
    }

    /// Convert 32-bit integer samples to float
    nonisolated private func convertInt32Samples(
        _ srcData: UnsafeMutablePointer<CChar>,
        _ floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>,
        _ frameCount: Int,
        _ channelCount: Int,
        _ isInterleaved: Bool
    ) {
        let srcInt32Ptr = UnsafeRawPointer(srcData).assumingMemoryBound(to: Int32.self)
        let scale = Float(Int32.max)
        if isInterleaved {
            for frame in 0..<frameCount {
                for channel in 0..<channelCount {
                    floatChannelData[channel][frame] = Float(srcInt32Ptr[frame * channelCount + channel]) / scale
                }
            }
        } else {
            for channel in 0..<channelCount {
                for frame in 0..<frameCount {
                    floatChannelData[channel][frame] = Float(srcInt32Ptr[channel * frameCount + frame]) / scale
                }
            }
        }
    }
}

// MARK: - Video Stream Output Handler

/// Dummy SCStreamOutput implementation for handling video samples
/// This handler exists solely to prevent "stream output NOT found" warnings
/// All video frames are silently discarded since we only need audio
final class VideoStreamOutputHandler: NSObject, SCStreamOutput, @unchecked Sendable {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Intentionally empty - discard all video frames
        // This prevents ScreenCaptureKit from logging "stream output NOT found" warnings
    }
}
