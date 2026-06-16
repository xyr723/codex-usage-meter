import CodexUsageMeterCore
import SwiftUI

struct FloatingBallRootView: View {
    @ObservedObject var viewModel: UsageViewModel
    @State private var expanded = false

    private var snapshot: ProviderUsageSnapshot? {
        viewModel.currentSnapshot
    }

    var body: some View {
        HStack(spacing: 16) {
            if expanded {
                floatingPanel
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    expanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.blue.opacity(0.88),
                                    Color.indigo.opacity(0.7),
                                ],
                                center: .topLeading,
                                startRadius: 8,
                                endRadius: 48))
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    Circle()
                        .stroke(Color.blue.opacity(0.35), lineWidth: 14)
                        .blur(radius: 10)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .blue.opacity(0.9), radius: 6)
                }
                .frame(width: 78, height: 78)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    private var floatingPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 22, weight: .semibold))
                Text("Codex")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            QuotaLine(icon: "clock", title: "5h 剩余", percent: snapshot?.fiveHourWindow?.remainingPercent, tint: .blue)
            QuotaLine(icon: "calendar", title: "7d 剩余", percent: snapshot?.weeklyWindow?.remainingPercent, tint: .green)

            HStack {
                Image(systemName: "timer")
                Text("今日 Token")
                Spacer()
                Text(DashboardFormatters.tokenText(snapshot?.todayTokens))
                    .fontWeight(.semibold)
                Text("/ 2.00M")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "arrow.clockwise")
                Text("同步时间")
                Spacer()
                Text("\(DashboardFormatters.syncText(snapshot: snapshot))前")
                    .fontWeight(.medium)
                Image(systemName: viewModel.errorMessage == nil ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(viewModel.errorMessage == nil ? .green : .orange)
            }

            Divider()

            HStack {
                Text("⌘ ⇧ S  切换服务商")
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 15))
        .padding(18)
        .frame(width: 330)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
    }
}

private struct QuotaLine: View {
    let icon: String
    let title: String
    let percent: Int?
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 18)
            Text(title)
            Spacer()
            ProgressView(value: Double(percent ?? 0), total: 100)
                .tint(tint)
                .frame(width: 92)
            Text(DashboardFormatters.percent(percent))
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}
