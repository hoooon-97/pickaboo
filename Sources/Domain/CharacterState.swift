import CoreGraphics

enum Facing {
    case left
    case right

    static func from(vector: CGVector, fallback: Facing) -> Facing {
        if vector.dx > 0.5 { return .right }
        if vector.dx < -0.5 { return .left }
        return fallback
    }
}

enum SpriteAnimation {
    case idle
    case walking
}

struct SpriteState: Equatable {
    var facing: Facing
    var animation: SpriteAnimation
    var frame: Int
}
