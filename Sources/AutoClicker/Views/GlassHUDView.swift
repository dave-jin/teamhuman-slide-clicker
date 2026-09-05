import SwiftUI

/// One footprint for every HUD state.
///
/// Play, countdown and paused used to size themselves to their own content,
/// so the HUD jumped and resized mid-talk. They now share a single card and
/// only the contents change, which also lets the panel keep a constant frame.
enum HUDMetrics {
    static let cardSize = CGSize(width: 248, height: 132)
    static let cornerRadius: CGFloat = 30
    /// Breathing room inside the panel for the drop shadow.
    static let shadowInset: CGFloat = 10

    static var panelSize: CGSize {
        CGSize(
            width: cardSize.width + shadowInset * 2,
            height: cardSize.height + shadowInset * 2
        )
    }
}

struct GlassHUDView: View {
    @ObservedObject var sequencer: SequencerService
    var onPlay: () -> Void
    var onPause: () -> Void
    var onResume: () -> Void
    var onStop: () -> Void
    /// Called on every mouse move while the pointer is down on the HUD.
    var onDragChanged: () -> Void
    /// Called on mouse up. Returns `true` if the HUD was actually moved,
    /// in which case the press must not be treated as a click.
    var onDragEnded: () -> Bool

    private let controlRowHeight: CGFloat = 34

    var body: some View {
        card
            .frame(width: HUDMetrics.cardSize.width, height: HUDMetrics.cardSize.height)
            .glassSurface(
                cornerRadius: HUDMetrics.cornerRadius,
                tint: sequencer.phase == .armed ? Theme.accent : nil
            )
            .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)
            .padding(HUDMetrics.shadowInset)
            .contentShape(Rectangle())
            .gesture(pressGesture(action: primaryAction))
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

    /// Same internal margins in every state, so only the contents differ.
    private func cardShell<Top: View, Bottom: View>(
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom
    ) -> some View {
        VStack(spacing: 4) {
            top()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottom()
                .frame(height: controlRowHeight)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .padding(.horizontal, 14)
    }

    // MARK: - Armed (waiting for Play)

    private var armedCard: some View {
        cardShell {
            HStack(spacing: 14) {
                Image(systemName: "play.fill")
                    .font(.system(size: 32, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Play")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                    Text(sequencer.progressLabel + " · " + sequencer.timeLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .opacity(0.85)
                }
            }
        } bottom: {
            Text("클릭하면 카운트다운 시작")
                .font(.system(size: 11, weight: .medium))
                .opacity(0.8)
        }
        .foregroundStyle(Theme.onAccent)
        .help("클릭: 카운트다운 시작 · 드래그: 위치 이동")
    }

    // MARK: - Running

    private var runningCard: some View {
        cardShell {
            readout(accessory: nil)
        } bottom: {
            progressBar
        }
        .help("클릭: 일시정지 · 드래그: 위치 이동")
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink.opacity(0.12))
                Capsule()
                    .fill(sequencer.isUrgent ? Theme.urgent : Theme.accent)
                    .frame(width: max(0, width * sequencer.slideProgress))
            }
            .frame(height: 5)
            .frame(maxHeight: .infinity)
            .animation(.linear(duration: 0.25), value: sequencer.slideProgress)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Paused

    private var pausedCard: some View {
        cardShell {
            readout(accessory: "pause.fill")
        } bottom: {
            HStack(spacing: 8) {
                pausedButton("재개", icon: "play.fill", tint: Theme.accent, action: onResume)
                pausedButton("정지", icon: "stop.fill", tint: nil, action: onStop)
            }
        }
        .help("재개하거나 메뉴로 돌아갑니다 · 드래그: 위치 이동")
    }

    private func pausedButton(
        _ title: String,
        icon: String,
        tint: Color?,
        action: @escaping () -> Void
    ) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint == nil ? Theme.ink : Theme.onAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassSurface(cornerRadius: 15, tint: tint, interactive: true)
            .contentShape(Capsule())
            .gesture(pressGesture(action: action))
    }

    // MARK: - Shared readout

    /// Countdown and slide position, identical in running and paused states so
    /// nothing shifts when the talk is paused.
    private func readout(accessory: String?) -> some View {
        VStack(spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(sequencer.timeLabel)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(sequencer.isUrgent ? Theme.urgent : Theme.ink)
                    .animation(.easeInOut(duration: 0.15), value: sequencer.remainingSeconds)

                if let accessory {
                    Image(systemName: accessory)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.inkMuted)
                }
            }

            Text(sequencer.progressLabel)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.inkMuted)
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
