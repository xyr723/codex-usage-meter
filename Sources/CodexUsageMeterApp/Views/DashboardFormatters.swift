import CodexUsageMeterCore
import Foundation

enum DashboardFormatters {
    static func tokenText(_ summary: TokenUsageSummary?) -> String {
        guard let summary else {
            return "--"
        }
        return UsageFormatters.compactTokens(summary.totalTokens)
    }

    static func syncText(snapshot: ProviderUsageSnapshot?) -> String {
        guard let snapshot else {
            return "--"
        }
        return UsageFormatters.relativeSyncAge(syncedAt: snapshot.syncedAt, now: snapshot.now)
    }

    static func percent(_ value: Int?) -> String {
        guard let value else {
            return "--%"
        }
        return "\(value)%"
    }

    static func resetText(_ date: Date?) -> String {
        guard let date else {
            return "--"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
