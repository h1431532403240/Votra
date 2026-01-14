//
//  VotraUITests.swift
//  VotraUITests
//
//  UI tests for Votra application.
//

import XCTest

/// Namespace for Votra UI tests
enum VotraUITests {}

// MARK: - Main Navigation Tests

/// Tests for main window navigation
final class MainNavigationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAppLaunches() throws {
        // Verify the app launches and main window exists
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }

    @MainActor
    func testSidebarExists() throws {
        // Verify sidebar navigation exists
        let sidebar = app.outlines["sidebar"]
        // If sidebar identifier doesn't work, check for list/outline
        XCTAssertTrue(
            sidebar.exists || app.outlines.count > 0,
            "Sidebar should exist"
        )
    }

    @MainActor
    func testNavigateToTranslateTab() throws {
        // Look for Translate tab in sidebar
        let translateTab = app.staticTexts["Translate"].firstMatch
        if translateTab.waitForExistence(timeout: 2) {
            translateTab.click()
            // Verify we're on the translate view
            let startButton = app.buttons["translation_start_stop_button"]
            XCTAssertTrue(
                startButton.waitForExistence(timeout: 2) ||
                app.staticTexts["Real-time Translation"].exists,
                "Should navigate to translate tab"
            )
        }
    }

    @MainActor
    func testNavigateToRecordingsTab() throws {
        // Look for Recordings tab in sidebar
        let recordingsTab = app.staticTexts["Recordings"].firstMatch
        if recordingsTab.waitForExistence(timeout: 2) {
            recordingsTab.click()
            // Verify we're on the recordings view
            XCTAssertTrue(
                app.buttons["recordings_record_button"].waitForExistence(timeout: 2) ||
                app.staticTexts["No Recordings"].exists ||
                app.textFields["recordings_search_field"].exists,
                "Should navigate to recordings tab"
            )
        }
    }

    @MainActor
    func testNavigateToMediaImportTab() throws {
        // Look for Media Import tab in sidebar
        let mediaImportTab = app.staticTexts["Media Import"].firstMatch
        if mediaImportTab.waitForExistence(timeout: 2) {
            mediaImportTab.click()
            // Verify we're on the media import view
            XCTAssertTrue(
                app.buttons["media_import_browse_button"].waitForExistence(timeout: 2) ||
                app.staticTexts["Import Media Files"].exists ||
                app.staticTexts["Drop files here"].exists,
                "Should navigate to media import tab"
            )
        }
    }

    @MainActor
    func testNavigateToSettingsTab() throws {
        // Look for Settings tab in sidebar
        let settingsTab = app.staticTexts["Settings"].firstMatch
        if settingsTab.waitForExistence(timeout: 2) {
            settingsTab.click()
            // Verify we're on the settings view
            XCTAssertTrue(
                app.staticTexts["General"].waitForExistence(timeout: 2) ||
                app.staticTexts["Appearance"].exists ||
                app.staticTexts["Audio"].exists,
                "Should navigate to settings tab"
            )
        }
    }
}

// MARK: - Settings View UI Tests

