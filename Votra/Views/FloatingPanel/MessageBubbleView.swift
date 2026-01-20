//
//  MessageBubbleView.swift
//  Votra
//
//  Chat bubble view for displaying translation messages.
//

import SwiftUI

/// View displaying a single message bubble with original and translated text
struct MessageBubbleView: View {
    let message: ConversationMessage
    let speakerName: String?
    let speakerColor: Color
    let onSpeak: (() -> Void)?
    @State private var isHovering = false

    init(
        message: ConversationMessage,
        speakerName: String? = nil,
        speakerColor: Color = .blue,
        onSpeak: (() -> Void)? = nil
    ) {
        self.message = message
        self.speakerName = speakerName
        self.speakerColor = speakerColor
        self.onSpeak = onSpeak
    }

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Speaker label (if provided)
                if let name = speakerName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(speakerColor)
                }

                // Bubble content
                VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
                    // Original text (smaller)
                    Text(message.originalText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Translated text (larger)
                    Text(message.translatedText)
                        .font(.body)
                        .foregroundStyle(.primary)

                    // Speak button on hover
                    if isHovering, let onSpeak = onSpeak {
                        Button {
                            onSpeak()
                        } label: {
                            Label(String(localized: "Speak"), systemImage: "speaker.wave.2")
                                .font(.caption)
                        }
                        .buttonStyle(GlassButtonStyle())
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(12)
                .background {
                    bubbleBackground
                }
                .clipShape(.rect(cornerRadius: 16))

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !message.isFromUser {
                Spacer(minLength: 40)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    @ViewBuilder private var bubbleBackground: some View {
        if message.isFromUser {
            // User's message - aligned right, accent color
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 4,
                topTrailingRadius: 16
            )
            .fill(.tint.opacity(0.3))
        } else {
            // Remote participant's message - aligned left
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 4,
                bottomTrailingRadius: 16,
                topTrailingRadius: 16
            )
            .fill(speakerColor.opacity(0.2))
        }
    }
}

// MARK: - Interim Message View

/// View for displaying interim (not yet final) transcription/translation
struct InterimMessageView: View {
    let transcription: String?
    let translation: String?
    let source: AudioSource?

    var body: some View {
        if let transcription = transcription {
            HStack {
                if source == .microphone {
                    Spacer(minLength: 40)
                }

                VStack(alignment: source == .microphone ? .trailing : .leading, spacing: 4) {
                    // Interim transcription
                    Text(transcription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Interim translation (if available)
                    if let translation = translation {
                        Text(translation)
                            .font(.body)
                            .foregroundStyle(.primary.opacity(0.7))
                    }

                    // Typing indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(.secondary)
                                .frame(width: 6, height: 6)
                                .opacity(0.5)
                        }
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

                if source != .microphone {
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Message Group View

/// View for displaying a group of consecutive messages from the same speaker
struct MessageGroupView: View {
    let messages: [ConversationMessage]
    let speakerName: String?
    let speakerColor: Color
    let onSpeak: ((ConversationMessage) -> Void)?

    var body: some View {
        VStack(alignment: messages.first?.isFromUser == true ? .trailing : .leading, spacing: 4) {
            // Speaker header (shown once for the group)
            if let name = speakerName, let firstMessage = messages.first {
                HStack {
                    if firstMessage.isFromUser {
                        Spacer()
                    }
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(speakerColor)
                    if !firstMessage.isFromUser {
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }

            // Messages in the group
            ForEach(messages) { message in
                MessageBubbleView(
                    message: message,
                    speakerName: nil, // Don't repeat speaker name within group
                    speakerColor: speakerColor,
                    onSpeak: onSpeak != nil ? { onSpeak?(message) } : nil
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Message Bubbles") {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: ConversationMessage(
                originalText: "Hello, how are you today?",
                translatedText: "你好，你今天好吗？",
                sourceLocale: Locale(identifier: "en"),
                targetLocale: Locale(identifier: "zh-Hans"),
                source: .microphone,
                timestamp: Date(),
                isFinal: true
            ),
            speakerName: "Me",
            speakerColor: .blue
        ) {
            print("Speak tapped")
        }

        MessageBubbleView(
            message: ConversationMessage(
                originalText: "我很好，谢谢！你呢？",
                translatedText: "I'm good, thank you! How about you?",
                sourceLocale: Locale(identifier: "zh-Hans"),
                targetLocale: Locale(identifier: "en"),
                source: .systemAudio,
                timestamp: Date(),
                isFinal: true
            ),
            speakerName: "Remote",
            speakerColor: .green
        ) {
            print("Speak tapped")
        }

        InterimMessageView(
            transcription: "I am currently typing...",
            translation: "我正在打字...",
            source: .microphone
        )
    }
    .padding()
    .frame(width: 400)
}
