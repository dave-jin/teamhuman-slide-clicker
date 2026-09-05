import SwiftUI

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

    private let accent = Color(red: 15 / 255, green: 118 / 255, blue: 110 / 255)

    var body: some View {
        Group {
            switch sequencer.phase {
            case .armed:
                armedView
            case .running:
                runningView
            case .paused:
                pausedView
            case .idle, .finished:
                EmptyView()
            }
        }
        .padding(8)
        .contentShape(Rectangle())
        // Bare background: drag only, no click action.
        .gesture(dragGesture())
    }

    // MARK: - Click vs. drag

    /// A press that moves the HUD is a drag; a press that stays put is a click.
    private func dragGesture(action: (() -> Void)? = nil) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { _ in onDragChanged() }
            .onEnded { _ in
                let moved = onDragEnded()
                if !moved { action?() }
            }
    }

    // MARK: - Armed (waiting for Play)

    private var armedView: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text("Play")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(sequencer.progressLabel + " · " + sequencer.timeLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.7)
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Capsule(style: .continuous)
                .fill(accent)
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        .contentShape(Capsule(style: .continuous))
        .gesture(dragGesture(action: onPlay))
        .help("눌러서 카운트다운 시작 · 드래그로 이동")
    }

    // MARK: - Running

    private var runningView: some View {
        let urgent = sequencer.isUrgent
        return VStack(spacing: 2) {
            Text(sequencer.timeLabel)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(urgent
                    ? Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
                    : Color(red: 11 / 255, green: 13 / 255, blue: 18 / 255).opacity(0.9))
                .animation(.easeInOut(duration: 0.15), value: sequencer.remainingSeconds)

            Text(sequencer.progressLabel)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            ZStack {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                Capsule(style: .continuous)
                    .fill(urgent
                        ? Color(red: 1, green: 0.92, blue: 0.92).opacity(0.35)
                        : Color.white.opacity(0.18))
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(urgent ? 0.65 : 0.55), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 6)
        .scaleEffect(urgent ? 1.03 : 1.0)
        .animation(
            urgent
                ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                : .default,
            value: urgent
        )
        .contentShape(Capsule(style: .continuous))
        .gesture(dragGesture(action: onPause))
        .help("클릭: 일시정지 · 드래그: 이동")
    }

    // MARK: - Paused

    private var pausedView: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text(sequencer.timeLabel)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("‖")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.45)
                }
                Text(sequencer.progressLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.4))
            }

            HStack(spacing: 8) {
                Label("재개", systemImage: "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .gesture(dragGesture(action: onResume))

                Label("정지", systemImage: "stop.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.12))
                    .foregroundStyle(.primary.opacity(0.85))
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .gesture(dragGesture(action: onStop))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 6)
        .help("재개 또는 정지(메뉴로) · 드래그로 이동")
    }
}
