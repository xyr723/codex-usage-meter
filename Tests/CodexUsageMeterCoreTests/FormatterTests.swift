import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func menuBarCompactMatchesReferenceCopy() {
    let snapshot = makeProviderUsageSnapshot(
        fiveHourUsed: 38,
        weeklyUsed: 59,
        todayTokens: 1_230_000,
        syncAgeSeconds: 120)

    #expect(MenuBarFormatter.string(for: snapshot, mode: .compact) == "Codex  5h 62%  7d 41%  Sync 2m")
}

@Test func menuBarFullIncludesCompactTokenCount() {
    let snapshot = makeProviderUsageSnapshot(
        fiveHourUsed: 38,
        weeklyUsed: 59,
        todayTokens: 1_230_000,
        syncAgeSeconds: 120)

    #expect(MenuBarFormatter.string(for: snapshot, mode: .full) == "Codex  5h 62%  7d 41%  Sync 2m  1.23M")
}

@Test func compactTokenFormattingUsesMillions() {
    #expect(UsageFormatters.compactTokens(1_230_000) == "1.23M")
}

@Test func compactTokenFormattingUsesThousands() {
    #expect(UsageFormatters.compactTokens(128_420) == "128k")
}

private func makeProviderUsageSnapshot(
    fiveHourUsed: Int,
    weeklyUsed: Int,
    todayTokens: Int,
    syncAgeSeconds: TimeInterval
) -> ProviderUsageSnapshot {
    let syncedAt = Date(timeIntervalSince1970: 1_766_900_000)
    return ProviderUsageSnapshot(
        provider: .codex,
        fiveHourWindow: QuotaWindow(
            kind: .fiveHour,
            usedPercent: fiveHourUsed,
            resetAt: Date(timeInterval: 18_000, since: syncedAt),
            windowSeconds: 18_000),
        weeklyWindow: QuotaWindow(
            kind: .weekly,
            usedPercent: weeklyUsed,
            resetAt: Date(timeInterval: 604_800, since: syncedAt),
            windowSeconds: 604_800),
        todayTokens: TokenUsageSummary(
            inputTokens: todayTokens,
            cachedInputTokens: 0,
            outputTokens: 0),
        syncedAt: syncedAt,
        now: Date(timeInterval: syncAgeSeconds, since: syncedAt),
        syncState: .synced)
}
