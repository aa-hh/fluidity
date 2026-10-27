import FluidityCore
import Testing

private let builtIn = Microphone(uid: "builtin", name: "MacBook Pro Microphone", isBluetooth: false, isBuiltIn: true)
private let usb = Microphone(uid: "usb", name: "Shure MV7", isBluetooth: false, isBuiltIn: false)
private let airPods = Microphone(uid: "airpods", name: "AirPods Pro", isBluetooth: true, isBuiltIn: false)

struct MicrophonesTests {
    @Test(arguments: [
        // Ignoring a saved microphone that is present turns this red.
        (String?("usb"), [builtIn, usb, airPods], String?("airpods"), String?("usb"), false),
        // Keeping a saved microphone that is gone, or not falling back to Automatic, turns this red.
        ("usb", [builtIn, airPods], "builtin", "builtin", true),
        // Swapping a wired or USB default for the built-in microphone turns this red.
        (nil, [builtIn, usb], "usb", "usb", false),
        // Opening a Bluetooth default while the Mac has its own microphone turns this red.
        (nil, [builtIn, airPods], "airpods", "builtin", false),
        // Refusing the Bluetooth default on a Mac with no microphone of its own turns this red.
        (nil, [usb, airPods], "airpods", "airpods", false),
        // Picking a microphone when there are none turns this red.
        (nil, [], nil, nil, false),
    ])
    func resolve(saved: String?, devices: [Microphone], defaultInput: String?, uid: String?, clearsSaved: Bool) {
        let choice = Microphones.resolve(saved: saved, devices: devices, defaultInput: defaultInput)
        #expect(choice.uid == uid)
        #expect(choice.clearsSaved == clearsSaved)
    }
}
