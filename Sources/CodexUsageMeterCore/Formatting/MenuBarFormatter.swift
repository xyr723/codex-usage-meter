public enum MenuBarDisplayMode: Sendable {
    case compact
    case full
}

public enum MenuBarFormatter {
    public static func string(
        for snapshot: ProviderUsageSnapshot,
        mode: MenuBarDisplayMode
    ) -> String {
        let provider = providerName(snapshot.provider)
        let fiveHour = snapshot.fiveHourWindow.map(\.remainingPercent)
        let weekly = snapshot.weeklyWindow.map(\.remainingPercent)
        let syncAge = UsageFormatters.relativeSyncAge(
            syncedAt: snapshot.syncedAt,
            now: snapshot.now)

        var parts = [
            provider,
            "5h \(percentText(fiveHour))",
            "7d \(percentText(weekly))",
            "Sync \(syncAge)",
        ]

        if mode == .full {
            parts.append(UsageFormatters.compactTokens(snapshot.todayTokens.totalTokens))
        }

        return parts.joined(separator: "  ")
    }

    private static func providerName(_ provider: ProviderID) -> String {
        switch provider {
        case .codex:
            return "Codex"
        case .claudeCode:
            return "Claude"
        }
    }

    private static func percentText(_ percent: Int?) -> String {
        guard let percent else {
            return "--%"
        }
        return "\(percent)%"
    }
}
