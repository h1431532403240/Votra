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

    /// Whether the panel is currently visible
    private(set) var isVisible: Bool = false

    /// The panel's opacity (0.3 - 1.0)
    var opacity: Double = 1.0 {
        didSet {
            panel?.alphaValue = CGFloat(opacity)
        }
    }

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

        // Default size and position (right side of screen)
        let panelWidth: CGFloat = 400
        let panelHeight: CGFloat = 600
        let panelX = screenFrame.maxX - panelWidth - 20
        let panelY = screenFrame.midY - panelHeight / 2

        let contentRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)

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
        panel.alphaValue = CGFloat(opacity)

        // Set minimum size
        panel.minSize = NSSize(width: 300, height: 400)

        // Create hosting view for SwiftUI content
        let hostingView = NSHostingView(rootView: content)
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

    /// Hide the floating panel
    @objc
    func closePanel() {
        panel?.orderOut(nil)
        isVisible = false
    }

    /// Destroy the panel completely
    func destroyPanel() {
        panel?.close()
        panel = nil
        isVisible = false
    }

    /// Toggle panel visibility
    func togglePanel() {
        if isVisible {
            closePanel()
        } else if let panel = panel {
            panel.orderFrontRegardless()
            isVisible = true
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
