import AppKit
import Foundation

struct ReminderItem: Identifiable, Equatable {
    let id: String
    let title: String
    let dueDate: Date?
    let listName: String
    let listColor: NSColor?

    var isOverdue: Bool {
        guard let dueDate else { return false }
        return dueDate < Date()
    }
}
