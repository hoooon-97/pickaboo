import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject var presence: PresenceController

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
        .frame(width: 260)
        .onAppear { presence.refreshAccessibility() }
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Accessibility permission required", systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.orange)
            Text("Pickaboo needs Accessibility access to detect active windows and stay out of your way.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                AccessibilityPermission.openSystemSettings()
            } label: {
                Text("Open System Settings…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
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
