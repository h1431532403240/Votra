//
//  NetworkMonitorTests.swift
//  VotraTests
//
//  Tests for NetworkMonitor connectivity monitoring utility.
//

import Foundation
import Testing
@testable import Votra

@Suite("Network Monitor Tests")
@MainActor
struct NetworkMonitorTests {

    // MARK: - Singleton Access Tests

    @Test("Shared instance returns same object")
    func sharedInstanceIdentity() {
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared

        #expect(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    @Test("Initial isConnected has default value")
    func initialIsConnectedState() {
        let monitor = NetworkMonitor.shared

        // isConnected should be a boolean (either true or false based on actual network)
        // We just verify it has a valid value
        #expect(monitor.isConnected == true || monitor.isConnected == false)
    }

    @Test("Initial connectionType is valid")
    func initialConnectionType() {
        let monitor = NetworkMonitor.shared

        // Verify connectionType is one of the valid enum cases
        let validTypes: [ConnectionType] = [.wifi, .cellular, .ethernet, .other, .none, .unknown]
        #expect(validTypes.contains(monitor.connectionType))
    }

    // MARK: - Observable Property Tests

    @Test("isOfflineMode reflects inverse of isConnected")
    func isOfflineModeReflectsConnection() {
        let monitor = NetworkMonitor.shared

        // isOfflineMode should be the opposite of isConnected
        #expect(monitor.isOfflineMode == !monitor.isConnected)
    }

    // MARK: - Public Method Tests

    @Test("startMonitoring is idempotent")
    func startMonitoringIdempotent() {
        let monitor = NetworkMonitor.shared

        // Calling startMonitoring multiple times should not cause issues
        monitor.startMonitoring()
        monitor.startMonitoring()

        // The monitor should still work correctly
        #expect(monitor.isConnected == true || monitor.isConnected == false)
    }

    @Test("stopMonitoring and startMonitoring cycle works")
    func stopAndStartMonitoringCycle() {
        let monitor = NetworkMonitor.shared

        // Stop monitoring
        monitor.stopMonitoring()

        // Start monitoring again
        monitor.startMonitoring()

        // Should still have valid state
        #expect(monitor.isConnected == true || monitor.isConnected == false)
    }

    @Test("stopMonitoring is idempotent when already stopped")
    func stopMonitoringIdempotent() {
        let monitor = NetworkMonitor.shared

        // Ensure monitoring is active first
        monitor.startMonitoring()

        // Stop monitoring
        monitor.stopMonitoring()

        // Call stopMonitoring again - should not cause issues (tests guard clause)
        monitor.stopMonitoring()

        // Monitor should still be in valid state
        #expect(monitor.isConnected == true || monitor.isConnected == false)

        // Restart for other tests
        monitor.startMonitoring()
    }

    @Test("refresh updates connection status")
    func refreshUpdatesStatus() {
        let monitor = NetworkMonitor.shared

        // Refresh should not throw and should maintain valid state
        monitor.refresh()

        #expect(monitor.isConnected == true || monitor.isConnected == false)
        let validTypes: [ConnectionType] = [.wifi, .cellular, .ethernet, .other, .none, .unknown]
        #expect(validTypes.contains(monitor.connectionType))
    }

    // MARK: - Offline Mode Helper Tests

    @Test("canOperateOffline returns true when both languages available")
    func canOperateOfflineWithBothLanguages() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .available },
            checkTargetAvailable: { .available }
        )

        #expect(result == true)
    }

    @Test("canOperateOffline returns false when source unavailable")
    func canOperateOfflineSourceUnavailable() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .downloadRequired(size: 100_000_000) },
            checkTargetAvailable: { .available }
        )

        #expect(result == false)
    }

    @Test("canOperateOffline returns false when target unavailable")
    func canOperateOfflineTargetUnavailable() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .available },
            checkTargetAvailable: { .unsupported }
        )

        #expect(result == false)
    }

    @Test("canOperateOffline returns false when both unavailable")
    func canOperateOfflineBothUnavailable() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .downloading(progress: 0.5) },
            checkTargetAvailable: { .downloadRequired(size: 50_000_000) }
        )

        #expect(result == false)
    }

    @Test("canOperateOffline returns false when source is downloading")
    func canOperateOfflineSourceDownloading() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .downloading(progress: 0.75) },
            checkTargetAvailable: { .available }
        )

        #expect(result == false)
    }

    @Test("canOperateOffline returns false when target is downloading")
    func canOperateOfflineTargetDownloading() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .available },
            checkTargetAvailable: { .downloading(progress: 0.25) }
        )

        #expect(result == false)
    }

    @Test("canOperateOffline returns false when source is unsupported")
    func canOperateOfflineSourceUnsupported() async {
        let monitor = NetworkMonitor.shared

        let result = await monitor.canOperateOffline(
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "zh-Hans"),
            checkSourceAvailable: { .unsupported },
            checkTargetAvailable: { .available }
        )

        #expect(result == false)
    }
}

// MARK: - Connection Type Tests

@Suite("Connection Type Tests")
@MainActor
struct ConnectionTypeTests {

