//
//  ChatMessageTests.swift
//  VotraTests
//
//  Comprehensive unit tests for the ChatMessage model.
//

import Testing
import Foundation
@testable import Votra

/// Namespace for ChatMessage tests
enum ChatMessageTests {}

// MARK: - ChatMessageRole Tests

@Suite("ChatMessageRole Tests")
@MainActor
struct ChatMessageRoleTests {
    @Test("Raw values are correct strings")
    func rawValues() {
        #expect(ChatMessageRole.user.rawValue == "user")
        #expect(ChatMessageRole.remote.rawValue == "remote")
        #expect(ChatMessageRole.system.rawValue == "system")
    }

    @Test("CaseIterable returns all cases")
    func caseIterable() {
        let allCases = ChatMessageRole.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.user))
        #expect(allCases.contains(.remote))
        #expect(allCases.contains(.system))
    }

    @Test("Equality works correctly")
    func equality() {
        // swiftlint:disable identical_operands
        #expect(ChatMessageRole.user == ChatMessageRole.user)
        #expect(ChatMessageRole.remote == ChatMessageRole.remote)
        #expect(ChatMessageRole.system == ChatMessageRole.system)
        // swiftlint:enable identical_operands
        #expect(ChatMessageRole.user != ChatMessageRole.remote)
        #expect(ChatMessageRole.user != ChatMessageRole.system)
        #expect(ChatMessageRole.remote != ChatMessageRole.system)
    }

    @Test("Codable encoding and decoding")
    func codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for role in ChatMessageRole.allCases {
            let data = try encoder.encode(role)
            let decoded = try decoder.decode(ChatMessageRole.self, from: data)
            #expect(decoded == role)
        }
    }

    @Test("Sendable conformance - can be used across concurrency boundaries")
    func sendableConformance() async {
        let role: ChatMessageRole = .user

        await Task {
            #expect(role == .user)
        }.value
    }
}

// MARK: - ChatMessage Initialization Tests

@Suite("ChatMessage Initialization Tests")
@MainActor
struct ChatMessageInitializationTests {
    @Test("Default initializer with role creates valid message")
    func defaultInitializerWithRole() {
        let timestamp = Date()
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message.originalText == "Hello")
        #expect(message.translatedText == "Hola")
        #expect(message.sourceLocaleIdentifier == "en")
        #expect(message.targetLocaleIdentifier == "es")
        #expect(message.role == .user)
        #expect(message.timestamp == timestamp)
        #expect(message.isFinal == true)
    }

    @Test("Initializer with custom ID preserves the ID")
    func initializerWithCustomID() {
        let customID = UUID()
        let message = ChatMessage(
            id: customID,
            originalText: "Test",
            translatedText: "Prueba",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.id == customID)
    }

    @Test("Default ID is generated when not provided")
    func defaultIDGenerated() {
        let message1 = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        let message2 = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        // Each message should have a unique ID
        #expect(message1.id != message2.id)
    }

    @Test("Initializer with AudioSource creates correct role for microphone")
    func initializerWithMicrophoneSource() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            source: .microphone,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.role == .user)
        #expect(message.isFromUser == true)
    }

    @Test("Initializer with AudioSource creates correct role for system audio")
    func initializerWithSystemAudioSource() {
        let message = ChatMessage(
            originalText: "Hola",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "es"),
            targetLocale: Locale(identifier: "en"),
            source: .systemAudio,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.role == .remote)
        #expect(message.isFromRemote == true)
    }

    @Test("Interim message initialization with isFinal false")
    func interimMessageInitialization() {
        let message = ChatMessage(
            originalText: "Hello wor",
            translatedText: "",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: false
        )

        #expect(message.isFinal == false)
    }

    @Test("Empty strings are preserved")
    func emptyStringsPreserved() {
        let message = ChatMessage(
            originalText: "",
            translatedText: "",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.originalText.isEmpty)
        #expect(message.translatedText.isEmpty)
    }

    @Test("Unicode text is preserved correctly")
    func unicodeTextPreserved() {
        let originalText = "Hello, world!"
        let translatedText = "Hello, world!"
        let chineseOriginal = "Hello"
        let chineseTranslated = "Hello"
        let emojiText = "Hey!"

        let message = ChatMessage(
            originalText: originalText,
            translatedText: translatedText,
            sourceLocale: Locale(identifier: "ja"),
            targetLocale: Locale(identifier: "zh-Hans"),
            role: .remote,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.originalText == originalText)
        #expect(message.translatedText == translatedText)

        // Test with Chinese characters
        let chineseMessage = ChatMessage(
            originalText: chineseOriginal,
            translatedText: chineseTranslated,
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "zh-Hans"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(chineseMessage.originalText == chineseOriginal)
        #expect(chineseMessage.translatedText == chineseTranslated)

        // Test with emoji (treating as regular text)
        let emojiMessage = ChatMessage(
            originalText: emojiText,
            translatedText: emojiText,
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(emojiMessage.originalText == emojiText)
    }
}

// MARK: - ChatMessage Role Tests

@Suite("ChatMessage Role Property Tests")
@MainActor
struct ChatMessageRolePropertyTests {
    @Test("isFromUser is true for user role")
    func isFromUserForUserRole() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.isFromUser == true)
        #expect(message.isFromRemote == false)
        #expect(message.isSystemMessage == false)
    }

    @Test("isFromRemote is true for remote role")
    func isFromRemoteForRemoteRole() {
        let message = ChatMessage(
            originalText: "Hola",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "es"),
            targetLocale: Locale(identifier: "en"),
            role: .remote,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.isFromUser == false)
        #expect(message.isFromRemote == true)
        #expect(message.isSystemMessage == false)
    }

    @Test("isSystemMessage is true for system role")
    func isSystemMessageForSystemRole() {
        let message = ChatMessage(
            originalText: "Connection established",
            translatedText: "Connection established",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "en"),
            role: .system,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.isFromUser == false)
        #expect(message.isFromRemote == false)
        #expect(message.isSystemMessage == true)
    }
}

