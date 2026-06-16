import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let viewModel: UsageViewModel
    private var cancellable: AnyCancellable?

    init(
        viewModel: UsageViewModel,
        toggleFloatingBall: @escaping () -> Void)
    {
        self.viewModel = viewModel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 680, height: 294)
        popover.contentViewController = NSHostingController(
            rootView: UsageDashboardView(
                viewModel: viewModel,
                toggleFloatingBall: toggleFloatingBall))

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Codex")
            button.imagePosition = .imageLeft
            button.font = .systemFont(ofSize: 14, weight: .medium)
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        updateTitle()
        cancellable = viewModel.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateTitle()
            }
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateTitle() {
        statusItem.button?.title = " \(viewModel.menuBarTitle)"
    }
}
