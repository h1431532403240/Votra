//
//  AppLauncher.swift
//  Votra
//
//  Entry point that detects test environment and skips hardware initialization.
//  This prevents the app from hanging on CI runners that lack audio/video hardware.
//
//  References:
//  - https://qualitycoding.org/bypass-swiftui-app-launch-unit-testing/
//  - https://mokacoding.com/blog/prevent-swiftui-app-loading-in-unit-tests/
//

import SwiftUI

/// Main entry point for the application.
/// Detects if running under XCTest and launches a minimal app to avoid hardware initialization.
@main
enum AppLauncher {
    static func main() {
        if NSClassFromString("XCTestCase") == nil {
            // Production: launch the full app
            VotraApp.main()
        } else {
            // Testing: launch minimal app without hardware initialization
            TestApp.main()
        }
    }
}

/// Minimal app used during unit testing.
/// Does not initialize audio, video, or other hardware-dependent services.
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Running Unit Tests")
                .frame(width: 200, height: 100)
        }
    }
}
