//
//  AudioSourceInfo.swift
//  Votra
//
//  Model representing a selectable audio source (application or window) for system audio capture.
//

import Foundation
import ScreenCaptureKit

/// Represents an audio source that can be selected for system audio capture
struct AudioSourceInfo: Identifiable, Hashable, Sendable {

    // MARK: - Type Properties

    /// Creates an "All System Audio" option
    static var allSystemAudio: AudioSourceInfo {
        AudioSourceInfo(
            id: "all-system-audio",
            name: String(localized: "All System Audio"),
            bundleIdentifier: nil,
            isAllSystemAudio: true,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )
    }

    // MARK: - Instance Properties

    /// Unique identifier for the audio source
    let id: String

    /// Application name
    let name: String

    /// Bundle identifier of the application (if available)
    let bundleIdentifier: String?

    /// Whether this represents capturing all system audio
    let isAllSystemAudio: Bool

    /// Window ID for window-specific capture (nil for app-level or all system audio)
    let windowID: CGWindowID?

    /// Window title for display (nil for app-level or all system audio)
    let windowTitle: String?

    /// Process ID of the application
    let processID: pid_t?

    /// The application icon (optional, not included in Hashable)
    private let _iconData: Data?

    var iconData: Data? { _iconData }

    /// Display name that includes window title if available
    var displayName: String {
        if isAllSystemAudio {
            return name
        }
        if let windowTitle, !windowTitle.isEmpty {
            return "\(name) - \(windowTitle)"
        }
        return name
    }

    /// Whether this is a window-level source (vs app-level)
    var isWindowLevel: Bool {
        windowID != nil
    }

    // MARK: - Initializer

    init(
        id: String,
        name: String,
        bundleIdentifier: String?,
        isAllSystemAudio: Bool,
        windowID: CGWindowID?,
        windowTitle: String?,
        processID: pid_t?,
        iconData: Data?
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.isAllSystemAudio = isAllSystemAudio
        self.windowID = windowID
        self.windowTitle = windowTitle
        self.processID = processID
        self._iconData = iconData
    }

    // MARK: - Type Methods

    /// Creates an audio source from a ScreenCaptureKit running application (app-level)
    @MainActor
    static func from(_ app: SCRunningApplication) -> AudioSourceInfo {
        AudioSourceInfo(
            id: "app-\(app.processID)",
            name: app.applicationName,
            bundleIdentifier: app.bundleIdentifier,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: app.processID,
            iconData: nil
        )
    }

    /// Creates an audio source from a ScreenCaptureKit window (window-level)
    @MainActor
    static func from(_ window: SCWindow, app: SCRunningApplication?) -> AudioSourceInfo {
        let appName = app?.applicationName ?? window.owningApplication?.applicationName ?? String(localized: "Unknown")
        let bundleId = app?.bundleIdentifier ?? window.owningApplication?.bundleIdentifier
        let pid = app?.processID ?? window.owningApplication?.processID

        return AudioSourceInfo(
            id: "window-\(window.windowID)",
            name: appName,
            bundleIdentifier: bundleId,
            isAllSystemAudio: false,
            windowID: window.windowID,
            windowTitle: window.title,
            processID: pid,
            iconData: nil
        )
    }

    static func == (lhs: AudioSourceInfo, rhs: AudioSourceInfo) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Instance Methods

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
