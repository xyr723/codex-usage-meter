import Foundation

public enum CodexAuthFileStoreError: LocalizedError, Equatable {
    case notFound(URL)

    public var errorDescription: String? {
        switch self {
        case let .notFound(url):
            return "未找到 Codex 登录文件：\(url.path)。请先运行 codex 登录。"
        }
    }
}

public struct CodexAuthFileStore {
    public let codexHome: URL

    public init(codexHome: URL = Self.defaultCodexHome()) {
        self.codexHome = codexHome
    }

    public static func defaultCodexHome(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL {
        if let codexHome = environment["CODEX_HOME"], !codexHome.isEmpty {
            return URL(fileURLWithPath: codexHome, isDirectory: true)
        }

        return homeDirectory.appendingPathComponent(".codex", isDirectory: true)
    }

    public func load() throws -> CodexCredentials {
        let url = authFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CodexAuthFileStoreError.notFound(url)
        }

        let data = try Data(contentsOf: url)
        return try CodexAuthParser.credentials(from: data)
    }

    public func save(_ credentials: CodexCredentials, refreshedAt: Date = Date()) throws {
        var json = try existingAuthJSON()
        var tokens = json["tokens"] as? [String: Any] ?? [:]

        tokens["access_token"] = credentials.accessToken
        if let refreshToken = credentials.refreshToken {
            tokens["refresh_token"] = refreshToken
        }
        if let accountID = credentials.accountID {
            tokens["account_id"] = accountID
        }
        if let idToken = credentials.idToken {
            tokens["id_token"] = idToken
        }

        json["tokens"] = tokens
        json["last_refresh"] = isoString(from: credentials.lastRefresh ?? refreshedAt)

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
        try data.write(to: authFileURL, options: .atomic)
    }

    private var authFileURL: URL {
        codexHome.appendingPathComponent("auth.json")
    }

    private func existingAuthJSON() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: authFileURL.path) else {
            return [:]
        }

        let data = try Data(contentsOf: authFileURL)
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
