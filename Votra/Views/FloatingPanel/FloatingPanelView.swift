//
//  FloatingPanelView.swift
//  Votra
//
//  Main floating panel view combining message bubbles and control bar with Liquid Glass styling.
//

import SwiftUI

/// Main floating panel view for real-time translation overlay
struct FloatingPanelView: View {
    @Bindable var viewModel: TranslationViewModel
    @Binding var isRecording: Bool
    @Binding var opacity: Double

    let availableSourceLanguages: [Locale]
    let availableTargetLanguages: [Locale]
    let isOffline: Bool

    let onStartStop: () async -> Void
    let onRecordToggle: () -> Void
    let onSpeak: (ConversationMessage) async -> Void

    @State private var isMinimized = false
    @State private var showIdleIndicator = true
    @State private var showFirstRunOverlay = false
    @State private var showPermissionGuidance = false

    var body: some View {
        VStack(spacing: 0) {
            if isMinimized {
                minimizedView
            } else {
                expandedView
            }
        }
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: isMinimized ? 50 : 400, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .opacity(opacity)
        .overlay {
            // First-run overlay for new users (FR-046)
            if showFirstRunOverlay {
                FirstRunOverlayView(
                    isPresented: $showFirstRunOverlay
                ) {
                    UserPreferences.shared.hasCompletedFirstRun = true
                }
            }
        }
        .onAppear {
            // Check if this is the first run
            if !UserPreferences.shared.hasCompletedFirstRun {
                showFirstRunOverlay = true
            }
        }
        .onChange(of: viewModel.messages) { _, newMessages in
            // Hide idle indicator when messages arrive
            if !newMessages.isEmpty && showIdleIndicator {
                withAnimation {
                    showIdleIndicator = false
                }
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            // Show permission guidance when entering error state with permission issue
            if case .error = newState, viewModel.requiredPermissionType != nil {
                showPermissionGuidance = true
            }
        }
        .sheet(isPresented: $showPermissionGuidance) {
            if let permissionType = viewModel.requiredPermissionType {
                PermissionGuidanceView(permissionType: permissionType) {
                    showPermissionGuidance = false
                }
            }
        }
    }

    // MARK: - Expanded View

    @ViewBuilder private var expandedView: some View {
        VStack(spacing: 0) {
            // Header with minimize button
            headerView

            Divider()

            // Messages area
            messagesArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Control bar
            ControlBarView(
                sourceLocale: Binding(
                    get: { viewModel.configuration.sourceLocale },
                    set: { viewModel.configuration.sourceLocale = $0 }
                ),
                targetLocale: Binding(
                    get: { viewModel.configuration.targetLocale },
                    set: { viewModel.configuration.targetLocale = $0 }
                ),
                autoSpeak: Binding(
                    get: { viewModel.configuration.autoSpeak },
                    set: { viewModel.configuration.autoSpeak = $0 }
                ),
                isRecording: $isRecording,
                audioInputMode: Binding(
                    get: { viewModel.configuration.audioInputMode },
                    set: { viewModel.configuration.audioInputMode = $0 }
                ),
                accurateMode: Binding(
                    get: { UserPreferences.shared.accurateRecognitionMode },
                    set: { UserPreferences.shared.accurateRecognitionMode = $0 }
                ),
                availableSourceLanguages: availableSourceLanguages,
                availableTargetLanguages: availableTargetLanguages,
                isTranslating: viewModel.state == .active,
                isOffline: isOffline,
                onStartStop: {
                    Task {
                        await onStartStop()
                    }
                },
                onSwapLanguages: swapLanguages,
                onRecordToggle: onRecordToggle
            )
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            // App icon and title
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Votra")
                    .font(.headline)
            }

            Spacer()

            // Audio source picker
            audioSourcePicker

            // Clear button
            if !viewModel.messages.isEmpty {
                Button {
                    viewModel.clearMessages()
                    withAnimation {
                        showIdleIndicator = true
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Clear messages"))
            }

            // Opacity slider
            HStack(spacing: 4) {
                Image(systemName: "sun.min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $opacity, in: 0.3...1.0)
                    .frame(width: 80)
                Image(systemName: "sun.max")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Minimize button
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isMinimized = true
                }
            } label: {
                Image(systemName: "chevron.up.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(String(localized: "Minimize panel"))
        }
        .padding()
    }

    // MARK: - Messages Area

    @ViewBuilder private var messagesArea: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Idle state indicator
                if showIdleIndicator && viewModel.messages.isEmpty && viewModel.state == .active {
                    IdleIndicatorView()
                        .transition(.opacity)
                }

                // Messages grouped by speaker
                ForEach(viewModel.messages.groupedBySpeaker(), id: \.0) { _, messages in
                    MessageGroupView(
                        messages: messages,
                        speakerName: messages.first?.isFromUser == true ? String(localized: "Me") : String(localized: "Remote"),
                        speakerColor: messages.first?.isFromUser == true ? .blue : .green
                    ) { message in
                        Task {
                            await onSpeak(message)
                        }
                    }
                }

                // Interim message
                if let transcription = viewModel.interimTranscription {
                    InterimMessageView(
                        transcription: transcription,
                        translation: viewModel.interimTranslation,
                        source: viewModel.interimSource
                    )
                }
            }
            .padding()
        }
        .defaultScrollAnchor(.bottom)
        .scrollIndicators(.hidden)
    }

    // MARK: - Minimized View

    private var minimizedView: some View {
        HStack {
            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.state == .active ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(viewModel.state == .active ? String(localized: "Translating") : String(localized: "Paused"))
                    .font(.caption)
            }

            Spacer()

            // Expand button
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isMinimized = false
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .buttonStyle(.plain)
            .help(String(localized: "Expand"))
        }
        .padding()
    }

