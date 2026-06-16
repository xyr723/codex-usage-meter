import Foundation

public enum UsageFormatters {
    public static func compactTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            let value = Double(tokens) / 1_000_000
            return String(format: "%.2fM", value)
        }

        if tokens >= 1_000 {
            return "\(tokens / 1_000)k"
        }

        return "\(tokens)"
    }

    public static func relativeSyncAge(syncedAt: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(syncedAt)))
        if seconds < 60 {
            return "\(seconds)s"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        }

        return "\(minutes / 60)h"
    }
}
