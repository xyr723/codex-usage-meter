import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func codexAuthParserReadsExistingCliShape() throws {
    let json = """
    {
      "auth_mode": "chatgpt",
      "last_refresh": "2026-06-16T07:20:10.123Z",
      "tokens": {
        "access_token": "access-token",
        "refresh_token": "refresh-token",
        "account_id": "account-id",
        "id_token": "id-token"
      }
    }
    """.data(using: .utf8)!

    let credentials = try CodexAuthParser.credentials(from: json)

    #expect(credentials.accessToken == "access-token")
    #expect(credentials.refreshToken == "refresh-token")
    #expect(credentials.accountID == "account-id")
    #expect(credentials.lastRefresh == Date(timeIntervalSince1970: 1_781_594_410.123))
}

@Test func codexAuthParserRejectsMissingAccessToken() throws {
    let json = """
    {
      "last_refresh": "2026-06-16T07:20:10Z",
      "tokens": {
        "refresh_token": "refresh-token"
      }
    }
    """.data(using: .utf8)!

    #expect(throws: CodexAuthError.self) {
        _ = try CodexAuthParser.credentials(from: json)
    }
}