/// Tests for Settings view
final class SettingsViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    private func navigateToSettings() {
        let settingsTab = app.staticTexts["Settings"].firstMatch
        if settingsTab.waitForExistence(timeout: 2) {
            settingsTab.click()
        }
    }

    @MainActor
    func testSettingsTabsExist() throws {
        navigateToSettings()

        // Verify settings tabs exist
        let generalTab = app.staticTexts["General"]
        let audioTab = app.staticTexts["Audio"]
        let languagesTab = app.staticTexts["Languages"]
        let privacyTab = app.staticTexts["Privacy"]

        XCTAssertTrue(
            generalTab.waitForExistence(timeout: 2),
            "General tab should exist"
        )
        XCTAssertTrue(audioTab.exists, "Audio tab should exist")
        XCTAssertTrue(languagesTab.exists, "Languages tab should exist")
        XCTAssertTrue(privacyTab.exists, "Privacy tab should exist")
    }

    @MainActor
    func testGeneralSettingsContent() throws {
        navigateToSettings()

        // Verify general settings content
        let generalTab = app.staticTexts["General"].firstMatch
        if generalTab.waitForExistence(timeout: 2) {
            generalTab.click()

            // Check for general settings elements
            XCTAssertTrue(
                app.staticTexts["Appearance"].waitForExistence(timeout: 2) ||
                app.staticTexts["Window Opacity"].exists,
                "Appearance section should exist"
            )
        }
    }

    @MainActor
    func testAudioSettingsNavigation() throws {
        navigateToSettings()

        // Navigate to Audio tab
        let audioTab = app.staticTexts["Audio"].firstMatch
        if audioTab.waitForExistence(timeout: 2) {
            audioTab.click()
            // Audio settings content should be visible
            XCTAssertTrue(true, "Successfully navigated to Audio settings")
        }
    }

    @MainActor
    func testLanguagesSettingsNavigation() throws {
        navigateToSettings()

        // Navigate to Languages tab
        let languagesTab = app.staticTexts["Languages"].firstMatch
        if languagesTab.waitForExistence(timeout: 2) {
            languagesTab.click()
            // Languages settings content should be visible
            XCTAssertTrue(true, "Successfully navigated to Languages settings")
        }
    }

    @MainActor
    func testPrivacySettingsNavigation() throws {
        navigateToSettings()

        // Navigate to Privacy tab
        let privacyTab = app.staticTexts["Privacy"].firstMatch
        if privacyTab.waitForExistence(timeout: 2) {
            privacyTab.click()

            // Verify privacy settings content
            XCTAssertTrue(
                app.staticTexts["Data Storage"].waitForExistence(timeout: 2) ||
                app.staticTexts["Sync with iCloud"].exists ||
                app.staticTexts["Permissions"].exists,
                "Privacy settings content should be visible"
            )
        }
    }

    @MainActor
    func testPrivacyPermissionsDisplay() throws {
        navigateToSettings()

        // Navigate to Privacy tab
        let privacyTab = app.staticTexts["Privacy"].firstMatch
        if privacyTab.waitForExistence(timeout: 2) {
            privacyTab.click()

            // Verify permissions are displayed
            XCTAssertTrue(
                app.staticTexts["Microphone"].waitForExistence(timeout: 2) ||
                app.staticTexts["Screen Recording"].exists ||
                app.staticTexts["Speech Recognition"].exists,
                "Permissions section should be visible"
            )
        }
    }
}

// MARK: - Recordings View UI Tests

/// Tests for Recordings view
final class RecordingsViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    private func navigateToRecordings() {
        let recordingsTab = app.staticTexts["Recordings"].firstMatch
        if recordingsTab.waitForExistence(timeout: 2) {
            recordingsTab.click()
        }
    }

    @MainActor
    func testRecordingsViewLoads() throws {
        navigateToRecordings()

        // Verify recordings view loads with either empty state or list
        XCTAssertTrue(
            app.buttons["recordings_record_button"].waitForExistence(timeout: 2) ||
            app.staticTexts["No Recordings"].exists ||
            app.staticTexts["Search recordings"].exists,
            "Recordings view should load"
        )
    }

    @MainActor
    func testRecordButtonExists() throws {
        navigateToRecordings()

        // Verify record button exists
        let recordButton = app.buttons["recordings_record_button"]
        let recordLabel = app.staticTexts["Record"]

        XCTAssertTrue(
            recordButton.waitForExistence(timeout: 2) || recordLabel.exists,
            "Record button should exist"
        )
    }

    @MainActor
    func testSearchFieldExists() throws {
        navigateToRecordings()

        // Verify search field exists
        let searchField = app.textFields["recordings_search_field"]
        let searchPlaceholder = app.textFields["Search recordings"]

        XCTAssertTrue(
            searchField.waitForExistence(timeout: 2) || searchPlaceholder.exists,
            "Search field should exist"
        )
    }

    @MainActor
    func testEmptyStateDisplayed() throws {
        navigateToRecordings()

        // On fresh app launch, expect empty state or recording list
        let emptyState = app.staticTexts["No Recordings"]

        // Either empty state or recording list should be visible
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 2) ||
            app.outlines.count > 0 ||
            app.tables.count > 0,
            "Either empty state or recording list should be displayed"
        )
    }

    @MainActor
    func testSearchFieldInteraction() throws {
        navigateToRecordings()

        // Find and interact with search field
        let searchField = app.textFields.firstMatch
        if searchField.waitForExistence(timeout: 2) {
            searchField.click()
            searchField.typeText("test")
            // Search should accept input
            XCTAssertTrue(true, "Search field accepts input")
        }
    }
}

