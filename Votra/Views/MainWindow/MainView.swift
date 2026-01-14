//
//  MainView.swift
//  Votra
//
//  Primary application window content.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var selectedTab: AppTab = .translate

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            ContentAreaView(selectedTab: selectedTab)
                .accessibilityIdentifier("content_\(selectedTab.rawValue)")
        }
        .navigationTitle("Votra")
        .accessibilityIdentifier("mainView")
    }
}

/// Application navigation tabs
enum AppTab: String, CaseIterable, Identifiable {
    case translate
    case recordings
    case mediaImport
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .translate: return String(localized: "Translate")
        case .recordings: return String(localized: "Recordings")
        case .mediaImport: return String(localized: "Media Import")
        case .settings: return String(localized: "Settings")
        }
    }

    var systemImage: String {
        switch self {
        case .translate: return "waveform"
        case .recordings: return "record.circle"
        case .mediaImport: return "doc.badge.plus"
        case .settings: return "gear"
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Session.self, Segment.self, Speaker.self, Recording.self, MeetingSummary.self], inMemory: true)
}
