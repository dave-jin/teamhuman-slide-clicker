import AppKit
import SwiftUI

/// Team Human palette, taken from withteamhuman.com.
///
/// The site is a warm light brand (terracotta on bone). macOS is not always
/// light, so every token carries a dark counterpart — mixing fixed light
/// values with system semantic colors is what made the setup window
/// unreadable in dark mode.
enum Theme {
    /// Brand accent — terracotta. Lifted in dark mode so it stays legible on glass.
    static let accent = adaptive(light: 0xC45C26, dark: 0xE2794A)
    /// Text and icons that sit on top of the accent.
    static let onAccent = Color.white

    /// Body text.
    static let ink = adaptive(light: 0x37210D, dark: 0xF1EDE7)
    /// Labels, captions, secondary rows.
    static let inkMuted = adaptive(light: 0x8C8A87, dark: 0xA39D96)

    /// Window canvas.
    static let canvas = adaptive(light: 0xF1F1ED, dark: 0x17130F)
    /// Faint fill for the inside of glass cards, so they read on any backdrop.
    static let surface = adaptive(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.55, darkAlpha: 0.06)
    /// Card and control borders.
    static let hairline = adaptive(light: 0x37210D, dark: 0xFFFFFF, lightAlpha: 0.12, darkAlpha: 0.14)

    /// Last seconds of a slide. A hotter red than the accent, still in the warm family.
    static let urgent = adaptive(light: 0xB3301C, dark: 0xFF7A5E)

    private static func adaptive(
        light: UInt32,
        dark: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(
                hex: isDark ? dark : light,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        })
    }
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Liquid Glass

/// How much of the backdrop the surface lets through.
enum GlassVariant {
    /// Standard frosted glass, for anything the eye needs to land on.
    case regular
    /// Barely-there glass, for the countdown that floats over a live slide.
    case clear
}

extension View {
    /// Liquid Glass on macOS 26+, a material of the same shape everywhere else.
    func glassSurface(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        interactive: Bool = false,
        variant: GlassVariant = .regular
    ) -> some View {
        modifier(GlassSurface(
            cornerRadius: cornerRadius,
            tint: tint,
            interactive: interactive,
            variant: variant
        ))
    }
}

struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color?
    var interactive: Bool
    var variant: GlassVariant = .regular

    /// Glass alone barely carries a hue, so a tinted surface also gets a brand
    /// fill layered over the glass. Without it the accent reads as plain gray.
    private var fillOpacity: Double { variant == .clear ? 0.35 : 0.88 }

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .background {
                    if let tint {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(fillOpacity))
                    }
                }
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background {
                    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    shape.fill(variant == .clear ? .ultraThinMaterial : .regularMaterial)
                        .opacity(variant == .clear ? 0.62 : 1)
                    if let tint {
                        shape.fill(tint.opacity(fillOpacity))
                    } else if variant == .regular {
                        shape.fill(Theme.surface)
                    }
                    shape.strokeBorder(Theme.hairline, lineWidth: 1)
                }
        }
    }

    @available(macOS 26.0, *)
    private var glass: Glass {
        var glass = variant == .clear ? Glass.clear : Glass.regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
}
