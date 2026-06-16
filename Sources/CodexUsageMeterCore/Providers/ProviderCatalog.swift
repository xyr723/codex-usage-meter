import Foundation

public struct ProviderDescriptor: Equatable, Sendable {
    public let id: ProviderID
    public let displayName: String
    public let systemImageName: String
    public let isImplemented: Bool

    public init(
        id: ProviderID,
        displayName: String,
        systemImageName: String,
        isImplemented: Bool)
    {
        self.id = id
        self.displayName = displayName
        self.systemImageName = systemImageName
        self.isImplemented = isImplemented
    }
}

public enum ProviderCatalog {
    public static let all: [ProviderDescriptor] = [
        ProviderDescriptor(
            id: .codex,
            displayName: "Codex",
            systemImageName: "brain.head.profile",
            isImplemented: true),
        ProviderDescriptor(
            id: .claudeCode,
            displayName: "Claude",
            systemImageName: "sparkles",
            isImplemented: false),
    ]

    public static func descriptor(for id: ProviderID) -> ProviderDescriptor? {
        all.first { $0.id == id }
    }
}

public struct ProviderUnavailableError: LocalizedError, Equatable, Sendable {
    public let providerID: ProviderID

    public init(providerID: ProviderID) {
        self.providerID = providerID
    }

    public var errorDescription: String? {
        let providerName = ProviderCatalog.descriptor(for: providerID)?.displayName ?? providerID.rawValue
        return "\(providerName) 暂未接入，已保留 Provider 扩展接口。"
    }
}

public struct UnavailableUsageProvider: UsageProvider {
    public let providerID: ProviderID

    public init(providerID: ProviderID) {
        self.providerID = providerID
    }

    public func snapshot(now: Date) async throws -> ProviderUsageSnapshot {
        throw ProviderUnavailableError(providerID: providerID)
    }
}
