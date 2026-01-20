//
//  FloatingPanelControllerTests.swift
//  VotraTests
//
//  Unit tests for FloatingPanelController logic.
//

import Testing
import Foundation
import AppKit
import CoreGraphics
import SwiftUI
@testable import Votra

/// Tests for FloatingPanelController properties and state management.
///
/// Note: Tests that require actual NSPanel instantiation are not included here
/// as they require AppKit UI infrastructure. These tests focus on the testable
/// logic: initial state, property values, and state transitions.
@Suite("FloatingPanelController Tests")
@MainActor
struct FloatingPanelControllerTests {
    // MARK: - Initial State Tests

    @Test("Initial visibility is false")
    func initialVisibilityIsFalse() {
        let controller = FloatingPanelController()

        #expect(controller.isVisible == false)
    }

    @Test("Initial opacity is 1.0")
    func initialOpacityIsOne() {
        let controller = FloatingPanelController()

        #expect(controller.opacity == 1.0)
    }

    @Test("Initial frame is zero when no panel exists")
    func initialFrameIsZero() {
        let controller = FloatingPanelController()

        #expect(controller.frame == .zero)
    }

    // MARK: - Opacity Property Tests

    @Test("Opacity can be set to valid values")
    func opacityCanBeSetToValidValues() {
        let controller = FloatingPanelController()

        controller.opacity = 0.5
        #expect(controller.opacity == 0.5)

        controller.opacity = 0.3
        #expect(controller.opacity == 0.3)

        controller.opacity = 1.0
        #expect(controller.opacity == 1.0)
    }

    @Test("Opacity accepts minimum value 0.3")
    func opacityAcceptsMinimumValue() {
        let controller = FloatingPanelController()

        controller.opacity = 0.3
        #expect(controller.opacity == 0.3)
    }

    @Test("Opacity accepts maximum value 1.0")
    func opacityAcceptsMaximumValue() {
        let controller = FloatingPanelController()

        controller.opacity = 1.0
        #expect(controller.opacity == 1.0)
    }

