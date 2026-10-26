import AppKit
import SwiftUI

// MARK: - Shell

/// The window and popover shell: system blur behind the window, the `app-window` fill,
/// a 1 pt rule outline, 16 pt corners and the lit top edge.
struct GlassShell: ViewModifier {
    var isLive: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassTheme.windowRadius, style: .continuous)
        content
            .background {
                ZStack {
                    BehindWindowBlur()
                    GlassTheme.window
                }
            }
            .clipShape(shape)
            .overlay { shape.strokeBorder(GlassTheme.lineRule, lineWidth: 1) }
            .overlay(alignment: .top) {
                LitTopEdge(isLive: isLive).padding(.horizontal, GlassTheme.windowRadius)
            }
    }
}

extension View {
    func glassShell(isLive: Bool = false) -> some View { modifier(GlassShell(isLive: isLive)) }
}

/// Blurs whatever is behind the window; the 72% fill on top sets the colour.
struct BehindWindowBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .underWindowBackground
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// The 1 pt line of light along the top of a floating panel. Resting, it is `ivory-white` fading
/// out at both ends; live, it is the pill's four ivory tones over a soft halo. It switches at once.
struct LitTopEdge: View {
    var isLive: Bool

    var body: some View {
        Group {
            if isLive {
                let tones = [GlassTheme.ivoryWarm, GlassTheme.ivoryWhite, GlassTheme.ivoryApricot, GlassTheme.ivoryCream]
                let rim = LinearGradient(colors: tones + tones + tones, startPoint: .leading, endPoint: .trailing)
                ZStack(alignment: .top) {
                    Rectangle().fill(rim).frame(height: 2.6).opacity(0.7).blur(radius: 4)
                    Rectangle().fill(rim).frame(height: 1.2)
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [GlassTheme.ivoryWhite.opacity(0), GlassTheme.ivoryWhite, GlassTheme.ivoryWhite.opacity(0)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Groups and rows

/// A section header: title, then a description 2 pt below, both inset 4 pt.
struct SectionHeader: View {
    let title: String
    var description: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(GlassTheme.section).foregroundStyle(GlassTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let description {
                Text(description).font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A raised panel holding rows: a plain fill, never blurred.
struct GlassPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GlassTheme.containerRadius, style: .continuous)
        VStack(spacing: 0) { content }
            .background(GlassTheme.raised, in: shape)
            .clipShape(shape)
            .overlay { shape.strokeBorder(GlassTheme.lineRule, lineWidth: 1) }
    }
}

/// The 1 pt rule between rows.
struct GlassRule: View {
    var body: some View {
        Rectangle().fill(GlassTheme.lineRule).frame(height: 1).accessibilityHidden(true)
    }
}

/// One row: optional leading icon, title, an optional error and the detail, then a control at the right end.
struct GlassRow<Leading: View, Trailing: View>: View {
    let title: String
    var error: String?
    var detail: String?
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            leading
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                if let error { FieldMessage(kind: .error, text: error) }
                if let detail {
                    Text(detail).font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(minHeight: GlassTheme.rowMinHeight)
    }
}

extension GlassRow where Leading == EmptyView {
    init(title: String, error: String? = nil, detail: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: title, error: error, detail: detail, leading: { EmptyView() }, trailing: trailing)
    }
}

// MARK: - Status marks

/// A 20 pt circle in a state colour holding a glyph.
struct StatusIcon: View {
    enum Kind { case done, attention, info }
    let kind: Kind

    var body: some View {
        let (color, glyph): (Color, String) = switch kind {
        case .done: (GlassTheme.stateDone, "checkmark")
        case .attention: (GlassTheme.stateAttention, "exclamationmark")
        case .info: (GlassTheme.textSecondary, "info")
        }
        Circle().fill(color)
            .frame(width: 20, height: 20)
            .overlay {
                Image(systemName: glyph).font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GlassTheme.actionOnPrimary)
            }
            .accessibilityHidden(true)
    }
}

/// The 8 pt status dot. Only the listening dot is ivory light.
struct StatusDot: View {
    enum Tone { case neutral, live, attention, hollow }
    let tone: Tone

    var body: some View {
        Group {
            switch tone {
            case .neutral: Circle().fill(GlassTheme.textSecondary)
            case .attention: Circle().fill(GlassTheme.stateAttention)
            case .hollow: Circle().strokeBorder(GlassTheme.textSecondary, lineWidth: 1)
            case .live:
                Circle().fill(GlassTheme.live)
                    .overlay { Circle().strokeBorder(GlassTheme.lineStrong, lineWidth: 1) }
                    .shadow(color: GlassTheme.live, radius: 3)
            }
        }
        .frame(width: 8, height: 8)
        .accessibilityHidden(true)
    }
}

/// One key of a set shortcut, as shown in the recorder and the status line.
struct KeyCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(GlassTheme.textPrimary)
            .padding(.horizontal, 6)
            .frame(height: 18)
            .background(GlassTheme.selected, in: RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous))
    }
}

// MARK: - Buttons

/// Capsule buttons: primary (one per pane), secondary and quiet.
struct GlassButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, quiet }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        GlassButtonBody(kind: kind, configuration: configuration)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glassPrimary: GlassButtonStyle { GlassButtonStyle(kind: .primary) }
    static var glassSecondary: GlassButtonStyle { GlassButtonStyle(kind: .secondary) }
    static var glassQuiet: GlassButtonStyle { GlassButtonStyle(kind: .quiet) }
}