    // MARK: - Audio Source Picker

    private var audioSourcePicker: some View {
        Menu {
            ForEach(viewModel.availableAudioSources) { source in
                Button {
                    viewModel.selectAudioSource(source)
                } label: {
                    Label {
                        Text(source.displayName)
                    } icon: {
                        AudioSourceIconView(source: source, size: 16)
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
            HStack(spacing: 4) {
                AudioSourceIconView(source: viewModel.selectedAudioSource, size: 16)
                Text(viewModel.selectedAudioSource.displayName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.2))
            .clipShape(.capsule)
        }
        .menuStyle(.button)
        .menuIndicator(.visible)
        .fixedSize()
        .help(String(localized: "Audio Sources"))
        .task {
            await viewModel.refreshAudioSources()
        }
    }

    // MARK: - Helpers

    private func swapLanguages() {
        let temp = viewModel.configuration.sourceLocale
        viewModel.configuration.sourceLocale = viewModel.configuration.targetLocale
        viewModel.configuration.targetLocale = temp
    }
}

// MARK: - Idle Indicator View

/// View shown when translation is active but no speech is detected
struct IdleIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            // Waveform animation
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.tint.opacity(0.6))
                        .frame(width: 4, height: isAnimating ? CGFloat.random(in: 8...24) : 8)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .frame(height: 24)

            Text(String(localized: "Listening..."))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(localized: "Start speaking to translate"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .glassCard()
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Audio Source Icon View

/// View for displaying an audio source's icon
struct AudioSourceIconView: View {
    let source: AudioSourceInfo
    let size: CGFloat

    var body: some View {
        Group {
            if source.isAllSystemAudio {
                Image(systemName: "speaker.wave.3.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint)
            } else if let bundleIdentifier = source.bundleIdentifier,
                      let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Floating Panel") {
    FloatingPanelView(
        viewModel: TranslationViewModel(),
        isRecording: .constant(false),
        opacity: .constant(1.0),
        availableSourceLanguages: [
            Locale(identifier: "en"),
            Locale(identifier: "zh-Hans")
        ],
        availableTargetLanguages: [
            Locale(identifier: "en"),
            Locale(identifier: "zh-Hans")
        ],
        isOffline: false,
        onStartStop: {},
        onRecordToggle: {},
        onSpeak: { _ in }
    )
    .frame(width: 400, height: 600)
}
