//
//  NetworkMonitor.swift
//  Votra
//
//  Network connectivity monitoring for offline mode detection.
//

import Foundation
import Network

/// Monitor for network connectivity status
@MainActor
@Observable
final class NetworkMonitor {
    // MARK: - Shared Instance

    /// Shared network monitor instance
    static let shared = NetworkMonitor()

    // MARK: - State

    /// Whether the network is currently available
    private(set) var isConnected: Bool = true

    /// Current network path status
    private(set) var connectionType: ConnectionType = .unknown

    /// Whether the app is in offline mode (either no network or user preference)
    var isOfflineMode: Bool {
        !isConnected
    }

    // MARK: - Private Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "app.votra.networkmonitor")
    private var isMonitoring = false

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    // Note: Cannot call stopMonitoring in deinit due to MainActor isolation
    // The monitor will be cleaned up when the object is deallocated

    // MARK: - Monitoring

    /// Start monitoring network changes
    func startMonitoring() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateConnectionStatus(path)
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true
    }

    /// Stop monitoring network changes
    func stopMonitoring() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false
    }

    /// Force a refresh of the network status
    func refresh() {
        let path = monitor.currentPath
        updateConnectionStatus(path)
    }

    // MARK: - Private Methods

    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = path.status == .satisfied ? .other : .none
        }
    }
}

// MARK: - Connection Type

/// Type of network connection
enum ConnectionType: Sendable {
    case wifi
    case cellular
    case ethernet
    case other
    case none
    case unknown

    var displayName: String {
        switch self {
        case .wifi:
            return String(localized: "Wi-Fi")
        case .cellular:
            return String(localized: "Cellular")
        case .ethernet:
            return String(localized: "Ethernet")
        case .other:
            return String(localized: "Connected")
        case .none:
            return String(localized: "Offline")
        case .unknown:
            return String(localized: "Unknown")
        }
    }

    var systemImage: String {
        switch self {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .other:
            return "network"
        case .none:
            return "wifi.slash"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Notification posted when network connectivity changes
    static let networkStatusChanged = Notification.Name("app.votra.networkStatusChanged")
}

// MARK: - Offline Mode Helper

extension NetworkMonitor {
    /// Check if the app can operate offline with the current language configuration
    /// - Parameters:
    ///   - sourceLocale: Source language locale
    ///   - targetLocale: Target language locale
    ///   - speechService: Speech recognition service to check language availability
    /// - Returns: Whether offline operation is possible
    func canOperateOffline(
        sourceLocale: Locale,
        targetLocale: Locale,
        checkSourceAvailable: () async -> LanguageAvailability,
        checkTargetAvailable: () async -> LanguageAvailability
    ) async -> Bool {
        // Check if both language packs are installed
        let sourceAvailable = await checkSourceAvailable()
        let targetAvailable = await checkTargetAvailable()

        return sourceAvailable == .available && targetAvailable == .available
    }
}
