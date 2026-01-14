//
//  FirstRunOverlayView.swift
//  Votra
//
//  First-run overlay with quick-start tips for new users (FR-046).
//

import SwiftUI

/// Overlay view showing quick-start tips for first-time users
struct FirstRunOverlayView: View {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    @State private var currentStep = 0
    private let tips = FirstRunTip.allTips

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }

            // Tip card
            VStack(spacing: 24) {
                // Header
                headerView

                // Tip content
                tipContentView

                // Navigation
                navigationView
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)

            Text(String(localized: "Welcome to Votra"))
                .font(.title2)
                .bold()

            Text(String(localized: "Real-time voice translation"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tip Content

    @ViewBuilder private var tipContentView: some View {
        let tip = tips[currentStep]

        VStack(spacing: 16) {
            // Tip icon
            Image(systemName: tip.icon)
                .font(.system(size: 32))
                .foregroundStyle(tip.color)
                .frame(width: 60, height: 60)
                .background {
                    Circle()
                        .fill(tip.color.opacity(0.15))
                }

            // Tip title and description
            VStack(spacing: 8) {
                Text(tip.title)
                    .font(.headline)

                Text(tip.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.1))
        }
        .id(currentStep) // Force view recreation for animation
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Navigation

    private var navigationView: some View {
        VStack(spacing: 16) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<tips.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }

            // Buttons
            HStack(spacing: 16) {
                // Skip button (only show if not on last tip)
                if currentStep < tips.count - 1 {
                    Button(String(localized: "Skip")) {
                        dismissOverlay()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Next/Done button
                Button {
                    if currentStep < tips.count - 1 {
                        withAnimation(.spring(duration: 0.3)) {
                            currentStep += 1
                        }
                    } else {
                        dismissOverlay()
                    }
                } label: {
                    Text(currentStep < tips.count - 1 ? String(localized: "Next") : String(localized: "Get Started"))
                        .frame(minWidth: 100)
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
            }
        }
    }

    // MARK: - Actions

    private func dismissOverlay() {
        withAnimation(.spring(duration: 0.3)) {
            isPresented = false
        }
        onDismiss()
    }
}

// MARK: - First Run Tips

struct FirstRunTip {
    static let allTips: [FirstRunTip] = [
        FirstRunTip(
            icon: "globe",
            title: "Choose Your Languages",
            description: "Select the source language you'll speak and the target language for translation at the bottom of the overlay.",
            color: .blue
        ),
        FirstRunTip(
            icon: "play.fill",
            title: "Start Translating",
            description: "Tap the Start button to begin real-time translation. Speak naturally and see translations appear instantly.",
            color: .green
        ),
        FirstRunTip(
            icon: "speaker.wave.2.fill",
            title: "Listen to Translations",
            description: "Enable auto-speak to hear translations automatically, or hover over a message bubble to manually trigger speech.",
            color: .orange
        ),
        FirstRunTip(
            icon: "record.circle",
            title: "Record Sessions",
            description: "Tap the Record button to save your conversation. Export recordings as audio files or transcripts later.",
            color: .red
        ),
        FirstRunTip(
            icon: "sun.max",
            title: "Adjust Visibility",
            description: "Use the opacity slider in the header to make the overlay more transparent when you need to see content behind it.",
            color: .yellow
        )
    ]

    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
}

// MARK: - Preview

#Preview("First Run Overlay") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        FirstRunOverlayView(
            isPresented: .constant(true)
        ) {}
    }
    .frame(width: 500, height: 600)
}