private struct GlassButtonBody: View {
    let kind: GlassButtonStyle.Kind
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        configuration.label
            .font(GlassTheme.label)
            .lineLimit(1)
            .foregroundStyle(kind == .primary ? GlassTheme.actionOnPrimary : GlassTheme.textPrimary)
            .padding(.horizontal, kind == .quiet ? 10 : 16)
            .frame(height: GlassTheme.controlHeight)
            .background {
                ZStack {
                    switch kind {
                    case .primary: Capsule().fill(GlassTheme.actionPrimary)
                    case .secondary: Capsule().fill(GlassTheme.raised)
                    case .quiet: Color.clear
                    }
                    if isHovering && isEnabled { Capsule().fill(GlassTheme.hover) }
                    if configuration.isPressed { Capsule().fill(GlassTheme.selected) }
                }
            }
            .overlay {
                if kind == .secondary { Capsule().strokeBorder(GlassTheme.lineStrong, lineWidth: 1) }
            }
            .contentShape(Capsule())
            .glassFocusRing(Capsule())
            .opacity(isEnabled ? 1 : 0.4)
            .onHover { isHovering = $0 }
            .animation(GlassTheme.snap, value: isHovering)
            .animation(GlassTheme.snap, value: configuration.isPressed)
    }
}

// MARK: - Toggle

/// The 38 × 22 pt capsule switch. It keeps the native toggle's meaning for VoiceOver,
/// and is a focusable button for Full Keyboard Access.
struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            GlassToggleTrack(isOn: configuration.isOn)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

private struct GlassToggleTrack: View {
    let isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(isOn ? GlassTheme.actionPrimary : GlassTheme.selected)
                .overlay { if !isOn { Capsule().strokeBorder(GlassTheme.lineRule, lineWidth: 1) } }
            Circle()
                .fill(isOn ? GlassTheme.actionOnPrimary : GlassTheme.controlKnob)
                .frame(width: 18, height: 18)
                .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
                .padding(2)
        }
        .frame(width: 38, height: 22)
        .contentShape(Capsule())
        .glassFocusRing(Capsule())
        .opacity(isEnabled ? 1 : 0.4)
        .animation(GlassTheme.snap, value: isOn)
    }
}

// MARK: - Segmented control

