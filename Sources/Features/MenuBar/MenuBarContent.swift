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
        .frame(width: 240)
    }

    private func label(for mode: PresenceMode) -> String {
        switch mode {
        case .floating: return "Floating"
        case .menuBarOnly: return "Menu Bar"
        case .hidden: return "Hidden"
        }
    }
}
