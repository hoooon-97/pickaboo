import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject var presence: PresenceController

    private let recheckTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pickaboo")
                .font(.headline)

            Divider()

            HStack {
                Text("Mode")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(label(for: presence.mode))
                    .fontWeight(.medium)
            }
            .font(.callout)

            if !presence.hasAccessibility {
                Divider()
                permissionBanner
            }

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Pickaboo")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 300)
        .onAppear { presence.refreshAccessibility() }
        .onReceive(recheckTimer) { _ in presence.refreshAccessibility() }
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Accessibility permission required", systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.orange)
            Text("Pickaboo needs Accessibility to detect active windows and full-screen state.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Just rebuilt? macOS may not recognise the new binary even if you've granted before. Remove the existing Pickaboo entry in System Settings → Privacy & Security → Accessibility, then re-add it, then quit & relaunch.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button {
                    AccessibilityPermission.openSystemSettings()
                } label: {
                    Text("Open Settings")
                }
                Button {
                    presence.refreshAccessibility()
                } label: {
                    Text("Re-check")
                }
            }
        }
    }

    private func label(for mode: PresenceMode) -> String {
        switch mode {
        case .floating: return "Floating"
        case .menuBarOnly: return "Menu Bar"
        case .hidden: return "Hidden"
        }
    }
}
