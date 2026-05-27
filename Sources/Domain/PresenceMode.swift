import Combine
import Foundation

enum PresenceMode {
    case floating
    case menuBarOnly
    case hidden
}

final class PresenceController: ObservableObject {
    @Published var mode: PresenceMode = .floating
    @Published var hasAccessibility: Bool = AccessibilityPermission.isGranted

    func refreshAccessibility() {
        hasAccessibility = AccessibilityPermission.isGranted
    }
}
