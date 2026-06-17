import AppKit
import CodexUsageMeterCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var viewModel: UsageViewModel?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = UsageViewModel(provider: CodexUsageProvider.live())

        viewModel = model
        statusBarController = StatusBarController(viewModel: model)

        model.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
