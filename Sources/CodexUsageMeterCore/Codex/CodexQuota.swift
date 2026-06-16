import Foundation

public enum CodexQuotaRequestBuilder {
    public static let endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    public static func request(
        credentials: CodexCredentials,
        endpoint: URL = endpoint
    ) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("codex-cli", forHTTPHeaderField: "User-Agent")

        if let accountID = credentials.accountID {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        return request
    }
}

public enum CodexQuotaEndpointResolver {
    public static func endpoint(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL {
        if let value = environment["CODEX_USAGE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty,
           let url = URL(string: value)
        {
            return url
        }

        return CodexQuotaRequestBuilder.endpoint
    }
}

public enum CodexQuotaError: LocalizedError, Equatable {
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Codex 精确额度接口返回了无法解析的数据。"
        }
    }
}

public enum CodexQuotaDecoder {
    public static func snapshot(
        from data: Data,
        todayTokens: TokenUsageSummary,
        syncedAt: Date,
        now: Date
    ) throws -> ProviderUsageSnapshot {
        let response: UsageResponse
        do {
            response = try JSONDecoder().decode(UsageResponse.self, from: data)
        } catch {
            throw CodexQuotaError.invalidJSON
        }

        let windows = [
            response.rateLimit.primaryWindow,
            response.rateLimit.secondaryWindow,
        ]

        return ProviderUsageSnapshot(
            provider: .codex,
            fiveHourWindow: windows.first(where: { $0.kind == .fiveHour })?.quotaWindow,
            weeklyWindow: windows.first(where: { $0.kind == .weekly })?.quotaWindow,
            todayTokens: todayTokens,
            syncedAt: syncedAt,
            now: now,
            syncState: .synced)
    }
}

private struct UsageResponse: Decodable {
    let rateLimit: RateLimit

    enum CodingKeys: String, CodingKey {
        case rateLimit = "rate_limit"
    }
}

private struct RateLimit: Decodable {
    let primaryWindow: UsageWindow
    let secondaryWindow: UsageWindow

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

private struct UsageWindow: Decodable {
    let usedPercent: Int
    let resetAt: Date?
    let limitWindowSeconds: Int?

    var kind: QuotaWindow.Kind {
        switch limitWindowSeconds {
        case 18_000:
            return .fiveHour
        case 604_800:
            return .weekly
        default:
            return .unknown
        }
    }

    var quotaWindow: QuotaWindow {
        QuotaWindow(
            kind: kind,
            usedPercent: usedPercent,
            resetAt: resetAt,
            windowSeconds: limitWindowSeconds)
    }

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case resetAt = "reset_at"
        case limitWindowSeconds = "limit_window_seconds"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        usedPercent = try container.decodeFlexibleInt(forKey: .usedPercent)
        resetAt = CodexDateParser.date(from: try container.decodeIfPresent(String.self, forKey: .resetAt))
        limitWindowSeconds = try container.decodeFlexibleOptionalInt(forKey: .limitWindowSeconds)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value.rounded())
        }
        if let value = try? decode(String.self, forKey: key), let intValue = Int(value) {
            return intValue
        }
        return 0
    }

    func decodeFlexibleOptionalInt(forKey key: Key) throws -> Int? {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value.rounded())
        }
        if let value = try? decode(String.self, forKey: key), let intValue = Int(value) {
            return intValue
        }
        return nil
    }
}
