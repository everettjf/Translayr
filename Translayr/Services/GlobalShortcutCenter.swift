//
//  GlobalShortcutCenter.swift
//  Translayr
//
//  全局快捷键管理器
//

import AppKit
import Carbon

struct KeyboardShortcutPreference: Codable, Equatable {
    var keyCode: Int
    var modifiers: ModifierFlags

    struct ModifierFlags: OptionSet, Codable, Equatable {
        let rawValue: UInt

        static let command = ModifierFlags(rawValue: 1 << 0)
        static let option = ModifierFlags(rawValue: 1 << 1)
        static let control = ModifierFlags(rawValue: 1 << 2)
        static let shift = ModifierFlags(rawValue: 1 << 3)

        var carbonFlags: UInt32 {
            var flags: UInt32 = 0
            if contains(.command) { flags |= UInt32(cmdKey) }
            if contains(.option) { flags |= UInt32(optionKey) }
            if contains(.control) { flags |= UInt32(controlKey) }
            if contains(.shift) { flags |= UInt32(shiftKey) }
            return flags
        }

        var displayString: String {
            var components: [String] = []
            if contains(.control) { components.append("⌃") }
            if contains(.option) { components.append("⌥") }
            if contains(.shift) { components.append("⇧") }
            if contains(.command) { components.append("⌘") }
            return components.joined()
        }
    }

    var displayString: String {
        let keyName = KeyCodeMapper.string(for: keyCode) ?? "Unknown"
        return modifiers.displayString + keyName
    }
}

final class GlobalShortcutCenter {
    static let shared = GlobalShortcutCenter()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    private init() {}

    func register(shortcut: KeyboardShortcutPreference, handler: @escaping () -> Void) {
        unregister()
        callback = handler

        let hotKeyID = EventHotKeyID(signature: "TRNL".fourCharCode, id: UInt32(1))
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let status = InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData else { return noErr }
            let manager = Unmanaged<GlobalShortcutCenter>.fromOpaque(userData).takeUnretainedValue()
            manager.handle(event: event)
            return noErr
        }, 1, &eventSpec, selfPointer, &eventHandler)

        guard status == noErr else {
            unregister()
            return
        }

        let registration = RegisterEventHotKey(UInt32(shortcut.keyCode),
                                               shortcut.modifiers.carbonFlags,
                                               hotKeyID,
                                               GetApplicationEventTarget(),
                                               0,
                                               &hotKeyRef)

        if registration != noErr {
            unregister()
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        eventHandler = nil
        callback = nil
    }

    private func handle(event: EventRef?) {
        guard let event else { return }
        let kind = GetEventKind(event)
        switch kind {
        case UInt32(kEventHotKeyPressed):
            callback?()
        default:
            break
        }
    }

    deinit {
        unregister()
    }
}

private extension String {
    var fourCharCode: OSType {
        var result: OSType = 0
        for scalar in unicodeScalars.prefix(4) {
            result = (result << 8) + OSType(scalar.value)
        }
        return result
    }
}

// 按键代码映射
struct KeyCodeMapper {
    static func string(for keyCode: Int) -> String? {
        let mapping: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space",
            50: "`",
            36: "Return", 48: "Tab", 51: "Delete", 53: "Escape",
            96: "F5", 97: "F6", 98: "F7", 99: "F3",
            100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
            118: "F4", 120: "F2", 122: "F1"
        ]
        return mapping[keyCode]
    }
}
