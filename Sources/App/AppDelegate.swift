import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let presence = PresenceController()

    private let mouseTracker = MouseTrackerService()
    private let windowMonitor = WindowMonitorService()
    private let positionEngine = PositionEngine()
    private var avatar: FloatingAvatarController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let avatar = FloatingAvatarController()
        avatar.show()
        self.avatar = avatar

        let mouse = mouseTracker.mouseLocation
        let window = windowMonitor.activeWindow

        Publishers.CombineLatest(mouse, window)
            .throttle(for: .milliseconds(33), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self, positionEngine] mouseLocation, windowInfo in
                guard let self else { return }
                self.applyPresence(for: windowInfo)
                guard self.presence.mode == .floating else { return }
                let frame = positionEngine.targetFrame(
                    forMouse: mouseLocation,
                    avatarSize: avatar.avatarSize,
                    avoiding: windowInfo?.frame
                )
                avatar.move(to: frame)
            }
            .store(in: &cancellables)

        mouseTracker.start()
        windowMonitor.start()

        scheduleAccessibilityRecheck()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker.stop()
        windowMonitor.stop()
    }

    private func applyPresence(for windowInfo: ActiveWindowInfo?) {
        let shouldRetreat = windowInfo?.isFullScreen ?? false
        let newMode: PresenceMode = shouldRetreat ? .menuBarOnly : .floating
        guard newMode != presence.mode else { return }
        presence.mode = newMode
        switch newMode {
        case .floating:
            avatar?.show()
        case .menuBarOnly, .hidden:
            avatar?.hide()
        }
    }

    private func scheduleAccessibilityRecheck() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let granted = AccessibilityPermission.isGranted
            if granted != self.presence.hasAccessibility {
                self.presence.hasAccessibility = granted
                if granted {
                    self.windowMonitor.start()
                }
            }
        }
    }
}
