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
        calendar: Calendar = .current,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> CodexUsageProvider {
        let authStore = CodexAuthFileStore(codexHome: codexHome)
        let tokenScanner = CodexTokenScanner(codexHome: codexHome, calendar: calendar)
        let httpClient = URLSessionHTTPClient()
        let tokenRefresher = CodexTokenRefresher(performRequest: httpClient.data)
        let quotaEndpoint = CodexQuotaEndpointResolver.endpoint(environment: environment)

        return CodexUsageProvider(
            loadCredentials: authStore.load,
            saveCredentials: { try authStore.save($0) },
            refreshCredentials: { try await tokenRefresher.refresh($0) },
            fetchQuotaData: { credentials in
                let request = CodexQuotaRequestBuilder.request(
                    credentials: credentials,
                    endpoint: quotaEndpoint)
                let response: HTTPDataResponse
                do {
                    response = try await httpClient.data(for: request)
                } catch {
                    throw CodexQuotaHTTPError.network(error.localizedDescription)
                }
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
        do {
            let quotaData = try await fetchQuotaData(credentials)
            return try CodexQuotaDecoder.snapshot(
                from: quotaData,
                todayTokens: todayTokens,
                syncedAt: now,
                now: now)
        } catch {
            return ProviderUsageSnapshot(
                provider: .codex,
                fiveHourWindow: nil,
                weeklyWindow: nil,
                todayTokens: todayTokens,
                syncedAt: now,
                now: now,
                syncState: .failed)
        }
    }
}

public enum CodexQuotaHTTPError: LocalizedError, Equatable {
    case failed(statusCode: Int)
    case network(String)

    public var errorDescription: String? {
        switch self {
        case let .failed(statusCode):
            return "Codex 精确额度接口请求失败：HTTP \(statusCode)。"
        case let .network(message):
            return "Codex 精确额度接口网络不可达：\(message)。"
        }
    }
}
