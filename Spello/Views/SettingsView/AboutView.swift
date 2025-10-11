//
//  AboutView.swift
//  Spello
//
//  Created by eevv on 10/10/25.
//


import SwiftUI
import Ollama

struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image(systemName: "character.textbox")
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
                Text("Spello")
                    .font(.largeTitle.weight(.bold))

                Text("Version 1.0.0")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Description
            VStack(spacing: 12) {
                Text("Intelligent Translation Assistant")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Automatically detects and translates text in many applications using local AI models")
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