// MARK: - ChatMessage Locale Tests

@Suite("ChatMessage Locale Tests")
@MainActor
struct ChatMessageLocaleTests {
    @Test("sourceLocale computed property returns correct locale")
    func sourceLocaleComputedProperty() {
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "ja"),
            targetLocale: Locale(identifier: "en"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.sourceLocale.identifier == "ja")
    }

    @Test("targetLocale computed property returns correct locale")
    func targetLocaleComputedProperty() {
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "ko"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.targetLocale.identifier == "ko")
    }

    @Test("Various locale identifiers are preserved correctly")
    func variousLocaleIdentifiers() {
        let localeIdentifiers = [
            ("en", "es"),
            ("zh-Hans", "en"),
            ("zh-Hant", "ja"),
            ("ja", "ko"),
            ("fr", "de"),
            ("pt-BR", "en-US"),
            ("en-GB", "en-US")
        ]

        for (sourceId, targetId) in localeIdentifiers {
            let message = ChatMessage(
                originalText: "Test",
                translatedText: "Test",
                sourceLocale: Locale(identifier: sourceId),
                targetLocale: Locale(identifier: targetId),
                role: .user,
                timestamp: Date(),
                isFinal: true
            )

            #expect(message.sourceLocaleIdentifier == sourceId)
            #expect(message.targetLocaleIdentifier == targetId)
        }
    }

    @Test("Same source and target locale is allowed")
    func sameSourceAndTargetLocale() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "en"),
            role: .system,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.sourceLocaleIdentifier == message.targetLocaleIdentifier)
    }
}

// MARK: - ChatMessage Timestamp Tests

@Suite("ChatMessage Timestamp Tests")
@MainActor
struct ChatMessageTimestampTests {
    @Test("Timestamp is preserved exactly")
    func timestampPreserved() {
        let timestamp = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message.timestamp == timestamp)
        #expect(message.timestamp.timeIntervalSince1970 == 1704067200)
    }

    @Test("Age computed property returns positive value for past timestamps")
    func ageComputedPropertyPositive() {
        let pastTimestamp = Date(timeIntervalSinceNow: -60) // 60 seconds ago
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: pastTimestamp,
            isFinal: true
        )

        #expect(message.age >= 59) // Allow for slight timing differences
        #expect(message.age <= 62)
    }

    @Test("Age computed property returns approximately zero for current timestamp")
    func ageComputedPropertyZero() {
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.age >= 0)
        #expect(message.age < 1) // Should be less than 1 second
    }

    @Test("Different timestamps create different messages")
    func differentTimestamps() {
        let timestamp1 = Date(timeIntervalSince1970: 1000)
        let timestamp2 = Date(timeIntervalSince1970: 2000)

        let message1 = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp1,
            isFinal: true
        )

        let message2 = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp2,
            isFinal: true
        )

        #expect(message1.timestamp != message2.timestamp)
    }

    @Test("Timestamp with subsecond precision is preserved")
    func subsecondPrecision() {
        let timestamp = Date(timeIntervalSince1970: 1704067200.123456)
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message.timestamp.timeIntervalSince1970 == 1704067200.123456)
    }
}

