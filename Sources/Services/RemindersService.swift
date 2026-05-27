import Combine
import EventKit
import Foundation

enum RemindersAccess: Equatable {
    case unknown
    case granted
    case denied
}

final class RemindersService: ObservableObject {
    @Published private(set) var reminders: [ReminderItem] = []
    @Published private(set) var access: RemindersAccess = .unknown

    private let store = EKEventStore()
    private var storeObserver: NSObjectProtocol?
    private var refreshTimer: Timer?

    private let lookaheadWindow: TimeInterval = 7 * 24 * 3600
    private let pollInterval: TimeInterval = 60

    func start() {
        refreshAccessStatus()
        switch access {
        case .granted:
            beginObserving()
            fetch()
        case .unknown:
            requestAccess()
        case .denied:
            break
        }
    }

    func stop() {
        if let storeObserver {
            NotificationCenter.default.removeObserver(storeObserver)
            self.storeObserver = nil
        }
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func requestAccess() {
        store.requestFullAccessToReminders { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.access = granted ? .granted : .denied
                if granted {
                    self.beginObserving()
                    self.fetch()
                }
            }
        }
    }

    func refresh() {
        guard access == .granted else { return }
        fetch()
    }

    private func refreshAccessStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess:
            access = .granted
        case .denied, .restricted, .writeOnly:
            access = .denied
        case .notDetermined:
            access = .unknown
        @unknown default:
            access = .unknown
        }
    }

    private func beginObserving() {
        guard storeObserver == nil else { return }
        storeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.fetch()
        }
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    private func fetch() {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: Date().addingTimeInterval(lookaheadWindow),
            calendars: nil
        )
        store.fetchReminders(matching: predicate) { [weak self] ekReminders in
            guard let self else { return }
            let items = (ekReminders ?? [])
                .filter { !$0.isCompleted }
                .map { ek in
                    ReminderItem(
                        id: ek.calendarItemIdentifier,
                        title: ek.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(untitled)",
                        dueDate: ek.dueDateComponents?.date,
                        listName: ek.calendar.title,
                        listColor: ek.calendar.color
                    )
                }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

            DispatchQueue.main.async {
                if self.reminders != items {
                    self.reminders = items
                }
            }
        }
    }
}
