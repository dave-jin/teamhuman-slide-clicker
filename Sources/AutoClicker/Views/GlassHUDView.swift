import SwiftUI

/// HUD footprint: compact while running, a little taller when paused so
/// Restart / Reset fit without covering the slide during countdown.
enum HUDMetrics {
    static let cardSize = CGSize(width: 136, height: 64)
    /// Paused expands vertically (mockup); width stays close so the HUD
    /// does not jump sideways when the talk is paused.
    static let pausedCardSize = CGSize(width: 148, height: 126)
    static let cornerRadius: CGFloat = 18
    /// Breathing room inside the panel for the drop shadow.
    static let shadowInset: CGFloat = 8

    static func cardSize(for phase: SequencerPhase) -> CGSize {
        phase == .paused ? pausedCardSize : cardSize
    }

    static func panelSize(for phase: SequencerPhase) -> CGSize {
        let card = cardSize(for: phase)
        return CGSize(
            width: card.width + shadowInset * 2,
            height: card.height + shadowInset * 2
        )
    }

    static var panelSize: CGSize {
        panelSize(for: .running)
    }
}

struct GlassHUDView: View {
    @ObservedObject var sequencer: SequencerService
    var language: AppLanguage
    var onPlay: () -> Void
    var onPause: () -> Void
    var onResume: () -> Void
    var onRestart: () -> Void
    var onReset: () -> Void
    /// Called on every mouse move while the pointer is down on the HUD.
    var onDragChanged: () -> Void
    /// Called on mouse up. Returns `true` if the HUD was actually moved,
    /// in which case the press must not be treated as a click.
    var onDragEnded: () -> Bool

    private let mainRowHeight: CGFloat = 30
    private let controlRowHeight: CGFloat = 18

    private var isRunning: Bool { sequencer.phase == .running }
    private var cardSize: CGSize { HUDMetrics.cardSize(for: sequencer.phase) }

    var body: some View {
        card
            .frame(width: cardSize.width, height: cardSize.height)
            // The pane is drawn behind the contents rather than around them, so
            // the countdown stays fully opaque while its glass fades back into
            // the slide. Fading the whole card would dim the numbers too.
            .background {
                Color.clear
                    .glassSurface(
                        cornerRadius: HUDMetrics.cornerRadius,
                        tint: sequencer.phase == .armed ? Theme.accent : nil,
                        variant: isRunning ? .clear : .regular
                    )
                    .opacity(isRunning ? 0.55 : 1)
                    .shadow(
                        color: .black.opacity(isRunning ? 0.10 : 0.2),
                        radius: isRunning ? 5 : 9,
                        x: 0,
                        y: 3
                    )
            }
            .padding(HUDMetrics.shadowInset)
            .contentShape(Rectangle())
            .gesture(pressGesture(action: primaryAction))
            .animation(.easeInOut(duration: 0.18), value: sequencer.phase)
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

    /// Clicking the card body does the obvious thing for the current state.
    private var primaryAction: (() -> Void)? {
        switch sequencer.phase {
        case .armed: return onPlay
        case .running: return onPause
        case .paused, .idle, .finished: return nil
        }
    }

    // MARK: - Click vs. drag

    /// A press that stays put is a click; a press that travels moves the HUD.
    private func pressGesture(action: (() -> Void)?) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { _ in onDragChanged() }
            .onEnded { _ in
                let moved = onDragEnded()
                if !moved { action?() }
            }
    }

    /// Same two rows in armed / running, so only the contents differ.
    private func cardShell<Top: View, Bottom: View>(
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom
    ) -> some View {
        VStack(spacing: 3) {
            top()
                .frame(maxWidth: .infinity, minHeight: mainRowHeight, maxHeight: .infinity)
            bottom()
                .frame(height: controlRowHeight)
        }
        .padding(.horizontal, 11)
        .padding(.top, 6)
        .padding(.bottom, 7)
    }

    // MARK: - Armed (waiting for Play)

    private var armedCard: some View {
        cardShell {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Play")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer(minLength: 4)
                Text(sequencer.progressLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .opacity(0.85)
            }
        } bottom: {
            Text(language.pick("클릭하면 시작", "Click to start"))
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.onAccent)
        .help(language.pick(
            "클릭: 카운트다운 시작 · 드래그: 위치 이동",
            "Click to start the countdown · drag to move"
        ))
    }

    // MARK: - Running

    private var runningCard: some View {
        cardShell {
            readout
        } bottom: {
            progressBar
        }
        .help(language.pick(
            "클릭: 일시정지 · 드래그: 위치 이동",
            "Click to pause · drag to move"
        ))
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink.opacity(0.16))
                Capsule()
                    .fill(sequencer.isUrgent ? Theme.urgent : Theme.accent)
                    .frame(width: max(0, width * sequencer.slideProgress))
            }
            .frame(height: 4)
            .frame(maxHeight: .infinity)
            .animation(.linear(duration: 0.25), value: sequencer.slideProgress)
        }
    }

    // MARK: - Paused (expanded: resume / restart / reset)

    private var pausedCard: some View {
        VStack(spacing: 6) {
            readout
                .frame(height: mainRowHeight)

            progressBar
                .frame(height: 4)

            pausedButton(
                language.pick("재개", "Resume"),
                icon: "play.fill",
                tint: Theme.accent,
                action: onResume
            )

            HStack(spacing: 6) {
                pausedButton(
                    language.pick("리셋", "Reset"),
                    icon: "xmark",
                    tint: nil,
                    action: onReset
                )
                pausedButton(
                    language.pick("다시 시작", "Restart"),
                    icon: "arrow.counterclockwise",
                    tint: nil,
                    action: onRestart
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .help(language.pick(
            "재개 · 다시 시작(1장부터) · 리셋(설정으로) · 드래그: 이동",
            "Resume · restart from slide 1 · reset to setup · drag to move"
        ))
    }

    private func pausedButton(
        _ title: String,
        icon: String,
        tint: Color?,
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
        .foregroundStyle(tint == nil ? Theme.ink : Theme.onAccent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .glassSurface(cornerRadius: 9, tint: tint, interactive: true)
        .contentShape(Capsule())
        .gesture(pressGesture(action: action))
    }

    // MARK: - Shared readout

    /// Countdown and slide position, identical in running and paused states so
    /// nothing shifts when the talk is paused.
    private var readout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(sequencer.timeLabel)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(sequencer.isUrgent ? Theme.urgent : Theme.ink)
                .animation(.easeInOut(duration: 0.15), value: sequencer.remainingSeconds)

            Spacer(minLength: 4)

            Text(sequencer.progressLabel)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(Theme.ink.opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(sequencer.isUrgent ? 1.03 : 1.0)
        .animation(
            sequencer.isUrgent
                ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                : .default,
            value: sequencer.isUrgent
        )
    }
}
