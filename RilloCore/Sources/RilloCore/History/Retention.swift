import Foundation

/// How long the History page keeps dictations, or their recordings.
public enum Retention: String, CaseIterable, Codable, Sendable {
    case forever, year, sixMonths, threeMonths, month, thirtyDays, week, sevenDays, day

    /// The Keep history menu, longest first.
    public static let historyChoices: [Retention] = [.forever, .year, .sixMonths, .threeMonths, .month, .week]
    /// The Keep recordings menu, longest first.
    public static let recordingChoices: [Retention] = [.forever, .year, .threeMonths, .thirtyDays, .sevenDays, .day]

    /// Nil for Forever. A month counts as 30 days, so 30 days is never longer than 1 month; the two lists name
    /// the same lengths their own way (1 week, 7 days).
    public var days: Int? {
        switch self {
        case .forever: nil
        case .year: 365
        case .sixMonths: 182
        case .threeMonths: 91
        case .month, .thirtyDays: 30
        case .week, .sevenDays: 7
        case .day: 1
        }
    }

    /// Dictations that started before this are past the period; nil for Forever.
    public func cutoff(now: Date) -> Date? {
        days.map { now.addingTimeInterval(-Double($0) * 86_400) }
    }

    public func isLonger(than other: Retention) -> Bool {
        (days ?? .max) > (other.days ?? .max)
    }
}

/// Which of the two periods a change is to.
public enum RetentionKind: Sendable {
    case history, recordings
}

/// What picking a new period comes to.
public enum RetentionChange: Equatable, Sendable {
    /// A shorter period leaves this many dictations or recordings already past it; ask whether to keep them.
    case ask(count: Int)
    /// The rules to save, already applied to the history.
    case applied(RetentionRules)
}

/// The History page's retention settings. Dictations that started before an `exemptBefore` date were already past
/// a period when the user shortened it and chose Keep; they stay until the user deletes them.
public struct RetentionRules: Equatable, Sendable {
    public var keepHistory: Retention
    public var keepRecordings: Retention
    public var historyExemptBefore: Date?
    public var recordingsExemptBefore: Date?

    public init(
        keepHistory: Retention = .forever,
        keepRecordings: Retention = .thirtyDays,
        historyExemptBefore: Date? = nil,
        recordingsExemptBefore: Date? = nil
    ) {
        self.keepHistory = keepHistory
        self.keepRecordings = keepRecordings
        self.historyExemptBefore = historyExemptBefore
        self.recordingsExemptBefore = recordingsExemptBefore
    }

    /// The rules once the user picks `period` for history. Shortening exempts the dictations already past it when
    /// `keepOlder`, and lets the next purge delete them when not; lengthening keeps earlier exemptions. Keep
    /// recordings is shortened to fit, since a recording with no dictation has nowhere to show.
    public func keepingHistory(for period: Retention, now: Date, keepOlder: Bool) -> RetentionRules {
        var rules = self
        if keepHistory.isLonger(than: period) {
            rules.historyExemptBefore = keepOlder ? period.cutoff(now: now) : nil
        }
        rules.keepHistory = period
        guard keepRecordings.isLonger(than: period) else { return rules }
        return rules.keepingRecordings(for: keepRecordings, now: now, keepOlder: keepOlder)
    }

    /// A period choice that affects the history or the recordings.
    public func period(_ kind: RetentionKind) -> Retention {
        kind == .history ? keepHistory : keepRecordings
    }

    public func keeping(_ kind: RetentionKind, for period: Retention, now: Date, keepOlder: Bool) -> RetentionRules {
        kind == .history
            ? keepingHistory(for: period, now: now, keepOlder: keepOlder)
            : keepingRecordings(for: period, now: now, keepOlder: keepOlder)
    }

    /// The rules once the user picks `period` for recordings, with the same Keep or Delete choice as history.
    /// A period longer than Keep history is cut to the longest one that fits.
    public func keepingRecordings(for period: Retention, now: Date, keepOlder: Bool) -> RetentionRules {
        let period = period.isLonger(than: keepHistory)
            ? Retention.recordingChoices.first { !$0.isLonger(than: keepHistory) } ?? .day
            : period
        var rules = self
        if keepRecordings.isLonger(than: period) {
            rules.recordingsExemptBefore = keepOlder ? period.cutoff(now: now) : nil
        }
        rules.keepRecordings = period
        return rules
    }
}
