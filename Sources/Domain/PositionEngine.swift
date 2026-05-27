import AppKit

struct PositionEngine {
    var cursorOffset: CGFloat = 24
    var obstacleGap: CGFloat = 8

    func targetFrame(forMouse mouseLocation: CGPoint,
                     avatarSize: CGSize,
                     avoiding obstacle: CGRect? = nil) -> CGRect {
        let bounds = screen(containing: mouseLocation).visibleFrame
        let preferred = preferredFrame(near: mouseLocation, size: avatarSize)

        guard let obstacle, preferred.intersects(obstacle) else {
            return clamp(preferred, in: bounds)
        }

        let candidates = sideCandidates(for: obstacle,
                                        mouse: mouseLocation,
                                        size: avatarSize,
                                        bounds: bounds)
        let valid = candidates.filter { !$0.intersects(obstacle) && bounds.contains($0) }

        let best = valid.min { distance($0.center, mouseLocation) < distance($1.center, mouseLocation) }
        return best ?? clamp(preferred, in: bounds)
    }

    private func preferredFrame(near point: CGPoint, size: CGSize) -> CGRect {
        CGRect(
            x: point.x + cursorOffset,
            y: point.y - cursorOffset - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func sideCandidates(for obstacle: CGRect,
                                mouse: CGPoint,
                                size: CGSize,
                                bounds: CGRect) -> [CGRect] {
        let alignedY = clampScalar(mouse.y - size.height / 2,
                                   min: bounds.minY,
                                   max: bounds.maxY - size.height)
        let alignedX = clampScalar(mouse.x - size.width / 2,
                                   min: bounds.minX,
                                   max: bounds.maxX - size.width)

        return [
            CGRect(x: obstacle.maxX + obstacleGap, y: alignedY, width: size.width, height: size.height),   // right
            CGRect(x: obstacle.minX - obstacleGap - size.width, y: alignedY, width: size.width, height: size.height), // left
            CGRect(x: alignedX, y: obstacle.maxY + obstacleGap, width: size.width, height: size.height),   // above
            CGRect(x: alignedX, y: obstacle.minY - obstacleGap - size.height, width: size.width, height: size.height) // below
        ]
    }

    private func screen(containing point: CGPoint) -> NSScreen {
        NSScreen.screens.first { $0.frame.contains(point) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func clamp(_ rect: CGRect, in container: CGRect) -> CGRect {
        var result = rect
        result.origin.x = clampScalar(result.origin.x, min: container.minX, max: container.maxX - result.width)
        result.origin.y = clampScalar(result.origin.y, min: container.minY, max: container.maxY - result.height)
        return result
    }

    private func clampScalar(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, lower), Swift.max(lower, upper))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
