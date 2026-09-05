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
            CommandMenu("Session") {
                Button("시작 (Play 대기)") { model.start() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(model.sequencer.isSessionOpen)

                Button("Play / 일시정지·재개") {
                    model.togglePause()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .disabled(!model.sequencer.isSessionOpen)

                Button("정지 (메뉴로)") { model.stop() }
                    .keyboardShortcut(".", modifiers: [.command])
                    .disabled(!model.sequencer.isSessionOpen && model.sequencer.phase != .finished)
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
                if model.sequencer.isSessionOpen || model.sequencer.phase == .finished {
                    model.stop()
                    return true
                }
            }
            if chars == "p", model.sequencer.isSessionOpen {
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
        model?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running if HUD is up without setup window.
        !(model?.sequencer.isSessionOpen ?? false)
    }
}
