import FluidityCore
import Foundation
import Testing

private struct TestShortcut: Codable, Equatable {
    var keyCode: Int
    var modifiers: Int
}

/// A `UserDefaults` suite of its own, removed when the test ends.
private func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
    let suite = "SettingsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    try body(defaults)
}

// Turns red if a fresh install starts with cleanup on without a key, rules other than the default, or a saved shortcut or word list, or reads an unknown live words or speech model value as anything but the default.
@Test func freshSettingsUseDefaults() {
    withDefaults { defaults in
        let settings = Settings(defaults: defaults, keyStore: FakeKeychain())
        #expect(settings.shortcut == nil)
        #expect(settings.isCleanupEnabled)
        #expect(!settings.isCleanupOn)
        #expect(settings.cleanupRules == Settings.defaultCleanupRules)
        #expect(settings.wordList.isEmpty)
        #expect(settings.liveWords == .inPill)
        defaults.set("sideways", forKey: "liveWords")
        #expect(settings.liveWords == .inPill)
        #expect(settings.speechModel == .parakeetTDTv2)
        defaults.set("whisper-huge", forKey: "speechModel")
        #expect(settings.speechModel == .parakeetTDTv2)
    }
}

// Turns red if a setting is saved under a key it is not read back from, so it is lost on relaunch.
@Test func settingsSurviveRelaunch() throws {
    try withDefaults { defaults in
        let keychain = FakeKeychain()
        let first = Settings(defaults: defaults, keyStore: keychain)
        try first.setShortcut(TestShortcut(keyCode: 61, modifiers: 524_288))
        first.isCleanupEnabled = false
        first.cleanupRules = "Be brief."
        first.wordList = ["SwiftUI", "Cerebras"]
        first.liveWords = .above
        first.speechModel = .parakeetUnified
        first.microphone = "usb"

        let second = Settings(defaults: defaults, keyStore: keychain)
        #expect(second.shortcut(as: TestShortcut.self) == TestShortcut(keyCode: 61, modifiers: 524_288))
        #expect(!second.isCleanupEnabled)
        #expect(second.cleanupRules == "Be brief.")
        #expect(second.wordList == ["SwiftUI", "Cerebras"])
        #expect(second.liveWords == .above)
        #expect(second.speechModel == .parakeetUnified)
        #expect(second.microphone == "usb")
        second.microphone = nil
        #expect(Settings(defaults: defaults, keyStore: keychain).microphone == nil)
    }
}

// Turns red if saving a key does not turn cleanup on, or cleanup counts as on without a key or while switched off.
@Test func cleanupIsOnOnlyWithAKeyAndEnabled() throws {
    try withDefaults { defaults in
        let keychain = FakeKeychain()
        let settings = Settings(defaults: defaults, keyStore: keychain)
        settings.isCleanupEnabled = false

        try settings.setAPIKey("  sk-test\n")
        #expect(settings.isCleanupOn)
        #expect(keychain.get() == "sk-test")

        settings.isCleanupEnabled = false
        #expect(!settings.isCleanupOn)

        settings.isCleanupEnabled = true
        try settings.setAPIKey(" ")
        #expect(!settings.hasAPIKey)
        #expect(!settings.isCleanupOn)
    }
}

// Turns red if the word list version depends on word order or misses a changed word.
@Test func wordListVersionFollowsContentNotOrder() {
    withDefaults { defaults in
        let settings = Settings(defaults: defaults, keyStore: FakeKeychain())
        settings.wordList = ["Cerebras", "SwiftUI"]
        let version = settings.wordListVersion
        #expect(version.count == 8)

        settings.wordList = ["SwiftUI", "Cerebras"]
        #expect(settings.wordListVersion == version)

        settings.wordList = ["SwiftUI", "Groq"]
        #expect(settings.wordListVersion != version)
    }
}

// Turns red if the word pace, the pause after the last word, the processing time or the Reduce Motion short cut of the General pane's preview changes.
@Test func previewPhasesFollowTheScript() {
    #expect(SpeechPreview.phase(at: .zero, cleanupOn: true, reduceMotion: false) == .listening(wordsHeard: 1))
    #expect(SpeechPreview.phase(at: .milliseconds(2420), cleanupOn: true, reduceMotion: false) == .listening(wordsHeard: 12))
    #expect(SpeechPreview.phase(at: .milliseconds(2810), cleanupOn: true, reduceMotion: false) == .listening(wordsHeard: 12))
    #expect(SpeechPreview.phase(at: .milliseconds(2820), cleanupOn: true, reduceMotion: false) == .processing)
    #expect(SpeechPreview.phase(at: .milliseconds(3810), cleanupOn: true, reduceMotion: false) == .processing)
    #expect(SpeechPreview.phase(at: .milliseconds(3820), cleanupOn: true, reduceMotion: false) == .pasted)
    #expect(SpeechPreview.phase(at: .zero, cleanupOn: true, reduceMotion: true) == .pasted)
    #expect(SpeechPreview.phase(at: .milliseconds(2810), cleanupOn: false, reduceMotion: false) == .listening(wordsHeard: 12))
    #expect(SpeechPreview.phase(at: .milliseconds(2820), cleanupOn: false, reduceMotion: false) == .pasted)
}
