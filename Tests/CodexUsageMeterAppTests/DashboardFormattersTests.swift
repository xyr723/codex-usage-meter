import CodexUsageMeterCore
import Foundation
import Testing
@testable import CodexUsageMeterApp

@Test func resetTimeItemsIncludeFiveHourAndWeeklyWindows() {
    let fiveHourReset = Date(timeIntervalSince1970: 1_781_594_410)
    let weeklyReset = Date(timeIntervalSince1970: 1_782_199_200)

    let items = DashboardFormatters.resetTimeItems(
        fiveHour: QuotaWindow(
            kind: .fiveHour,
            usedPercent: 38,
            resetAt: fiveHourReset,
            windowSeconds: 18_000),
        weekly: QuotaWindow(
            kind: .weekly,
            usedPercent: 59,
            resetAt: weeklyReset,
            windowSeconds: 604_800))

    #expect(items.map(\.title) == ["5小时", "7天"])
    #expect(items.map(\.date) == [fiveHourReset, weeklyReset])
}

@Test func resetTimeItemsKeepWeeklyRowWhenExactDateUnavailable() {
    let fiveHourReset = Date(timeIntervalSince1970: 1_781_594_410)

    let items = DashboardFormatters.resetTimeItems(
        fiveHour: QuotaWindow(
            kind: .fiveHour,
            usedPercent: 38,
            resetAt: fiveHourReset,
            windowSeconds: 18_000),
        weekly: nil)

    #expect(items.map(\.title) == ["5小时", "7天"])
    #expect(items.map(\.date) == [fiveHourReset, nil])
}
