import Combine
import Foundation

final class SpriteAnimator: ObservableObject {
    @Published private(set) var state: SpriteState = SpriteState(facing: .right, animation: .idle, frame: 0)

    var frameDuration: TimeInterval = 0.2
    private var accumulator: TimeInterval = 0

    func update(facing: Facing, animation: SpriteAnimation, deltaTime: TimeInterval) {
        var next = state
        next.facing = facing
        next.animation = animation

        switch animation {
        case .walking:
            accumulator += deltaTime
            if accumulator >= frameDuration {
                accumulator -= frameDuration
                next.frame = (state.frame + 1) % 4
            }
        case .idle:
            accumulator = 0
            next.frame = 0
        }

        if next != state {
            state = next
        }
    }
}
