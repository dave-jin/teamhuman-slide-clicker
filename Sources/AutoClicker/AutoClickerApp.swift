import AppKit
import SwiftUI

@main
struct AutoClickerApp: App {
    @StateObject private var model = AppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Auto Clicker") {
            ContentView(model: model)
                .onAppear {
                    appDelegate.model = model
                }
        }
        .defaultSize(width: 440, height: 720)
        .windowResizability(.contentSize)
        .commands {
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

                Button(model.language.pick("다시 시작 (1장부터)", "Restart (from slide 1)")) {
                    model.restartSession()
                }
                .disabled(!model.sequencer.isSessionOpen)

                Button(model.language.pick("리셋 (설정으로)", "Reset (back to setup)")) {
                    model.resetToSetup()
                }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!model.sequencer.isSessionOpen)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let handler: (NSEvent) -> Bool = { [weak self] event in
            guard let model = self?.model else { return false }
            guard event.modifierFlags.contains(.command) else { return false }
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if chars == "." {
                if model.sequencer.isSessionOpen {
                    model.resetToSetup()
                    return true
                }
            }
            if chars == "p", model.sequencer.isSessionOpen, model.sequencer.phase != .finished {
                model.togglePause()
                return true
            }
            return false
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event) ? nil : event
        }
        // When Keynote (or another app) is focused — needs Accessibility.
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handler(event)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
        }
        model?.resetToSetup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running while HUD or the session-end overlay is up without Setup.
        !(model?.sequencer.isSessionOpen ?? false)
    }
}
