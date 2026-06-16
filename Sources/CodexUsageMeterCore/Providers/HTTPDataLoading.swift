import Foundation

public struct HTTPDataResponse: Sendable {
    public let data: Data
    public let statusCode: Int

    public init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }
}

public struct URLSessionHTTPClient {
    public init() {}

    public func data(for request: URLRequest) async throws -> HTTPDataResponse {
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return HTTPDataResponse(data: data, statusCode: statusCode)
    }
}