// MARK: - ChatMessage Content Property Tests

@Suite("ChatMessage Content Property Tests")
@MainActor
struct ChatMessageContentPropertyTests {
    @Test("displayText returns translated text when available")
    func displayTextWithTranslation() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.displayText == "Hola")
    }

    @Test("displayText returns original text when translation is empty")
    func displayTextWithoutTranslation() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: false
        )

        #expect(message.displayText == "Hello")
    }

    @Test("hasTranslation is true when translation differs from original")
    func hasTranslationTrue() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.hasTranslation == true)
    }

    @Test("hasTranslation is false when translation is empty")
    func hasTranslationFalseEmpty() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: false
        )

        #expect(message.hasTranslation == false)
    }

    @Test("hasTranslation is false when translation equals original")
    func hasTranslationFalseSameText() {
        let message = ChatMessage(
            originalText: "Hello",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "en"),
            role: .system,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.hasTranslation == false)
    }

    @Test("isFinal property reflects initialization - true case")
    func isFinalTrue() {
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.isFinal == true)
    }

    @Test("isFinal property reflects initialization - false case")
    func isFinalFalse() {
        let message = ChatMessage(
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: false
        )

        #expect(message.isFinal == false)
    }
}

// MARK: - ChatMessage Factory Method Tests

@Suite("ChatMessage Factory Method Tests")
@MainActor
struct ChatMessageFactoryMethodTests {
    @Test("userMessage factory creates user role message")
    func userMessageFactory() {
        let message = ChatMessage.userMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es")
        )

        #expect(message.role == .user)
        #expect(message.isFromUser == true)
        #expect(message.isFinal == true)
    }

    @Test("userMessage factory with custom parameters")
    func userMessageFactoryWithCustomParameters() {
        let customID = UUID()
        let customTimestamp = Date(timeIntervalSince1970: 1000)

        let message = ChatMessage.userMessage(
            id: customID,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            timestamp: customTimestamp,
            isFinal: false
        )

        #expect(message.id == customID)
        #expect(message.timestamp == customTimestamp)
        #expect(message.isFinal == false)
    }

    @Test("remoteMessage factory creates remote role message")
    func remoteMessageFactory() {
        let message = ChatMessage.remoteMessage(
            originalText: "Hola",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "es"),
            targetLocale: Locale(identifier: "en")
        )

        #expect(message.role == .remote)
        #expect(message.isFromRemote == true)
        #expect(message.isFinal == true)
    }

    @Test("remoteMessage factory with custom parameters")
    func remoteMessageFactoryWithCustomParameters() {
        let customID = UUID()
        let customTimestamp = Date(timeIntervalSince1970: 2000)

        let message = ChatMessage.remoteMessage(
            id: customID,
            originalText: "Bonjour",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "fr"),
            targetLocale: Locale(identifier: "en"),
            timestamp: customTimestamp,
            isFinal: false
        )

        #expect(message.id == customID)
        #expect(message.timestamp == customTimestamp)
        #expect(message.isFinal == false)
    }

    @Test("systemMessage factory creates system role message")
    func systemMessageFactory() {
        let message = ChatMessage.systemMessage(
            text: "Connection established",
            locale: Locale(identifier: "en")
        )

        #expect(message.role == .system)
        #expect(message.isSystemMessage == true)
        #expect(message.originalText == "Connection established")
        #expect(message.translatedText == "Connection established")
        #expect(message.sourceLocaleIdentifier == "en")
        #expect(message.targetLocaleIdentifier == "en")
        #expect(message.isFinal == true)
    }

    @Test("systemMessage factory with custom parameters")
    func systemMessageFactoryWithCustomParameters() {
        let customID = UUID()
        let customTimestamp = Date(timeIntervalSince1970: 3000)

        let message = ChatMessage.systemMessage(
            id: customID,
            text: "Session ended",
            locale: Locale(identifier: "ja"),
            timestamp: customTimestamp
        )

        #expect(message.id == customID)
        #expect(message.timestamp == customTimestamp)
        #expect(message.sourceLocaleIdentifier == "ja")
        #expect(message.targetLocaleIdentifier == "ja")
    }
}

