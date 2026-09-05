import Carbon.HIToolbox
import Foundation

enum AdvanceKey: String, CaseIterable, Identifiable, Codable, Sendable {
    case space
    case rightArrow
    case pageDown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .space: return "Space"
        case .rightArrow: return "→ Right"
        case .pageDown: return "Page Down"
        }
    }

    var keyCode: CGKeyCode {
        switch self {
        case .space: return CGKeyCode(kVK_Space)
        case .rightArrow: return CGKeyCode(kVK_RightArrow)
        case .pageDown: return CGKeyCode(kVK_PageDown)
        }
    }
}