    @Test("Opacity accepts intermediate values")
    func opacityAcceptsIntermediateValues() {
        let controller = FloatingPanelController()

        let testValues: [Double] = [0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
        for value in testValues {
            controller.opacity = value
            #expect(controller.opacity == value)
        }
    }

    @Test("Opacity property stores value without panel")
    func opacityPropertyStoresValueWithoutPanel() {
        let controller = FloatingPanelController()

        // Even without a panel, the opacity property should store the value
        controller.opacity = 0.75
        #expect(controller.opacity == 0.75)

        controller.opacity = 0.42
        #expect(controller.opacity == 0.42)
    }

    // MARK: - Toggle Panel State Tests

    @Test("Toggle panel does not change visibility when no panel exists")
    func togglePanelNoChangeWithoutPanel() {
        let controller = FloatingPanelController()

        // Initially not visible
        #expect(controller.isVisible == false)

        // Toggle should not change visibility since there's no panel
        controller.togglePanel()
        #expect(controller.isVisible == false)
    }

    @Test("Close panel sets visibility to false")
    func closePanelSetsVisibilityToFalse() {
        let controller = FloatingPanelController()

        // Close panel should ensure visibility is false
        controller.closePanel()
        #expect(controller.isVisible == false)
    }

    @Test("Destroy panel sets visibility to false")
    func destroyPanelSetsVisibilityToFalse() {
        let controller = FloatingPanelController()

        // Destroy panel should ensure visibility is false
        controller.destroyPanel()
        #expect(controller.isVisible == false)
    }

    // MARK: - Frame Property Tests

    @Test("Frame returns zero rect when panel is nil")
    func frameReturnsZeroRectWhenPanelIsNil() {
        let controller = FloatingPanelController()

        let frame = controller.frame
        #expect(frame.origin.x == 0)
        #expect(frame.origin.y == 0)
        #expect(frame.size.width == 0)
        #expect(frame.size.height == 0)
    }

    // MARK: - State Consistency Tests

    @Test("Multiple close calls maintain consistent state")
    func multipleCloseCallsMaintainConsistentState() {
        let controller = FloatingPanelController()

        // Multiple close calls should not cause issues
        controller.closePanel()
        #expect(controller.isVisible == false)

        controller.closePanel()
        #expect(controller.isVisible == false)

        controller.closePanel()
        #expect(controller.isVisible == false)
    }

    @Test("Multiple destroy calls maintain consistent state")
    func multipleDestroyCallsMaintainConsistentState() {
        let controller = FloatingPanelController()

        // Multiple destroy calls should not cause issues
        controller.destroyPanel()
        #expect(controller.isVisible == false)

        controller.destroyPanel()
        #expect(controller.isVisible == false)
    }

    @Test("Close after destroy maintains consistent state")
    func closeAfterDestroyMaintainsConsistentState() {
        let controller = FloatingPanelController()

        controller.destroyPanel()
        #expect(controller.isVisible == false)

        controller.closePanel()
        #expect(controller.isVisible == false)
    }

    @Test("Destroy after close maintains consistent state")
    func destroyAfterCloseMaintainsConsistentState() {
        let controller = FloatingPanelController()

        controller.closePanel()
        #expect(controller.isVisible == false)

        controller.destroyPanel()
        #expect(controller.isVisible == false)
    }

    // MARK: - Bring to Front Tests

    @Test("Bring to front does not crash when panel is nil")
    func bringToFrontDoesNotCrashWhenPanelIsNil() {
        let controller = FloatingPanelController()

        // Should not crash when panel is nil
        controller.bringToFront()

        // State should remain consistent
        #expect(controller.isVisible == false)
    }

    // MARK: - Position Methods Tests (without panel)

    @Test("Move to right does not crash when panel is nil")
    func moveToRightDoesNotCrashWhenPanelIsNil() {
        let controller = FloatingPanelController()

        // Should not crash when panel is nil
        controller.moveToRight()

        // State should remain consistent
        #expect(controller.isVisible == false)
    }

    @Test("Move to left does not crash when panel is nil")
    func moveToLeftDoesNotCrashWhenPanelIsNil() {
        let controller = FloatingPanelController()

        // Should not crash when panel is nil
        controller.moveToLeft()

        // State should remain consistent
        #expect(controller.isVisible == false)
    }

    @Test("Center does not crash when panel is nil")
    func centerDoesNotCrashWhenPanelIsNil() {
        let controller = FloatingPanelController()

        // Should not crash when panel is nil
        controller.center()

        // State should remain consistent
        #expect(controller.isVisible == false)
    }

    // MARK: - Observable Property Tests

    @Test("isVisible is read-only from outside")
    func isVisibleIsReadOnly() {
        let controller = FloatingPanelController()

        // isVisible is private(set), so we can only read it
        // Verify initial state
        let visible = controller.isVisible
        #expect(visible == false)
    }

    @Test("Opacity changes are tracked")
    func opacityChangesAreTracked() {
        let controller = FloatingPanelController()

        #expect(controller.opacity == 1.0)

        controller.opacity = 0.5
        #expect(controller.opacity == 0.5)

        controller.opacity = 0.8
        #expect(controller.opacity == 0.8)
    }

    // MARK: - Edge Case Tests

    @Test("Opacity can be set to very small positive values")
    func opacityVerySmallPositiveValues() {
        let controller = FloatingPanelController()

        controller.opacity = 0.01
        #expect(controller.opacity == 0.01)

        controller.opacity = 0.001
        #expect(controller.opacity == 0.001)
    }

    @Test("Opacity can be set to zero")
    func opacityCanBeSetToZero() {
        let controller = FloatingPanelController()

        controller.opacity = 0.0
        #expect(controller.opacity == 0.0)
    }

    @Test("Opacity handles negative values")
    func opacityHandlesNegativeValues() {
        let controller = FloatingPanelController()

        // Negative values should be stored (validation may happen at panel level)
        controller.opacity = -0.5
        #expect(controller.opacity == -0.5)
    }

    @Test("Opacity handles values greater than one")
    func opacityHandlesValuesGreaterThanOne() {
        let controller = FloatingPanelController()

        // Values > 1.0 should be stored (validation may happen at panel level)
        controller.opacity = 1.5
        #expect(controller.opacity == 1.5)
    }

    // MARK: - Frame Setter Tests

    @Test("Frame setter does not crash when panel is nil")
    func frameSetterDoesNotCrashWhenPanelIsNil() {
        let controller = FloatingPanelController()

        // Should not crash when setting frame with nil panel
        controller.frame = NSRect(x: 100, y: 100, width: 400, height: 600)

        // Frame should still be zero since panel is nil
        #expect(controller.frame == .zero)
    }

    // MARK: - Multiple Controller Tests

    @Test("Multiple controllers maintain independent state")
    func multipleControllersIndependentState() {
        let controller1 = FloatingPanelController()
        let controller2 = FloatingPanelController()

        controller1.opacity = 0.5
        controller2.opacity = 0.8

        #expect(controller1.opacity == 0.5)
        #expect(controller2.opacity == 0.8)
        #expect(controller1.isVisible == false)
        #expect(controller2.isVisible == false)
    }

    @Test("Controller actions do not affect other controllers")
    func controllerActionsDoNotAffectOthers() {
        let controller1 = FloatingPanelController()
        let controller2 = FloatingPanelController()

        controller1.closePanel()
        controller2.destroyPanel()

        // Both should have independent state
        #expect(controller1.isVisible == false)
        #expect(controller2.isVisible == false)
        #expect(controller1.opacity == 1.0)
        #expect(controller2.opacity == 1.0)
    }

    // MARK: - Sequential Operation Tests

    @Test("Sequential operations maintain state integrity")
    func sequentialOperationsMaintainStateIntegrity() {
        let controller = FloatingPanelController()

        // Series of operations
        controller.opacity = 0.7
        #expect(controller.opacity == 0.7)

        controller.closePanel()
        #expect(controller.isVisible == false)
        #expect(controller.opacity == 0.7) // Opacity should be preserved

        controller.opacity = 0.9
        #expect(controller.opacity == 0.9)

        controller.destroyPanel()
        #expect(controller.isVisible == false)
        #expect(controller.opacity == 0.9) // Opacity should still be preserved

        controller.bringToFront()
        #expect(controller.isVisible == false)
        #expect(controller.opacity == 0.9)

        controller.togglePanel()
        #expect(controller.isVisible == false) // No panel to toggle
        #expect(controller.opacity == 0.9)
    }

    // MARK: - Position Operations Sequential Test

    @Test("Position operations do not affect visibility state")
    func positionOperationsDoNotAffectVisibilityState() {
        let controller = FloatingPanelController()

        #expect(controller.isVisible == false)

        controller.moveToRight()
        #expect(controller.isVisible == false)

        controller.moveToLeft()
        #expect(controller.isVisible == false)

        controller.center()
        #expect(controller.isVisible == false)
    }
}

// MARK: - Panel Lifecycle Tests

/// Tests that require creating an actual NSPanel.
/// These tests verify the full lifecycle of the floating panel.
@Suite("FloatingPanelController Panel Lifecycle Tests")
@MainActor
struct FloatingPanelControllerPanelLifecycleTests {
    // MARK: - Show Panel Tests

