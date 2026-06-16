import CodexUsageMeterCore
import SwiftUI

public struct WatchUsageGlanceView: View {
    private let snapshot: ProviderUsageSnapshot?

    public init(snapshot: ProviderUsageSnapshot?) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Codex")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.white)
            }

            Text("今日 Token")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(tokenText)
                .font(.title3.bold())
                .foregroundStyle(.blue)

            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 6) {
                    WatchQuotaRow(title: "5h 剩余", percent: snapshot?.fiveHourWindow?.remainingPercent, tint: .blue)
                    WatchQuotaRow(title: "7d 剩余", percent: snapshot?.weeklyWindow?.remainingPercent, tint: .green)
                    WatchSyncRow(text: syncText)
                }

                WatchQuotaRing(percent: snapshot?.fiveHourWindow?.remainingPercent)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.black)
        .foregroundStyle(.white)
    }

    private var tokenText: String {
        guard let summary = snapshot?.todayTokens else {
            return "--"
        }
        return UsageFormatters.compactTokens(summary.totalTokens)
    }

    private var syncText: String {
        guard let snapshot else {
            return "--"
        }
        return UsageFormatters.relativeSyncAge(syncedAt: snapshot.syncedAt, now: snapshot.now)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: snapshot?.now ?? Date())
    }
}

public struct CircularQuotaComplicationView: View {
    private let percent: Int?

    public init(percent: Int?) {
        self.percent = percent
    }

    public var body: some View {
        ZStack {
            WatchQuotaRing(percent: percent)
            VStack(spacing: 0) {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("7d")
                    .font(.title3.bold())
                Text(percentText)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
        }
        .background(.black)
    }

    private var percentText: String {
        guard let percent else {
            return "--%"
        }
        return "\(percent)%"
    }
}

public struct RectangularQuotaComplicationView: View {
    private let title: String
    private let percent: Int?

    public init(title: String = "5h", percent: Int?) {
        self.title = title
        self.percent = percent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(title)
                .font(.title.bold())
            Text(percentText)
                .font(.headline.bold())
                .foregroundStyle(.blue)
            ProgressView(value: Double(percent ?? 0), total: 100)
                .tint(.blue)
        }
        .background(.black)
    }

    private var percentText: String {
        guard let percent else {
            return "--%"
        }
        return "\(percent)%"
    }
}

private struct WatchQuotaRow: View {
    let title: String
    let percent: Int?
    let tint: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(percentText)
                .foregroundStyle(tint)
                .fontWeight(.semibold)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var percentText: String {
        guard let percent else {
            return "--%"
        }
        return "\(percent)%"
    }
}

private struct WatchSyncRow: View {
    let text: String

    var body: some View {
        HStack {
            Text("同步时间")
            Spacer()
            Text("\(text)前")
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
    }
}

private struct WatchQuotaRing: View {
    let percent: Int?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(percent ?? 0) / 100)
                .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(percentText)
                .font(.caption.bold())
        }
        .frame(width: 52, height: 52)
    }

    private var percentText: String {
        guard let percent else {
            return "--%"
        }
        return "\(percent)%"
    }
}
