//
//  SessionTests.swift
//  VotraTests
//
//  Unit tests for the Session model.
//

import Testing
import Foundation
import SwiftData
@testable import Votra

@MainActor
struct SessionTests {
    let container: ModelContainer

    init() {
        container = TestModelContainer.createFresh()
    }

    @Test
    func testSessionInitialization() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        #expect(session.id != UUID())
        #expect(session.startTime <= Date())
        #expect(session.endTime == nil)
        #expect(session.sourceLocaleIdentifier == "en-US")
        #expect(session.targetLocaleIdentifier == "zh-Hant")
        #expect(session.isPersisted == false)
        #expect(session.isActive == true)
    }

    @Test
    func testSessionWithCustomLocales() {
        let context = container.mainContext
        let sourceLocale = Locale(identifier: "ja-JP")
        let targetLocale = Locale(identifier: "ko-KR")

        let session = Session(
            sourceLocale: sourceLocale,
            targetLocale: targetLocale
        )
        context.insert(session)

        #expect(session.sourceLocaleIdentifier == "ja-JP")
        #expect(session.targetLocaleIdentifier == "ko-KR")
        #expect(session.sourceLocale.identifier == "ja-JP")
        #expect(session.targetLocale.identifier == "ko-KR")
    }

    @Test
    func testSessionEnd() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)
        #expect(session.isActive == true)
        #expect(session.endTime == nil)

        session.end()

        #expect(session.isActive == false)
        #expect(session.endTime != nil)
        if let endTime = session.endTime {
            #expect(endTime >= session.startTime)
        }
    }

    @Test
    func testSessionDuration() async throws {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        // Wait a small amount
        try await Task.sleep(for: .milliseconds(100))

        let duration = session.duration
        #expect(duration >= 0.1)

        session.end()
        let finalDuration = session.duration
        #expect(finalDuration >= 0.1)
    }

    @Test
    func testAddSegment() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment = Segment(
            startTime: 0,
            endTime: 5,
            originalText: "Hello"
        )
        context.insert(segment)

        session.addSegment(segment)

        #expect(session.segmentCount == 1)
        #expect(session.segments?.first?.originalText == "Hello")
        #expect(segment.session === session)
    }

    @Test
    func testAddMultipleSegments() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let segment1 = Segment(startTime: 0, endTime: 5, originalText: "First")
        let segment2 = Segment(startTime: 5, endTime: 10, originalText: "Second")
        let segment3 = Segment(startTime: 10, endTime: 15, originalText: "Third")

        context.insert(segment1)
        context.insert(segment2)
        context.insert(segment3)

        session.addSegment(segment1)
        session.addSegment(segment2)
        session.addSegment(segment3)

        #expect(session.segmentCount == 3)

        let sorted = session.sortedSegments
        #expect(sorted[0].originalText == "First")
        #expect(sorted[1].originalText == "Second")
        #expect(sorted[2].originalText == "Third")
    }

    @Test
    func testAddSpeaker() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker = Speaker.createMe()
        context.insert(speaker)

        session.addSpeaker(speaker)

        #expect(session.speakers?.count == 1)
        #expect(session.speakers?.first?.isMe == true)
    }

    @Test
    func testAddDuplicateSpeaker() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        let speaker = Speaker.createMe()
        context.insert(speaker)

        session.addSpeaker(speaker)
        session.addSpeaker(speaker)

        #expect(session.speakers?.count == 1)
    }

    @Test
    func testLocaleComputedProperties() {
        let context = container.mainContext
        let session = Session()
        context.insert(session)

        session.sourceLocale = Locale(identifier: "fr-FR")
        session.targetLocale = Locale(identifier: "de-DE")

        #expect(session.sourceLocaleIdentifier == "fr-FR")
        #expect(session.targetLocaleIdentifier == "de-DE")
    }
}