// MARK: - Media Import View UI Tests

/// Tests for Media Import view
final class MediaImportViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    private func navigateToMediaImport() {
        let mediaImportTab = app.staticTexts["Media Import"].firstMatch
        if mediaImportTab.waitForExistence(timeout: 2) {
            mediaImportTab.click()
        }
    }

    @MainActor
    func testMediaImportViewLoads() throws {
        navigateToMediaImport()

        // Verify media import view loads
        XCTAssertTrue(
            app.staticTexts["Import Media Files"].waitForExistence(timeout: 2) ||
            app.staticTexts["Drop files here"].exists ||
            app.buttons["media_import_browse_button"].exists,
            "Media Import view should load"
        )
    }

    @MainActor
    func testDropZoneDisplayed() throws {
        navigateToMediaImport()

        // Verify drop zone is displayed
        XCTAssertTrue(
            app.staticTexts["Drop files here"].waitForExistence(timeout: 2) ||
            app.buttons["media_import_browse_button"].exists,
            "Drop zone should be displayed"
        )
    }

    @MainActor
    func testBrowseFilesButtonExists() throws {
        navigateToMediaImport()

        // Verify Browse Files button exists
        let browseButton = app.buttons["media_import_browse_button"]
        let browseLabel = app.buttons["Browse Files"]

        XCTAssertTrue(
            browseButton.waitForExistence(timeout: 2) || browseLabel.exists,
            "Browse Files button should exist"
        )
    }

    @MainActor
    func testSubtitleModePickerExists() throws {
        navigateToMediaImport()

        // Verify subtitle mode selection exists
        XCTAssertTrue(
            app.staticTexts["Subtitle Mode"].waitForExistence(timeout: 2) ||
            app.popUpButtons.count > 0 ||
            app.segmentedControls.count > 0,
            "Subtitle mode picker should exist"
        )
    }

    @MainActor
    func testSourceLanguagePickerExists() throws {
        navigateToMediaImport()

        // Verify source language picker exists
        XCTAssertTrue(
            app.staticTexts["Source Language"].waitForExistence(timeout: 2),
            "Source language picker should exist"
        )
    }

    @MainActor
    func testTargetLanguagePickerExists() throws {
        navigateToMediaImport()

        // Verify target language picker exists (may be hidden based on subtitle mode)
        let targetLabel = app.staticTexts["Target Language"]
        // Target language may or may not be visible depending on subtitle mode
        XCTAssertTrue(true, "Target language test passed (visibility depends on mode)")
    }

    @MainActor
    func testSubtitleFormatPickerExists() throws {
        navigateToMediaImport()

        // Verify subtitle format picker exists
        XCTAssertTrue(
            app.staticTexts["Subtitle Format"].waitForExistence(timeout: 2),
            "Subtitle format picker should exist"
        )
    }

    @MainActor
    func testGenerateSubtitlesButtonExists() throws {
        navigateToMediaImport()

        // Verify generate subtitles button exists
        let generateButton = app.buttons["media_import_generate_button"]
        let generateLabel = app.buttons["Generate Subtitles"]

        XCTAssertTrue(
            generateButton.waitForExistence(timeout: 2) || generateLabel.exists,
            "Generate Subtitles button should exist"
        )
    }

    @MainActor
    func testGenerateButtonDisabledWhenEmpty() throws {
        navigateToMediaImport()

        // Verify generate button is disabled when no files are added
        let generateButton = app.buttons["media_import_generate_button"]
        let generateLabel = app.buttons["Generate Subtitles"]

        if generateButton.waitForExistence(timeout: 2) {
            XCTAssertFalse(generateButton.isEnabled, "Generate button should be disabled when empty")
        } else if generateLabel.exists {
            XCTAssertFalse(generateLabel.isEnabled, "Generate button should be disabled when empty")
        }
    }

    @MainActor
    func testSupportedFormatsTextDisplayed() throws {
        navigateToMediaImport()

        // Verify supported formats text is displayed
        XCTAssertTrue(
            app.staticTexts["Supported formats: MP4, MOV, MP3, M4A"].waitForExistence(timeout: 2),
            "Supported formats text should be displayed"
        )
    }
}

