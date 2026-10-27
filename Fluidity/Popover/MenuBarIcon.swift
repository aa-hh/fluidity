import AppKit
import FluidityCore

/// The menu bar icon, option A: the pill outline in every state, drawn as an 18 × 18 pt
/// template image so macOS tints it for the menu bar. Geometry from the Figma library's
/// "Menu bar icon/Pill outline" set.
enum MenuBarIcon {
    static func image(for state: MenuBarState) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            draw(state, in: context)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = description(for: state)
        return image
    }

    static func description(for state: MenuBarState) -> String {
        switch state {
        case .ready: "Fluidity"
        case .recording: "Fluidity, listening"
        case .cleanupOff: "Fluidity, cleanup off"
        case .permissionMissing(.microphone): "Fluidity, microphone access is off"
        case .permissionMissing(.accessibility): "Fluidity, Accessibility access is off"
        }
    }

    private static let stroke: CGFloat = 1.5
    private static let pill = CGRect(x: 1, y: 4.5, width: 16, height: 9)
    /// The clear space cut around a badge so it reads apart from the outline.
    private static let gap: CGFloat = 1.25

    private static func draw(_ state: MenuBarState, in context: CGContext) {
        context.setFillColor(NSColor.black.cgColor)
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(stroke)
        context.setLineCap(.round)

        if state == .recording {
            context.addPath(capsule(pill))
            context.fillPath()
            return
        }

        context.addPath(capsule(pill.insetBy(dx: stroke / 2, dy: stroke / 2)))
        context.strokePath()

        switch state {
        case .cleanupOff:
            let dot = CGRect(x: 10.75, y: 10.25, width: 6.5, height: 6.5)
            context.setBlendMode(.clear)
            context.fillEllipse(in: dot.insetBy(dx: -gap, dy: -gap))
            context.setBlendMode(.normal)
            context.fillEllipse(in: dot)
        case .permissionMissing:
            let start = CGPoint(x: 2.3, y: 16.5), end = CGPoint(x: 16.5, y: 2.3)
            context.setBlendMode(.clear)
            context.setLineWidth(stroke + gap * 2)
            context.strokeLineSegments(between: [start, end])
            context.setBlendMode(.normal)
            context.setLineWidth(stroke)
            context.strokeLineSegments(between: [start, end])
        case .ready, .recording:
            break
        }
    }

    private static func capsule(_ rect: CGRect) -> CGPath {
        let radius = rect.height / 2
        return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }
}
