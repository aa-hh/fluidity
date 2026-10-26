import Foundation

/// The on-device speech models Fluidity can dictate with. The raw value is saved in each dictation record.
public enum SpeechModelID: String, Codable, CaseIterable, Sendable {
    case parakeetTDTv2 = "parakeet-tdt-0.6b-v2"
    case appleBuiltIn = "apple-speech"
    case parakeetUnified = "parakeet-unified-0.6b"
}

/// One row of the model catalogue: what the settings pane shows about a model.
public struct SpeechModel: Sendable, Identifiable {
    public enum Install: Sendable {
        case partOfMacOS
        case download(bytes: Int64, approximate: Bool, folder: String)
    }

    /// Measured figures; nil when the model has not been measured.
    public struct Figures: Sendable {
        public var firstWordMs: Int
        public var updateEveryMs: Int
        public var liveVsFinalPercent: Double
    }

    public var id: SpeechModelID
    public var name: String
    public var language: String
    public var install: Install
    public var figures: Figures?

    public static let all: [SpeechModel] = [
        SpeechModel(
            id: .parakeetTDTv2, name: "Parakeet TDT v2", language: "English",
            install: .download(bytes: 443_000_000, approximate: false, folder: "parakeet-tdt-0.6b-v2-coreml"),
            figures: Figures(firstWordMs: 546, updateEveryMs: 383, liveVsFinalPercent: 1.6)),
        SpeechModel(
            id: .appleBuiltIn, name: "Apple's built-in speech model", language: "10+ languages",
            install: .partOfMacOS, figures: nil),
        SpeechModel(
            id: .parakeetUnified, name: "Parakeet Unified 0.6B", language: "English",
            install: .download(bytes: 565_000_000, approximate: true, folder: "parakeet-unified-en-0.6b-coreml"),
            figures: Figures(firstWordMs: 956, updateEveryMs: 203, liveVsFinalPercent: 9.0)),
    ]

    public static func model(_ id: SpeechModelID) -> SpeechModel {
        all.first { $0.id == id }!
    }
}
