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
    private let session: URLSession

    public init(proxyURL: URL? = HTTPProxyResolver.proxyURL()) {
        let configuration = URLSessionConfiguration.default
        if let proxyURL {
            configuration.connectionProxyDictionary = HTTPProxyResolver.connectionProxyDictionary(proxyURL: proxyURL)
        }
        session = URLSession(configuration: configuration)
    }

    public func data(for request: URLRequest) async throws -> HTTPDataResponse {
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return HTTPDataResponse(data: data, statusCode: statusCode)
    }
}

public enum HTTPProxyResolver {
    public static func proxyURL(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        let keys = ["CODEX_PROXY_URL", "HTTPS_PROXY", "https_proxy", "ALL_PROXY", "all_proxy"]
        for key in keys {
            if let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty,
               let url = URL(string: value)
            {
                return url
            }
        }
        return nil
    }

    public static func connectionProxyDictionary(proxyURL: URL) -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]
        let host = proxyURL.host(percentEncoded: false) ?? "127.0.0.1"
        let port = proxyURL.port ?? 7897

        dictionary[kCFNetworkProxiesHTTPEnable as String] = true
        dictionary[kCFNetworkProxiesHTTPProxy as String] = host
        dictionary[kCFNetworkProxiesHTTPPort as String] = port
        dictionary[kCFNetworkProxiesHTTPSEnable as String] = true
        dictionary[kCFNetworkProxiesHTTPSProxy as String] = host
        dictionary[kCFNetworkProxiesHTTPSPort as String] = port

        if proxyURL.scheme?.lowercased().hasPrefix("socks") == true {
            dictionary[kCFNetworkProxiesSOCKSEnable as String] = true
            dictionary[kCFNetworkProxiesSOCKSProxy as String] = host
            dictionary[kCFNetworkProxiesSOCKSPort as String] = port
        }

        return dictionary
    }
}