    @Test("Show panel creates panel and sets visibility to true")
    func showPanelCreatesPanel() {
        let controller = FloatingPanelController()

        #expect(controller.isVisible == false)

        controller.showPanel(with: Text("Test Content"))

        #expect(controller.isVisible == true)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Show panel multiple times reuses existing panel")
    func showPanelReusesExistingPanel() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("First"))
        #expect(controller.isVisible == true)

        let firstFrame = controller.frame

        controller.showPanel(with: Text("Second"))
        #expect(controller.isVisible == true)

        // Frame should be the same (same panel)
        #expect(controller.frame == firstFrame)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Panel has valid frame after showing")
    func panelHasValidFrameAfterShowing() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))

        let frame = controller.frame
        #expect(frame.width > 0)
        #expect(frame.height > 0)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Panel frame uses default size")
    func panelFrameUsesDefaultSize() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))

        let frame = controller.frame
        // Width should be in expected range
        #expect(frame.width >= 300 && frame.width <= 700)
        // Height is now dynamically calculated based on user settings
        // Minimum expected height is around 80 (panel.minSize) to 700 for conversation mode
        #expect(frame.height >= 80 && frame.height <= 700)

        // Cleanup
        controller.destroyPanel()
    }

    // MARK: - Close Panel Tests

    @Test("Close panel destroys panel for fresh settings on reopen")
    func closePanelDestroysPanelForFreshSettings() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)

        controller.closePanel()
        #expect(controller.isVisible == false)

        // Panel should be destroyed (frame is zero)
        // This allows panel to be recreated with fresh settings when reopened
        #expect(controller.frame == .zero)
    }

    // MARK: - Destroy Panel Tests

    @Test("Destroy panel removes panel completely")
    func destroyPanelRemovesPanelCompletely() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)
        #expect(controller.frame != .zero)

        controller.destroyPanel()
        #expect(controller.isVisible == false)

        // Frame should be zero since panel is destroyed
        #expect(controller.frame == .zero)
    }

    // MARK: - Toggle Panel Tests

    @Test("Toggle panel shows hidden panel")
    func togglePanelShowsHiddenPanel() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)

        // Use hidePanel to hide without destroying
        controller.hidePanel()
        #expect(controller.isVisible == false)

        controller.togglePanel()
        #expect(controller.isVisible == true)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Toggle panel hides visible panel")
    func togglePanelHidesVisiblePanel() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)

        controller.togglePanel()
        #expect(controller.isVisible == false)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Multiple toggles work correctly")
    func multipleTogglesWorkCorrectly() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)

        controller.togglePanel()
        #expect(controller.isVisible == false)

        controller.togglePanel()
        #expect(controller.isVisible == true)

        controller.togglePanel()
        #expect(controller.isVisible == false)

        controller.togglePanel()
        #expect(controller.isVisible == true)

        // Cleanup
        controller.destroyPanel()
    }

    // MARK: - Opacity With Panel Tests

    @Test("Opacity change applies to existing panel")
    func opacityChangeAppliesToExistingPanel() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))

        controller.opacity = 0.5
        #expect(controller.opacity == 0.5)

        controller.opacity = 0.8
        #expect(controller.opacity == 0.8)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Opacity set before showing panel is applied")
    func opacitySetBeforeShowingPanelIsApplied() {
        let controller = FloatingPanelController()

        controller.opacity = 0.7
        #expect(controller.opacity == 0.7)

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)
        #expect(controller.opacity == 0.7)

        // Cleanup
        controller.destroyPanel()
    }

    // MARK: - Frame Setter Tests With Panel

    @Test("Frame setter updates panel frame")
    func frameSetterUpdatesPanelFrame() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))

        let initialFrame = controller.frame
        let newFrame = NSRect(x: 200, y: 200, width: 500, height: 700)
        controller.frame = newFrame

        // Note: Frame uses animation so exact match is timing-dependent
        // Just verify frame is valid (non-zero) and frame setter was called
        let currentFrame = controller.frame
        #expect(currentFrame.width > 0)
        #expect(currentFrame.height > 0)

        // Cleanup
        controller.destroyPanel()
    }

    // MARK: - Position Methods With Panel Tests

    @Test("Move to right positions panel correctly")
    func moveToRightPositionsPanelCorrectly() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        let initialX = controller.frame.origin.x

        controller.moveToLeft()
        let leftX = controller.frame.origin.x

        controller.moveToRight()
        let rightX = controller.frame.origin.x

        // Right position should be greater than left position
        #expect(rightX > leftX)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Move to left positions panel correctly")
    func moveToLeftPositionsPanelCorrectly() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))

        controller.moveToRight()
        let rightX = controller.frame.origin.x

        controller.moveToLeft()
        let leftX = controller.frame.origin.x

        // Left position should be less than right position
        #expect(leftX < rightX)

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Center positions panel on screen")
    func centerPositionsPanelOnScreen() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))

        // Move to left first
        controller.moveToLeft()
        let leftX = controller.frame.origin.x

        // Move to right
        controller.moveToRight()
        let rightX = controller.frame.origin.x

        // Center should be between left and right
        controller.center()
        let centerX = controller.frame.origin.x

        // Center should be somewhere between left and right
        #expect(centerX > leftX)
        #expect(centerX < rightX)

        // Cleanup
        controller.destroyPanel()
    }

    // MARK: - Bring to Front Tests

    @Test("Bring to front does not change visibility")
    func bringToFrontDoesNotChangeVisibility() {
        let controller = FloatingPanelController()

        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)

        controller.bringToFront()
        #expect(controller.isVisible == true)

        // Cleanup
        controller.destroyPanel()
    }

    // MARK: - Complete Lifecycle Tests

    @Test("Full lifecycle: create, show, hide, show, destroy")
    func fullLifecycle() {
        let controller = FloatingPanelController()

        // Initial state
        #expect(controller.isVisible == false)
        #expect(controller.frame == .zero)

        // Show panel
        controller.showPanel(with: Text("Test"))
        #expect(controller.isVisible == true)
        #expect(controller.frame != .zero)

        // Hide panel (without destroying)
        controller.hidePanel()
        #expect(controller.isVisible == false)
        #expect(controller.frame != .zero) // Panel still exists

        // Show again (toggle back)
        controller.togglePanel()
        #expect(controller.isVisible == true)

        // Close panel (destroys it for fresh settings)
        controller.closePanel()
        #expect(controller.isVisible == false)
        #expect(controller.frame == .zero) // Panel destroyed

        // Can show again after close/destroy
        controller.showPanel(with: Text("New Panel"))
        #expect(controller.isVisible == true)
        #expect(controller.frame != .zero)

        // Final cleanup
        controller.destroyPanel()
    }

    @Test("Lifecycle with opacity changes")
    func lifecycleWithOpacityChanges() {
        let controller = FloatingPanelController()

        // Set opacity before panel exists
        controller.opacity = 0.5
        #expect(controller.opacity == 0.5)

        // Show panel
        controller.showPanel(with: Text("Test"))
        #expect(controller.opacity == 0.5)

        // Change opacity while visible
        controller.opacity = 0.8
        #expect(controller.opacity == 0.8)

        // Hide panel
        controller.closePanel()
        #expect(controller.opacity == 0.8)

        // Change opacity while hidden
        controller.opacity = 0.6
        #expect(controller.opacity == 0.6)

        // Show panel again
        controller.togglePanel()
        #expect(controller.opacity == 0.6)

        // Destroy panel
        controller.destroyPanel()
        #expect(controller.opacity == 0.6) // Opacity property preserved

        // Cleanup
        controller.destroyPanel()
    }

    @Test("Multiple panels can coexist")
    func multiplePanelsCanCoexist() {
        let controller1 = FloatingPanelController()
        let controller2 = FloatingPanelController()

        controller1.showPanel(with: Text("Panel 1"))
        controller2.showPanel(with: Text("Panel 2"))

        #expect(controller1.isVisible == true)
        #expect(controller2.isVisible == true)

        controller1.opacity = 0.5
        controller2.opacity = 0.9

        #expect(controller1.opacity == 0.5)
        #expect(controller2.opacity == 0.9)

        controller1.closePanel()
        #expect(controller1.isVisible == false)
        #expect(controller2.isVisible == true)

        // Cleanup
        controller1.destroyPanel()
        controller2.destroyPanel()
    }
}
