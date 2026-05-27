import SwiftUI

struct CharacterSprite: View {
    @ObservedObject var animator: SpriteAnimator
    let size: CGSize
    let onTap: () -> Void

    var body: some View {
        Image(systemName: symbolName)
            .resizable()
            .interpolation(.none)
            .antialiased(false)
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .foregroundStyle(
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
            .scaleEffect(x: animator.state.facing == .left ? -1 : 1, y: 1, anchor: .center)
            .offset(y: walkBob)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .animation(.easeInOut(duration: 0.1), value: animator.state.frame)
    }

    private var symbolName: String {
        switch animator.state.animation {
        case .walking:
            return animator.state.frame % 2 == 0 ? "figure.walk" : "figure.run"
        case .idle:
            return "figure.stand"
        }
    }

    private var walkBob: CGFloat {
        guard animator.state.animation == .walking else { return 0 }
        return animator.state.frame % 2 == 0 ? 0 : -2
    }
}