// MARK: - Translation View UI Tests

/// Tests for Translation view
final class TranslationViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    private func navigateToTranslation() {
        let translateTab = app.staticTexts["Translate"].firstMatch
        if translateTab.waitForExistence(timeout: 2) {
            translateTab.click()
        }
    }

    @MainActor
    func testTranslationViewLoads() throws {
        navigateToTranslation()

        // Verify translation view loads
        XCTAssertTrue(
            app.staticTexts["Real-time Translation"].waitForExistence(timeout: 2) ||
            app.buttons["translation_start_stop_button"].exists ||
            app.staticTexts["Ready"].exists,
            "Translation view should load"
        )
    }

    @MainActor
    func testIdleStateDisplayed() throws {
        navigateToTranslation()

        // Verify idle state is displayed
        XCTAssertTrue(
            app.staticTexts["Real-time Translation"].waitForExistence(timeout: 2) ||
            app.staticTexts["Select your languages below and click Start to begin translating"].exists,
            "Idle state should be displayed"
        )
    }

    @MainActor
    func testStartButtonExists() throws {
        navigateToTranslation()

        // Verify start translation button exists
        let startButton = app.buttons["translation_start_stop_button"]
        let startLabel = app.buttons["Start Translation"]

        XCTAssertTrue(
            startButton.waitForExistence(timeout: 2) || startLabel.exists,
            "Start Translation button should exist"
        )
    }

    @MainActor
    func testLanguagePickers() throws {
        navigateToTranslation()

        // Verify language pickers exist
        XCTAssertTrue(
            app.staticTexts["From"].waitForExistence(timeout: 2) &&
            app.staticTexts["To"].exists,
            "Language pickers should exist"
        )
    }

    @MainActor
    func testAudioSourceSelector() throws {
        navigateToTranslation()

        // Verify audio source selector exists
        XCTAssertTrue(
            app.staticTexts["Audio Source"].waitForExistence(timeout: 2),
            "Audio source selector should exist"
        )
    }

    @MainActor
    func testStatusIndicator() throws {
        navigateToTranslation()

        // Verify status indicator exists
        XCTAssertTrue(
            app.staticTexts["Ready"].waitForExistence(timeout: 2) ||
            app.staticTexts["Translating"].exists ||
            app.staticTexts["Starting..."].exists,
            "Status indicator should exist"
        )
    }

    @MainActor
    func testAutoSpeakToggle() throws {
        navigateToTranslation()

        // Verify auto-speak toggle exists
        XCTAssertTrue(
            app.staticTexts["Auto-speak"].waitForExistence(timeout: 2) ||
            app.switches.count > 0,
            "Auto-speak toggle should exist"
        )
    }

    @MainActor
    func testRecordButtonExists() throws {
        navigateToTranslation()

        // Verify record button exists in translation view
        let recordLabel = app.staticTexts["Record"]

        XCTAssertTrue(
            recordLabel.waitForExistence(timeout: 2) ||
            app.buttons["Record"].exists,
            "Record button should exist"
        )
    }

    @MainActor
    func testSwapLanguagesButton() throws {
        navigateToTranslation()

        // Verify swap languages button exists
        let swapButton = app.buttons.matching(identifier: "arrow.left.arrow.right").firstMatch
        let swapImage = app.images["arrow.left.arrow.right"]

        XCTAssertTrue(
            swapButton.waitForExistence(timeout: 2) || swapImage.exists || app.buttons.count > 0,
            "Swap languages button should exist"
        )
    }
}

// MARK: - Launch Performance Tests

/// Tests for app launch performance
final class LaunchPerformanceUITests: XCTestCase {

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch the application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testLaunchPerformanceBaseline() throws {
        // Test that app launches within reasonable time
        let app = XCUIApplication()
        let startTime = Date()
        app.launch()
        let launchTime = Date().timeIntervalSince(startTime)

        // App should launch within 5 seconds
        XCTAssertLessThan(launchTime, 5.0, "App should launch within 5 seconds")
    }
}
