//
//  TestModelContainer.swift
//  VotraTests
//
//  Provides an in-memory ModelContainer for testing SwiftData models.
//

import Foundation
import SwiftData
@testable import Votra

/// Test helper providing an in-memory ModelContainer for SwiftData model tests.
///
/// Usage in tests:
/// ```swift
/// @MainActor
/// struct SessionTests {
///     let container: ModelContainer
///
///     init() {
///         container = TestModelContainer.createFresh()
///     }
///
///     @Test
///     func testSession() {
///         let context = container.mainContext
///         let session = Session()
///         context.insert(session)
///         // ... test assertions
///     }
/// }
/// ```
@MainActor
enum TestModelContainer {
    /// Creates a fresh in-memory container for isolated tests
    /// Each test should create its own container to ensure isolation
    static func createFresh() -> ModelContainer {
        let schema = Schema([
            Session.self,
            Segment.self,
            Speaker.self,
            Recording.self,
            MeetingSummary.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create test ModelContainer: \(error)")
        }
    }
}
