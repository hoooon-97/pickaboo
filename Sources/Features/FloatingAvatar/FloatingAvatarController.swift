import AppKit
import SwiftUI

final class FloatingAvatarController {
    let avatarSize = CGSize(width: 80, height: 80)
    let animator = SpriteAnimator()
    private let panel: FloatingPanel

    init(onTap: @escaping () -> Void) {
        let initialRect = NSRect(origin: .zero, size: avatarSize)
        panel = FloatingPanel(contentRect: initialRect)
        panel.contentView = NSHostingView(
            rootView: CharacterSprite(animator: animator, size: avatarSize, onTap: onTap)
        )
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func move(to origin: CGPoint) {
        let frame = NSRect(origin: origin, size: avatarSize)
        panel.setFrame(frame, display: false, animate: false)
    }
}
