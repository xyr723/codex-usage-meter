import AppKit
import CodexUsageMeterCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var viewModel: UsageViewModel?
    private var statusBarController: StatusBarController?
    private var floatingBallController: FloatingBallController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = UsageViewModel(provider: CodexUsageProvider.live())
        let floating = FloatingBallController(viewModel: model)

        viewModel = model
        floatingBallController = floating
        statusBarController = StatusBarController(
            viewModel: model,
            toggleFloatingBall: { floating.toggleVisibility() })

        floating.show()
        model.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
