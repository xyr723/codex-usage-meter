import CodexUsageMeterCore
import Combine
import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: ProviderUsageSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var now = Date()

    private let provider: any UsageProvider
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    init(provider: any UsageProvider) {
        self.provider = provider
    }

    var currentSnapshot: ProviderUsageSnapshot? {
        guard let snapshot else {
            return nil
        }

        return ProviderUsageSnapshot(
            provider: snapshot.provider,
            fiveHourWindow: snapshot.fiveHourWindow,
            weeklyWindow: snapshot.weeklyWindow,
            todayTokens: snapshot.todayTokens,
            syncedAt: snapshot.syncedAt,
            now: now,
            syncState: snapshot.syncState)
    }

    var menuBarTitle: String {
        guard let currentSnapshot else {
            return "Codex  5h --%  7d --%  Sync --"
        }

        return MenuBarFormatter.string(for: currentSnapshot, mode: .compact)
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                if let snapshot = self.snapshot,
                   Date().timeIntervalSince(snapshot.syncedAt) > 120,
                   !self.isLoading
                {
                    self.refresh()
                }
            }
        }
    }

    func refresh() {
        refreshTask?.cancel()
        isLoading = true
        errorMessage = nil

        refreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let fetchedSnapshot = try await self.provider.snapshot(now: Date())
                guard !Task.isCancelled else { return }
                snapshot = fetchedSnapshot
                now = Date()
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
