import AppKit
import SwiftUI

final class ChatPanelController {
    let viewModel: ChatViewModel
    private let panel: ChatPanel
    private let defaultSize = NSSize(width: 380, height: 480)

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        let rect = NSRect(origin: .zero, size: defaultSize)
        panel = ChatPanel(contentRect: rect)
        panel.contentView = NSHostingView(rootView: ChatView(viewModel: viewModel))
    }

    var isVisible: Bool { panel.isVisible }

    func toggle(near anchorPoint: CGPoint) {
        if panel.isVisible {
            close()
        } else {
            open(near: anchorPoint)
        }
    }

    func open(near anchorPoint: CGPoint) {
        let screen = screenContaining(anchorPoint) ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let size = panel.frame.size

        var origin = CGPoint(
            x: anchorPoint.x + 24,
            y: anchorPoint.y - size.height + 40
        )
        origin.x = clamp(origin.x, lower: visible.minX + 8, upper: visible.maxX - size.width - 8)
        origin.y = clamp(origin.y, lower: visible.minY + 8, upper: visible.maxY - size.height - 8)

        panel.setFrameOrigin(origin)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        panel.close()
    }

    private func screenContaining(_ point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }
}
