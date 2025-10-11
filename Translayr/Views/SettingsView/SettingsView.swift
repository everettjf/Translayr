//
//  SettingsView.swift
//  Translayr
//
//  设置页面 - 使用 NavigationSplitView 架构
//

import SwiftUI

// MARK: - Main Settings Window

struct SettingsView: View {
    @State private var selection: PreferencesSection? = .general

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(PreferencesSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("Translayr")
            .frame(minWidth: 180)
        } detail: {
            // Detail content
            switch selection {
            case .general:
                GeneralSettingsView()
            case .language:
                LanguageSettingsView()
            case .color:
                ColorSettingsView()
            case .models:
                ModelsSettingsView()
            case .skipApps:
                SkipAppsSettingsView()
            case .about:
                AboutView()
            case .none:
                Text("Select a section from the sidebar")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}

#Preview {
    SettingsView()
}
