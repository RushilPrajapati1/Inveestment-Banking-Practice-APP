import SwiftUI
import UIKit

// Ledger (light) / Vault (dark) — two cohesive directions, one adaptive palette.
//
// Ledger: cream paper #EFECE5, ink #161E2E, gold rule #8E6B1F.
// Vault:  deep navy #0A1426, ivory #ECE6D2, gold accent #D4AC4B.
//
// Typography:
//   .display  — serif (New York) for hero numerals + question titles
//   .eyebrow  — monospaced uppercase for caption labels ("ANSWER", "01 BROWSE")
//   body      — system SF Pro everywhere else

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { trait in trait.userInterfaceStyle == .dark ? dark : light }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(UIColor(hex: hex, alpha: alpha))
    }
}

enum Palette {
    // Surfaces ------------------------------------------------------------
    static let canvas = Color(.adaptive(
        light: UIColor(hex: 0xEFECE5),        // cream paper
        dark:  UIColor(hex: 0x0A1426)         // deep navy
    ))
    static let card = Color(.adaptive(
        light: UIColor(hex: 0xFBF7EC),        // lighter cream
        dark:  UIColor(hex: 0x13223A)         // elevated navy
    ))
    static let cardElevated = Color(.adaptive(
        light: UIColor(hex: 0xF2EBDB),
        dark:  UIColor(hex: 0x1A2A48)
    ))
    static let bar = Color(.adaptive(
        light: UIColor(hex: 0xE8E2D2),
        dark:  UIColor(hex: 0x0F1B30)
    ))

    // Ink -----------------------------------------------------------------
    static let ink = Color(.adaptive(
        light: UIColor(hex: 0x161E2E),
        dark:  UIColor(hex: 0xECE6D2)
    ))
    static let inkBright = Color(.adaptive(
        light: UIColor(hex: 0x0E1424),
        dark:  UIColor(hex: 0xFFF8E3)
    ))
    static let inkMuted = Color(.adaptive(
        light: UIColor(hex: 0x5A5345),
        dark:  UIColor(hex: 0x8DA0BF)
    ))
    static let inkSubtle = Color(.adaptive(
        light: UIColor(hex: 0x8B826C),
        dark:  UIColor(hex: 0x5E6F8D)
    ))

    // Accents -------------------------------------------------------------
    static let gold = Color(.adaptive(
        light: UIColor(hex: 0x8E6B1F),
        dark:  UIColor(hex: 0xD4AC4B)
    ))
    static let goldSoft = Color(.adaptive(
        light: UIColor(hex: 0x8E6B1F, alpha: 0.15),
        dark:  UIColor(hex: 0xD4AC4B, alpha: 0.18)
    ))
    static let known = Color(.adaptive(
        light: UIColor(hex: 0x3F6B3A),
        dark:  UIColor(hex: 0x5BBE83)
    ))
    static let knownSoft = Color(.adaptive(
        light: UIColor(hex: 0x3F6B3A, alpha: 0.14),
        dark:  UIColor(hex: 0x5BBE83, alpha: 0.18)
    ))
    static let review = Color(.adaptive(
        light: UIColor(hex: 0xA85B22),
        dark:  UIColor(hex: 0xE3A24B)
    ))
    static let reviewSoft = Color(.adaptive(
        light: UIColor(hex: 0xA85B22, alpha: 0.14),
        dark:  UIColor(hex: 0xE3A24B, alpha: 0.18)
    ))

    // Lines / borders -----------------------------------------------------
    static let rule = Color(.adaptive(
        light: UIColor(hex: 0xD9CFB7),
        dark:  UIColor(white: 1, alpha: 0.10)
    ))
    static let ruleStrong = Color(.adaptive(
        light: UIColor(hex: 0x8E6B1F, alpha: 0.30),
        dark:  UIColor(hex: 0xD4AC4B, alpha: 0.32)
    ))
    static let hairline = Color(.adaptive(
        light: UIColor(hex: 0xC9BFA5),
        dark:  UIColor(white: 1, alpha: 0.06)
    ))
}

enum Theme {
    static let radiusControl: CGFloat = 6
    static let radiusRow: CGFloat = 8
    static let radiusCard: CGFloat = 10
    static let radiusHero: CGFloat = 12

    // Subtle gradients used only on emphasis (known/review states, hero ring)
    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [Palette.gold, Palette.gold.opacity(0.75)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static var knownGradient: LinearGradient {
        LinearGradient(
            colors: [Palette.known, Palette.known.opacity(0.75)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static var reviewGradient: LinearGradient {
        LinearGradient(
            colors: [Palette.review, Palette.review.opacity(0.75)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static func iconName(forGroup group: String) -> String {
        switch group.lowercased() {
        case let g where g.contains("fit"): return "person.fill"
        case let g where g.contains("account"): return "doc.text.fill"
        case let g where g.contains("valuation"): return "scalemass.fill"
        case let g where g.contains("dcf"): return "function"
        case let g where g.contains("merger"), let g where g.contains("m&a"): return "arrow.triangle.merge"
        case let g where g.contains("lbo"): return "chart.line.uptrend.xyaxis"
        case let g where g.contains("brain"): return "brain.head.profile"
        case let g where g.contains("market"): return "chart.bar.fill"
        default: return "folder.fill"
        }
    }

    // Haptics
    static func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func triggerSelectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func triggerSuccessHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Typography

extension Font {
    /// Serif display (uses iOS New York). Used for hero numerals + question titles.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Uppercase monospaced caption — eyebrow labels like "ANSWER", "01 / BROWSE".
    static func eyebrow(_ size: CGFloat = 11, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    /// Monospaced for digits/counters where alignment matters.
    static func figure(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Reusable styling

/// Gold hairline rule — Ledger paper-and-ink staple.
struct GoldRule: View {
    var width: CGFloat? = nil
    var body: some View {
        Rectangle()
            .fill(Palette.ruleStrong)
            .frame(width: width, height: 1)
    }
}

/// Paper/navy card surface with optional outline.
struct PaperCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.radiusCard
    var outlined: Bool = true
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(elevated ? Palette.cardElevated : Palette.card)
            )
            .overlay(
                outlined
                    ? AnyView(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Palette.rule, lineWidth: 0.75)
                    )
                    : AnyView(EmptyView())
            )
    }
}

/// Eyebrow label — small, mono, uppercase, tracked. Optionally gold-tinted.
struct Eyebrow: View {
    let text: String
    var color: Color? = nil
    var size: CGFloat = 11
    var body: some View {
        Text(text.uppercased())
            .font(.eyebrow(size, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(color ?? Palette.inkMuted)
    }
}

/// Mastery ring used in hero cards.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var trackColor: Color = Palette.rule
    var color: Color = Palette.gold

    var body: some View {
        ZStack {
            Circle().stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
        }
    }
}

// MARK: - Convenience

extension View {
    /// Paper / navy canvas background that adapts to color scheme.
    func canvasBackground() -> some View {
        background(Palette.canvas.ignoresSafeArea())
    }
}
