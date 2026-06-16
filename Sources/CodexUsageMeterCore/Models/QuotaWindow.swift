import Foundation

public struct QuotaWindow: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case fiveHour
        case weekly
        case unknown
    }

    public let kind: Kind
    public let usedPercent: Int
    public let resetAt: Date?
    public let windowSeconds: Int?

    public init(kind: Kind, usedPercent: Int, resetAt: Date?, windowSeconds: Int?) {
        self.kind = kind
        self.usedPercent = usedPercent
        self.resetAt = resetAt
        self.windowSeconds = windowSeconds
    }

    public var remainingPercent: Int {
        min(100, max(0, 100 - usedPercent))
    }
}
