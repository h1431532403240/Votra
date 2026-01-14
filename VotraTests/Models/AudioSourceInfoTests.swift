//
//  AudioSourceInfoTests.swift
//  VotraTests
//
//  Unit tests for the AudioSourceInfo struct.
//

import CoreGraphics
import Foundation
import Testing
@testable import Votra

@Suite("AudioSourceInfo")
@MainActor
struct AudioSourceInfoTests {

    // MARK: - Initialization

    @Test("Initializes with all parameters")
    func initWithAllParameters() {
        let iconData = Data([0x00, 0x01, 0x02])
        let source = AudioSourceInfo(
            id: "test-id",
            name: "Test App",
            bundleIdentifier: "com.test.app",
            isAllSystemAudio: false,
            windowID: 12345,
            windowTitle: "Main Window",
            processID: 9876,
            iconData: iconData
        )

        #expect(source.id == "test-id")
        #expect(source.name == "Test App")
        #expect(source.bundleIdentifier == "com.test.app")
        #expect(source.isAllSystemAudio == false)
        #expect(source.windowID == 12345)
        #expect(source.windowTitle == "Main Window")
        #expect(source.processID == 9876)
        #expect(source.iconData == iconData)
    }

    @Test("Initializes with nil optional parameters")
    func initWithNilOptionalParameters() {
        let source = AudioSourceInfo(
            id: "app-123",
            name: "App Name",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.id == "app-123")
        #expect(source.name == "App Name")
        #expect(source.bundleIdentifier == nil)
        #expect(source.isAllSystemAudio == false)
        #expect(source.windowID == nil)
        #expect(source.windowTitle == nil)
        #expect(source.processID == nil)
        #expect(source.iconData == nil)
    }

    // MARK: - Static Properties

