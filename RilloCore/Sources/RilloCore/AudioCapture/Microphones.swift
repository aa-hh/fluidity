/// One input device as Core Audio reports it. `uid` stays the same across replugs and restarts.
public struct Microphone: Equatable, Identifiable, Sendable {
    public let uid: String
    public let name: String
    public let isBluetooth: Bool
    public let isBuiltIn: Bool

    public var id: String { uid }

    public init(uid: String, name: String, isBluetooth: Bool, isBuiltIn: Bool) {
        self.uid = uid
        self.name = name
        self.isBluetooth = isBluetooth
        self.isBuiltIn = isBuiltIn
    }
}

public enum Microphones {
    /// The microphone to record from, or none for the macOS default, and whether the saved choice must be cleared.
    public struct Choice: Equatable, Sendable {
        public let uid: String?
        public let clearsSaved: Bool
    }

    /// Resolves the saved choice (`nil` is Automatic) against the input devices present now.
    ///
    /// Automatic uses the macOS default input, except a Bluetooth default on a Mac with a built-in microphone:
    /// opening a Bluetooth microphone drops the headset's sound to call quality.
    public static func resolve(saved: String?, devices: [Microphone], defaultInput: String?) -> Choice {
        if let saved, devices.contains(where: { $0.uid == saved }) {
            return Choice(uid: saved, clearsSaved: false)
        }
        let clears = saved != nil
        let fallback = devices.first { $0.uid == defaultInput }
        if fallback?.isBluetooth == true, let builtIn = devices.first(where: \.isBuiltIn) {
            return Choice(uid: builtIn.uid, clearsSaved: clears)
        }
        return Choice(uid: fallback?.uid, clearsSaved: clears)
    }
}
