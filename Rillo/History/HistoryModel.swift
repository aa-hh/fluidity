import AppKit
import Observation
import RilloCore

/// What the History page shows. The app shell writes `items` and the recordings settings; the page reports
/// deletes through `onDelete`.
@MainActor
@Observable
final class HistoryModel {
    /// Newest first, as `HistoryStore.items()` returns them.
    var items: [HistoryItem] = []
    var selection: UUID?
    var query = ""
    var saveRecordings = false
    /// Where a dictation's recording is, saved or not.
    var recordingURL: (UUID) -> URL = { _ in URL(filePath: "/dev/null") }

    var onDelete: (UUID) -> Void = { _ in }

    /// The dictations the search finds.
    var shown: [HistoryItem] { HistoryItem.search(items, for: query) }

    /// The chosen dictation, or the newest shown one.
    var selected: HistoryItem? {
        let shown = shown
        return shown.first { $0.record.id == selection } ?? shown.first
    }

    /// Deletes the dictation and its recording, choosing the next one down, or the one above at the end.
    func delete(_ id: UUID) {
        selection = HistoryItem.neighbour(of: id, in: shown)
        onDelete(id)
    }

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        AccessibilityNotification.Announcement("Copied").post()
    }
}

extension DictationRecord {
    /// "Notes": the app the dictation went to.
    var appName: String? {
        guard let app, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) else { return nil }
        let name = FileManager.default.displayName(atPath: url.path(percentEncoded: false))
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }

    /// "Raw transcript · cleanup too slow": why the pasted text is not the cleaned text, when it isn't.
    var pasteNote: String? {
        if !pasteLanded { return "Not pasted" }
        guard let reason = fallbackReason else { return nil }
        let why = switch reason {
        case .slow: "cleanup too slow"
        case .offline: "offline"
        case .unparseable, .cutOff, .wordsNotInTranscript, .lengthOutOfRange, .answeredInstead: "cleanup didn't pass its check"
        }
        return "Raw transcript · \(why)"
    }
}

extension Retention {
    /// The menu title, as in "Keep history: 3 months".
    var title: String {
        switch self {
        case .forever: "Forever"
        case .year: "1 year"
        case .sixMonths: "6 months"
        case .threeMonths: "3 months"
        case .month: "1 month"
        case .thirtyDays: "30 days"
        case .week: "1 week"
        case .sevenDays: "7 days"
        case .day: "1 day"
        }
    }
}