// MARK: - ChatMessage Equatable Tests

@Suite("ChatMessage Equatable Tests")
@MainActor
struct ChatMessageEquatableTests {
    @Test("Equal messages with same properties")
    func equalMessages() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1 == message2)
    }

    @Test("Messages with different IDs are not equal")
    func differentIDs() {
        let timestamp = Date()

        let message1 = ChatMessage(
            id: UUID(),
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: UUID(),
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1 != message2)
    }

    @Test("Messages with different original text are not equal")
    func differentOriginalText() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hi",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1 != message2)
    }

    @Test("Messages with different translated text are not equal")
    func differentTranslatedText() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Ola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1 != message2)
    }

    @Test("Messages with different roles are not equal")
    func differentRoles() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .remote,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1 != message2)
    }

    @Test("Messages with different timestamps are not equal")
    func differentTimestamps() {
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(timeIntervalSince1970: 1000),
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(timeIntervalSince1970: 2000),
            isFinal: true
        )

        #expect(message1 != message2)
    }

    @Test("Messages with different isFinal values are not equal")
    func differentIsFinal() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: false
        )

        #expect(message1 != message2)
    }

    @Test("Messages with different source locales are not equal")
    func differentSourceLocales() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en-US"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1 != message2)
    }
}

// MARK: - ChatMessage Hashable Tests

@Suite("ChatMessage Hashable Tests")
@MainActor
struct ChatMessageHashableTests {
    @Test("Equal messages have equal hash values")
    func equalHashValues() {
        let timestamp = Date()
        let id = UUID()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        #expect(message1.hashValue == message2.hashValue)
    }

    @Test("Messages can be used in Set")
    func setUsage() {
        let message1 = ChatMessage.userMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es")
        )

        let message2 = ChatMessage.remoteMessage(
            originalText: "Bonjour",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "fr"),
            targetLocale: Locale(identifier: "en")
        )

        var messageSet: Set<ChatMessage> = []
        messageSet.insert(message1)
        messageSet.insert(message2)

        #expect(messageSet.count == 2)
        #expect(messageSet.contains(message1))
        #expect(messageSet.contains(message2))
    }

    @Test("Duplicate messages in Set are handled correctly")
    func duplicateInSet() {
        let id = UUID()
        let timestamp = Date()

        let message1 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let message2 = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        var messageSet: Set<ChatMessage> = []
        messageSet.insert(message1)
        messageSet.insert(message2)

        #expect(messageSet.count == 1)
    }

    @Test("Messages can be used as Dictionary keys")
    func dictionaryKeyUsage() {
        let message1 = ChatMessage.userMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es")
        )

        let message2 = ChatMessage.remoteMessage(
            originalText: "Bonjour",
            translatedText: "Hello",
            sourceLocale: Locale(identifier: "fr"),
            targetLocale: Locale(identifier: "en")
        )

        var messageDict: [ChatMessage: String] = [:]
        messageDict[message1] = "First"
        messageDict[message2] = "Second"

        #expect(messageDict[message1] == "First")
        #expect(messageDict[message2] == "Second")
    }
}

// MARK: - ChatMessage Identifiable Tests

@Suite("ChatMessage Identifiable Tests")
@MainActor
struct ChatMessageIdentifiableTests {
    @Test("Identifiable conformance uses id property")
    func identifiableConformance() {
        let customID = UUID()
        let message = ChatMessage(
            id: customID,
            originalText: "Test",
            translatedText: "Test",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: true
        )

        #expect(message.id == customID)
    }

    @Test("Messages can be identified in a collection")
    func identifiableInCollection() {
        let messages = [
            ChatMessage.userMessage(
                originalText: "Hello",
                translatedText: "Hola",
                sourceLocale: Locale(identifier: "en"),
                targetLocale: Locale(identifier: "es")
            ),
            ChatMessage.remoteMessage(
                originalText: "Bonjour",
                translatedText: "Hello",
                sourceLocale: Locale(identifier: "fr"),
                targetLocale: Locale(identifier: "en")
            ),
            ChatMessage.systemMessage(
                text: "Connected",
                locale: Locale(identifier: "en")
            )
        ]

        // All IDs should be unique
        let ids = messages.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == messages.count)
    }
}

