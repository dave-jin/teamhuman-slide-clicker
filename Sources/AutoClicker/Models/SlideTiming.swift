import Foundation

struct SlideItem: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    var seconds: Int

    init(id: UUID = UUID(), seconds: Int) {
        self.id = id
        self.seconds = max(1, min(999, seconds))
    }
}

enum TimingPreset: String, CaseIterable, Identifiable {
    case pechaKucha
    case ignite
    case customExample

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pechaKucha: return "PechaKucha"
        case .ignite: return "Ignite"
        case .customExample: return "Custom"
        }
    }

    var timings: [Int] {
        switch self {
        case .pechaKucha:
            return Array(repeating: 20, count: 20)
        case .ignite:
            return Array(repeating: 15, count: 20)
        case .customExample:
            return [10, 15, 15, 15, 15, 15, 15, 15, 15, 60]
        }
    }
}

enum TimeFormat {
    static func remaining(_ seconds: Int) -> String {
        if seconds < 60 {
            return "0:\(String(format: "%02d", seconds))"
        }
        let m = seconds / 60
        let s = seconds % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    static func total(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "0:\(String(format: "%02d", s))" }
        return "\(m):\(String(format: "%02d", s))"
    }

    /// Spoken-style duration for the session-end summary card.
    static func spokenDuration(_ seconds: Int, language: AppLanguage) -> String {
        let m = seconds / 60
        let s = seconds % 60
        switch language {
        case .korean:
            if m == 0 { return "\(s)초" }
            if s == 0 { return "\(m)분" }
            return "\(m)분 \(s)초"
        case .english:
            if m == 0 { return "\(s) sec" }
            if s == 0 { return m == 1 ? "1 min" : "\(m) min" }
            return "\(m) min \(s) sec"
        }
    }
}
