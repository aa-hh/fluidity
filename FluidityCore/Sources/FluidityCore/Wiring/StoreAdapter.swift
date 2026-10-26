import AVFoundation
import ApplicationServices
import Foundation
import os

/// `DictationStoring` over `DictationStore`. `didChange` runs after every save or update, for the
/// popover's list of recent dictations.
public struct StoreAdapter: DictationStoring {
    private static let log = Logger(subsystem: "com.fluidity.app", category: "DictationStore")

    private let store: DictationStore
    private let didChange: @Sendable () -> Void

    public init(store: DictationStore, didChange: @escaping @Sendable () -> Void = {}) {
        self.store = store
        self.didChange = didChange
    }

    public func save(_ record: DictationRecord, recording: DictationController.Recording) async {
        do {
            try await store.save(record: record, audio: recording.samples)
        } catch {
            Self.log.error("Saving dictation \(record.id) failed: \(String(describing: error), privacy: .public)")
        }
        didChange()
    }

    public func updateFinalText(_ finalText: String?, reason: WatchStopReason, for id: UUID) async {
        do {
            try await store.updateFinalText(id: id, finalText: finalText, stopReason: reason)
        } catch {
            Self.log.error("Saving the final text of dictation \(id) failed: \(String(describing: error), privacy: .public)")
        }
        didChange()
    }
}

/// `PermissionChecking` over the system's Microphone and Accessibility grants.
public struct SystemPermissions: PermissionChecking {
    public init() {}

    public var microphoneGranted: Bool { AVCaptureDevice.authorizationStatus(for: .audio) == .authorized }
    public var accessibilityGranted: Bool { AXIsProcessTrusted() }

    /// Shows the system's Microphone prompt if it has never been answered.
    public func requestMicrophone() async {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined else { return }
        _ = await AVCaptureDevice.requestAccess(for: .audio)
    }

    /// Shows the system's Accessibility prompt, which leads to System Settings.
    public func requestAccessibility() {
        guard !accessibilityGranted else { return }
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}
