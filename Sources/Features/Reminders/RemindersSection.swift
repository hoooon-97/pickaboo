import SwiftUI

struct RemindersSection: View {
    @ObservedObject var service: RemindersService

    private let displayLimit = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            switch service.access {
            case .granted:
                body(forGranted: Array(service.reminders.prefix(displayLimit)))
            case .denied:
                deniedView
            case .unknown:
                Button {
                    service.requestAccess()
                } label: {
                    Text("Grant Reminders access…")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var header: some View {
        HStack {
            Label("Upcoming", systemImage: "checklist")
                .font(.callout)
            Spacer()
            if service.access == .granted {
                Text("\(service.reminders.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private func body(forGranted items: [ReminderItem]) -> some View {
        if items.isEmpty {
            Text("Nothing due in the next 7 days")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items) { item in
                    reminderRow(item)
                }
                if service.reminders.count > displayLimit {
                    Text("+\(service.reminders.count - displayLimit) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func reminderRow(_ item: ReminderItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(item.listColor.map { Color(nsColor: $0) } ?? .gray)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.caption)
                    .lineLimit(1)
                if let due = item.dueDate {
                    Text(due, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                        .font(.caption2)
                        .foregroundStyle(item.isOverdue ? Color.red : Color.secondary)
                } else {
                    Text(item.listName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var deniedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Reminders access denied")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("Enable in System Settings → Privacy & Security → Reminders, then quit & relaunch Pickaboo.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
