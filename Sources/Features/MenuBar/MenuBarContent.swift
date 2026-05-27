import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject var presence: PresenceController
    @EnvironmentObject var reminders: RemindersService
    @EnvironmentObject var weather: WeatherService
    @EnvironmentObject var location: LocationService

    private let recheckTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pickaboo")
                    .font(.headline)
                Spacer()
                Text(label(for: presence.mode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            StatusSection(weather: weather, location: location)

            Divider()

            RemindersSection(service: reminders)

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
        .frame(width: 340)
        .onAppear {
            presence.refreshAccessibility()
            reminders.refresh()
            weather.refresh()
        }
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
                Button { AccessibilityPermission.openSystemSettings() } label: { Text("Open Settings") }
                Button { presence.refreshAccessibility() } label: { Text("Re-check") }
            }
        }
    }

    private func label(for mode: PresenceMode) -> String {
        switch mode {
        case .floating: return "Floating"
        case .menuBarOnly: return "Diving"
        case .hidden: return "Hidden"
        }
    }
}
