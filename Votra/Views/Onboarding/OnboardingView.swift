//
//  OnboardingView.swift
//  Votra
//
//  Onboarding view that guides users through initial setup and permission requests.
//

import AppKit
import AVFoundation
import SwiftUI

/// Main onboarding view displayed on first app launch
struct OnboardingView: View {
    // MARK: - Subtypes

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case microphone
        case screenRecording
        case complete
    }

    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
    }

    enum OnboardingPermissionType {
        case microphone
        case screenRecording
    }

    // MARK: - Instance Properties

    var preferences: UserPreferences

    @State private var currentStep: OnboardingStep = .welcome
    @State private var microphoneStatus: PermissionStatus = .notDetermined
    @State private var screenRecordingStatus: PermissionStatus = .notDetermined

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            progressHeader

            // Content area
            Group {
                switch currentStep {
                case .welcome:
                    welcomeContent
                case .microphone:
                    microphoneContent
                case .screenRecording:
                    screenRecordingContent
                case .complete:
                    completeContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation buttons
            navigationButtons
        }
        .frame(width: 500, height: 450)
        .onAppear {
            checkCurrentPermissions()
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Step indicator
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }

            // Step title
            Text(stepTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private var stepTitle: String {
        switch currentStep {
        case .welcome:
            return String(localized: "Welcome")
        case .microphone:
            return String(localized: "Microphone Access")
        case .screenRecording:
            return String(localized: "Screen Recording")
        case .complete:
            return String(localized: "Ready to Go")
        }
    }

    // MARK: - Welcome Content

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Votra")
                .font(.largeTitle)
                .bold()

            Text("Real-time voice translation for your conversations. Before we begin, we need to set up a few permissions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Microphone Content

    private var microphoneContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.fill")
                .font(.system(size: 64))
                .foregroundStyle(microphoneStatus == .authorized ? Color.green : Color.accentColor)

            Text("Microphone Access Required")
                .font(.title2)
                .bold()

            Text("Votra needs microphone access to capture your voice for translation.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            permissionStatusView(for: microphoneStatus)

            if microphoneStatus == .notDetermined {
                Button(String(localized: "Enable Microphone Access")) {
                    Task {
                        await requestMicrophonePermission()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else if microphoneStatus == .denied {
                Button(String(localized: "Open System Settings")) {
                    openSystemSettings(for: .microphone)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Screen Recording Content

    private var screenRecordingContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(screenRecordingStatus == .authorized ? Color.green : Color.accentColor)

            Text("Screen Recording Access Required")
                .font(.title2)
                .bold()

            Text("Votra needs screen recording access to capture system audio from other applications like Zoom, FaceTime, or Safari.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            permissionStatusView(for: screenRecordingStatus)

            if screenRecordingStatus != .authorized {
                Button(String(localized: "Open System Settings")) {
                    openSystemSettings(for: .screenRecording)
                }
                .buttonStyle(.borderedProminent)

                Button(String(localized: "Check Permission Status")) {
                    checkScreenRecordingPermission()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Complete Content

    private var completeContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .bold()

            Text("Votra is ready to help you translate conversations in real-time. Enjoy!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "waveform", text: String(localized: "Speak naturally and see translations instantly"))
                featureRow(icon: "speaker.wave.2", text: String(localized: "Listen to translations with text-to-speech"))
                featureRow(icon: "record.circle", text: String(localized: "Record and save your translation sessions"))
            }
            .padding(.top, 16)
        }
        .padding()
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if currentStep != .welcome {
                Button(String(localized: "Back")) {
                    withAnimation {
                        goToPreviousStep()
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep == .complete {
                Button(String(localized: "Get Started")) {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(currentStep == .welcome ? String(localized: "Continue") : String(localized: "Next")) {
                    withAnimation {
                        goToNextStep()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
        }
        .padding(24)
    }

    private var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .microphone:
            // Allow proceeding even if denied - user can fix later
            return microphoneStatus != .notDetermined
        case .screenRecording:
            // Screen recording is required for system audio
            return screenRecordingStatus != .notDetermined
        case .complete:
            return true
        }
    }

    // MARK: - Helper Views

    private func permissionStatusView(for status: PermissionStatus) -> some View {
        HStack(spacing: 8) {
            switch status {
            case .authorized:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Granted")
                    .foregroundStyle(.green)
            case .denied:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Denied")
                    .foregroundStyle(.red)
            case .notDetermined:
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
                Text("Not Set")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Actions

    private func goToNextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }

    private func goToPreviousStep() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevStep
    }

    private func completeOnboarding() {
        preferences.hasCompletedOnboarding = true
        onComplete()
    }

    // MARK: - Permissions

    private func checkCurrentPermissions() {
        // Check microphone
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        microphoneStatus = mapAVAuthStatus(micStatus)

        // Check screen recording
        checkScreenRecordingPermission()
    }

    private func mapAVAuthStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func requestMicrophonePermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            microphoneStatus = granted ? .authorized : .denied
        }
    }

    private func checkScreenRecordingPermission() {
        if CGPreflightScreenCaptureAccess() {
            screenRecordingStatus = .authorized
        } else {
            // Try to request - this will show the system dialog
            let granted = CGRequestScreenCaptureAccess()
            screenRecordingStatus = granted ? .authorized : .denied
        }
    }

    private func openSystemSettings(for permission: OnboardingPermissionType) {
        switch permission {
        case .microphone:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        case .screenRecording:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(preferences: UserPreferences.shared) {}
}
