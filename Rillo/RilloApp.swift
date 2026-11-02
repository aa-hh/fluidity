import SwiftUI

@main
struct RilloApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var app

    init() { PillPreview.startIfAsked() }

    var body: some Scene {
        // `AppDelegate` owns the menu bar item and the windows. A SwiftUI app needs one scene; this one never shows.
        MenuBarExtra("Rillo", isInserted: .constant(false)) { EmptyView() }
    }
}
