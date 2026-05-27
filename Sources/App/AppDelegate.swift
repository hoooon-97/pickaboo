import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let presence = PresenceController()
    let remindersService = RemindersService()

    private let mouseTracker = MouseTrackerService()
    private let windowMonitor = WindowMonitorService()
    private let positionEngine = PositionEngine()
    private var avatar: FloatingAvatarController?
    private var behavior: BehaviorController?
    private var tickTimer: Timer?
    private var lastTickAt: Date?
    private var isAnimatingPresence = false
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
        remindersService.start()
        startTickLoop()
        scheduleAccessibilityRecheck()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tickTimer?.invalidate()
        mouseTracker.stop()
        windowMonitor.stop()
        remindersService.stop()
    }

    private func startTickLoop() {
        lastTickAt = Date()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let behavior, let avatar else { return }
        let allowTick = presence.mode == .floating || behavior.isDiving
        guard allowTick else {
            lastTickAt = Date()
            return
        }

        let now = Date()
        let dt = now.timeIntervalSince(lastTickAt ?? now)
        lastTickAt = now

        let obstacle = behavior.isDiving ? nil : windowMonitor.activeWindow.value?.frame
        behavior.tick(deltaTime: dt, obstacle: obstacle)
        avatar.move(to: behavior.origin)
        avatar.animator.update(facing: behavior.facing,
                               animation: behavior.animation,
                               deltaTime: dt)
    }

    private func applyPresence(for windowInfo: ActiveWindowInfo?) {
        guard !isAnimatingPresence else { return }

        let shouldRetreat = windowInfo?.isFullScreen ?? false
        let newMode: PresenceMode = shouldRetreat ? .menuBarOnly : .floating
        guard newMode != presence.mode else { return }

        switch newMode {
        case .menuBarOnly:
            let target = menuBarPosition()
            isAnimatingPresence = true
            behavior?.startDive(to: target, duration: 0.4) { [weak self] in
                guard let self else { return }
                self.avatar?.hide()
                self.presence.mode = .menuBarOnly
                self.isAnimatingPresence = false
            }

        case .floating:
            let spawn = menuBarPosition()
            avatar?.move(to: spawn)
            behavior?.respawn(at: spawn)
            avatar?.show()
            presence.mode = .floating
            lastTickAt = Date()

        case .hidden:
            avatar?.hide()
            presence.mode = .hidden
        }
    }

    private func menuBarPosition() -> CGPoint {
        let size = avatar?.avatarSize ?? CGSize(width: 80, height: 80)
        guard let primary = NSScreen.screens.first else { return .zero }
        let frame = primary.frame
        return CGPoint(
            x: frame.maxX - size.width - 100,
            y: frame.maxY - size.height - 8
        )
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
