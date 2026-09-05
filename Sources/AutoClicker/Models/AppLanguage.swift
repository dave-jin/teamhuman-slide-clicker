import Foundation

/// UI language, chosen by the user rather than by the system.
///
/// The app ships as a plain SPM executable with no `.lproj` resources, so
/// strings are paired at the call site with `pick(_:_:)` instead of going
/// through a string catalog. Keeping both languages side by side also makes
/// it obvious when one of them is missing.
enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case korean
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        }
    }

    func pick(_ korean: String, _ english: String) -> String {
        switch self {
        case .korean: return korean
        case .english: return english
        }
    }

    /// First launch follows the system; after that the saved choice wins.
    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ko") ? .korean : .english
    }
}
