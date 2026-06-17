import CodexUsageMeterCore
import Testing
@testable import CodexUsageMeterApp

@MainActor
@Test func selectedProviderDisplayMetadataChangesWhenProviderChanges() {
    let viewModel = UsageViewModel(providers: [
        UnavailableUsageProvider(providerID: .codex),
        UnavailableUsageProvider(providerID: .claudeCode),
    ])

    #expect(viewModel.selectedProviderName == "Codex")
    #expect(viewModel.selectedProviderIconName == "brain.head.profile")

    viewModel.selectProvider(.claudeCode)

    #expect(viewModel.selectedProviderName == "Claude")
    #expect(viewModel.selectedProviderIconName == "sparkles")
}
