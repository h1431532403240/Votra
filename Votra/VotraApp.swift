//
//  VotraApp.swift
//  Votra
//
//  Main application entry point with SwiftData ModelContainer configuration.
//

import SwiftUI
import SwiftData
@preconcurrency import Translation

struct VotraApp: App {
    // MARK: - Type Properties

    /// Shared model container - created once and reused
    /// Using static to ensure single instance across app lifecycle
    private static var _modelContainer: ModelContainer?

    // MARK: - Instance Properties

    @AppStorage("iCloudSyncEnabled")
    private var iCloudSyncEnabled = false

    // Core services and view models
    @State private var translationViewModel = TranslationViewModel()
    @State private var floatingPanelController = FloatingPanelController()
    @State private var recordingViewModel = RecordingViewModel()

    // Recording state
    @State private var isRecording = false

    // Onboarding state
    @State private var showOnboarding = false

    // Recovery dialog state
    @State private var showRecoveryDialog = false
    @State private var incompleteRecordings: [RecordingMetadata] = []

    // Translation configuration for the session
    @State private var translationConfiguration: TranslationSession.Configuration?

    /// Check if running in a test environment
    private var isRunningTests: Bool {
        // Check various test environment indicators
        let env = ProcessInfo.processInfo.environment
        return env["XCTestConfigurationFilePath"] != nil ||
               env["XCTestSessionIdentifier"] != nil ||
               env["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil ||
               NSClassFromString("XCTestCase") != nil
    }

    var sharedModelContainer: ModelContainer {
        if let existing = Self._modelContainer {
            return existing
        }

        let schema = Schema([
            Session.self,
            Segment.self,
            Speaker.self,
            Recording.self,
            MeetingSummary.self
        ])

        let modelConfiguration: ModelConfiguration
        if isRunningTests {
            // Test environment - use in-memory storage without CloudKit
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true
            )
        } else if iCloudSyncEnabled {
            // CloudKit-enabled configuration
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .private("iCloud.9RGPF3DKLN.votra.macos")
            )
        } else {
            // Local-only configuration (default)
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
        }

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Self._modelContainer = container
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(translationViewModel)
                .environment(recordingViewModel)
                .environment(floatingPanelController)
                .environment(UserPreferences.shared)
                .onAppear {
                    StoragePaths.ensureDirectoriesExist()
                    setupFloatingPanel()
                    updateTranslationConfiguration()
                    checkOnboardingStatus()

                    // Run audio diagnostics on startup
                    Task {
                        await AudioDiagnostics.printDiagnostics()
                    }
                }
                .onChange(of: translationViewModel.configuration) {
                    updateTranslationConfiguration()
                }
                .translationTask(translationConfiguration) { session in
                    await translationViewModel.setTranslationSession(session)
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(preferences: UserPreferences.shared) {
                        showOnboarding = false
                        // Check for incomplete recordings after onboarding
                        checkForIncompleteRecordings()
                    }
                }
                .sheet(isPresented: $showRecoveryDialog) {
                    RecoveryDialogView(
                        incompleteRecordings: incompleteRecordings,
                        viewModel: recordingViewModel,
                        isPresented: $showRecoveryDialog
                    )
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // Add menu commands for floating panel
            CommandGroup(after: .windowArrangement) {
                Button(String(localized: "Show Translation Overlay")) {
                    floatingPanelController.bringToFront()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button(String(localized: "Toggle Translation Overlay")) {
                    floatingPanelController.togglePanel()
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
            }
        }
    }

    // MARK: - Private Methods

    private func setupFloatingPanel() {
        let preferences = UserPreferences.shared
        let controller = floatingPanelController
        let panelView = FloatingPanelContainerView(
            viewModel: translationViewModel,
            preferences: preferences,
            isRecording: $isRecording,
            opacity: Binding(
                get: { preferences.floatingWindowOpacity },
                set: { newValue in
                    preferences.floatingWindowOpacity = newValue
                    controller.opacity = newValue
                }
            ),
            onStartStop: {
                await toggleTranslation()
            },
            onRecordToggle: {
                isRecording.toggle()
            },
            onSpeak: { message in
                await translationViewModel.speak(message)
            }
        )

        floatingPanelController.showPanel(with: panelView)
        floatingPanelController.opacity = preferences.floatingWindowOpacity

        // Set up the recreate closure for when the panel is closed and needs to be reopened
        floatingPanelController.onNeedRecreate = { [self] in
            setupFloatingPanel()
        }
    }

    private func updateTranslationConfiguration() {
        translationConfiguration = TranslationService.configuration(
            source: translationViewModel.configuration.sourceLocale,
            target: translationViewModel.configuration.targetLocale
        )
    }

    private func toggleTranslation() async {
        print("[Votra] toggleTranslation called, current state: \(translationViewModel.state)")
        switch translationViewModel.state {
        case .idle, .paused:
            do {
                print("[Votra] Starting translation...")
                try await translationViewModel.start()
                print("[Votra] Translation started, new state: \(translationViewModel.state)")
            } catch {
                print("[Votra] Failed to start translation: \(error)")
            }
        case .active:
            print("[Votra] Stopping translation...")
            await translationViewModel.stop()
            print("[Votra] Translation stopped, new state: \(translationViewModel.state)")
        default:
            print("[Votra] Ignoring toggle, state: \(translationViewModel.state)")
        }
    }

    // MARK: - Onboarding

    private func checkOnboardingStatus() {
        let preferences = UserPreferences.shared
        if !preferences.hasCompletedOnboarding {
            showOnboarding = true
        } else {
            // Already onboarded, check for incomplete recordings
            checkForIncompleteRecordings()
        }
    }

    // MARK: - Recovery

    private func checkForIncompleteRecordings() {
        incompleteRecordings = recordingViewModel.checkForIncompleteRecordings()
        if !incompleteRecordings.isEmpty {
            showRecoveryDialog = true
        }
    }

    // MARK: - Session Lifecycle (T074)

    /// Cleanup temporary sessions on app termination
    private func cleanupTemporarySessions(context: ModelContext) {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { !$0.isPersisted }
        )

        guard let tempSessions = try? context.fetch(descriptor) else { return }

        for session in tempSessions {
            // SwiftData handles external storage cleanup automatically
            // when the Recording model is deleted via cascade
            context.delete(session)
        }

        try? context.save()
    }

    /// Check for recoverable sessions on launch (T075)
    private func checkForRecoverableSessions(context: ModelContext) -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endTime == nil && !$0.isPersisted }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
