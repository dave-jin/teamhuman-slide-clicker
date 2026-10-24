import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var slides: [SlideItem]
    @Published var advanceKey: AdvanceKey
    @Published var language: AppLanguage
    @Published var selectedPreset: TimingPreset? = .customExample
    @Published var profiles: [TimingProfile] = []
    @Published var profileNameDraft: String = ""
    @Published var showProfiles = false
    @Published var showAccessibilityAlert = false

    let sequencer = SequencerService()
    let hudController = GlassHUDPanelController()
    let endOverlay = SessionEndOverlayController()

    private var cancellables = Set<AnyCancellable>()

    var totalSeconds: Int {
        slides.reduce(0) { $0 + $1.seconds }
    }

    var canEdit: Bool {
        !sequencer.isSessionOpen
    }

    /// Label used on the session-end card (preset name, or Custom).
    var sessionPresetTitle: String {
        selectedPreset?.title ?? language.pick("사용자 설정", "Custom")
    }

    init() {
        let timings = PersistenceService.loadTimings()
        slides = timings.map { SlideItem(seconds: $0) }
        advanceKey = PersistenceService.loadAdvanceKey()
        language = PersistenceService.loadLanguage()
        profiles = PersistenceService.loadProfiles()

        hudController.attach(sequencer: sequencer)
        hudController.language = language
        hudController.onPlay = { [weak self] in self?.play() }
        hudController.onPause = { [weak self] in self?.sequencer.pause() }
        hudController.onResume = { [weak self] in self?.sequencer.resume() }
        hudController.onRestart = { [weak self] in self?.restartSession() }
        hudController.onReset = { [weak self] in self?.resetToSetup() }

        sequencer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        sequencer.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] phase in
                guard let self else { return }
                if phase == .finished {
                    self.handleFinished()
                }
            }
            .store(in: &cancellables)
    }

    func applyPreset(_ preset: TimingPreset) {
        guard canEdit else { return }
        selectedPreset = preset
        slides = preset.timings.map { SlideItem(seconds: $0) }
        persist()
    }

    func addSlide() {
        guard canEdit else { return }
        selectedPreset = nil
        slides.append(SlideItem(seconds: 15))
        persist()
    }

    func removeSlide(_ id: UUID) {
        guard canEdit, slides.count > 1 else { return }
        selectedPreset = nil
        slides.removeAll { $0.id == id }
        persist()
    }

    func updateSeconds(id: UUID, seconds: Int) {
        guard canEdit else { return }
        selectedPreset = nil
        if let idx = slides.firstIndex(where: { $0.id == id }) {
            slides[idx].seconds = max(1, min(999, seconds))
            persist()
        }
    }

    /// Language can change at any time — it does not touch a running session.
    func setLanguage(_ language: AppLanguage) {
        self.language = language
        PersistenceService.saveLanguage(language)
        hudController.language = language
        endOverlay.language = language
    }

    func setAdvanceKey(_ key: AdvanceKey) {
        guard canEdit else { return }
        advanceKey = key
        persist()
    }

    /// Setup "시작": arm HUD with Play — does not start the timer yet.
    func start() {
        if !AccessibilityService.isTrusted {
            AccessibilityService.requestTrustPrompt()
            if !AccessibilityService.isTrusted {
                showAccessibilityAlert = true
                return
            }
        }

        let timings = slides.map(\.seconds)
        persist()
        endOverlay.hide()
        sequencer.arm(timings: timings, key: advanceKey)
        hideSetupWindow()
        hudController.show()
    }

    /// HUD Play: begin countdown.
    func play() {
        sequencer.play()
    }

    /// Same sequence / key / preset — back to slide 1, Setup stays closed.
    /// Lands in armed (Play) so the speaker can get ready again.
    func restartSession() {
        endOverlay.hide()
        let timings = slides.map(\.seconds)
        guard !timings.isEmpty else {
            resetToSetup()
            return
        }
        sequencer.arm(timings: timings, key: advanceKey)
        hideSetupWindow()
        hudController.show()
    }

    /// End the session and return to Setup. Prefs stay for editing.
    func resetToSetup() {
        endOverlay.hide()
        sequencer.stop()
        hudController.hide()
        showSetupWindow()
    }

    /// Alias used by menu / shortcuts that previously meant "stop".
    func stop() {
        resetToSetup()
    }

    func togglePause() {
        switch sequencer.phase {
        case .armed:
            play()
        case .running, .paused:
            sequencer.togglePause()
        default:
            break
        }
    }

    func saveProfile() {
        let name = profileNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let profile = TimingProfile(
            name: name,
            seconds: slides.map(\.seconds),
            advanceKey: advanceKey
        )
        profiles.insert(profile, at: 0)
        PersistenceService.saveProfiles(profiles)
        profileNameDraft = ""
    }

    func loadProfile(_ profile: TimingProfile) {
        guard canEdit else { return }
        selectedPreset = nil
        slides = profile.seconds.map { SlideItem(seconds: $0) }
        advanceKey = profile.advanceKey
        persist()
    }

    func deleteProfile(_ profile: TimingProfile) {
        profiles.removeAll { $0.id == profile.id }
        PersistenceService.saveProfiles(profiles)
    }

    private func persist() {
        PersistenceService.saveTimings(slides.map(\.seconds))
        PersistenceService.saveAdvanceKey(advanceKey)
    }

    private func handleFinished() {
        hudController.hide()
        // Setup stays closed until the user picks Reset (or Restart → HUD).
        endOverlay.show(
            slideCount: slides.count,
            totalSeconds: totalSeconds,
            presetTitle: sessionPresetTitle,
            language: language,
            onRestart: { [weak self] in self?.restartSession() },
            onReset: { [weak self] in self?.resetToSetup() }
        )
    }

    private func hideSetupWindow() {
        NSApp.windows
            .filter { !($0 is NSPanel) }
            .forEach { $0.orderOut(nil) }
    }

    private func showSetupWindow() {
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
