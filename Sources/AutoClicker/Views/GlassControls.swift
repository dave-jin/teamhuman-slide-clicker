import AppKit
import SwiftUI

/// Small uppercase section heading.
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.9)
            .foregroundStyle(Theme.inkMuted)
    }
}

/// One option in a segmented row. Selected chips carry the brand accent.
struct GlassChip: View {
    let title: String
    let isSelected: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .glassSurface(
                    cornerRadius: 16,
                    tint: isSelected ? Theme.accent : nil,
                    interactive: true
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// The single call-to-action button, filled with the brand accent.
struct AccentButton: View {
    let title: String
    var isEnabled: Bool = true
    var fillsWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .glassSurface(cornerRadius: 18, tint: Theme.accent, interactive: true)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// A quiet button for secondary actions.
struct QuietButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .glassSurface(cornerRadius: 14, interactive: true)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// Blurs whatever sits behind the window so the glass cards have something to
/// refract. Without it the "glass" would float on a flat fill.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

/// Makes the setup window translucent so `VisualEffectBackground` actually blurs.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
