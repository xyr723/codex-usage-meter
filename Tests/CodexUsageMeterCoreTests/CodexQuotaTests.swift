import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func codexQuotaDecoderMapsWindowsByDuration() throws {
    let json = """
    {
      "rate_limit": {
        "primary_window": {
          "used_percent": 59,
          "reset_at": "2026-06-23T08:00:00Z",
          "limit_window_seconds": 604800
        },
        "secondary_window": {
          "used_percent": 38,
          "reset_at": "2026-06-16T13:00:00Z",
          "limit_window_seconds": 18000
        }
      }
    }
    """.data(using: .utf8)!

    let snapshot = try CodexQuotaDecoder.snapshot(
        from: json,
        todayTokens: TokenUsageSummary(
            inputTokens: 1_000_000,
            cachedInputTokens: 200_000,
            outputTokens: 30_000),
        syncedAt: Date(timeIntervalSince1970: 1_781_578_800),
        now: Date(timeIntervalSince1970: 1_781_578_920))

    #expect(snapshot.provider == .codex)
    #expect(snapshot.fiveHourWindow?.remainingPercent == 62)
    #expect(snapshot.weeklyWindow?.remainingPercent == 41)
    #expect(snapshot.todayTokens.totalTokens == 1_230_000)
}

@Test func codexQuotaRequestUsesExactUsageEndpoint() throws {
    let credentials = CodexCredentials(
        accessToken: "access-token",
        refreshToken: "refresh-token",
        accountID: "account-id",
        lastRefresh: nil)

    let request = CodexQuotaRequestBuilder.request(credentials: credentials)

    #expect(request.url?.absoluteString == "https://chatgpt.com/backend-api/wham/usage")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
    #expect(request.value(forHTTPHeaderField: "ChatGPT-Account-Id") == "account-id")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
}
