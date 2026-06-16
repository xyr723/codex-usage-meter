import CodexUsageMeterCore
import Combine
import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: ProviderUsageSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var now = Date()
    @Published private(set) var selectedProviderID: ProviderID

    let availableProviders = ProviderCatalog.all
    private let providers: [ProviderID: any UsageProvider]
    private var snapshots: [ProviderID: ProviderUsageSnapshot] = [:]
    private var errorMessages: [ProviderID: String] = [:]
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    init(provider: any UsageProvider) {
        self.providers = [
            provider.providerID: provider,
            ProviderID.claudeCode: UnavailableUsageProvider(providerID: .claudeCode),
        ]
        self.selectedProviderID = provider.providerID
    }

    init(
        providers: [any UsageProvider],
        selectedProviderID: ProviderID = .codex)
    {
        var providerMap: [ProviderID: any UsageProvider] = [:]
        for provider in providers {
            providerMap[provider.providerID] = provider
        }
        self.providers = providerMap
        self.selectedProviderID = selectedProviderID
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
            return "\(selectedProviderName)  5h --%  7d --%  Sync --"
        }

        return MenuBarFormatter.string(for: currentSnapshot, mode: .compact)
    }

    var selectedProviderName: String {
        ProviderCatalog.descriptor(for: selectedProviderID)?.displayName ?? selectedProviderID.rawValue
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

    func selectProvider(_ providerID: ProviderID) {
        guard selectedProviderID != providerID else {
            return
        }

        selectedProviderID = providerID
        snapshot = snapshots[providerID]
        errorMessage = errorMessages[providerID]
        refresh()
    }

    func refresh() {
        refreshTask?.cancel()
        isLoading = true
        let providerID = selectedProviderID
        errorMessage = nil
        errorMessages[providerID] = nil

        refreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard let provider = self.providers[providerID] else {
                    throw ProviderUnavailableError(providerID: providerID)
                }

                let fetchedSnapshot = try await provider.snapshot(now: Date())
                guard !Task.isCancelled else { return }
                self.snapshots[providerID] = fetchedSnapshot
                if self.selectedProviderID == providerID {
                    snapshot = fetchedSnapshot
                    now = Date()
                    errorMessage = fetchedSnapshot.syncState == .failed
                        ? "未获取到精确额度，请检查网络或 CODEX_USAGE_URL。"
                        : nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessages[providerID] = error.localizedDescription
                self.snapshots[providerID] = nil
                if self.selectedProviderID == providerID {
                    snapshot = nil
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
}
