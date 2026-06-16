import Foundation

public protocol UsageProvider: Sendable {
    var providerID: ProviderID { get }
    func snapshot(now: Date) async throws -> ProviderUsageSnapshot
}
