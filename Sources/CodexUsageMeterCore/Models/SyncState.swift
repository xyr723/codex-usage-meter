public enum SyncState: String, Codable, Equatable, Sendable {
    case idle
    case syncing
    case synced
    case failed
}
