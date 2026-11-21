import AppKit
import SwiftUI

@main
struct AutoClickerApp: App {
    /// Model lives on the AppKit delegate — avoid `@StateObject` (SwiftUIMacros)
    /// so Command Line Tools can `swift build` without the Xcode macro plugin.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Auto Clicker") {
            ContentView(model: appDelegate.model)
        }
        .defaultSize(width: 440, height: 720)
        .windowResizability(.contentSize)
        .commands {
            let model = appDelegate.model
            CommandMenu(model.language.pick("세션", "Session")) {
                Button(model.language.pick("시작 (Play 대기)", "Start (wait for Play)")) {
                    model.start()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(model.sequencer.isSessionOpen)

                Button(model.language.pick("Play / 일시정지·재개", "Play / pause · resume")) {
                    model.togglePause()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .disabled(!model.sequencer.isSessionOpen || model.sequencer.phase == .finished)

                Button(model.language.pick("리셋 (준비 칩)", "Reset (ready chip)")) {
                    model.restartSession()
                }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!model.sequencer.isSessionOpen)

                Button(model.language.pick("설정 (전체 Setup)", "Settings (full setup)")) {
                    model.openSetup()
                }
                .disabled(!model.sequencer.isSessionOpen)
            }
        }
    }
}

/// Own `AppModel` on the main actor so Swift 6 / CLT accepts `AppModel()` —
/// stored property init must not run in a nonisolated `NSObject` context.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        // NSEvent monitors are delivered on the main thread; assumeIsolated
        // bridges the nonisolated monitor closure into @MainActor AppModel.
        let handler: (NSEvent) -> Bool = { [weak self] event in
            guard let self else { return false }
            return MainActor.assumeIsolated {
                self.handleCommandKey(event)
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event) ? nil : event
        }
        // When Keynote (or another app) is focused — needs Accessibility.
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handler(event)
        }
    }

    private func handleCommandKey(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return false }
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if chars == "." {
            if model.sequencer.isSessionOpen {
                // Chip Reset semantics: back to armed ready chip.
                model.restartSession()
                return true
            }
        }
        if chars == "p", model.sequencer.isSessionOpen, model.sequencer.phase != .finished {
            model.togglePause()
            return true
        }
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
        }
        model.openSetup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running while HUD or the session-end overlay is up without Setup.
        !model.sequencer.isSessionOpen
    }
}
