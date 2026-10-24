import AppKit
import Combine
import SwiftUI

@MainActor
final class GlassHUDPanelController: NSObject {
    weak var sequencer: SequencerService?
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onResume: (() -> Void)?
    var onRestart: (() -> Void)?
    var onReset: (() -> Void)?
    /// Set by `AppModel`; the HUD lives outside the SwiftUI environment chain.
    var language: AppLanguage = .korean {
        didSet { updateContent() }
    }

    private var panel: NSPanel?
    private var hosting: NSHostingView<GlassHUDView>?
    private var phaseCancellable: AnyCancellable?

    /// Panel origin and pointer location captured when a press begins.
    private var dragAnchor: (origin: CGPoint, mouse: CGPoint)?
    /// The press has passed the drag threshold, so it is a move and not a click.
    private var isDragging = false
    private let dragThreshold: CGFloat = 3

    func attach(sequencer: SequencerService) {
        self.sequencer = sequencer
        phaseCancellable = sequencer.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] phase in
                self?.applySize(for: phase)
                self?.updateContent()
            }
    }

    func show() {
        guard let sequencer else { return }
        if panel == nil {
            panel = makePanel(sequencer: sequencer)
        }
        applySize(for: sequencer.phase)
        updateContent()
        positionIfNeeded()
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makeHUDView(sequencer: SequencerService) -> GlassHUDView {
        GlassHUDView(
            sequencer: sequencer,
            language: language,
            onPlay: { [weak self] in self?.onPlay?() },
            onPause: { [weak self] in self?.onPause?() },
            onResume: { [weak self] in self?.onResume?() },
            onRestart: { [weak self] in self?.onRestart?() },
            onReset: { [weak self] in self?.onReset?() },
            onDragChanged: { [weak self] in self?.dragChanged() },
            onDragEnded: { [weak self] in self?.dragEnded() ?? false }
        )
    }

    private func updateContent() {
        guard let sequencer, let panel else { return }
        let view = makeHUDView(sequencer: sequencer)
        if let hosting {
            hosting.rootView = view
        } else {
            let size = HUDMetrics.panelSize(for: sequencer.phase)
            let host = NSHostingView(rootView: view)
            host.frame = NSRect(origin: .zero, size: size)
            panel.contentView = host
            hosting = host
        }
    }

    private func applySize(for phase: SequencerPhase) {
        guard let panel else { return }
        let size = HUDMetrics.panelSize(for: phase)
        var frame = panel.frame
        // Grow/shrink from the top-right so the countdown corner stays put.
        let oldSize = frame.size
        frame.origin.x += oldSize.width - size.width
        frame.origin.y += oldSize.height - size.height
        frame.size = size
        panel.setFrame(frame, display: true)
        hosting?.frame = NSRect(origin: .zero, size: size)
    }

    private func makePanel(sequencer: SequencerService) -> NSPanel {
        let size = HUDMetrics.panelSize(for: sequencer.phase)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        // The HUD content handles dragging itself; AppKit's background drag never
        // fires because the SwiftUI hit targets swallow the mouse-down.
        panel.isMovableByWindowBackground = false
        panel.animationBehavior = .utilityWindow

        let host = NSHostingView(rootView: makeHUDView(sequencer: sequencer))
        host.frame = NSRect(origin: .zero, size: size)
        panel.contentView = host
        hosting = host

        return panel
    }

    private func positionIfNeeded() {
        guard let panel, let sequencer else { return }
        let size = HUDMetrics.panelSize(for: sequencer.phase)
        if let saved = PersistenceService.loadHUDOrigin() {
            // A saved spot can land off-screen after a display change.
            panel.setFrameOrigin(clampedOrigin(saved, size: size))
            return
        }
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        panel.setFrameOrigin(
            CGPoint(x: visible.maxX - size.width - 24, y: visible.minY + 24)
        )
    }

    // MARK: - Dragging

    /// Called on every pointer move while the button is down on the HUD.
    private func dragChanged() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation

        guard let anchor = dragAnchor else {
            dragAnchor = (panel.frame.origin, mouse)
            isDragging = false
            return
        }

        let dx = mouse.x - anchor.mouse.x
        let dy = mouse.y - anchor.mouse.y
        if !isDragging {
            guard abs(dx) > dragThreshold || abs(dy) > dragThreshold else { return }
            isDragging = true
        }

        // Anchoring on the screen-absolute pointer keeps the HUD from drifting:
        // the window moves under the cursor, so per-frame deltas would compound.
        let target = CGPoint(x: anchor.origin.x + dx, y: anchor.origin.y + dy)
        panel.setFrameOrigin(clampedOrigin(target, size: panel.frame.size))
    }

    /// Called on mouse up. Returns `true` when the press moved the HUD,
    /// so the caller can skip the click action.
    private func dragEnded() -> Bool {
        let moved = isDragging
        dragAnchor = nil
        isDragging = false
        if moved, let panel {
            PersistenceService.saveHUDOrigin(panel.frame.origin)
        }
        return moved
    }

    /// Allows the HUD to cross displays but never to disappear off every screen.
    private func clampedOrigin(_ origin: CGPoint, size: CGSize) -> CGPoint {
        let proposed = CGRect(origin: origin, size: size)
        let minWidth = min(size.width, 48)
        let minHeight = min(size.height, 24)

        let screens = NSScreen.screens
        for screen in screens {
            let overlap = proposed.intersection(screen.visibleFrame)
            if overlap.width >= minWidth, overlap.height >= minHeight {
                return origin
            }
        }

        let nearest = screens.max { lhs, rhs in
            let l = proposed.intersection(lhs.frame)
            let r = proposed.intersection(rhs.frame)
            return l.width * l.height < r.width * r.height
        } ?? NSScreen.main
        guard let visible = nearest?.visibleFrame else { return origin }

        return CGPoint(
            x: min(max(origin.x, visible.minX), max(visible.minX, visible.maxX - size.width)),
            y: min(max(origin.y, visible.minY), max(visible.minY, visible.maxY - size.height))
        )
    }
}
