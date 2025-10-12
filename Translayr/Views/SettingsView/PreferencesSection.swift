//
//  PreferencesSection.swift
//  Translayr
//
//  Created by eevv on 10/10/25.
//


import SwiftUI
import Ollama

enum PreferencesSection: String, CaseIterable, Identifiable {
    case general = "General"
    case language = "Language"
    case models = "Models"
    case shortcuts = "Shortcuts"
    case skipApps = "Skip Apps"
    case color = "Color"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .language: return "globe"
        case .color: return "paintpalette"
        case .models: return "cpu"
        case .shortcuts: return "keyboard"
        case .skipApps: return "eraser"
        case .about: return "info.circle"
        }
    }
}
