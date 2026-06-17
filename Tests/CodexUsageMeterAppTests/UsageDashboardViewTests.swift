import CodexUsageMeterCore
import Testing
@testable import CodexUsageMeterApp

@MainActor
@Test func usageDashboardViewInitializesWithViewModelOnly() {
    let viewModel = UsageViewModel(providers: [
        UnavailableUsageProvider(providerID: .codex),
    ])

    _ = UsageDashboardView(viewModel: viewModel)
}
