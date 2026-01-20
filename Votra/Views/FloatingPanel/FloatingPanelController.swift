//
//  FloatingPanelController.swift
//  Votra
//
//  Controller for managing the floating NSPanel for translation overlay.
//

import AppKit
import SwiftUI

/// Controller for managing the floating translation overlay panel
@MainActor
@Observable
final class FloatingPanelController {
    private var panel: NSPanel?

    /// Closure to recreate the panel when needed (with fresh settings)
    var onNeedRecreate: (() -> Void)?

    /// Whether the panel is currently visible
    private(set) var isVisible: Bool = false

    /// The panel's background opacity (0.3 - 1.0)
    /// Note: This only affects the background material, not text
    var opacity: Double = 1.0

    /// The panel's frame
    var frame: NSRect {
        get { panel?.frame ?? .zero }
        set { panel?.setFrame(newValue, display: true, animate: true) }
    }

    // MARK: - Panel Lifecycle

    /// Show the floating panel with the given SwiftUI view
    func showPanel<Content: View>(with content: Content) {
        guard panel == nil else {
            panel?.orderFrontRegardless()
            isVisible = true
            return
        }

        // Get the screen size to position the panel
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)

        // Get size based on current display mode preference and user settings
        let preferences = UserPreferences.shared
        let displayMode = preferences.floatingPanelDisplayMode
        let dynamicHeight: CGFloat
        switch displayMode {
        case .subtitle:
            dynamicHeight = CGFloat(preferences.floatingPanelMinimumHeight)
        case .conversation:
            dynamicHeight = displayMode.recommendedSize.height
        }
        let panelSize = CGSize(width: displayMode.recommendedSize.width, height: dynamicHeight)

        // Position at bottom center of screen
        let panelX = screenFrame.midX - panelSize.width / 2
        let panelY = screenFrame.minY + 60

        let contentRect = NSRect(x: panelX, y: panelY, width: panelSize.width, height: panelSize.height)

        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        // Configure panel behavior
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        panel.isOpaque = false

        // Set fixed minimum size to avoid constraint conflicts
        panel.minSize = NSSize(width: 400, height: 80)

        // Create hosting view for SwiftUI content
        let hostingView = NSHostingView(rootView: content)
        hostingView.sizingOptions = [.minSize, .maxSize]
        panel.contentView = hostingView

        // Show the panel
        panel.orderFrontRegardless()

        // Store reference
        self.panel = panel
        self.isVisible = true

        // Setup close button behavior
        panel.standardWindowButton(.closeButton)?.target = self
        panel.standardWindowButton(.closeButton)?.action = #selector(closePanel)
    }

    /// Close and destroy the floating panel (so it will be recreated with fresh settings)
    @objc
    func closePanel() {
        panel?.close()
        panel = nil
        isVisible = false
    }

    /// Alias for closePanel() - destroys the panel completely
    func destroyPanel() {
        closePanel()
    }

    /// Hide the floating panel without destroying it
    func hidePanel() {
        panel?.orderOut(nil)
        isVisible = false
    }

    /// Toggle panel visibility
    func togglePanel() {
        if isVisible {
            hidePanel()
        } else if let panel = panel {
            panel.orderFrontRegardless()
            isVisible = true
        } else {
            // Panel was destroyed, recreate it
            onNeedRecreate?()
        }
    }

    /// Bring panel to front
    func bringToFront() {
        panel?.orderFrontRegardless()
    }

    // MARK: - Panel Position

    /// Move panel to the right side of the screen
    func moveToRight() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let newX = screenFrame.maxX - panelFrame.width - 20
        let newY = panelFrame.origin.y
        panel.setFrameOrigin(NSPoint(x: newX, y: newY))
    }

    /// Move panel to the left side of the screen
    func moveToLeft() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let newX = screenFrame.minX + 20
        let newY = panel.frame.origin.y
        panel.setFrameOrigin(NSPoint(x: newX, y: newY))
    }

    /// Center the panel on screen
    func center() {
        panel?.center()
    }

    // MARK: - Deinitializer

    deinit {
        MainActor.assumeIsolated {
            panel?.close()
            panel = nil
        }
    }
}
