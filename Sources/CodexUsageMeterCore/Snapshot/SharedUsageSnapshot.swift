import Foundation

public struct SharedUsageSnapshot: Codable, Equatable, Sendable {
    public let provider: ProviderID
    public let fiveHourRemainingPercent: Int?
    public let weeklyRemainingPercent: Int?
    public let todayTotalTokens: Int
    public let syncedAt: Date

    public init(
        provider: ProviderID,
        fiveHourRemainingPercent: Int?,
        weeklyRemainingPercent: Int?,
        todayTotalTokens: Int,
        syncedAt: Date)
    {
        self.provider = provider
        self.fiveHourRemainingPercent = fiveHourRemainingPercent
        self.weeklyRemainingPercent = weeklyRemainingPercent
        self.todayTotalTokens = todayTotalTokens
        self.syncedAt = syncedAt
    }
}
