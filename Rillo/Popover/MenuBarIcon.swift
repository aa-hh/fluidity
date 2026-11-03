import AppKit
import RilloCore

/// The menu bar icon: the Rillo logo's menu bar mark (website repo, `brand/menubar/`), a long pill
/// outline with a line through it that fades out past both ends, drawn as a 28 × 18 pt template
/// image so macOS tints it for the menu bar. Each state keeps the same shape and adds one change.
enum MenuBarIcon {
    static let size = NSSize(width: 28, height: 18)

    static func image(for state: MenuBarState) -> NSImage {
        let image = NSImage(size: size, flipped: true) { _ in
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
        case .ready: "Rillo"
        case .recording: "Rillo, listening"
        case .cleanupOff: "Rillo, cleanup off"
        case .permissionMissing(.microphone): "Rillo, microphone access is off"
        case .permissionMissing(.accessibility): "Rillo, Accessibility access is off"
        }
    }

    /// Every edge sits on a whole point, so the icon stays sharp at 1x and 2x.
    private static let pill = CGRect(x: 5, y: 6, width: 18, height: 6)
    private static let outline: CGFloat = 1
    private static let line = CGRect(x: 1, y: 8, width: 26, height: 2)
    /// How strong the line is at the icon's left and right edges; it is full strength along the pill.
    private static let lineEdgeAlpha: CGFloat = 0.15
    /// The clear space cut around a badge so it reads apart from the pill and its line.
    private static let gap: CGFloat = 1.25

    private static func draw(_ state: MenuBarState, in context: CGContext) {
        context.setFillColor(NSColor.black.cgColor)
        context.setStrokeColor(NSColor.black.cgColor)

        if state == .recording {
            context.addPath(capsule(pill))
            context.fillPath()
        } else {
            context.addPath(capsule(pill))
            context.addPath(capsule(pill.insetBy(dx: outline, dy: outline)))
            context.fillPath(using: .evenOdd)
        }
        drawLine(in: context)

        switch state {
        case .cleanupOff:
            let dot = CGRect(x: 19.5, y: 10.5, width: 6.5, height: 6.5)
            context.setBlendMode(.clear)
            context.fillEllipse(in: dot.insetBy(dx: -gap, dy: -gap))
            context.setBlendMode(.normal)
            context.fillEllipse(in: dot)
        case .permissionMissing:
            let start = CGPoint(x: 8.5, y: 16), end = CGPoint(x: 19.5, y: 2)
            context.setLineCap(.round)
            context.setBlendMode(.clear)
            context.setLineWidth(1.5 + gap * 2)
            context.strokeLineSegments(between: [start, end])
            context.setBlendMode(.normal)
            context.setLineWidth(1.5)
            context.strokeLineSegments(between: [start, end])
        case .ready, .recording:
            break
        }
    }

    /// The line through the pill, full strength between the pill's ends and fading toward the icon's edges.
    private static func drawLine(in context: CGContext) {
        let edge = NSColor.black.withAlphaComponent(lineEdgeAlpha).cgColor, full = NSColor.black.cgColor
        let inner = (pill.minX - line.minX) / line.width
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: [edge, full, full, edge] as CFArray,
            locations: [0, inner, 1 - inner, 1])
        else { return }
        context.saveGState()
        context.clip(to: line)
        context.drawLinearGradient(
            gradient, start: CGPoint(x: line.minX, y: 0), end: CGPoint(x: line.maxX, y: 0), options: [])
        context.restoreGState()
    }

    private static func capsule(_ rect: CGRect) -> CGPath {
        let radius = rect.height / 2
        return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }
}
