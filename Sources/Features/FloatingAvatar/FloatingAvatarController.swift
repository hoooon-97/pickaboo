import AppKit
import SwiftUI

final class FloatingAvatarController {
    let avatarSize = CGSize(width: 72, height: 72)
    private let panel: FloatingPanel

    init() {
        let initialRect = NSRect(origin: .zero, size: avatarSize)
        panel = FloatingPanel(contentRect: initialRect)
        panel.contentView = NSHostingView(rootView: AvatarView())
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func move(to frame: CGRect) {
        panel.setFrame(frame, display: true, animate: false)
    }
}
