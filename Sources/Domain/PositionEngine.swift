import AppKit

struct PositionEngine {
    var cursorOffset: CGFloat = 24

    func targetFrame(forMouse mouseLocation: CGPoint, avatarSize: CGSize) -> CGRect {
        let origin = CGPoint(
            x: mouseLocation.x + cursorOffset,
            y: mouseLocation.y - cursorOffset - avatarSize.height
        )
        let proposed = CGRect(origin: origin, size: avatarSize)
        let bounds = screen(containing: mouseLocation).visibleFrame
        return clamp(proposed, in: bounds)
    }

    private func screen(containing point: CGPoint) -> NSScreen {
        NSScreen.screens.first { $0.frame.contains(point) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func clamp(_ rect: CGRect, in container: CGRect) -> CGRect {
        var result = rect
        result.origin.x = min(max(result.origin.x, container.minX), container.maxX - result.width)
        result.origin.y = min(max(result.origin.y, container.minY), container.maxY - result.height)
        return result
    }
}
