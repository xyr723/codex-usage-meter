import AppKit
import SwiftUI

@MainActor
final class FloatingBallController {
    private let panel: NSPanel

    init(viewModel: UsageViewModel) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: 470, height: 240)
        let origin = NSPoint(
            x: screenFrame.maxX - size.width - 36,
            y: screenFrame.midY - size.height / 2)

        panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: FloatingBallRootView(viewModel: viewModel))
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func toggleVisibility() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
}
