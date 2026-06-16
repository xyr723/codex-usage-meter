import Foundation

public struct CodexUsageProvider: UsageProvider, @unchecked Sendable {
    public let providerID: ProviderID = .codex

    private let loadCredentials: () throws -> CodexCredentials
    private let saveCredentials: (CodexCredentials) throws -> Void
    private let refreshCredentials: (CodexCredentials) async throws -> CodexCredentials
    private let fetchQuotaData: (CodexCredentials) async throws -> Data
    private let scanTokens: (Date) throws -> TokenUsageSummary

    public init(
        loadCredentials: @escaping () throws -> CodexCredentials,
        saveCredentials: @escaping (CodexCredentials) throws -> Void,
        refreshCredentials: @escaping (CodexCredentials) async throws -> CodexCredentials,
        fetchQuotaData: @escaping (CodexCredentials) async throws -> Data,
        scanTokens: @escaping (Date) throws -> TokenUsageSummary)
    {
        self.loadCredentials = loadCredentials
        self.saveCredentials = saveCredentials
        self.refreshCredentials = refreshCredentials
        self.fetchQuotaData = fetchQuotaData
        self.scanTokens = scanTokens
    }

    public static func live(
        codexHome: URL = CodexAuthFileStore.defaultCodexHome(),
        calendar: Calendar = .current
    ) -> CodexUsageProvider {
        let authStore = CodexAuthFileStore(codexHome: codexHome)
        let tokenScanner = CodexTokenScanner(codexHome: codexHome, calendar: calendar)
        let httpClient = URLSessionHTTPClient()
        let tokenRefresher = CodexTokenRefresher(performRequest: httpClient.data)

        return CodexUsageProvider(
            loadCredentials: authStore.load,
            saveCredentials: { try authStore.save($0) },
            refreshCredentials: { try await tokenRefresher.refresh($0) },
            fetchQuotaData: { credentials in
                let request = CodexQuotaRequestBuilder.request(credentials: credentials)
                let response = try await httpClient.data(for: request)
                guard response.statusCode == 200 else {
                    throw CodexQuotaHTTPError.failed(statusCode: response.statusCode)
                }
                return response.data
            },
            scanTokens: tokenScanner.tokensForDay)
    }

    public func snapshot(now: Date = Date()) async throws -> ProviderUsageSnapshot {
        var credentials = try loadCredentials()

        if CodexTokenRefreshPolicy.needsRefresh(credentials, now: now),
           credentials.refreshToken != nil
        {
            let refreshedCredentials = try await refreshCredentials(credentials)
            try saveCredentials(refreshedCredentials)
            credentials = refreshedCredentials
        }

        let todayTokens = try scanTokens(now)
        let quotaData = try await fetchQuotaData(credentials)

        return try CodexQuotaDecoder.snapshot(
            from: quotaData,
            todayTokens: todayTokens,
            syncedAt: now,
            now: now)
    }
}

public enum CodexQuotaHTTPError: Error, Equatable {
    case failed(statusCode: Int)
}
