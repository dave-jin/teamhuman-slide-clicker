import SwiftUI

/// Compact chip HUD: idle shows time + thin progress bar; hover reveals controls.
enum HUDMetrics {
    /// Running idle — time + bar, tiny footprint.
    static let idleCardSize = CGSize(width: 88, height: 44)
    /// Hover / paused — Pause|Resume + Reset stacked under the time.
    static let hoverCardSize = CGSize(width: 120, height: 102)
    /// Armed ready — Play + Settings.
    static let armedCardSize = CGSize(width: 120, height: 72)
    static let cornerRadius: CGFloat = 14
    /// Thin track under the countdown.
    static let progressBarHeight: CGFloat = 3
    /// Breathing room inside the panel for the drop shadow.
    static let shadowInset: CGFloat = 8

    static func cardSize(phase: SequencerPhase, hovered: Bool) -> CGSize {
        switch phase {
        case .armed:
            return armedCardSize
        case .running:
            return hovered ? hoverCardSize : idleCardSize
        case .paused:
            return hoverCardSize
        case .idle, .finished:
            return idleCardSize
        }
    }

    static func panelSize(phase: SequencerPhase, hovered: Bool) -> CGSize {
        let card = cardSize(phase: phase, hovered: hovered)
        return CGSize(
            width: card.width + shadowInset * 2,
            height: card.height + shadowInset * 2
        )
    }

    /// Default panel size before the first show.
    static var panelSize: CGSize {
        panelSize(phase: .running, hovered: false)
    }
}

struct GlassHUDView: View {
    @ObservedObject var sequencer: SequencerService
    var language: AppLanguage
    /// Owned by `GlassHUDPanelController` (AppKit) — avoid `@State` so
    /// `swift build` works with Command Line Tools (no SwiftUIMacros plugin).
    var isHovered: Bool
    var onPlay: () -> Void
    var onPause: () -> Void
    var onResume: () -> Void
    var onReset: () -> Void
    /// Armed chip → full Setup window.
    var onOpenSettings: () -> Void
    /// Hover enter/leave — panel resizes around the chip.
    var onHoverChanged: (Bool) -> Void
    /// Called on every mouse move while the pointer is down on the HUD.
    var onDragChanged: () -> Void
    /// Called on mouse up. Returns `true` if the HUD was actually moved,
    /// in which case the press must not be treated as a click.
    var onDragEnded: () -> Bool

    private var isRunning: Bool { sequencer.phase == .running }
    private var showControls: Bool {
        switch sequencer.phase {
        case .running: return isHovered
        case .paused, .armed: return true
        case .idle, .finished: return false
        }
    }

    private var cardSize: CGSize {
        HUDMetrics.cardSize(phase: sequencer.phase, hovered: isHovered)
    }

    var body: some View {
        card
            .frame(width: cardSize.width, height: cardSize.height)
            .background {
                Color.clear
                    .glassSurface(
                        cornerRadius: HUDMetrics.cornerRadius,
                        tint: sequencer.phase == .armed ? Theme.accent : nil,
                        variant: isRunning && !isHovered ? .clear : .regular
                    )
                    .opacity(isRunning && !isHovered ? 0.42 : 1)
                    .shadow(
                        color: .black.opacity(isRunning && !isHovered ? 0.08 : 0.2),
                        radius: isRunning && !isHovered ? 4 : 8,
                        x: 0,
                        y: 2
                    )
            }
            .padding(HUDMetrics.shadowInset)
            .contentShape(Rectangle())
            .onHover { hovering in
                onHoverChanged(hovering)
            }
            .gesture(pressGesture(action: primaryAction))
            .animation(.easeInOut(duration: 0.16), value: showControls)
            .animation(.easeInOut(duration: 0.16), value: sequencer.phase)
    }

    @ViewBuilder
    private var card: some View {
        switch sequencer.phase {
        case .armed:
            armedCard
        case .running:
            runningCard
        case .paused:
            pausedCard
        case .idle, .finished:
            Color.clear
        }
    }

    /// Body click only while running idle (no hover). Armed Play and
    /// hover/paused controls use their own button gestures.
    private var primaryAction: (() -> Void)? {
        switch sequencer.phase {
        case .running: return showControls ? nil : onPause
        case .armed, .paused, .idle, .finished: return nil
        }
    }

