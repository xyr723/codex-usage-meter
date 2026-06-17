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

@Test func codexQuotaDecoderAcceptsNumericResetTimestamps() throws {
    let json = """
    {
      "rate_limit": {
        "primary_window": {
          "used_percent": 10,
          "reset_at": 1781594410,
          "limit_window_seconds": 18000
        },
        "secondary_window": {
          "used_percent": 20,
          "reset_at": 1782199200,
          "limit_window_seconds": 604800
        }
      }
    }
    """.data(using: .utf8)!

    let snapshot = try CodexQuotaDecoder.snapshot(
        from: json,
        todayTokens: TokenUsageSummary(inputTokens: 0, cachedInputTokens: 0, outputTokens: 0),
        syncedAt: Date(timeIntervalSince1970: 1_781_568_000),
        now: Date(timeIntervalSince1970: 1_781_568_000))

    #expect(snapshot.fiveHourWindow?.resetAt == Date(timeIntervalSince1970: 1_781_594_410))
    #expect(snapshot.weeklyWindow?.resetAt == Date(timeIntervalSince1970: 1_782_199_200))
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

@Test func codexQuotaRequestCanUseConfiguredExactUsageEndpoint() throws {
    let credentials = CodexCredentials(
        accessToken: "access-token",
        refreshToken: nil,
        accountID: nil,
        lastRefresh: nil)
    let endpoint = URL(string: "https://proxy.example.test/backend-api/wham/usage")!

    let request = CodexQuotaRequestBuilder.request(
        credentials: credentials,
        endpoint: endpoint)

    #expect(request.url == endpoint)
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
}

@Test func codexQuotaEndpointResolverReadsFullUsageURLFromEnvironment() throws {
    let endpoint = CodexQuotaEndpointResolver.endpoint(environment: [
        "CODEX_USAGE_URL": "https://proxy.example.test/backend-api/wham/usage",
    ])

    #expect(endpoint.absoluteString == "https://proxy.example.test/backend-api/wham/usage")
}

@Test func httpProxyResolverReadsCodexProxyURL() throws {
    let proxyURL = try #require(HTTPProxyResolver.proxyURL(environment: [
        "CODEX_PROXY_URL": "http://127.0.0.1:7897",
    ]))
    let dictionary = HTTPProxyResolver.connectionProxyDictionary(proxyURL: proxyURL)

    #expect(proxyURL.absoluteString == "http://127.0.0.1:7897")
    #expect(dictionary[kCFNetworkProxiesHTTPProxy as String] as? String == "127.0.0.1")
    #expect(dictionary[kCFNetworkProxiesHTTPPort as String] as? Int == 7897)
}
