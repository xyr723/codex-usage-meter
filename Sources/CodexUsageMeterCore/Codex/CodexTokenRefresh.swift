import Foundation

public enum CodexTokenRefreshPolicy {
    private static let refreshInterval: TimeInterval = 8 * 24 * 60 * 60

    public static func needsRefresh(_ credentials: CodexCredentials, now: Date = Date()) -> Bool {
        guard let lastRefresh = credentials.lastRefresh else {
            return true
        }

        return now.timeIntervalSince(lastRefresh) > refreshInterval
    }
}

public enum CodexTokenRefreshError: LocalizedError, Equatable {
    case missingRefreshToken
    case invalidJSON
    case failed(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .missingRefreshToken:
            return "Codex 登录文件缺少 refresh token，请重新登录 codex。"
        case .invalidJSON:
            return "Codex token refresh 返回了无法解析的数据。"
        case let .failed(statusCode):
            return "Codex token refresh 失败：HTTP \(statusCode)。"
        }
    }
}

public enum CodexTokenRefreshRequestBuilder {
    public static let endpoint = URL(string: "https://auth.openai.com/oauth/token")!
    public static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"

    public static func request(credentials: CodexCredentials) throws -> URLRequest {
        guard let refreshToken = credentials.refreshToken, !refreshToken.isEmpty else {
            throw CodexTokenRefreshError.missingRefreshToken
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "scope": "openid profile email",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

public enum CodexTokenRefreshDecoder {
    public static func credentials(
        from data: Data,
        base: CodexCredentials,
        refreshedAt: Date
    ) throws -> CodexCredentials {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CodexTokenRefreshError.invalidJSON
        }

        return CodexCredentials(
            accessToken: json["access_token"] as? String ?? base.accessToken,
            refreshToken: json["refresh_token"] as? String ?? base.refreshToken,
            accountID: base.accountID,
            lastRefresh: refreshedAt,
            idToken: json["id_token"] as? String ?? base.idToken)
    }
}

public struct CodexTokenRefresher {
    private let performRequest: (URLRequest) async throws -> HTTPDataResponse

    public init(performRequest: @escaping (URLRequest) async throws -> HTTPDataResponse = URLSessionHTTPClient().data) {
        self.performRequest = performRequest
    }

    public func refresh(_ credentials: CodexCredentials, now: Date = Date()) async throws -> CodexCredentials {
        let request = try CodexTokenRefreshRequestBuilder.request(credentials: credentials)
        let response = try await performRequest(request)
        guard response.statusCode == 200 else {
            throw CodexTokenRefreshError.failed(statusCode: response.statusCode)
        }

        return try CodexTokenRefreshDecoder.credentials(
            from: response.data,
            base: credentials,
            refreshedAt: now)
    }
}
