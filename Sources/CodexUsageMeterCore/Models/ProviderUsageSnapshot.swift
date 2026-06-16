import Foundation

public struct ProviderUsageSnapshot: Codable, Equatable, Sendable {
    public let provider: ProviderID
    public let fiveHourWindow: QuotaWindow?
    public let weeklyWindow: QuotaWindow?
    public let todayTokens: TokenUsageSummary
    public let syncedAt: Date
    public let now: Date
    public let syncState: SyncState

    public init(
        provider: ProviderID,
        fiveHourWindow: QuotaWindow?,
        weeklyWindow: QuotaWindow?,
        todayTokens: TokenUsageSummary,
        syncedAt: Date,
        now: Date,
        syncState: SyncState)
    {
        self.provider = provider
        self.fiveHourWindow = fiveHourWindow
        self.weeklyWindow = weeklyWindow
        self.todayTokens = todayTokens
        self.syncedAt = syncedAt
        self.now = now
        self.syncState = syncState
    }
}
