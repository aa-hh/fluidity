import FluidityCore
import SwiftUI

struct PermissionsPane: View {
    let model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Access",
                          description: "Fluidity needs both: the microphone to hear you, Accessibility to paste.")
            GlassPanel {
                PermissionRow(model: model, permission: .microphone)
                GlassRule()
                PermissionRow(model: model, permission: .accessibility)
            }
        }
    }
}

/// One permission with its live state and a button to the place that grants it.
/// Shared by the Permissions pane and the first-run check.
struct PermissionRow: View {
    let model: SettingsModel
    let permission: DictationController.Permission

    private var status: PermissionStatus {
        permission == .microphone ? model.microphone : model.accessibility
    }

    var body: some View {
        GlassRow(title: title, detail: detail) {
            StatusIcon(kind: status == .granted ? .done : .attention)
        } trailing: {
            if let button {
                Button(button.label, action: button.action).buttonStyle(.glassSecondary)
            }
        }
        .onChange(of: status) { _, new in
            if new == .granted {
                AccessibilityNotification.Announcement("\(name) allowed").post()
            }
        }
    }

    private var name: String { permission == .microphone ? "Microphone" : "Accessibility" }

    private var title: String {
        switch (permission, status) {
        case (_, .granted), (.microphone, .notAsked): name
        case (.microphone, _): "Microphone access is off"
        case (.accessibility, _): "Accessibility access is off"
        }
    }

    private var detail: String {
        switch (permission, status) {
        case (_, .granted): "Allowed"
        case (.microphone, .notAsked): "Fluidity needs it to hear you. macOS will ask once."
        case (.microphone, _): "Fluidity needs it to hear you. Turn it on in System Settings."
        case (.accessibility, _): "Fluidity needs it to paste where you type."
        }
    }

    private var button: (label: String, action: () -> Void)? {
        switch (permission, status) {
        case (_, .granted): nil
        case (.microphone, .notAsked): ("Allow Microphone", model.onRequestMicrophone)
        case (.microphone, _): ("Open Microphone Settings", { model.onOpenPrivacySettings(.microphone) })
        case (.accessibility, _): ("Open Accessibility Settings", { model.onOpenPrivacySettings(.accessibility) })
        }
    }
}
