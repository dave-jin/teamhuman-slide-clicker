import CoreGraphics
import Foundation

enum KeystrokeService {
    static func send(_ key: AdvanceKey) {
        guard AccessibilityService.isTrusted else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key.keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key.keyCode, keyDown: false)

        keyDown?.post(tap: .cghidEventTap)
        // Tiny gap helps some apps register the pair reliably.
        usleep(12_000)
        keyUp?.post(tap: .cghidEventTap)
    }
}
