//
//  FloatingPanelContainerView.swift
//  Votra
//
//  Container view that provides an independent translation session for the floating panel.
//  This ensures translation continues even when the main window loses focus.
//

import SwiftUI
@preconcurrency import Translation

/// Container view that wraps FloatingPanelView with its own translation session
/// This ensures the floating panel has an independent session that doesn't get
/// invalidated when the main window loses focus
struct FloatingPanelContainerView: View {
    @Bindable var viewModel: TranslationViewModel
    var preferences: UserPreferences
    @Binding var isRecording: Bool
    @Binding var opacity: Double

    let onStartStop: () async -> Void
    let onRecordToggle: () -> Void
    let onSpeak: (ConversationMessage) async -> Void

    /// Translation configuration for the floating panel's session
    @State private var translationConfiguration: TranslationSession.Configuration?

    var body: some View {
        FloatingPanelView(
            viewModel: viewModel,
            preferences: preferences,
            isRecording: $isRecording,
            opacity: $opacity,
            availableSourceLanguages: Locale.pickerLanguages,
            availableTargetLanguages: Locale.pickerLanguages,
            isOffline: false,
            onStartStop: onStartStop,
            onRecordToggle: onRecordToggle,
            onSpeak: onSpeak
        )
        .onAppear {
            updateTranslationConfiguration()
        }
        .onChange(of: viewModel.configuration.sourceLocale) {
            updateTranslationConfiguration()
        }
        .onChange(of: viewModel.configuration.targetLocale) {
            updateTranslationConfiguration()
        }
        .translationTask(translationConfiguration) { session in
            // Set the session - this provides a backup session for when the main window's is invalidated
            await viewModel.setTranslationSession(session)
        }
    }

    private func updateTranslationConfiguration() {
        translationConfiguration = TranslationSession.Configuration(
            source: viewModel.configuration.sourceLocale.language,
            target: viewModel.configuration.targetLocale.language
        )
    }
}
