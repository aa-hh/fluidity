import SwiftUI

/// The word list: an add field above one word per row, sorted. Every action works from the
/// keyboard: Return adds, Delete removes the focused row, Command-Z restores.
struct WordsPane: View {
    let model: SettingsModel
    @Environment(\.undoManager) private var undoManager
    @State private var newWord = ""
    @State private var duplicate: String?
    @State private var lastDeleted: String?
    @FocusState private var addFieldFocused: Bool
    @FocusState private var focusedWord: String?

    private var words: [String] {
        model.wordList.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var trimmed: String { newWord.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Your words", description: "Names and terms Fluidity should get right. One per row.")
            GlassPanel {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Add a word or name", text: $newWord)
                            .textFieldStyle(.plain)
                            .font(GlassTheme.body)
                            .foregroundStyle(GlassTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .glassFieldChrome(isFocused: addFieldFocused, isError: duplicate != nil)
                            .focused($addFieldFocused)
                            .onSubmit { add() }
                            .accessibilityLabel("Add a word or name")
                        Button("Add") { add() }
                            .buttonStyle(.glassSecondary)
                            .disabled(trimmed.isEmpty)
                    }
                    if let duplicate {
                        FieldMessage(kind: .error, text: "\u{201C}\(duplicate)\u{201D} is already in your words.")
                            .padding(.horizontal, 6)
                    }
                }
                .padding(6)
                .onChange(of: newWord) { duplicate = nil }

                if words.isEmpty {
                    GlassRule()
                    Text("No words yet. Add names, products and terms you say often.")
                        .font(GlassTheme.detail)
                        .foregroundStyle(GlassTheme.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(words, id: \.self) { word in
                    GlassRule()
                    WordRow(word: word, isFocused: focusedWord == word) { delete(word) }
                        .focusable()
                        .focused($focusedWord, equals: word)
                        .onTapGesture { focusedWord = word }
                        .onDeleteCommand { delete(word) }
                        .onKeyPress(.downArrow) { moveFocus(from: word, by: 1) }
                        .onKeyPress(.upArrow) { moveFocus(from: word, by: -1) }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Your words, \(words.count) items")

            if let lastDeleted {
                HStack(spacing: 8) {
                    Text("Deleted \u{201C}\(lastDeleted)\u{201D}.")
                        .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                    Button("Undo") { restore(lastDeleted) }.buttonStyle(.glassQuiet)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func add() {
        let word = trimmed
        guard !word.isEmpty else { return }
        if let existing = model.wordList.first(where: { $0.caseInsensitiveCompare(word) == .orderedSame }) {
            duplicate = existing
            return
        }
        model.changeWordList(model.wordList + [word])
        newWord = ""
        lastDeleted = nil
        undoManager?.registerUndo(withTarget: model) { model in
            MainActor.assumeIsolated { model.changeWordList(model.wordList.filter { $0 != word }) }
        }
        undoManager?.setActionName("Add Word")
        addFieldFocused = true
    }

    private func delete(_ word: String) {
        let next = neighbour(of: word)
        model.changeWordList(model.wordList.filter { $0 != word })
        lastDeleted = word
        focusedWord = next
        undoManager?.registerUndo(withTarget: model) { model in
            MainActor.assumeIsolated {
                if !model.wordList.contains(word) { model.changeWordList(model.wordList + [word]) }
            }
        }
        undoManager?.setActionName("Delete Word")
        AccessibilityNotification.Announcement("Deleted \(word)").post()
    }

    private func restore(_ word: String) {
        if !model.wordList.contains(word) { model.changeWordList(model.wordList + [word]) }
        lastDeleted = nil
        focusedWord = word
    }

    private func neighbour(of word: String) -> String? {
        guard let index = words.firstIndex(of: word) else { return nil }
        if index + 1 < words.count { return words[index + 1] }
        return index > 0 ? words[index - 1] : nil
    }

    private func moveFocus(from word: String, by step: Int) -> KeyPress.Result {
        guard let index = words.firstIndex(of: word), words.indices.contains(index + step) else { return .ignored }
        focusedWord = words[index + step]
        return .handled
    }
}

private struct WordRow: View {
    let word: String
    let isFocused: Bool
    let delete: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Text(word).font(GlassTheme.body).foregroundStyle(GlassTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            // Always present, so Voice Control and VoiceOver can reach it without a hover.
            Button(action: delete) {
                Image(systemName: "trash")
                    .foregroundStyle(isHovering || isFocused ? GlassTheme.textPrimary : GlassTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                    .glassFocusRing(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(word)")
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 36)
        .background {
            if isFocused { GlassTheme.selected } else if isHovering { GlassTheme.hover }
        }
        // Inside the row: the panel around the list clips anything drawn outside it.
        .overlay { if isFocused { Rectangle().strokeBorder(GlassTheme.focusRing, lineWidth: 2) } }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(word)
        .accessibilityAction(named: "Delete", delete)
    }
}
