import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func providerCatalogExposesCodexAndClaudeCodeTabs() {
    let providers = ProviderCatalog.all

    #expect(providers.map(\.id) == [.codex, .claudeCode])
    #expect(providers[0].displayName == "Codex")
    #expect(providers[1].displayName == "Claude")
    #expect(providers[0].isImplemented)
    #expect(providers[1].isImplemented == false)
}

@Test func unavailableProviderThrowsTypedUnavailableError() async {
    let provider = UnavailableUsageProvider(providerID: .claudeCode)

    await #expect(throws: ProviderUnavailableError.self) {
        _ = try await provider.snapshot(now: Date(timeIntervalSince1970: 1_781_568_000))
    }
}
