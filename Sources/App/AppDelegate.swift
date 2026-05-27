import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let presence = PresenceController()

    private let mouseTracker = MouseTrackerService()
    private let windowMonitor = WindowMonitorService()
    private let positionEngine = PositionEngine()
    private var avatar: FloatingAvatarController?
    private var behavior: BehaviorController?
    private var tickTimer: Timer?
    private var lastTickAt: Date?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let avatar = FloatingAvatarController()
        let initialOrigin = initialAvatarOrigin(size: avatar.avatarSize)
        let behavior = BehaviorController(
            initialOrigin: initialOrigin,
            characterSize: avatar.avatarSize,
            positionEngine: positionEngine
        )
        avatar.move(to: initialOrigin)
        avatar.show()
        self.avatar = avatar
        self.behavior = behavior

        mouseTracker.clicks
            .sink { [weak self] clickLocation in
                guard let self else { return }
                let obstacle = self.windowMonitor.activeWindow.value?.frame
                self.behavior?.reactToClick(at: clickLocation, obstacle: obstacle)
            }
            .store(in: &cancellables)

        windowMonitor.activeWindow
            .sink { [weak self] info in
                self?.applyPresence(for: info)
            }
            .store(in: &cancellables)

        mouseTracker.start()
        windowMonitor.start()
        startTickLoop()
        scheduleAccessibilityRecheck()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tickTimer?.invalidate()
        mouseTracker.stop()
        windowMonitor.stop()
    }

    private func startTickLoop() {
        lastTickAt = Date()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let behavior, let avatar else { return }
        guard presence.mode == .floating else {
            lastTickAt = Date()
            return
        }

        let now = Date()
        let dt = now.timeIntervalSince(lastTickAt ?? now)
        lastTickAt = now

        let obstacle = windowMonitor.activeWindow.value?.frame
        behavior.tick(deltaTime: dt, obstacle: obstacle)
        avatar.move(to: behavior.origin)
        avatar.animator.update(facing: behavior.facing,
                               animation: behavior.animation,
                               deltaTime: dt)
    }

    private func applyPresence(for windowInfo: ActiveWindowInfo?) {
        let shouldRetreat = windowInfo?.isFullScreen ?? false
        let newMode: PresenceMode = shouldRetreat ? .menuBarOnly : .floating
        guard newMode != presence.mode else { return }
        presence.mode = newMode
        switch newMode {
        case .floating:
            avatar?.show()
            lastTickAt = Date()
        case .menuBarOnly, .hidden:
            avatar?.hide()
        }
    }

    private func initialAvatarOrigin(size: CGSize) -> CGPoint {
        guard let screen = NSScreen.main else { return .zero }
        let visible = screen.visibleFrame
        return CGPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
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