// MARK: - ChatMessage Codable Tests

@Suite("ChatMessage Codable Tests")
@MainActor
struct ChatMessageCodableTests {
    @Test("Encoding and decoding preserves all properties")
    func encodingDecodingPreservesProperties() throws {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1704067200) // Fixed timestamp for testing

        let original = ChatMessage(
            id: id,
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: timestamp,
            isFinal: true
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.originalText == original.originalText)
        #expect(decoded.translatedText == original.translatedText)
        #expect(decoded.sourceLocaleIdentifier == original.sourceLocaleIdentifier)
        #expect(decoded.targetLocaleIdentifier == original.targetLocaleIdentifier)
        #expect(decoded.role == original.role)
        #expect(decoded.timestamp == original.timestamp)
        #expect(decoded.isFinal == original.isFinal)
    }

    @Test("All role types can be encoded and decoded")
    func allRolesEncodeDecode() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for role in ChatMessageRole.allCases {
            let message = ChatMessage(
                originalText: "Test",
                translatedText: "Test",
                sourceLocale: Locale(identifier: "en"),
                targetLocale: Locale(identifier: "es"),
                role: role,
                timestamp: Date(),
                isFinal: true
            )

            let data = try encoder.encode(message)
            let decoded = try decoder.decode(ChatMessage.self, from: data)

            #expect(decoded.role == role)
        }
    }

    @Test("Unicode text survives encoding and decoding")
    func unicodeSurvivesEncoding() throws {
        let originalText = "Hello"
        let translatedText = "Translated"

        let message = ChatMessage(
            originalText: originalText,
            translatedText: translatedText,
            sourceLocale: Locale(identifier: "ja"),
            targetLocale: Locale(identifier: "zh-Hans"),
            role: .remote,
            timestamp: Date(),
            isFinal: true
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        #expect(decoded.originalText == originalText)
        #expect(decoded.translatedText == translatedText)
    }

    @Test("Empty strings are preserved through encoding")
    func emptyStringsPreservedThroughEncoding() throws {
        let message = ChatMessage(
            originalText: "",
            translatedText: "",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es"),
            role: .user,
            timestamp: Date(),
            isFinal: false
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        #expect(decoded.originalText.isEmpty)
        #expect(decoded.translatedText.isEmpty)
    }

    @Test("Array of messages can be encoded and decoded")
    func arrayEncodeDecode() throws {
        let messages = [
            ChatMessage.userMessage(
                originalText: "Hello",
                translatedText: "Hola",
                sourceLocale: Locale(identifier: "en"),
                targetLocale: Locale(identifier: "es")
            ),
            ChatMessage.remoteMessage(
                originalText: "Bonjour",
                translatedText: "Hello",
                sourceLocale: Locale(identifier: "fr"),
                targetLocale: Locale(identifier: "en")
            )
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(messages)
        let decoded = try decoder.decode([ChatMessage].self, from: data)

        #expect(decoded.count == messages.count)
        for (original, decodedMessage) in zip(messages, decoded) {
            #expect(decodedMessage.id == original.id)
            #expect(decodedMessage.originalText == original.originalText)
            #expect(decodedMessage.role == original.role)
        }
    }
}

// MARK: - ChatMessage Sendable Tests

@Suite("ChatMessage Sendable Tests")
@MainActor
struct ChatMessageSendableTests {
    @Test("Message can be sent across concurrency boundaries")
    func sendableConformance() async {
        let message = ChatMessage.userMessage(
            originalText: "Hello",
            translatedText: "Hola",
            sourceLocale: Locale(identifier: "en"),
            targetLocale: Locale(identifier: "es")
        )

        let result = await Task.detached {
            // Access message from a different isolation context
            message.originalText
        }.value

        #expect(result == "Hello")
    }

    @Test("Array of messages can be sent across concurrency boundaries")
    func sendableArrayConformance() async {
        let messages = [
            ChatMessage.userMessage(
                originalText: "Hello",
                translatedText: "Hola",
                sourceLocale: Locale(identifier: "en"),
                targetLocale: Locale(identifier: "es")
            ),
            ChatMessage.remoteMessage(
                originalText: "Bonjour",
                translatedText: "Hello",
                sourceLocale: Locale(identifier: "fr"),
                targetLocale: Locale(identifier: "en")
            )
        ]

        let count = await Task.detached {
            messages.count
        }.value

        #expect(count == 2)
    }
}
