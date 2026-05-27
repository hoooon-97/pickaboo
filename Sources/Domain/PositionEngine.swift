import AppKit

struct PositionEngine {
    var obstacleGap: CGFloat = 8

    func bounds(containing point: CGPoint) -> CGRect {
        screen(containing: point).visibleFrame
    }

    /// Returns the nearest valid origin (bottom-left) that fits within bounds
    /// and does not intersect the obstacle, starting from `desiredOrigin`.
    func nearestValidOrigin(to desiredOrigin: CGPoint,
                            size: CGSize,
                            bounds: CGRect,
                            avoiding obstacle: CGRect?) -> CGPoint {
        let proposed = CGRect(origin: desiredOrigin, size: size)
        let clamped = clamp(proposed, in: bounds)

        guard let obstacle, clamped.intersects(obstacle) else {
            return clamped.origin
        }

        let candidates = sideCandidates(for: obstacle,
                                        anchor: CGPoint(x: clamped.midX, y: clamped.midY),
                                        size: size,
                                        bounds: bounds)
        let best = candidates
            .filter { !$0.intersects(obstacle) && bounds.contains($0) }
            .min { distance($0.origin, desiredOrigin) < distance($1.origin, desiredOrigin) }

        return (best ?? clamped).origin
    }

    /// Picks a random origin within bounds that doesn't intersect the obstacle.
    /// Falls back to a corner farthest from the obstacle if no random point fits.
    func randomValidOrigin(size: CGSize,
                           bounds: CGRect,
                           avoiding obstacle: CGRect?) -> CGPoint {
        let xRange = bounds.minX...max(bounds.minX, bounds.maxX - size.width)
        let yRange = bounds.minY...max(bounds.minY, bounds.maxY - size.height)

        for _ in 0..<16 {
            let candidate = CGPoint(x: .random(in: xRange), y: .random(in: yRange))
            let rect = CGRect(origin: candidate, size: size)
            if let obstacle, rect.intersects(obstacle) { continue }
            return candidate
        }

        return nearestValidOrigin(to: CGPoint(x: bounds.minX, y: bounds.minY),
                                  size: size,
                                  bounds: bounds,
                                  avoiding: obstacle)
    }

    private func sideCandidates(for obstacle: CGRect,
                                anchor: CGPoint,
                                size: CGSize,
                                bounds: CGRect) -> [CGRect] {
        let alignedY = clampScalar(anchor.y - size.height / 2,
                                   min: bounds.minY,
                                   max: bounds.maxY - size.height)
        let alignedX = clampScalar(anchor.x - size.width / 2,
                                   min: bounds.minX,
                                   max: bounds.maxX - size.width)

        return [
            CGRect(x: obstacle.maxX + obstacleGap, y: alignedY, width: size.width, height: size.height),
            CGRect(x: obstacle.minX - obstacleGap - size.width, y: alignedY, width: size.width, height: size.height),
            CGRect(x: alignedX, y: obstacle.maxY + obstacleGap, width: size.width, height: size.height),
            CGRect(x: alignedX, y: obstacle.minY - obstacleGap - size.height, width: size.width, height: size.height)
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