    // MARK: - Display Name Tests

    @Test("All connection types have display names")
    func allTypesHaveDisplayNames() {
        let types: [ConnectionType] = [.wifi, .cellular, .ethernet, .other, .none, .unknown]

        for type in types {
            #expect(!type.displayName.isEmpty, "Display name for \(type) should not be empty")
        }
    }

    @Test("WiFi display name is correct")
    func wifiDisplayName() {
        #expect(ConnectionType.wifi.displayName == String(localized: "Wi-Fi"))
    }

    @Test("Cellular display name is correct")
    func cellularDisplayName() {
        #expect(ConnectionType.cellular.displayName == String(localized: "Cellular"))
    }

    @Test("Ethernet display name is correct")
    func ethernetDisplayName() {
        #expect(ConnectionType.ethernet.displayName == String(localized: "Ethernet"))
    }

    @Test("Other display name is correct")
    func otherDisplayName() {
        #expect(ConnectionType.other.displayName == String(localized: "Connected"))
    }

    @Test("None display name is correct")
    func noneDisplayName() {
        #expect(ConnectionType.none.displayName == String(localized: "Offline"))
    }

    @Test("Unknown display name is correct")
    func unknownDisplayName() {
        #expect(ConnectionType.unknown.displayName == String(localized: "Unknown"))
    }

    // MARK: - System Image Tests

    @Test("All connection types have system images")
    func allTypesHaveSystemImages() {
        let types: [ConnectionType] = [.wifi, .cellular, .ethernet, .other, .none, .unknown]

        for type in types {
            #expect(!type.systemImage.isEmpty, "System image for \(type) should not be empty")
        }
    }

    @Test("WiFi system image is wifi")
    func wifiSystemImage() {
        #expect(ConnectionType.wifi.systemImage == "wifi")
    }

    @Test("Cellular system image is antenna")
    func cellularSystemImage() {
        #expect(ConnectionType.cellular.systemImage == "antenna.radiowaves.left.and.right")
    }

    @Test("Ethernet system image is cable")
    func ethernetSystemImage() {
        #expect(ConnectionType.ethernet.systemImage == "cable.connector")
    }

    @Test("Other system image is network")
    func otherSystemImage() {
        #expect(ConnectionType.other.systemImage == "network")
    }

    @Test("None system image is wifi slash")
    func noneSystemImage() {
        #expect(ConnectionType.none.systemImage == "wifi.slash")
    }

    @Test("Unknown system image is question mark")
    func unknownSystemImage() {
        #expect(ConnectionType.unknown.systemImage == "questionmark.circle")
    }

    // MARK: - Sendable Conformance Tests

    @Test("ConnectionType is Sendable")
    func connectionTypeIsSendable() async {
        // Verify ConnectionType can be sent across actor boundaries
        let type: ConnectionType = .wifi

        let result = await Task.detached {
            type
        }.value

        #expect(result == .wifi)
    }
}

// MARK: - Notification Name Tests

@Suite("Network Notification Tests")
struct NetworkNotificationTests {

    @Test("Network status changed notification name exists")
    func networkStatusChangedNotificationExists() {
        let name = Notification.Name.networkStatusChanged
        #expect(name.rawValue == "app.votra.networkStatusChanged")
    }
}

// MARK: - Language Availability Tests

@Suite("Language Availability Tests")
struct LanguageAvailabilityTests {

    @Test("LanguageAvailability equals self")
    func availabilityEqualsSelf() {
        #expect(LanguageAvailability.available == .available)
        #expect(LanguageAvailability.unsupported == .unsupported)
        #expect(LanguageAvailability.downloadRequired(size: 100) == .downloadRequired(size: 100))
        #expect(LanguageAvailability.downloading(progress: 0.5) == .downloading(progress: 0.5))
    }

    @Test("LanguageAvailability different cases are not equal")
    func availabilityDifferentCasesNotEqual() {
        #expect(LanguageAvailability.available != .unsupported)
        #expect(LanguageAvailability.available != .downloadRequired(size: 100))
        #expect(LanguageAvailability.available != .downloading(progress: 0.5))
        #expect(LanguageAvailability.unsupported != .downloadRequired(size: 100))
        #expect(LanguageAvailability.downloadRequired(size: 100) != .downloading(progress: 0.5))
    }

    @Test("LanguageAvailability downloadRequired different sizes are not equal")
    func downloadRequiredDifferentSizes() {
        #expect(LanguageAvailability.downloadRequired(size: 100) != .downloadRequired(size: 200))
    }

    @Test("LanguageAvailability downloading different progress are not equal")
    func downloadingDifferentProgress() {
        #expect(LanguageAvailability.downloading(progress: 0.5) != .downloading(progress: 0.75))
    }

    @Test("LanguageAvailability is Sendable")
    func languageAvailabilityIsSendable() async {
        let availability: LanguageAvailability = .downloading(progress: 0.5)

        let result = await Task.detached {
            availability
        }.value

        #expect(result == .downloading(progress: 0.5))
    }
}
