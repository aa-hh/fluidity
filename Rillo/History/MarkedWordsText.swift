import AppKit
import RilloCore
import SwiftUI

/// One side of one History row: selectable words with cleanup's changes marked. Removed words (the raw side) are
/// red and struck through, added or rewritten words (the pasted side) green and underlined, each on a tint of its
/// colour. Pointing at a change outlines it, and `heardWord` is boxed while the recording plays.
///
/// An `NSTextView`, because the page needs selection, per-word pointing and clicks, and boxes drawn round words
/// in one wrapping text; SwiftUI's `Text` gives selection or word positions, not both. Copying gives plain text.
struct MarkedWordsText: NSViewRepresentable {
    enum Side { case raw, pasted }

    let words: [HistoryComparison.Word]
    let side: Side
    let hoveredChange: Int?
    /// A raw word's index, while the recording plays it.
    var heardWord: Int?
    let onHover: (Int?) -> Void
    /// Clicking a word, given its index; nil where clicks do nothing.
    var onClickWord: ((Int) -> Void)?

    func makeNSView(context: Context) -> WordsTextView {
        // TextKit 1: the boxes come from `NSLayoutManager`'s line rectangles.
        let view = WordsTextView(usingTextLayoutManager: false)
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = true
        view.isVerticallyResizable = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateNSView(_ view: WordsTextView, context: Context) {
        view.onHover = onHover
        view.onClickWord = onClickWord
        view.update(words: words, side: side, hoveredChange: hoveredChange, heardWord: heardWord)
    }

    /// Measured on a copy of the text: SwiftUI tries several widths before settling, and laying out the shown text
    /// at each would leave it at whichever width came last, spilling out of its column.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView view: WordsTextView, context: Context) -> CGSize? {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? view.frame.width
        guard let text = view.textStorage else { return nil }
        let storage = NSTextStorage(attributedString: text)
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        layout.ensureLayout(for: container)
        return CGSize(width: width, height: ceil(layout.usedRect(for: container).height))
    }
}

final class WordsTextView: NSTextView {
    private static let wordKey = NSAttributedString.Key("rillo.historyWord")
    private static let font = NSFont.systemFont(ofSize: 13)
    private static let lineSpacing: CGFloat = 5