    @Test("allSystemAudio has correct id")
    func allSystemAudioHasCorrectId() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.id == "all-system-audio")
    }

    @Test("allSystemAudio has non-empty name")
    func allSystemAudioHasNonEmptyName() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(!source.name.isEmpty)
    }

    @Test("allSystemAudio has isAllSystemAudio set to true")
    func allSystemAudioIsAllSystemAudioFlagIsTrue() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.isAllSystemAudio == true)
    }

    @Test("allSystemAudio has nil bundleIdentifier")
    func allSystemAudioHasNilBundleIdentifier() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.bundleIdentifier == nil)
    }

    @Test("allSystemAudio has nil windowID")
    func allSystemAudioHasNilWindowID() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.windowID == nil)
    }

    @Test("allSystemAudio has nil windowTitle")
    func allSystemAudioHasNilWindowTitle() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.windowTitle == nil)
    }

    @Test("allSystemAudio has nil processID")
    func allSystemAudioHasNilProcessID() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.processID == nil)
    }

    @Test("allSystemAudio has nil iconData")
    func allSystemAudioHasNilIconData() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.iconData == nil)
    }

    // MARK: - Display Name

    @Test("displayName returns name for allSystemAudio")
    func displayNameReturnsNameForAllSystemAudio() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.displayName == source.name)
    }

    @Test("displayName returns name when windowTitle is nil")
    func displayNameReturnsNameWhenWindowTitleIsNil() {
        let source = AudioSourceInfo(
            id: "app-123",
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: 1234,
            iconData: nil
        )

        #expect(source.displayName == "Safari")
    }

    @Test("displayName returns name when windowTitle is empty")
    func displayNameReturnsNameWhenWindowTitleIsEmpty() {
        let source = AudioSourceInfo(
            id: "window-123",
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            isAllSystemAudio: false,
            windowID: 123,
            windowTitle: "",
            processID: 1234,
            iconData: nil
        )

        #expect(source.displayName == "Safari")
    }

    @Test("displayName includes windowTitle when available")
    func displayNameIncludesWindowTitle() {
        let source = AudioSourceInfo(
            id: "window-456",
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            isAllSystemAudio: false,
            windowID: 456,
            windowTitle: "Apple Homepage",
            processID: 1234,
            iconData: nil
        )

        #expect(source.displayName == "Safari - Apple Homepage")
    }

    @Test("displayName handles window title with special characters")
    func displayNameHandlesSpecialCharacters() {
        let source = AudioSourceInfo(
            id: "window-789",
            name: "Browser",
            bundleIdentifier: "com.test.browser",
            isAllSystemAudio: false,
            windowID: 789,
            windowTitle: "Page: Test & Demo (2024)",
            processID: 5678,
            iconData: nil
        )

        #expect(source.displayName == "Browser - Page: Test & Demo (2024)")
    }

    // MARK: - isWindowLevel

    @Test("isWindowLevel returns true when windowID is set")
    func isWindowLevelReturnsTrueWhenWindowIDIsSet() {
        let source = AudioSourceInfo(
            id: "window-100",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 100,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.isWindowLevel == true)
    }

    @Test("isWindowLevel returns false when windowID is nil")
    func isWindowLevelReturnsFalseWhenWindowIDIsNil() {
        let source = AudioSourceInfo(
            id: "app-200",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.isWindowLevel == false)
    }

    @Test("allSystemAudio is not window level")
    func allSystemAudioIsNotWindowLevel() {
        let source = AudioSourceInfo.allSystemAudio
        #expect(source.isWindowLevel == false)
    }

    // MARK: - Identifiable

    @Test("id property is accessible for Identifiable conformance")
    func identifiableIdProperty() {
        let source = AudioSourceInfo(
            id: "unique-id-123",
            name: "Test",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.id == "unique-id-123")
    }

    // MARK: - Equatable

    @Test("Sources with same id are equal")
    func sourcesWithSameIdAreEqual() {
        let source1 = AudioSourceInfo(
            id: "same-id",
            name: "App 1",
            bundleIdentifier: "com.test.app1",
            isAllSystemAudio: false,
            windowID: 100,
            windowTitle: "Window 1",
            processID: 1000,
            iconData: Data([0x01])
        )

        let source2 = AudioSourceInfo(
            id: "same-id",
            name: "App 2",
            bundleIdentifier: "com.test.app2",
            isAllSystemAudio: true,
            windowID: 200,
            windowTitle: "Window 2",
            processID: 2000,
            iconData: Data([0x02])
        )

        #expect(source1 == source2)
    }

    @Test("Sources with different ids are not equal")
    func sourcesWithDifferentIdsAreNotEqual() {
        let source1 = AudioSourceInfo(
            id: "id-1",
            name: "Same Name",
            bundleIdentifier: "com.test.same",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let source2 = AudioSourceInfo(
            id: "id-2",
            name: "Same Name",
            bundleIdentifier: "com.test.same",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source1 != source2)
    }

    @Test("allSystemAudio equals itself")
    func allSystemAudioEqualsItself() {
        let source1 = AudioSourceInfo.allSystemAudio
        let source2 = AudioSourceInfo.allSystemAudio

        #expect(source1 == source2)
    }

    // MARK: - Hashable

    @Test("Sources with same id have same hash value")
    func sourcesWithSameIdHaveSameHash() {
        let source1 = AudioSourceInfo(
            id: "hash-test-id",
            name: "App 1",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let source2 = AudioSourceInfo(
            id: "hash-test-id",
            name: "App 2",
            bundleIdentifier: "com.different.bundle",
            isAllSystemAudio: true,
            windowID: 999,
            windowTitle: "Different",
            processID: 8888,
            iconData: Data([0xFF])
        )

        #expect(source1.hashValue == source2.hashValue)
    }

    @Test("Can be used in a Set")
    func canBeUsedInSet() {
        let source1 = AudioSourceInfo(
            id: "set-id-1",
            name: "App 1",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let source2 = AudioSourceInfo(
            id: "set-id-2",
            name: "App 2",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let source3 = AudioSourceInfo(
            id: "set-id-1", // Same id as source1
            name: "App 3",
            bundleIdentifier: nil,
            isAllSystemAudio: true,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        var set = Set<AudioSourceInfo>()
        set.insert(source1)
        set.insert(source2)
        set.insert(source3)

        // Should only have 2 elements since source1 and source3 have the same id
        #expect(set.count == 2)
        #expect(set.contains(source1))
        #expect(set.contains(source2))
    }

    @Test("Can be used as dictionary key")
    func canBeUsedAsDictionaryKey() {
        let source1 = AudioSourceInfo(
            id: "dict-key-1",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let source2 = AudioSourceInfo(
            id: "dict-key-1", // Same id
            name: "Different App",
            bundleIdentifier: nil,
            isAllSystemAudio: true,
            windowID: 123,
            windowTitle: "Window",
            processID: 456,
            iconData: nil
        )

        var dictionary = [AudioSourceInfo: String]()
        dictionary[source1] = "First"
        dictionary[source2] = "Second"

        // Should overwrite since they have the same id
        #expect(dictionary.count == 1)
        #expect(dictionary[source1] == "Second")
    }

    // MARK: - iconData Property

    @Test("iconData returns stored icon data")
    func iconDataReturnsStoredData() {
        let testData = Data([0xAB, 0xCD, 0xEF])
        let source = AudioSourceInfo(
            id: "icon-test",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: testData
        )

        #expect(source.iconData == testData)
    }

    @Test("iconData returns nil when not set")
    func iconDataReturnsNilWhenNotSet() {
        let source = AudioSourceInfo(
            id: "no-icon",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.iconData == nil)
    }

    // MARK: - Sendable Conformance

    @Test("Can be passed across concurrency boundaries")
    func sendableConformance() async {
        let source = AudioSourceInfo(
            id: "sendable-test",
            name: "Test App",
            bundleIdentifier: "com.test.app",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        // AudioSourceInfo is Sendable, so it can be captured in a Task
        // The fact that this compiles proves Sendable conformance
        let capturedId = source.id
        let result = await Task {
            capturedId
        }.value

        #expect(result == "sendable-test")
    }

    // MARK: - Edge Cases

    @Test("Handles empty string id")
    func handlesEmptyStringId() {
        let source = AudioSourceInfo(
            id: "",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.id.isEmpty)
    }

    @Test("Handles empty string name")
    func handlesEmptyStringName() {
        let source = AudioSourceInfo(
            id: "test",
            name: "",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.name.isEmpty)
        #expect(source.displayName.isEmpty)
    }

    @Test("Handles maximum CGWindowID value")
    func handlesMaxWindowID() {
        let maxWindowID = CGWindowID.max
        let source = AudioSourceInfo(
            id: "max-window",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: maxWindowID,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.windowID == maxWindowID)
        #expect(source.isWindowLevel == true)
    }

    @Test("Handles zero windowID")
    func handlesZeroWindowID() {
        let source = AudioSourceInfo(
            id: "zero-window",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 0,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.windowID == 0)
        #expect(source.isWindowLevel == true) // 0 is still a valid windowID
    }

    @Test("Handles negative processID")
    func handlesNegativeProcessID() {
        let source = AudioSourceInfo(
            id: "neg-pid",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: -1,
            iconData: nil
        )

        #expect(source.processID == -1)
    }

    @Test("Handles unicode in names and titles")
    func handlesUnicodeStrings() {
        let source = AudioSourceInfo(
            id: "unicode-test",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 123,
            windowTitle: "Test Page",
            processID: nil,
            iconData: nil
        )

        #expect(source.displayName == "App - Test Page")
    }

    @Test("Handles large icon data")
    func handlesLargeIconData() {
        let largeData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB
        let source = AudioSourceInfo(
            id: "large-icon",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: largeData
        )

        #expect(source.iconData?.count == 1024 * 1024)
    }

    // MARK: - displayName Edge Cases

    @Test("displayName for non-allSystemAudio with nil windowTitle returns name")
    func displayNameNonAllSystemAudioNilWindowTitle() {
        let source = AudioSourceInfo(
            id: "app-edge",
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: 1234,
            iconData: nil
        )

        // Not allSystemAudio, windowTitle is nil -> returns name
        #expect(source.displayName == "TestApp")
    }

    @Test("displayName for non-allSystemAudio with non-nil non-empty windowTitle returns combined")
    func displayNameNonAllSystemAudioWithWindowTitle() {
        let source = AudioSourceInfo(
            id: "window-edge",
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            isAllSystemAudio: false,
            windowID: 999,
            windowTitle: "Document 1",
            processID: 1234,
            iconData: nil
        )

        // Not allSystemAudio, windowTitle is non-nil and non-empty -> returns "name - windowTitle"
        #expect(source.displayName == "TestApp - Document 1")
    }

    @Test("displayName for non-allSystemAudio with empty windowTitle returns name only")
    func displayNameNonAllSystemAudioEmptyWindowTitle() {
        let source = AudioSourceInfo(
            id: "window-empty-title",
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            isAllSystemAudio: false,
            windowID: 888,
            windowTitle: "",
            processID: 1234,
            iconData: nil
        )

        // Not allSystemAudio, windowTitle is empty -> returns name
        #expect(source.displayName == "TestApp")
    }

    // MARK: - Additional Hashable Tests

    @Test("hash function produces consistent results")
    func hashFunctionConsistency() {
        let source = AudioSourceInfo(
            id: "consistent-hash-test",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        var hasher1 = Hasher()
        source.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        source.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        #expect(hash1 == hash2)
    }

    @Test("hash function only uses id")
    func hashFunctionOnlyUsesId() {
        let source1 = AudioSourceInfo(
            id: "same-id-for-hash",
            name: "App1",
            bundleIdentifier: "com.app1",
            isAllSystemAudio: false,
            windowID: 100,
            windowTitle: "Window1",
            processID: 1000,
            iconData: Data([0x01])
        )

        let source2 = AudioSourceInfo(
            id: "same-id-for-hash",
            name: "App2",
            bundleIdentifier: "com.app2",
            isAllSystemAudio: true,
            windowID: 200,
            windowTitle: "Window2",
            processID: 2000,
            iconData: Data([0x02])
        )

        var hasher1 = Hasher()
        source1.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        source2.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        // Same id means same hash
        #expect(hash1 == hash2)
    }

    // MARK: - Additional Equatable Tests

    @Test("equality operator returns true for identical sources")
    func equalityOperatorTrueForIdenticalSources() {
        let source1 = AudioSourceInfo(
            id: "identical-test",
            name: "Same Name",
            bundleIdentifier: "com.same.bundle",
            isAllSystemAudio: false,
            windowID: 123,
            windowTitle: "Same Title",
            processID: 456,
            iconData: Data([0xAA])
        )

        let source2 = AudioSourceInfo(
            id: "identical-test",
            name: "Same Name",
            bundleIdentifier: "com.same.bundle",
            isAllSystemAudio: false,
            windowID: 123,
            windowTitle: "Same Title",
            processID: 456,
            iconData: Data([0xAA])
        )

        #expect(source1 == source2)
    }

    @Test("equality operator uses only id for comparison")
    func equalityOperatorUsesOnlyId() {
        let source1 = AudioSourceInfo(
            id: "equality-id-test",
            name: "Different",
            bundleIdentifier: "com.different1",
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        let source2 = AudioSourceInfo(
            id: "equality-id-test",
            name: "Also Different",
            bundleIdentifier: "com.different2",
            isAllSystemAudio: true,
            windowID: 999,
            windowTitle: "Title",
            processID: 888,
            iconData: Data([0xFF])
        )

        // Even though all other properties differ, equality is based on id
        #expect(source1 == source2)
    }

    // MARK: - isWindowLevel Edge Cases

    @Test("isWindowLevel returns true for window with windowID of 0")
    func isWindowLevelTrueForWindowIdZero() {
        let source = AudioSourceInfo(
            id: "window-id-zero",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 0,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        // windowID of 0 is still a valid window ID (not nil)
        #expect(source.isWindowLevel == true)
    }

    @Test("isWindowLevel returns true for maximum CGWindowID")
    func isWindowLevelTrueForMaxWindowId() {
        let source = AudioSourceInfo(
            id: "window-id-max",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: CGWindowID.max,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.isWindowLevel == true)
    }

    // MARK: - allSystemAudio Property Verification

    @Test("allSystemAudio returns consistent instances")
    func allSystemAudioReturnsConsistentInstances() {
        let instance1 = AudioSourceInfo.allSystemAudio
        let instance2 = AudioSourceInfo.allSystemAudio

        #expect(instance1.id == instance2.id)
        #expect(instance1.isAllSystemAudio == instance2.isAllSystemAudio)
        #expect(instance1 == instance2)
    }

    @Test("allSystemAudio has all expected nil properties")
    func allSystemAudioHasAllExpectedNilProperties() {
        let source = AudioSourceInfo.allSystemAudio

        #expect(source.bundleIdentifier == nil)
        #expect(source.windowID == nil)
        #expect(source.windowTitle == nil)
        #expect(source.processID == nil)
        #expect(source.iconData == nil)
    }

    @Test("allSystemAudio has correct boolean flags")
    func allSystemAudioHasCorrectBooleanFlags() {
        let source = AudioSourceInfo.allSystemAudio

        #expect(source.isAllSystemAudio == true)
        #expect(source.isWindowLevel == false)
    }

    // MARK: - displayName Branch Coverage

    @Test("displayName early return for allSystemAudio before checking windowTitle")
    func displayNameEarlyReturnForAllSystemAudio() {
        // Create a source that is allSystemAudio but also has a windowTitle set
        // The displayName should return name early without checking windowTitle
        let source = AudioSourceInfo(
            id: "all-system-with-title",
            name: "All System",
            bundleIdentifier: nil,
            isAllSystemAudio: true,
            windowID: nil,
            windowTitle: "This should be ignored",
            processID: nil,
            iconData: nil
        )

        // displayName should return name (early return for isAllSystemAudio)
        #expect(source.displayName == "All System")
    }

    @Test("displayName window title check only happens when not allSystemAudio")
    func displayNameWindowTitleCheckOnlyWhenNotAllSystemAudio() {
        // Case 1: Not allSystemAudio, with non-empty windowTitle
        let sourceWithTitle = AudioSourceInfo(
            id: "with-title",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 1,
            windowTitle: "Window Title",
            processID: nil,
            iconData: nil
        )
        #expect(sourceWithTitle.displayName == "App - Window Title")

        // Case 2: Not allSystemAudio, with nil windowTitle
        let sourceNilTitle = AudioSourceInfo(
            id: "nil-title",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )
        #expect(sourceNilTitle.displayName == "App")

        // Case 3: Not allSystemAudio, with empty windowTitle
        let sourceEmptyTitle = AudioSourceInfo(
            id: "empty-title",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: 2,
            windowTitle: "",
            processID: nil,
            iconData: nil
        )
        #expect(sourceEmptyTitle.displayName == "App")
    }

    // MARK: - iconData Private Storage Test

    @Test("iconData computed property returns private _iconData value")
    func iconDataReturnsPrivateIconData() {
        let testData = Data([0x12, 0x34, 0x56, 0x78])
        let source = AudioSourceInfo(
            id: "icon-storage-test",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: testData
        )

        // Verify iconData getter returns the stored value
        #expect(source.iconData == testData)
        #expect(source.iconData?.count == 4)
    }

    @Test("iconData computed property returns nil when _iconData is nil")
    func iconDataReturnsNilWhenPrivateIconDataIsNil() {
        let source = AudioSourceInfo(
            id: "icon-nil-test",
            name: "App",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.iconData == nil)
    }

    // MARK: - Initializer Coverage

    @Test("initializer correctly assigns all properties")
    func initializerCorrectlyAssignsAllProperties() {
        let iconData = Data([0xAB, 0xCD])
        let source = AudioSourceInfo(
            id: "init-test-id",
            name: "Init Test Name",
            bundleIdentifier: "com.init.test",
            isAllSystemAudio: true,
            windowID: 12345,
            windowTitle: "Init Window Title",
            processID: 67890,
            iconData: iconData
        )

        #expect(source.id == "init-test-id")
        #expect(source.name == "Init Test Name")
        #expect(source.bundleIdentifier == "com.init.test")
        #expect(source.isAllSystemAudio == true)
        #expect(source.windowID == 12345)
        #expect(source.windowTitle == "Init Window Title")
        #expect(source.processID == 67890)
        #expect(source.iconData == iconData)
    }

    @Test("initializer handles all nil optional parameters")
    func initializerHandlesAllNilOptionalParameters() {
        let source = AudioSourceInfo(
            id: "nil-test",
            name: "Nil Test",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        #expect(source.bundleIdentifier == nil)
        #expect(source.windowID == nil)
        #expect(source.windowTitle == nil)
        #expect(source.processID == nil)
        #expect(source.iconData == nil)
    }

    // MARK: - Struct Value Type Behavior

    @Test("AudioSourceInfo is a value type with copy semantics")
    func audioSourceInfoIsValueType() {
        let original = AudioSourceInfo(
            id: "value-type-test",
            name: "Original",
            bundleIdentifier: nil,
            isAllSystemAudio: false,
            windowID: nil,
            windowTitle: nil,
            processID: nil,
            iconData: nil
        )

        // Copy the struct
        let copy = original

        // Both should have the same values (struct copy)
        #expect(original.id == copy.id)
        #expect(original.name == copy.name)
        #expect(original == copy)
    }

    // MARK: - Collection Usage Tests

    @Test("AudioSourceInfo works correctly in Array")
    func audioSourceInfoWorksInArray() {
        let sources = [
            AudioSourceInfo(
                id: "array-1",
                name: "App 1",
                bundleIdentifier: nil,
                isAllSystemAudio: false,
                windowID: nil,
                windowTitle: nil,
                processID: nil,
                iconData: nil
            ),
            AudioSourceInfo(
                id: "array-2",
                name: "App 2",
                bundleIdentifier: nil,
                isAllSystemAudio: false,
                windowID: nil,
                windowTitle: nil,
                processID: nil,
                iconData: nil
            )
        ]

        #expect(sources.count == 2)
        #expect(sources.contains { $0.id == "array-1" })
        #expect(sources.contains { $0.id == "array-2" })
    }

    @Test("AudioSourceInfo first where predicate works correctly")
    func audioSourceInfoFirstWhereWorks() {
        let sources = [
            AudioSourceInfo.allSystemAudio,
            AudioSourceInfo(
                id: "app-specific",
                name: "Specific App",
                bundleIdentifier: "com.specific",
                isAllSystemAudio: false,
                windowID: nil,
                windowTitle: nil,
                processID: nil,
                iconData: nil
            )
        ]

        let allSystem = sources.first { $0.isAllSystemAudio }
        #expect(allSystem != nil)
        #expect(allSystem?.id == "all-system-audio")

        let specific = sources.first { !$0.isAllSystemAudio }
        #expect(specific != nil)
        #expect(specific?.id == "app-specific")
    }

    @Test("AudioSourceInfo filter works correctly")
    func audioSourceInfoFilterWorks() {
        let sources = [
            AudioSourceInfo(
                id: "window-1",
                name: "App",
                bundleIdentifier: nil,
                isAllSystemAudio: false,
                windowID: 1,
                windowTitle: nil,
                processID: nil,
                iconData: nil
            ),
            AudioSourceInfo(
                id: "app-1",
                name: "App",
                bundleIdentifier: nil,
                isAllSystemAudio: false,
                windowID: nil,
                windowTitle: nil,
                processID: nil,
                iconData: nil
            ),
            AudioSourceInfo(
                id: "window-2",
                name: "App",
                bundleIdentifier: nil,
                isAllSystemAudio: false,
                windowID: 2,
                windowTitle: nil,
                processID: nil,
                iconData: nil
            )
        ]

        let windowLevelSources = sources.filter { $0.isWindowLevel }
        #expect(windowLevelSources.count == 2)

        let appLevelSources = sources.filter { !$0.isWindowLevel }
        #expect(appLevelSources.count == 1)
    }
}
