import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func quotaWindowComputesRemainingPercent() {
    let window = QuotaWindow(
        kind: .fiveHour,
        usedPercent: 62,
        resetAt: Date(timeIntervalSince1970: 1_766_948_068),
        windowSeconds: 18_000)

    #expect(window.remainingPercent == 38)
}

@Test func quotaWindowClampsRemainingPercent() {
    let overused = QuotaWindow(
        kind: .fiveHour,
        usedPercent: 140,
        resetAt: nil,
        windowSeconds: 18_000)
    let negative = QuotaWindow(
        kind: .weekly,
        usedPercent: -20,
        resetAt: nil,
        windowSeconds: 604_800)

    #expect(overused.remainingPercent == 0)
    #expect(negative.remainingPercent == 100)
}

@Test func tokenUsageSummaryComputesTotalTokens() {
    let summary = TokenUsageSummary(
        inputTokens: 82_000,
        cachedInputTokens: 31_000,
        outputTokens: 15_000)

    #expect(summary.totalTokens == 128_000)
}

@Test func sharedSnapshotRoundTrips() throws {
    let snapshot = SharedUsageSnapshot(
        provider: .codex,
        fiveHourRemainingPercent: 38,
        weeklyRemainingPercent: 59,
        todayTotalTokens: 1_230_000,
        syncedAt: Date(timeIntervalSince1970: 1_766_900_000))

    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(SharedUsageSnapshot.self, from: data)

    #expect(decoded.provider == .codex)
    #expect(decoded.todayTotalTokens == 1_230_000)
}
