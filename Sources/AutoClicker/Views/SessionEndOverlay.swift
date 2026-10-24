import AppKit
import SwiftUI

/// Full-screen dim + light blur when the last slide timer finishes.
///
/// Uses a borderless `NSPanel` with `NSVisualEffectView` (behind-window material)
/// plus a dark tint — no ScreenCaptureKit. Works on macOS 13+ over other apps
/// (including Keynote fullscreen) via `.fullScreenAuxiliary`, same as the HUD.
/// Stays until the user picks Restart or Reset; nothing auto-dismisses it.
struct SessionEndCard: View {
    var slideCount: Int
    var totalSeconds: Int
    var presetTitle: String
    var language: AppLanguage
    var onRestart: () -> Void
    var onReset: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 8, height: 8)

            Text(language.pick("발표가 끝났습니다", "Presentation finished"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(summaryLine)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                AccentButton(
                    title: language.pick("다시 시작", "Restart"),
                    fillsWidth: true,
                    action: onRestart
                )
                QuietButton(
                    title: language.pick("리셋", "Reset"),
                    fillsWidth: true,
                    action: onReset
                )
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(width: 320)
        .glassSurface(cornerRadius: 24)
        .shadow(color: .black.opacity(0.35), radius: 28, y: 12)
    }

    private var summaryLine: String {
        let duration = TimeFormat.spokenDuration(totalSeconds, language: language)
        return language.pick(
            "\(slideCount)장 · \(duration) · \(presetTitle)",
            "\(slideCount) slides · \(duration) · \(presetTitle)"
        )
    }
}

@MainActor
final class SessionEndOverlayController {
    var language: AppLanguage = .korean

    private var panels: [NSPanel] = []
    private var cardPanel: NSPanel?
    private var onRestart: (() -> Void)?
    private var onReset: (() -> Void)?

    func show(
        slideCount: Int,
        totalSeconds: Int,
        presetTitle: String,
        language: AppLanguage,
        onRestart: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        hide()
        self.language = language
        self.onRestart = onRestart
        self.onReset = onReset

        for screen in NSScreen.screens {
            panels.append(makeDimPanel(covering: screen))
        }

        let card = makeCardPanel(
            slideCount: slideCount,
            totalSeconds: totalSeconds,
            presetTitle: presetTitle,
            language: language
        )
        cardPanel = card

        panels.forEach { $0.orderFrontRegardless() }
        card.orderFrontRegardless()
    }

    func hide() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        cardPanel?.orderOut(nil)
        cardPanel = nil
        onRestart = nil
        onReset = nil
    }

    private func makeDimPanel(covering screen: NSScreen) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        // Above the HUD (.statusBar) so the fade covers the mini menu too.
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        // Eat clicks on the dim so the talk behind cannot be advanced by accident.
        panel.ignoresMouseEvents = false
        panel.setFrame(screen.frame, display: true)

        let root = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        root.wantsLayer = true

        let effect = NSVisualEffectView(frame: root.bounds)
        effect.autoresizingMask = [.width, .height]
        // Soft system blur of whatever is behind (Keynote, desktop, …).
        effect.material = .fullScreenUI
        effect.blendingMode = .behindWindow
        effect.state = .active
        root.addSubview(effect)

        // Cool dark dim ~55% so the slide still reads faintly through the blur.
        let dim = NSView(frame: root.bounds)
        dim.autoresizingMask = [.width, .height]
        dim.wantsLayer = true
        dim.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        root.addSubview(dim)

        panel.contentView = root
        return panel
    }

    private func makeCardPanel(
        slideCount: Int,
        totalSeconds: Int,
        presetTitle: String,
        language: AppLanguage
    ) -> NSPanel {
        let cardSize = CGSize(width: 360, height: 220)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: cardSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true

        let view = SessionEndCard(
            slideCount: slideCount,
            totalSeconds: totalSeconds,
            presetTitle: presetTitle,
            language: language,
            onRestart: { [weak self] in self?.onRestart?() },
            onReset: { [weak self] in self?.onReset?() }
        )
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: cardSize)
        panel.contentView = host

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = CGPoint(
                x: visible.midX - cardSize.width / 2,
                y: visible.midY - cardSize.height / 2
            )
            panel.setFrameOrigin(origin)
        }

        return panel
    }
}
