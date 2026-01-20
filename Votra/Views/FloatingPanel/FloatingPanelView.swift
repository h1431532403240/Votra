//
//  FloatingPanelView.swift
//  Votra
//
//  Floating panel view with subtitle and conversation modes.
//

import SwiftUI

/// Main floating panel view for real-time translation overlay
struct FloatingPanelView: View {
    @Bindable var viewModel: TranslationViewModel
    var preferences: UserPreferences
    @Binding var isRecording: Bool
    @Binding var opacity: Double

    let availableSourceLanguages: [Locale]
    let availableTargetLanguages: [Locale]
    let isOffline: Bool

    let onStartStop: () async -> Void
    let onRecordToggle: () -> Void
    let onSpeak: (ConversationMessage) async -> Void

    @State private var displayMode: FloatingPanelDisplayMode = UserPreferences.shared.floatingPanelDisplayMode
    @State private var showControls = false
    @State private var showPermissionGuidance = false

    /// Dynamic minimum height based on user settings (message count, text size, show original)
    private var dynamicMinimumHeight: CGFloat {
        switch displayMode {
        case .subtitle:
            return CGFloat(preferences.floatingPanelMinimumHeight)
        case .conversation:
            return displayMode.minimumSize.height
        }
    }

    /// Text size from user preferences
    private var textSize: CGFloat {
        CGFloat(preferences.floatingPanelTextSize)
    }

    /// Message count from user preferences
    private var messageCount: Int {
        preferences.floatingPanelMessageCount
    }

