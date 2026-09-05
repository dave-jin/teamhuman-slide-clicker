import Combine
import Foundation

enum SequencerPhase: Equatable, Sendable {
    case idle
    case armed
    case running
    case paused
    case finished
}

@MainActor
final class SequencerService: ObservableObject {
    @Published private(set) var phase: SequencerPhase = .idle
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var totalSlides: Int = 0
    @Published private(set) var isUrgent: Bool = false
    /// Full length of the slide now on screen — the denominator for the HUD progress bar.
    @Published private(set) var currentSlideSeconds: Int = 0

    var advanceKey: AdvanceKey = .space
    private var timings: [Int] = []
    private var runTask: Task<Void, Never>?
    private var pauseContinuation: CheckedContinuation<Void, Never>?

    /// Setup locked while armed / running / paused.
    var isSessionOpen: Bool {
        switch phase {
        case .armed, .running, .paused:
            return true
        case .idle, .finished:
            return false
        }
    }

    var isActive: Bool {
        phase == .running || phase == .paused
    }

    var progressLabel: String {
        guard totalSlides > 0 else { return "0 / 0" }
        return "\(currentIndex + 1) / \(totalSlides)"
    }

    var timeLabel: String {
        TimeFormat.remaining(max(0, remainingSeconds))
    }

    /// How much of the current slide has already elapsed, 0...1.
    var slideProgress: Double {
        guard currentSlideSeconds > 0 else { return 0 }
        let elapsed = Double(currentSlideSeconds - max(0, remainingSeconds))
        return min(1, max(0, elapsed / Double(currentSlideSeconds)))
    }

    /// Prepare timings and wait for Play — countdown does not start yet.
    func arm(timings: [Int], key: AdvanceKey) {
        guard !timings.isEmpty else { return }
        stop()
        self.timings = timings
        self.advanceKey = key
        self.totalSlides = timings.count
        self.currentIndex = 0
        self.remainingSeconds = timings[0]
        self.currentSlideSeconds = timings[0]
        self.phase = .armed
        self.isUrgent = false
    }

    /// Begin countdown from armed state.
    func play() {
        guard phase == .armed, !timings.isEmpty else { return }
        phase = .running
        isUrgent = remainingSeconds <= 3
        runTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
        isUrgent = false
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .running
        isUrgent = remainingSeconds <= 3
        if let cont = pauseContinuation {
            pauseContinuation = nil
            cont.resume()
        }
    }

    func togglePause() {
        if phase == .running {
            pause()
        } else if phase == .paused {
            resume()
        }
    }

    func stop() {
        runTask?.cancel()
        runTask = nil
        if let cont = pauseContinuation {
            pauseContinuation = nil
            cont.resume()
        }
        phase = .idle
        currentIndex = 0
        remainingSeconds = 0
        currentSlideSeconds = 0
        totalSlides = 0
        isUrgent = false
        timings = []
    }

    private func runLoop() async {
        while !Task.isCancelled && currentIndex < timings.count {
            if remainingSeconds <= 0 {
                remainingSeconds = timings[currentIndex]
            }
            currentSlideSeconds = timings[currentIndex]
            isUrgent = remainingSeconds <= 3

            while remainingSeconds > 0 {
                if Task.isCancelled { return }

                if phase == .paused {
                    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                        pauseContinuation = cont
                    }
                    if Task.isCancelled { return }
                    continue
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                if phase == .paused { continue }

                remainingSeconds -= 1
                isUrgent = remainingSeconds <= 3
            }

            if Task.isCancelled { return }

            let isLast = currentIndex >= timings.count - 1
            if !isLast {
                KeystrokeService.send(advanceKey)
                currentIndex += 1
                remainingSeconds = timings[currentIndex]
                currentSlideSeconds = timings[currentIndex]
            } else {
                phase = .finished
                remainingSeconds = 0
                isUrgent = false
                return
            }
        }

        if !Task.isCancelled {
            phase = .finished
        }
    }
}