    // MARK: - Click vs. drag

    private func pressGesture(action: (() -> Void)?) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { _ in onDragChanged() }
            .onEnded { _ in
                let moved = onDragEnded()
                if !moved { action?() }
            }
    }

    // MARK: - Horizontal progress (under the time)

    /// Simple filled capsule — avoids RoundedRectangle.trim stroke artifacts.
    private var progressBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink.opacity(0.14))
                Capsule()
                    .fill(sequencer.isUrgent ? Theme.urgent : Theme.accent)
                    .frame(width: max(0, width * sequencer.slideProgress))
            }
            .frame(height: HUDMetrics.progressBarHeight)
            .frame(maxHeight: .infinity, alignment: .center)
            .animation(.linear(duration: 0.25), value: sequencer.slideProgress)
        }
        .frame(height: HUDMetrics.progressBarHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Armed (ready chip)

    private var armedCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Play")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(pressGesture(action: onPlay))

            chipButton(
                language.pick("설정", "Settings"),
                icon: "gearshape",
                accent: false,
                onAccentSurface: true,
                action: onOpenSettings
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .help(language.pick(
            "클릭: 시작 · 설정: 전체 Setup · 드래그: 이동",
            "Click to start · Settings opens setup · drag to move"
        ))
    }

    // MARK: - Running (idle = time + bar; hover = Pause + Reset)

    private var runningCard: some View {
        VStack(spacing: showControls ? 5 : 4) {
            timeOnly
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            progressBar

            if showControls {
                chipButton(
                    language.pick("일시정지", "Pause"),
                    icon: "pause.fill",
                    accent: true,
                    action: onPause
                )
                chipButton(
                    language.pick("리셋", "Reset"),
                    icon: "xmark",
                    accent: false,
                    action: onReset
                )
            }
        }
        .padding(.horizontal, showControls ? 10 : 8)
        .padding(.vertical, showControls ? 8 : 5)
        .help(language.pick(
            "호버: 일시정지·리셋 · 클릭: 일시정지 · 드래그: 이동",
            "Hover: pause · reset · click to pause · drag to move"
        ))
    }

    // MARK: - Paused (Resume + Reset always visible)

    private var pausedCard: some View {
        VStack(spacing: 5) {
            timeOnly
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            progressBar

            chipButton(
                language.pick("재개", "Resume"),
                icon: "play.fill",
                accent: true,
                action: onResume
            )
            chipButton(
                language.pick("리셋", "Reset"),
                icon: "xmark",
                accent: false,
                action: onReset
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .help(language.pick(
            "재개 · 리셋(준비 칩) · 드래그: 이동",
            "Resume · reset to ready chip · drag to move"
        ))
    }

    // MARK: - Shared pieces

    /// Preferences: idle chip shows time + thin bar (no slide count).
    private var timeOnly: some View {
        Text(sequencer.timeLabel)
            .font(.system(size: showControls ? 22 : 20, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(sequencer.isUrgent ? Theme.urgent : Theme.ink)
            .frame(maxWidth: .infinity)
            .scaleEffect(sequencer.isUrgent ? 1.04 : 1.0)
            .animation(
                sequencer.isUrgent
                    ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                    : .default,
                value: sequencer.isUrgent
            )
            .animation(.easeInOut(duration: 0.15), value: sequencer.remainingSeconds)
    }

    private func chipButton(
        _ title: String,
        icon: String,
        accent: Bool,
        onAccentSurface: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(buttonForeground(accent: accent, onAccentSurface: onAccentSurface))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background {
            if accent {
                Capsule().fill(Theme.accent)
            } else if onAccentSurface {
                Capsule().fill(Color.white.opacity(0.22))
            } else {
                Capsule()
                    .fill(Color.clear)
                    .glassSurface(cornerRadius: 9, interactive: true)
            }
        }
        .contentShape(Capsule())
        .gesture(pressGesture(action: action))
    }

    private func buttonForeground(accent: Bool, onAccentSurface: Bool) -> Color {
        if accent { return Theme.onAccent }
        if onAccentSurface { return Theme.onAccent.opacity(0.95) }
        return Theme.ink
    }
}