    /// The text wraps at the frame's width, set here as well as by `widthTracksTextView`, which does not always
    /// follow a frame SwiftUI sets.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        textContainer?.containerSize = NSSize(width: newSize.width, height: .greatestFiniteMagnitude)
    }

    var onHover: (Int?) -> Void = { _ in }
    var onClickWord: ((Int) -> Void)?
    private var words: [HistoryComparison.Word] = []
    private var side = MarkedWordsText.Side.raw
    private var hoveredChange: Int?
    private var heardWord: Int?
    /// Each word's characters in the text.
    private var ranges: [NSRange] = []
    private var lastReportedChange: Int??

    func update(words: [HistoryComparison.Word], side: MarkedWordsText.Side, hoveredChange: Int?, heardWord: Int?) {
        if words != self.words || side != self.side {
            self.words = words
            self.side = side
            rebuildText()
        }
        if hoveredChange != self.hoveredChange || heardWord != self.heardWord {
            let heardChanged = heardWord != self.heardWord
            self.hoveredChange = hoveredChange
            self.heardWord = heardWord
            if heardChanged { applyHeardFont() }
            needsDisplay = true
        }
    }

    // Plain text only: marks, tints and colours never reach the clipboard.
    override var writablePasteboardTypes: [NSPasteboard.PasteboardType] { [.string] }

    private var markColor: NSColor { side == .raw ? GlassTheme.stateDestructiveAppKit : GlassTheme.changeAddedAppKit }
    private var tintColor: NSColor { side == .raw ? GlassTheme.changeRemovedTint : GlassTheme.changeAddedTint }

    private func rebuildText() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = Self.lineSpacing
        let plain: [NSAttributedString.Key: Any] = [
            .font: Self.font, .foregroundColor: GlassTheme.textPrimaryAppKit, .paragraphStyle: paragraph,
        ]
        let text = NSMutableAttributedString()
        ranges = []
        for (position, word) in words.enumerated() {
            if position > 0 {
                // The space inside one change takes its marks, so "three pm" reads as one struck run.
                let joined = word.change != nil && word.change == words[position - 1].change
                text.append(NSAttributedString(string: " ", attributes: joined ? marked(plain) : plain))
            }
            var attributes = word.change == nil ? plain : marked(plain)
            attributes[Self.wordKey] = position
            ranges.append(NSRange(location: text.length, length: (word.text as NSString).length))
            text.append(NSAttributedString(string: word.text, attributes: attributes))
        }
        textStorage?.setAttributedString(text)
        applyHeardFont()
    }

    private func marked(_ plain: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var attributes = plain
        attributes[.foregroundColor] = markColor
        attributes[side == .raw ? .strikethroughStyle : .underlineStyle] = NSUnderlineStyle.single.rawValue
        attributes[side == .raw ? .strikethroughColor : .underlineColor] = markColor
        return attributes
    }

    /// The word being heard turns semibold, so it reads without colour.
    private func applyHeardFont() {
        guard let storage = textStorage, storage.length > 0 else { return }
        storage.addAttribute(.font, value: Self.font, range: NSRange(location: 0, length: storage.length))
        if let range = heardRange {
            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 13, weight: .semibold), range: range)
        }
    }

    private var heardRange: NSRange? {
        guard let heardWord, let position = words.firstIndex(where: { $0.index == heardWord }) else { return nil }
        return ranges[position]
    }

    // MARK: Drawing

    /// Tints and the heard word's box under the text, then the pointed-at change's outline over it.
    override func draw(_ dirtyRect: NSRect) {
        tintColor.setFill()
        for run in changeRuns() {
            for box in boxes(for: run.range) { NSBezierPath(roundedRect: box, xRadius: 3, yRadius: 3).fill() }
        }
        if let range = heardRange {
            for box in boxes(for: range) {
                let path = NSBezierPath(roundedRect: box.insetBy(dx: -1, dy: 0), xRadius: 4, yRadius: 4)
                GlassTheme.selectedAppKit.setFill()
                path.fill()
                GlassTheme.lineStrongAppKit.setStroke()
                path.lineWidth = 1
                path.stroke()
            }
        }
        super.draw(dirtyRect)
        guard let hoveredChange else { return }
        markColor.setStroke()
        for run in changeRuns() where run.change == hoveredChange {
            for box in boxes(for: run.range) {
                let path = NSBezierPath(roundedRect: box.insetBy(dx: -1.5, dy: -1), xRadius: 4, yRadius: 4)
                path.lineWidth = 1.5
                path.stroke()
            }
        }
    }

    /// Each change's characters, spaces inside it included.
    private func changeRuns() -> [(change: Int, range: NSRange)] {
        var runs: [(change: Int, range: NSRange)] = []
        for (position, word) in words.enumerated() {
            guard let change = word.change else { continue }
            if let last = runs.last, last.change == change, words[position - 1].change == change {
                runs[runs.count - 1].range.length = NSMaxRange(ranges[position]) - last.range.location
            } else {
                runs.append((change, ranges[position]))
            }
        }
        return runs
    }

    /// One rectangle per line the characters sit on, the height of the text without the line spacing.
    private func boxes(for range: NSRange) -> [NSRect] {
        guard let layout = layoutManager, let container = textContainer else { return [] }
        let glyphs = layout.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var boxes: [NSRect] = []
        layout.enumerateEnclosingRects(
            forGlyphRange: glyphs, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: container
        ) { rect, _ in
            var box = rect.offsetBy(dx: self.textContainerOrigin.x, dy: self.textContainerOrigin.y)
            box.size.height = max(0, box.height - Self.lineSpacing)
            boxes.append(box.insetBy(dx: -2, dy: 0))
        }
        return boxes
    }

    // MARK: Pointing and clicking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas where area.owner === self && area.options.contains(.mouseMoved) { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self))
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        report(wordPosition(at: event).flatMap { words[$0].change })
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        report(nil)
    }

    /// A click that selects nothing jumps playback to the word.
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard let onClickWord, selectedRange().length == 0, let position = wordPosition(at: event) else { return }
        onClickWord(words[position].index)
    }

    private func report(_ change: Int?) {
        guard lastReportedChange != .some(change) else { return }
        lastReportedChange = .some(change)
        onHover(change)
    }

    /// The word under the pointer, by its position in `words`.
    private func wordPosition(at event: NSEvent) -> Int? {
        guard let layout = layoutManager, let container = textContainer, let storage = textStorage else { return nil }
        var point = convert(event.locationInWindow, from: nil)
        point.x -= textContainerOrigin.x
        point.y -= textContainerOrigin.y
        let glyph = layout.glyphIndex(for: point, in: container)
        guard layout.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: container).contains(point) else {
            return nil
        }
        let character = layout.characterIndexForGlyph(at: glyph)
        guard character < storage.length else { return nil }
        return storage.attribute(Self.wordKey, at: character, effectiveRange: nil) as? Int
    }
}