/// Capsule track with equal-width capsule segments; the selected one is raised.
struct GlassSegmentedControl<Value: Hashable>: View {
    let name: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                Button { selection = option.value } label: {
                    GlassSegment(label: option.label, allLabels: options.map(\.label), isSelected: option.value == selection)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 3)
        .frame(height: GlassTheme.controlHeight)
        .background {
            Capsule().fill(GlassTheme.hover)
                .overlay { Capsule().strokeBorder(GlassTheme.lineRule, lineWidth: 1) }
        }
        .opacity(isEnabled ? 1 : 0.4)
        .animation(GlassTheme.snap, value: selection)
        .accessibilityRepresentation {
            Picker(name, selection: $selection) {
                ForEach(options, id: \.value) { Text($0.label).tag($0.value) }
            }
        }
    }
}

private struct GlassSegment: View {
    let label: String
    let allLabels: [String]
    let isSelected: Bool

    var body: some View {
        ZStack {
            ForEach(allLabels, id: \.self) { Text($0).font(GlassTheme.label).hidden() }
            Text(label)
                .font(GlassTheme.label)
                .foregroundStyle(isSelected ? GlassTheme.textPrimary : GlassTheme.textSecondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(height: 24)
        .background {
            if isSelected {
                Capsule().fill(GlassTheme.raised)
                    .overlay { Capsule().strokeBorder(GlassTheme.lineStrong, lineWidth: 1) }
                    .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
            }
        }
        .contentShape(Capsule())
        .glassFocusRing(Capsule())
    }
}

// MARK: - Focus

/// Keyboard focus: a 2 pt `app-focus-ring` ring 1 pt outside `shape`, in place of the system ring,
/// which each window turns off with `focusEffectDisabled()`. Apply it inside the focusable control,
/// on a button's label or in its style, where `isFocused` reports that control.
struct GlassFocusRing<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        content.overlay {
            if isFocused {
                shape.strokeBorder(GlassTheme.focusRing, lineWidth: 2).padding(-3).allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func glassFocusRing(_ shape: some InsettableShape) -> some View { modifier(GlassFocusRing(shape: shape)) }
}

// MARK: - Fields

/// The capsule look shared by text fields and the shortcut recorder: `app-raised` fill, rule
/// outline at rest, strong outline, focus ring and resting lit top edge when focused, red on error.
struct GlassFieldChrome: ViewModifier {
    var isFocused: Bool
    var isError = false

    func body(content: Content) -> some View {
        content
            .frame(height: GlassTheme.controlHeight)
            .background(GlassTheme.raised, in: Capsule())
            .overlay {
                Capsule().strokeBorder(
                    isError ? GlassTheme.stateDestructive : isFocused ? GlassTheme.lineStrong : GlassTheme.lineRule,
                    lineWidth: 1)
            }
            .overlay {
                if isFocused { Capsule().strokeBorder(GlassTheme.focusRing, lineWidth: 2).padding(-3) }
            }
            .overlay(alignment: .top) {
                if isFocused { LitTopEdge(isLive: false).padding(.horizontal, 14) }
            }
    }
}

extension View {
    func glassFieldChrome(isFocused: Bool, isError: Bool = false) -> some View {
        modifier(GlassFieldChrome(isFocused: isFocused, isError: isError))
    }
}

/// An error, a success or a note shown under a field: icon then text, `app-detail`.
struct FieldMessage: View {
    enum Kind { case error, done, info }
    let kind: Kind
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            switch kind {
            case .error: Image(systemName: "exclamationmark.circle").foregroundStyle(GlassTheme.stateDestructive)
            case .done: Image(systemName: "checkmark").foregroundStyle(GlassTheme.stateDone)
            case .info: Image(systemName: "info.circle").foregroundStyle(GlassTheme.textSecondary)
            }
            Text(text)
                .foregroundStyle(kind == .error ? GlassTheme.stateDestructive : GlassTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(GlassTheme.detail)
        .accessibilityElement(children: .combine)
    }
}
