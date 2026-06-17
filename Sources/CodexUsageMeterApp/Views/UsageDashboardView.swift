import CodexUsageMeterCore
import SwiftUI

struct UsageDashboardView: View {
    @ObservedObject var viewModel: UsageViewModel

    private var snapshot: ProviderUsageSnapshot? {
        viewModel.currentSnapshot
    }

    var body: some View {
        VStack(spacing: 14) {
            providerTabs
            HStack(spacing: 0) {
                quotaColumn
                Divider().opacity(0.5)
                tokenColumn
            }
        }
        .padding(14)
        .frame(width: 680, height: 294)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var providerTabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.availableProviders.enumerated()), id: \.element.id) { index, provider in
                if index > 0 {
                    Divider().frame(height: 22)
                }

                DashboardTab(
                    icon: provider.systemImageName,
                    title: provider.displayName,
                    selected: viewModel.selectedProviderID == provider.id,
                    enabled: provider.isImplemented,
                    action: { viewModel.selectProvider(provider.id) })
            }
            Divider().frame(height: 22)
            DashboardTab(
                icon: "ellipsis",
                title: "More",
                selected: false,
                enabled: false,
                action: {})
        }
        .padding(4)
        .background(Color.white.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var quotaColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            QuotaProgressRow(
                title: "5小时额度剩余",
                percent: snapshot?.fiveHourWindow?.remainingPercent,
                tint: .blue)
            QuotaProgressRow(
                title: "7天额度剩余",
                percent: snapshot?.weeklyWindow?.remainingPercent,
                tint: .green)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                    Text("重置时间")
                }
                .foregroundStyle(.secondary)

                ForEach(
                    DashboardFormatters.resetTimeItems(
                        fiveHour: snapshot?.fiveHourWindow,
                        weekly: snapshot?.weeklyWindow),
                    id: \.title
                ) { item in
                    HStack(spacing: 8) {
                        Text(item.title)
                            .frame(width: 42, alignment: .leading)
                            .foregroundStyle(.secondary)
                        Text(item.text)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 14))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tokenColumn: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日 Token")
                        .font(.system(size: 14, weight: .medium))
                    Text(DashboardFormatters.tokenText(snapshot?.todayTokens))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.blue)
                }
                Spacer()
                PercentRing(percent: snapshot?.fiveHourWindow?.remainingPercent)
            }
            .padding(.horizontal, 10)

            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("同步时间")
                Spacer()
                Text("\(DashboardFormatters.syncText(snapshot: snapshot))前")
                    .fontWeight(.medium)
                Image(systemName: viewModel.errorMessage == nil ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(viewModel.errorMessage == nil ? .green : .orange)
            }
            .font(.system(size: 14))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                Button {
                    viewModel.refresh()
                } label: {
                    Label(viewModel.isLoading ? "刷新中" : "刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(DashboardButtonStyle())

                Button {} label: {
                    Label("设置", systemImage: "gearshape")
                }
                .buttonStyle(DashboardButtonStyle())
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .lineLimit(1)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

private struct DashboardTab: View {
    let icon: String
    let title: String
    let selected: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 17))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(enabled || selected ? Color.primary : Color.secondary)
            .background(selected ? Color.black.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(enabled ? title : "\(title) 暂未接入")
    }
}

private struct QuotaProgressRow: View {
    let title: String
    let percent: Int?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            HStack(spacing: 14) {
                ProgressView(value: Double(percent ?? 0), total: 100)
                    .tint(tint)
                    .frame(width: 144)
                Text(DashboardFormatters.percent(percent))
                    .font(.system(size: 17, weight: .medium))
                    .monospacedDigit()
            }
        }
    }
}

private struct PercentRing: View {
    let percent: Int?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 7)
            Circle()
                .trim(from: 0, to: CGFloat(percent ?? 0) / 100)
                .stroke(.blue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(DashboardFormatters.percent(percent))
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
        }
        .frame(width: 64, height: 64)
    }
}

private struct DashboardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(minWidth: 92, maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(configuration.isPressed ? 0.55 : 0.42))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