    /// Whether to show original text
    private var showOriginal: Bool {
        preferences.floatingPanelShowOriginal
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Main content
                VStack(spacing: 0) {
                    switch displayMode {
                    case .subtitle:
                        subtitleModeView
                    case .conversation:
                        conversationModeView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial.opacity(opacity))
                .clipShape(.rect(cornerRadius: 16))

                // Quick controls - only show in subtitle mode, fixed position
                if displayMode == .subtitle {
                    quickControls
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
            }
        }
        .frame(
            minWidth: displayMode.minimumSize.width,
            idealWidth: displayMode.recommendedSize.width,
            minHeight: dynamicMinimumHeight,
            idealHeight: dynamicMinimumHeight
        )
        .onChange(of: displayMode) { _, newMode in
            UserPreferences.shared.floatingPanelDisplayMode = newMode
        }
        .onChange(of: viewModel.state) { _, newState in
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

    // MARK: - Subtitle Mode

    private var subtitleModeView: some View {
        VStack(spacing: 0) {
            // Main content area
            HStack(spacing: 12) {
                // Status indicator
                statusIndicator

                // Translation text
                translationTextView
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.trailing, 80) // Reserve space for overlay controls
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Expandable control bar
            if showControls {
                Divider()
                compactControlBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showControls)
    }

    // MARK: - Conversation Mode

    private var conversationModeView: some View {
        VStack(spacing: 0) {
            // Header with controls
            conversationHeader
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            // Messages area (horizontal scrolling)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.messages.suffix(5)) { message in
                        CompactMessageBubble(message: message) {
                            Task { await onSpeak(message) }
                        }
                    }

                    // Interim message
                    if let transcription = viewModel.interimTranscription {
                        InterimBubble(
                            transcription: transcription,
                            translation: viewModel.interimTranslation
                        )
                    }

                    // Empty state
                    if viewModel.messages.isEmpty && viewModel.interimTranscription == nil {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .defaultScrollAnchor(.trailing)

            Divider()

            // Bottom control bar
            conversationControlBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .overlay {
                if viewModel.state == .active {
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(0.8)
                }
            }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .active: return .green
        case .starting: return .yellow
        case .error: return .red
        default: return .gray
        }
    }

    // MARK: - Translation Text (Subtitle Mode)

    private var translationTextView: some View {
        // Reserve one slot for interim message if present
        let hasInterim = viewModel.interimTranscription != nil
        let finalizedCount = hasInterim ? max(messageCount - 1, 0) : messageCount
        let recentMessages = viewModel.messages.suffix(finalizedCount)
        let mainFont = Font.system(size: textSize, weight: .semibold)
        let secondaryFont = Font.system(size: textSize - 2)

        return VStack(alignment: .leading, spacing: 6) {
            if recentMessages.isEmpty && viewModel.interimTranscription == nil {
                // Empty state
                Text(viewModel.state == .active ? String(localized: "Listening...") : String(localized: "Ready"))
                    .font(mainFont)
                    .foregroundStyle(.secondary)
            } else {
                // Show recent finalized messages
                ForEach(Array(recentMessages), id: \.id) { message in
                    VStack(alignment: .leading, spacing: 2) {
                        if showOriginal {
                            Text(message.originalText)
                                .font(secondaryFont)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                        Text(message.translatedText)
                            .font(mainFont)
                            .lineLimit(2)
                            .truncationMode(.head)
                            .foregroundStyle(message.id == viewModel.messages.last?.id ? .primary : .tertiary)
                    }
                }

                // Show interim translation if available
                if let translation = viewModel.interimTranslation {
                    VStack(alignment: .leading, spacing: 2) {
                        if showOriginal, let transcription = viewModel.interimTranscription {
                            Text(transcription)
                                .font(secondaryFont)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                        Text(translation)
                            .font(mainFont)
                            .lineLimit(2)
                            .truncationMode(.head)
                            .foregroundStyle(.primary)
                    }
                } else if let transcription = viewModel.interimTranscription {
                    // Show transcription while waiting for translation
                    Text(transcription)
                        .font(secondaryFont)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
        }
    }

    // MARK: - Quick Controls (Subtitle Mode)

    private var quickControls: some View {
        HStack(spacing: 8) {
            // Mode toggle
            Button {
                withAnimation {
                    displayMode = .conversation
                }
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(String(localized: "Switch to conversation mode"))

            // Start/Stop
            Button {
                Task { await onStartStop() }
            } label: {
                Image(systemName: viewModel.state == .active ? "stop.fill" : "play.fill")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(viewModel.state == .active ? .red : .accentColor)

            // More controls toggle
            Button {
                withAnimation {
                    showControls.toggle()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Compact Control Bar (Subtitle Mode)

    private var compactControlBar: some View {
        HStack(spacing: 16) {
            // Language selection
            HStack(spacing: 8) {
                languagePicker(
                    selection: Binding(
                        get: { viewModel.configuration.sourceLocale },
                        set: { viewModel.configuration.sourceLocale = $0 }
                    ),
                    languages: availableSourceLanguages
                )

                Button {
                    swapLanguages()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                languagePicker(
                    selection: Binding(
                        get: { viewModel.configuration.targetLocale },
                        set: { viewModel.configuration.targetLocale = $0 }
                    ),
                    languages: availableTargetLanguages
                )
            }

            Spacer()

            // Auto-speak
            Toggle(isOn: Binding(
                get: { viewModel.configuration.autoSpeak },
                set: { viewModel.configuration.autoSpeak = $0 }
            )) {
                Image(systemName: "speaker.wave.2")
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            // Opacity
            HStack(spacing: 4) {
                Image(systemName: "sun.min")
                    .font(.caption2)
                Slider(value: $opacity, in: 0.3...1.0)
                    .frame(width: 60)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Conversation Header

    private var conversationHeader: some View {
        HStack(spacing: 12) {
            // App title
            HStack(spacing: 6) {
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(.tint)
                Text("Votra")
                    .font(.subheadline)
                    .bold()
            }

            Spacer()

            // Language display
            HStack(spacing: 6) {
                Text(viewModel.configuration.sourceLocale.localizedString(forIdentifier: viewModel.configuration.sourceLocale.identifier) ?? "")
                    .font(.caption)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text(viewModel.configuration.targetLocale.localizedString(forIdentifier: viewModel.configuration.targetLocale.identifier) ?? "")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            // Mode toggle
            Button {
                withAnimation {
                    displayMode = .subtitle
                }
            } label: {
                Image(systemName: "text.bubble")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(String(localized: "Switch to subtitle mode"))

            // Clear
            if !viewModel.messages.isEmpty {
                Button {
                    viewModel.clearMessages()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Conversation Control Bar

    private var conversationControlBar: some View {
        HStack(spacing: 12) {
            // Language pickers
            languagePicker(
                selection: Binding(
                    get: { viewModel.configuration.sourceLocale },
                    set: { viewModel.configuration.sourceLocale = $0 }
                ),
                languages: availableSourceLanguages
            )

            Button {
                swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            languagePicker(
                selection: Binding(
                    get: { viewModel.configuration.targetLocale },
                    set: { viewModel.configuration.targetLocale = $0 }
                ),
                languages: availableTargetLanguages
            )

            Spacer()

            // Auto-speak
            Toggle(isOn: Binding(
                get: { viewModel.configuration.autoSpeak },
                set: { viewModel.configuration.autoSpeak = $0 }
            )) {
                Label(String(localized: "Auto-speak"), systemImage: "speaker.wave.2")
                    .font(.caption)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            // Start/Stop button
            Button {
                Task { await onStartStop() }
            } label: {
                Label(
                    viewModel.state == .active ? String(localized: "Stop") : String(localized: "Start"),
                    systemImage: viewModel.state == .active ? "stop.fill" : "play.fill"
                )
                .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.state == .active ? "waveform" : "play.circle")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(viewModel.state == .active ? String(localized: "Listening...") : String(localized: "Press Start to begin"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 150)
        .padding()
    }

    // MARK: - Helpers

    private func languagePicker(selection: Binding<Locale>, languages: [Locale]) -> some View {
        Picker("", selection: selection) {
            ForEach(languages, id: \.identifier) { locale in
                Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                    .tag(locale)
            }
        }
        .labelsHidden()
        .fixedSize()
    }

    private func swapLanguages() {
        let temp = viewModel.configuration.sourceLocale
        viewModel.configuration.sourceLocale = viewModel.configuration.targetLocale
        viewModel.configuration.targetLocale = temp
    }
}

// MARK: - Compact Message Bubble

struct CompactMessageBubble: View {
    let message: ConversationMessage
    let onSpeak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.originalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.head)

            Text(message.translatedText)
                .font(.callout)
                .lineLimit(3)
                .truncationMode(.head)
        }
        .padding(10)
        .frame(minWidth: 120, maxWidth: 250, alignment: .leading)
        .background(message.isFromUser ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
        .clipShape(.rect(cornerRadius: 12))
        .onTapGesture {
            onSpeak()
        }
    }
}

// MARK: - Interim Bubble

struct InterimBubble: View {
    let transcription: String
    let translation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transcription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.head)

            if let translation = translation {
                Text(translation)
                    .font(.callout)
                    .lineLimit(3)
                    .truncationMode(.head)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(10)
        .frame(minWidth: 120, maxWidth: 250, alignment: .leading)
        .background(.yellow.opacity(0.15))
        .clipShape(.rect(cornerRadius: 12))
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

#Preview("Subtitle Mode") {
    FloatingPanelView(
        viewModel: TranslationViewModel(),
        preferences: UserPreferences.shared,
        isRecording: .constant(false),
        opacity: .constant(1.0),
        availableSourceLanguages: Locale.pickerLanguages,
        availableTargetLanguages: Locale.pickerLanguages,
        isOffline: false,
        onStartStop: {},
        onRecordToggle: {},
        onSpeak: { _ in }
    )
    .frame(width: 500, height: 120)
}

#Preview("Conversation Mode") {
    FloatingPanelView(
        viewModel: TranslationViewModel(),
        preferences: UserPreferences.shared,
        isRecording: .constant(false),
        opacity: .constant(1.0),
        availableSourceLanguages: Locale.pickerLanguages,
        availableTargetLanguages: Locale.pickerLanguages,
        isOffline: false,
        onStartStop: {},
        onRecordToggle: {},
        onSpeak: { _ in }
    )
    .frame(width: 600, height: 220)
}
