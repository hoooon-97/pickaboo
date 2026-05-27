import AppKit
import Combine

final class BehaviorController: ObservableObject {
    enum WalkReason {
        case wander
        case escape
        case approach
    }

    private enum State {
        case idle(until: Date)
        case walking(to: CGPoint, reason: WalkReason)
    }

    @Published private(set) var origin: CGPoint
    @Published private(set) var facing: Facing = .right
    @Published private(set) var animation: SpriteAnimation = .idle

    var characterSize: CGSize
    var walkSpeed: CGFloat = 90
    var arrivalThreshold: CGFloat = 2

    private var state: State
    private let positionEngine: PositionEngine

    init(initialOrigin: CGPoint, characterSize: CGSize, positionEngine: PositionEngine) {
        self.origin = initialOrigin
        self.characterSize = characterSize
        self.positionEngine = positionEngine
        self.state = .idle(until: Date().addingTimeInterval(0.5))
    }

    func tick(deltaTime: TimeInterval, obstacle: CGRect?) {
        let bounds = positionEngine.bounds(containing: CGPoint(x: origin.x + characterSize.width / 2,
                                                                y: origin.y + characterSize.height / 2))

        if shouldEscape(from: obstacle) {
            let escape = positionEngine.nearestValidOrigin(to: origin,
                                                           size: characterSize,
                                                           bounds: bounds,
                                                           avoiding: obstacle)
            state = .walking(to: escape, reason: .escape)
        }

        switch state {
        case .walking(let target, let reason):
            advance(toward: target, deltaTime: deltaTime)
            if distance(origin, target) <= arrivalThreshold {
                arrive(reason: reason, bounds: bounds, obstacle: obstacle)
            }

        case .idle(let until):
            animation = .idle
            if Date() >= until {
                let target = positionEngine.randomValidOrigin(size: characterSize,
                                                              bounds: bounds,
                                                              avoiding: obstacle)
                state = .walking(to: target, reason: .wander)
            }
        }
    }

    func reactToClick(at clickLocation: CGPoint, obstacle: CGRect?) {
        let bounds = positionEngine.bounds(containing: clickLocation)
        let vector = CGVector(dx: clickLocation.x - (origin.x + characterSize.width / 2),
                              dy: clickLocation.y - (origin.y + characterSize.height / 2))
        facing = Facing.from(vector: vector, fallback: facing)

        let desiredOrigin = CGPoint(x: clickLocation.x - characterSize.width / 2,
                                    y: clickLocation.y - characterSize.height / 2)
        let target = positionEngine.nearestValidOrigin(to: desiredOrigin,
                                                       size: characterSize,
                                                       bounds: bounds,
                                                       avoiding: obstacle)
        state = .walking(to: target, reason: .approach)
    }

    private func shouldEscape(from obstacle: CGRect?) -> Bool {
        guard let obstacle else { return false }
        let rect = CGRect(origin: origin, size: characterSize)
        guard rect.intersects(obstacle) else { return false }
        if case .walking(_, .escape) = state { return false }
        return true
    }

    private func advance(toward target: CGPoint, deltaTime: TimeInterval) {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let dist = (dx * dx + dy * dy).squareRoot()
        guard dist > 0 else { return }

        let step = min(dist, walkSpeed * CGFloat(deltaTime))
        let unitX = dx / dist
        let unitY = dy / dist
        origin = CGPoint(x: origin.x + unitX * step, y: origin.y + unitY * step)

        facing = Facing.from(vector: CGVector(dx: unitX, dy: unitY), fallback: facing)
        animation = .walking
    }

    private func arrive(reason: WalkReason, bounds: CGRect, obstacle: CGRect?) {
        animation = .idle
        let idleDuration: TimeInterval = switch reason {
        case .wander: .random(in: 1.2...3.0)
        case .escape: .random(in: 0.3...0.8)
        case .approach: .random(in: 2.0...4.0)
        }
        state = .idle(until: Date().addingTimeInterval(idleDuration))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
