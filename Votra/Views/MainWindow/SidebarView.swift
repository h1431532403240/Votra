//
//  SidebarView.swift
//  Votra
//
//  Navigation sidebar for the main application window.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        List(AppTab.allCases, selection: $selectedTab) { tab in
            Label(tab.title, systemImage: tab.systemImage)
                .tag(tab)
                .accessibilityIdentifier("sidebar_\(tab.rawValue)")
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .accessibilityIdentifier("sidebar")
    }
}

#Preview {
    @Previewable @State var selectedTab: AppTab = .translate
    SidebarView(selectedTab: $selectedTab)
}
