//
//  MainTranslationView.swift
//  Votra
//
//  Main translation view for the primary window with full translation controls.
//

import SwiftUI

/// Main translation view displayed in the primary app window
struct MainTranslationView: View {
    @Environment(TranslationViewModel.self)
    private var translationViewModel

    @Environment(RecordingViewModel.self)
    private var recordingViewModel

    @State private var isRecording = false
    @State private var showIdleIndicator = true
    @State private var showPermissionGuidance = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    /// Track if user has manually scrolled away from bottom
    /// Uses a timestamp to auto-reset after a period of no interaction
    @State private var lastUserScrollTime: Date?

    /// Auto-scroll is disabled for 3 seconds after user scrolls
    private var isAutoScrollEnabled: Bool {
        guard let lastScroll = lastUserScrollTime else { return true }
        return Date().timeIntervalSince(lastScroll) > 3.0
    }

    var body: some View {
        @Bindable var viewModel = translationViewModel

        VStack(spacing: 0) {
            // Header with audio source and settings
            headerSection
                .padding()

            Divider()

            // Messages area
            messagesArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Control bar
            controlBarSection
                .padding()
        }
        .navigationTitle(String(localized: "Real-time Translation"))
        .onChange(of: translationViewModel.messages) { _, newMessages in
            if !newMessages.isEmpty && showIdleIndicator {
                withAnimation {
                    showIdleIndicator = false
                }
            }
        }
        .onChange(of: translationViewModel.state) { _, newState in
            // Show appropriate dialog when entering error state
            if case .error(let message) = newState {
                if translationViewModel.requiredPermissionType != nil {
                    showPermissionGuidance = true
                } else {
                    // Show general error alert for non-permission errors
                    errorMessage = message
                    showErrorAlert = true
                }
            }
        }
        .sheet(isPresented: $showPermissionGuidance) {
            if let permissionType = translationViewModel.requiredPermissionType {
                PermissionGuidanceView(permissionType: permissionType) {
                    showPermissionGuidance = false
                }
            }
        }
        .alert(String(localized: "Error"), isPresented: $showErrorAlert) {
            Button(String(localized: "OK")) {
                showErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        @Bindable var viewModel = translationViewModel

        return HStack {
            // Audio source picker
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Audio Source"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(viewModel.availableAudioSources) { source in
                        Button {
                            viewModel.selectAudioSource(source)
                        } label: {
                            HStack {
                                AudioSourceIconView(source: source, size: 16)
                                Text(source.displayName)
                                if source.id == viewModel.selectedAudioSource.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        Task {
                            await viewModel.refreshAudioSources()
                        }
                    } label: {
                        Label(String(localized: "Refresh"), systemImage: "arrow.clockwise")
                    }
                } label: {
                    HStack(spacing: 6) {
                        AudioSourceIconView(source: viewModel.selectedAudioSource, size: 16)
                        Text(viewModel.selectedAudioSource.displayName)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.1))
                    }
                }
                .menuStyle(.borderlessButton)
            }

            Spacer()

            // Status indicator
            statusIndicator

            Spacer()

            // Clear messages button
            if !translationViewModel.messages.isEmpty {
                Button(String(localized: "Clear"), systemImage: "trash") {
                    translationViewModel.clearMessages()
                    showIdleIndicator = true
                }
                .buttonStyle(.bordered)
            }
        }
        .task {
            await translationViewModel.refreshAudioSources()
        }
    }

    // MARK: - Status Indicator

    @ViewBuilder private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.secondary.opacity(0.1))
        }
    }

    private var statusColor: Color {
        switch translationViewModel.state {
        case .active:
            return .green
        case .starting:
            return .yellow
        case .error:
            return .red
        default:
            return .gray
        }
    }

    private var statusText: String {
        switch translationViewModel.state {
        case .idle:
            return String(localized: "Ready")
        case .starting:
            return String(localized: "Starting...")
        case .active:
            return String(localized: "Translating")
        case .paused:
            return String(localized: "Paused")
        case .error(let message):
            return message
        }
    }

    // MARK: - Messages Area

    @ViewBuilder private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Idle state indicator
                    if showIdleIndicator && translationViewModel.messages.isEmpty {
                        idleStateView
                    }

                    // Messages grouped by speaker
                    ForEach(translationViewModel.messages.groupedBySpeaker(), id: \.0) { groupId, messages in
                        MessageGroupView(
                            messages: messages,
                            speakerName: messages.first?.isFromUser == true ? String(localized: "Me") : String(localized: "Remote"),
                            speakerColor: messages.first?.isFromUser == true ? .blue : .green
                        ) { message in
                            Task {
                                await translationViewModel.speak(message)
                            }
                        }
                        .id(groupId)
                    }

                    // Interim message
                    if let transcription = translationViewModel.interimTranscription {
                        InterimMessageView(
                            transcription: transcription,
                            translation: translationViewModel.interimTranslation,
                            source: translationViewModel.interimSource
                        )
                        .id("interim")
                    }

                    // Bottom anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .onScrollPhaseChange { _, newPhase in
                // Detect when user is actively scrolling
                if newPhase == .interacting || newPhase == .decelerating {
                    lastUserScrollTime = Date()
                }
            }
            .onChange(of: translationViewModel.messages.count) { _, _ in
                // Only scroll to bottom if auto-scroll is enabled
                if isAutoScrollEnabled {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: translationViewModel.interimTranscription) { _, _ in
                // Also scroll for interim transcription updates
                if isAutoScrollEnabled {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Idle State View

    private var idleStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(String(localized: "Real-time Translation"))
                .font(.title2)
                .bold()

            Text(String(localized: "Select your languages below and click Start to begin translating"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if translationViewModel.state == .active {
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.accentColor.opacity(0.6))
                                .frame(width: 4, height: 16)
                        }
                    }
                    Text(String(localized: "Listening..."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .accessibilityIdentifier("translation_idle_state")
    }

    // MARK: - Control Bar Section

    private var controlBarSection: some View {
        @Bindable var viewModel = translationViewModel

        return VStack(spacing: 16) {
            // Language selection row
            HStack(spacing: 16) {
                // Source language picker
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "From"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker(selection: Binding(
                        get: { viewModel.configuration.sourceLocale },
                        set: { viewModel.configuration.sourceLocale = $0 }
                    )) {
                        ForEach(Locale.pickerLanguages, id: \.identifier) { locale in
                            Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                                .tag(locale)
                        }
                    } label: {
                        EmptyView()
                    }
                    .frame(width: 150)
                }

                // Swap button
                Button {
                    swapLanguages()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .help(String(localized: "Swap languages"))

                // Target language picker
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "To"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker(selection: Binding(
                        get: { viewModel.configuration.targetLocale },
                        set: { viewModel.configuration.targetLocale = $0 }
                    )) {
                        ForEach(Locale.pickerLanguages, id: \.identifier) { locale in
                            Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                                .tag(locale)
                        }
                    } label: {
                        EmptyView()
                    }
                    .frame(width: 150)
                }

                Spacer()

                // Auto-speak toggle
                Toggle(isOn: Binding(
                    get: { viewModel.configuration.autoSpeak },
                    set: { viewModel.configuration.autoSpeak = $0 }
                )) {
                    Label(String(localized: "Auto-speak"), systemImage: "speaker.wave.2")
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            Divider()

            // Action buttons row
            HStack(spacing: 16) {
                // Recording button
                Button {
                    toggleRecording()
                } label: {
                    Label(
                        isRecording ? String(localized: "Stop Recording") : String(localized: "Record"),
                        systemImage: isRecording ? "stop.circle.fill" : "record.circle"
                    )
                }
                .buttonStyle(.bordered)
                .foregroundStyle(isRecording ? .red : .primary)
                .disabled(viewModel.state != .active)

                Spacer()

                // Start/Stop translation button
                Button {
                    Task {
                        await toggleTranslation()
                    }
                } label: {
                    Label(
                        viewModel.state == .active ? String(localized: "Stop Translation") : String(localized: "Start Translation"),
                        systemImage: viewModel.state == .active ? "stop.fill" : "play.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("translation_start_stop_button")
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.05))
        }
    }

    // MARK: - Helpers

    private func swapLanguages() {
        let temp = translationViewModel.configuration.sourceLocale
        translationViewModel.configuration.sourceLocale = translationViewModel.configuration.targetLocale
        translationViewModel.configuration.targetLocale = temp
    }

    private func toggleTranslation() async {
        switch translationViewModel.state {
        case .idle, .paused:
            do {
                try await translationViewModel.start()
            } catch {
                print("Failed to start translation: \(error)")
            }
        case .active:
            await translationViewModel.stop()
        default:
            break
        }
    }

    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            Task {
                await recordingViewModel.startRecording()
            }
        } else {
            Task {
                await recordingViewModel.stopRecording()
            }
        }
    }
}

// MARK: - Preview

#Preview("Main Translation View") {
    MainTranslationView()
        .environment(TranslationViewModel())
        .environment(RecordingViewModel())
        .frame(width: 700, height: 600)
}
