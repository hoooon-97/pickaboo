import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let presence = PresenceController()

    private let mouseTracker = MouseTrackerService()
    private let positionEngine = PositionEngine()
    private var avatar: FloatingAvatarController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let avatar = FloatingAvatarController()
        avatar.show()
        self.avatar = avatar

        mouseTracker.mouseLocation
            .throttle(for: .milliseconds(33), scheduler: DispatchQueue.main, latest: true)
            .map { [positionEngine] location in
                positionEngine.targetFrame(forMouse: location,
                                           avatarSize: avatar.avatarSize)
            }
            .sink { frame in
                avatar.move(to: frame)
            }
            .store(in: &cancellables)

        mouseTracker.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker.stop()
    }
}
