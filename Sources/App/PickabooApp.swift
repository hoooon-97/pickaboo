import SwiftUI

@main
struct PickabooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Pickaboo", systemImage: "eye.circle.fill") {
            MenuBarContent()
                .environmentObject(appDelegate.presence)
        }
        .menuBarExtraStyle(.window)
    }
}
