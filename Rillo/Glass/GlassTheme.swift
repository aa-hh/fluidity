import AppKit
import SwiftUI

/// The Glass token values from DESIGN.md ("App surfaces"), light and dark.
enum GlassTheme {
    // MARK: Colors

    static let window = dynamic(rgba(255, 255, 255, 0.72), rgba(14, 15, 19, 0.72))
    static let sidebar = dynamic(rgba(255, 255, 255, 0.4), rgba(10, 11, 14, 0.5))
    static let raised = dynamic(rgba(255, 255, 255, 0.85), rgba(255, 255, 255, 0.06))
    static let selectedAppKit = nsDynamic(rgba(20, 21, 25, 0.08), rgba(255, 255, 255, 0.12))
    static let selected = Color(nsColor: selectedAppKit)
    static let hover = dynamic(rgba(20, 21, 25, 0.04), rgba(255, 255, 255, 0.06))
    static let lineRule = dynamic(rgba(20, 21, 25, 0.1), rgba(255, 255, 255, 0.1))
    static let lineStrongAppKit = nsDynamic(rgba(20, 21, 25, 0.22), rgba(255, 255, 255, 0.22))
    static let lineStrong = Color(nsColor: lineStrongAppKit)
    static let textPrimaryAppKit = nsDynamic(hex(0x1C1C1E), hex(0xF4EFE6))
    static let textPrimary = Color(nsColor: textPrimaryAppKit)
    static let textSecondary = dynamic(hex(0x6F6A62), hex(0xA8A49C))
    static let actionPrimary = dynamic(hex(0x1C1C1E), hex(0xFFF6EA))
    static let actionOnPrimary = dynamic(hex(0xFFFFFF), hex(0x0E0F13))
    /// Icons only in Light: 4.11:1 on the window is too low for text.
    static let stateDone = dynamic(hex(0x1A8A52), hex(0x3EDC8A))
    static let stateAttention = dynamic(hex(0x9A5B00), hex(0xFFB020))
    static let stateDestructiveAppKit = nsDynamic(hex(0xC83230), hex(0xFF6B66))
    static let stateDestructive = Color(nsColor: stateDestructiveAppKit)
    /// The History page's added and rewritten words; Light is darker than `stateDone`, which is too low for text.
    static let changeAddedAppKit = nsDynamic(hex(0x146E40), hex(0x3EDC8A))
    static let changeRemovedTint = nsDynamic(rgba(200, 50, 48, 0.08), rgba(255, 107, 102, 0.12))
    static let changeAddedTint = nsDynamic(rgba(20, 110, 64, 0.08), rgba(62, 220, 138, 0.12))
    static let live = Color(nsColor: hex(0xFFE4B8))
    static let controlKnob = dynamic(hex(0xFFFFFF), hex(0xD9D4CB))
    static let focusRing = dynamic(rgba(28, 28, 30, 0.6), rgba(255, 228, 184, 0.85))

    /// The pill's four ivory tones, in the order the live top edge repeats them.
    static let ivoryWarm = Color(nsColor: hex(0xFFE4B8))
    static let ivoryWhite = Color(nsColor: hex(0xFFF6EA))
    static let ivoryApricot = Color(nsColor: hex(0xFFCFA0))
    static let ivoryCream = Color(nsColor: hex(0xFFEBD2))

    // MARK: Type

    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let section = Font.system(size: 15, weight: .medium, design: .rounded)
    static let label = Font.system(size: 13, weight: .medium, design: .rounded)
    static let body = Font.system(size: 13)
    static let detail = Font.system(size: 12)
    static let small = Font.system(size: 11)
    /// The popover transcript uses the pill's word metrics (13 pt on a 17 pt line).
    static let transcript = Font.system(size: 13)

    // MARK: Shape and size

    static let windowRadius: CGFloat = 16
    static let containerRadius: CGFloat = 14
    static let innerRadius: CGFloat = 8
    static let controlHeight: CGFloat = 28
    static let rowMinHeight: CGFloat = 44
    static let sidebarWidth: CGFloat = 184
    /// The Speech model tables: the First word and Updates every columns, then Live vs final.
    static let modelFigureWidth: CGFloat = 76
    static let modelLiveVsFinalWidth: CGFloat = 84
    static let modelRowHeight: CGFloat = 48
    static let modelHeaderHeight: CGFloat = 28
    /// The download bar under a model's name.
    static let progressTrackWidth: CGFloat = 48
    static let progressTrackHeight: CGFloat = 4

    // MARK: Motion

    /// `duration/snap`: hover, press and toggle, and the Reduce Motion cross-fade.
    static let snap = Animation.easeInOut(duration: 0.13)
    /// `duration/hold`: how long a success mark stays.
    static let hold: Duration = .milliseconds(260)

    // MARK: Helpers

    private static func dynamic(_ light: NSColor, _ dark: NSColor) -> Color {
        Color(nsColor: nsDynamic(light, dark))
    }

    /// For AppKit views, such as the History page's text, that need the colour itself.
    private static func nsDynamic(_ light: NSColor, _ dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    private static func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> NSColor {
        NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    private static func hex(_ value: UInt32) -> NSColor {
        rgba(CGFloat(value >> 16 & 0xFF), CGFloat(value >> 8 & 0xFF), CGFloat(value & 0xFF), 1)
    }
}
