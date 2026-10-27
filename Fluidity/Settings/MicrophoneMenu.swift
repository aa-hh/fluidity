import FluidityCore
import SwiftUI

/// The microphone pop-up, shared by Settings › General and the popover: Automatic, a separator, then each
/// microphone by its macOS name. The inline picker lets macOS draw the check on the saved choice.
struct MicrophoneMenu<Label: View>: View {
    let model: SettingsModel
    @ViewBuilder let label: () -> Label

    var body: some View {
        Menu {
            Picker("Microphone", selection: Binding(get: { model.chosenMicrophone }, set: { model.changeMicrophone($0) })) {
                Text("Automatic").tag(String?.none)
                Divider()
                ForEach(model.microphones) { Text($0.name).tag(Optional($0.uid)) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            label()
        }
        .menuIndicator(.hidden)
        .accessibilityLabel("Microphone")
        .accessibilityValue(model.chosenMicrophoneName)
    }
}
