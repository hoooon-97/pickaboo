import Combine
import Foundation

enum PresenceMode {
    case floating
    case menuBarOnly
    case hidden
}

final class PresenceController: ObservableObject {
    @Published var mode: PresenceMode = .floating
}
