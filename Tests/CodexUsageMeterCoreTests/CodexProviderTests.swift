import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func codexRefreshPolicyMarksCredentialsStaleAfterEightDays() {
    let now = Date(timeIntervalSince1970: 1_781_568_000)
    let fresh = CodexCredentials(
        accessToken: "access",
        refreshToken: "refresh",
        accountID: nil,
        lastRefresh: Date(timeInterval: -7 * 24 * 60 * 60, since: now))
    let stale = CodexCredentials(
        accessToken: "access",
        refreshToken: "refresh",
        accountID: nil,
        lastRefresh: Date(timeInterval: -9 * 24 * 60 * 60, since: now))

    #expect(CodexTokenRefreshPolicy.needsRefresh(fresh, now: now) == false)
    #expect(CodexTokenRefreshPolicy.needsRefresh(stale, now: now) == true)
}

@Test func codexRefreshRequestUsesOpenAIRefreshContract() throws {
    let credentials = CodexCredentials(
        accessToken: "old-access",
        refreshToken: "refresh-token",
        accountID: nil,
        lastRefresh: nil)

    let request = try CodexTokenRefreshRequestBuilder.request(credentials: credentials)
    let body = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

    #expect(request.url?.absoluteString == "https://auth.openai.com/oauth/token")
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(json["client_id"] == "app_EMoamEEZ73f0CkXaXp7hrann")
    #expect(json["grant_type"] == "refresh_token")
    #expect(json["refresh_token"] == "refresh-token")
    #expect(json["scope"] == "openid profile email")
}

@Test func codexRefreshDecoderPreservesAccountAndUsesReturnedTokens() throws {
    let base = CodexCredentials(
        accessToken: "old-access",
        refreshToken: "old-refresh",
        accountID: "account-id",
        lastRefresh: nil)
    let response = """
    {
      "access_token": "new-access",
      "refresh_token": "new-refresh",
      "id_token": "new-id"
    }
    """.data(using: .utf8)!
    let refreshedAt = Date(timeIntervalSince1970: 1_781_568_000)

    let credentials = try CodexTokenRefreshDecoder.credentials(
        from: response,
        base: base,
        refreshedAt: refreshedAt)

    #expect(credentials.accessToken == "new-access")
    #expect(credentials.refreshToken == "new-refresh")
    #expect(credentials.accountID == "account-id")
    #expect(credentials.lastRefresh == refreshedAt)
}

@Test func codexUsageProviderRefreshesBeforeFetchingQuota() async throws {
    let stale = CodexCredentials(
        accessToken: "stale-access",
        refreshToken: "refresh-token",
        accountID: "account-id",
        lastRefresh: Date(timeIntervalSince1970: 1_780_000_000))
    let fresh = CodexCredentials(
        accessToken: "fresh-access",
        refreshToken: "fresh-refresh",
        accountID: "account-id",
        lastRefresh: Date(timeIntervalSince1970: 1_781_568_000))
    let quotaJSON = """
    {
      "rate_limit": {
        "primary_window": {
          "used_percent": 38,
          "reset_at": "2026-06-16T13:00:00Z",
          "limit_window_seconds": 18000
        },
        "secondary_window": {
          "used_percent": 59,
          "reset_at": "2026-06-23T08:00:00Z",
          "limit_window_seconds": 604800
        }
      }
    }
    """.data(using: .utf8)!

    var refreshed = false
    var fetchedAccessToken: String?
    let provider = CodexUsageProvider(
        loadCredentials: { stale },
        saveCredentials: { _ in },
        refreshCredentials: { credentials in
            refreshed = credentials.accessToken == "stale-access"
            return fresh
        },
        fetchQuotaData: { credentials in
            fetchedAccessToken = credentials.accessToken
            return quotaJSON
        },
        scanTokens: { _ in
            TokenUsageSummary(inputTokens: 1_000, cachedInputTokens: 200, outputTokens: 30)
        })

    let snapshot = try await provider.snapshot(now: Date(timeIntervalSince1970: 1_781_568_000))

    #expect(refreshed)
    #expect(fetchedAccessToken == "fresh-access")
    #expect(snapshot.fiveHourWindow?.remainingPercent == 62)
    #expect(snapshot.weeklyWindow?.remainingPercent == 41)
    #expect(snapshot.todayTokens.totalTokens == 1_230)
}

@Test func codexAuthFileStoreRespectsCodexHome() throws {
    let codexHome = try makeTemporaryProviderCodexHome()
    let authURL = codexHome.appendingPathComponent("auth.json")
    try """
    {
      "last_refresh": "2026-06-16T07:20:10Z",
      "tokens": {
        "access_token": "access-token",
        "refresh_token": "refresh-token"
      }
    }
    """.write(to: authURL, atomically: true, encoding: .utf8)

    let store = CodexAuthFileStore(codexHome: codexHome)
    let credentials = try store.load()

    #expect(credentials.accessToken == "access-token")
}

private func makeTemporaryProviderCodexHome() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
