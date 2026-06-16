public struct TokenUsageSummary: Codable, Equatable, Sendable {
    public let inputTokens: Int
    public let cachedInputTokens: Int
    public let outputTokens: Int

    public init(inputTokens: Int, cachedInputTokens: Int, outputTokens: Int) {
        self.inputTokens = inputTokens
        self.cachedInputTokens = cachedInputTokens
        self.outputTokens = outputTokens
    }

    public var totalTokens: Int {
        inputTokens + cachedInputTokens + outputTokens
    }
}
