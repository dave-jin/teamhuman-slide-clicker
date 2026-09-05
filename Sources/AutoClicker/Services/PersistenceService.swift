import CoreGraphics
import Foundation

@MainActor
enum PersistenceService {
    private static let timingsKey = "timings"
    private static let advanceKeyKey = "advanceKey"
    private static let hudOriginXKey = "hudOriginX"
    private static let hudOriginYKey = "hudOriginY"
    private static let languageKey = "language"
    private static let profilesFileName = "profiles.json"

    static func loadTimings() -> [Int] {
        let defaults = UserDefaults.standard
        if let arr = defaults.array(forKey: timingsKey) as? [Int], !arr.isEmpty {
            return arr.map { max(1, min(999, $0)) }
        }
        return TimingPreset.customExample.timings
    }

    static func saveTimings(_ timings: [Int]) {
        UserDefaults.standard.set(timings, forKey: timingsKey)
    }

    static func loadAdvanceKey() -> AdvanceKey {
        if let raw = UserDefaults.standard.string(forKey: advanceKeyKey),
           let key = AdvanceKey(rawValue: raw) {
            return key
        }
        return .space
    }

    static func saveAdvanceKey(_ key: AdvanceKey) {
        UserDefaults.standard.set(key.rawValue, forKey: advanceKeyKey)
    }

    static func loadLanguage() -> AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: raw) {
            return language
        }
        return .systemDefault
    }

    static func saveLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    static func loadHUDOrigin() -> CGPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: hudOriginXKey) != nil else { return nil }
        return CGPoint(
            x: defaults.double(forKey: hudOriginXKey),
            y: defaults.double(forKey: hudOriginYKey)
        )
    }

    static func saveHUDOrigin(_ origin: CGPoint) {
        let defaults = UserDefaults.standard
        defaults.set(origin.x, forKey: hudOriginXKey)
        defaults.set(origin.y, forKey: hudOriginYKey)
    }

    private static var profilesURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("AutoClicker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(profilesFileName)
    }

    static func loadProfiles() -> [TimingProfile] {
        let url = profilesURL
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([TimingProfile].self, from: data)) ?? []
    }

    static func saveProfiles(_ profiles: [TimingProfile]) {
        let url = profilesURL
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
