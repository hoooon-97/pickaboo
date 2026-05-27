import AppKit
import ApplicationServices
import Combine

struct ActiveWindowInfo: Equatable {
    let frame: CGRect
    let isFullScreen: Bool
    let appBundleId: String?
}

final class WindowMonitorService {
    let activeWindow = CurrentValueSubject<ActiveWindowInfo?, Never>(nil)

    private var pollTimer: Timer?
    private var workspaceObservers: [NSObjectProtocol] = []
    private let ownBundleId = Bundle.main.bundleIdentifier

    func start() {
        guard AccessibilityPermission.isGranted else {
            AccessibilityPermission.request()
            return
        }
        observeWorkspace()
        startPolling()
        refresh()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        workspaceObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        workspaceObservers.removeAll()
    }

    private func observeWorkspace() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didDeactivateApplicationNotification,
            NSWorkspace.activeSpaceDidChangeNotification
        ]
        for name in names {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
            workspaceObservers.append(token)
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func refresh() {
        let info = readActiveWindow()
        if info != activeWindow.value {
            activeWindow.send(info)
        }
    }

    private func readActiveWindow() -> ActiveWindowInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        if app.bundleIdentifier == ownBundleId {
            return activeWindow.value
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowRef: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
            let windowValue = windowRef
        else { return nil }
        let window = windowValue as! AXUIElement

        guard let frameTopLeft = readFrame(of: window) else { return nil }
        let isFullScreen = readBool(of: window, attribute: "AXFullScreen") ?? false
        let frame = convertToBottomLeft(topLeftOriginRect: frameTopLeft)

        return ActiveWindowInfo(frame: frame, isFullScreen: isFullScreen, appBundleId: app.bundleIdentifier)
    }

    private func readFrame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
            let posValue = posRef, let sizeValue = sizeRef
        else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(posValue as! AXValue, .cgPoint, &origin),
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        else { return nil }

        return CGRect(origin: origin, size: size)
    }

    private func readBool(of element: AXUIElement, attribute: String) -> Bool? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
              let value = ref as? Bool
        else { return nil }
        return value
    }

    private func convertToBottomLeft(topLeftOriginRect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return topLeftOriginRect }
        let primaryHeight = primary.frame.height
        return CGRect(
            x: topLeftOriginRect.minX,
            y: primaryHeight - topLeftOriginRect.minY - topLeftOriginRect.height,
            width: topLeftOriginRect.width,
            height: topLeftOriginRect.height
        )
    }
}
