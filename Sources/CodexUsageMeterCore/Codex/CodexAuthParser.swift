import Foundation

public enum CodexAuthError: Error, Equatable {
    case missingAccessToken
    case invalidJSON
}

public struct CodexCredentials: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let accountID: String?
    public let lastRefresh: Date?
    public let idToken: String?

    public init(
        accessToken: String,
        refreshToken: String?,
        accountID: String?,
        lastRefresh: Date?,
        idToken: String? = nil)
    {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accountID = accountID
        self.lastRefresh = lastRefresh
        self.idToken = idToken
    }
}

public enum CodexAuthParser {
    public static func credentials(from data: Data) throws -> CodexCredentials {
        let file: AuthFile
        do {
            file = try JSONDecoder().decode(AuthFile.self, from: data)
        } catch {
            throw CodexAuthError.invalidJSON
        }

        guard let accessToken = file.tokens.accessToken, !accessToken.isEmpty else {
            throw CodexAuthError.missingAccessToken
        }

        return CodexCredentials(
            accessToken: accessToken,
            refreshToken: emptyToNil(file.tokens.refreshToken),
            accountID: emptyToNil(file.tokens.accountID),
            lastRefresh: CodexDateParser.date(from: file.lastRefresh),
            idToken: emptyToNil(file.tokens.idToken))
    }

    private static func emptyToNil(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }
}

private struct AuthFile: Decodable {
    let lastRefresh: String?
    let tokens: TokenBlock

    enum CodingKeys: String, CodingKey {
        case lastRefresh = "last_refresh"
        case tokens
    }
}

private struct TokenBlock: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let accountID: String?
    let idToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case accountID = "account_id"
        case idToken = "id_token"
    }
}
