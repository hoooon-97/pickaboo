import AppKit
import Combine

final class MouseTrackerService {
    let clicks = PassthroughSubject<CGPoint, Never>()

    private var clickMonitor: Any?

    func start() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            self?.clicks.send(NSEvent.mouseLocation)
        }
    }

    func stop() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
