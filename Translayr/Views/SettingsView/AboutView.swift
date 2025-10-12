//
//  AboutView.swift
//  Translayr
//
//  Created by eevv on 10/10/25.
//


import SwiftUI
import Ollama

struct AboutView: View {
    // 动态获取应用版本信息
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image(systemName: "character.textbox.badge.sparkles")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // App Name and Version
            VStack(spacing: 8) {
                Text("Translayr")
                    .font(.largeTitle.weight(.bold))

                Text(appVersion)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Description
            VStack(spacing: 12) {
                Text("Intelligent Translation Assistant")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Automatically detects and translates text in many applications using AI models")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("About")
    }
}
