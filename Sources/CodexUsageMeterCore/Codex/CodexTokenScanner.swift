import Foundation

public struct CodexTokenScanner {
    private let codexHome: URL
    private let calendar: Calendar
    private let fileManager: FileManager

    public init(
        codexHome: URL,
        calendar: Calendar = .current,
        fileManager: FileManager = .default)
    {
        self.codexHome = codexHome
        self.calendar = calendar
        self.fileManager = fileManager
    }

    public func tokensForDay(_ date: Date) throws -> TokenUsageSummary {
        let summaries = try sessionFiles(for: date).map { fileURL in
            lastTokenUsage(in: fileURL, matchingDay: nil)
        } + archivedSessionFiles().map { fileURL in
            lastTokenUsage(in: fileURL, matchingDay: date)
        }

        return summaries.compactMap(\.self).reduce(TokenUsageSummary.zero, +)
    }

    private func sessionFiles(for date: Date) throws -> [URL] {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return []
        }

        let directory = codexHome
            .appendingPathComponent("sessions", isDirectory: true)
            .appendingPathComponent(String(format: "%04d", year), isDirectory: true)
            .appendingPathComponent(String(format: "%02d", month), isDirectory: true)
            .appendingPathComponent(String(format: "%02d", day), isDirectory: true)

        return jsonlFiles(in: directory)
    }

    private func archivedSessionFiles() -> [URL] {
        jsonlFiles(in: codexHome.appendingPathComponent("archived_sessions", isDirectory: true))
    }

    private func jsonlFiles(in directory: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles])
        else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "jsonl" else {
                return nil
            }
            return url
        }
    }

    private func lastTokenUsage(in fileURL: URL, matchingDay date: Date?) -> TokenUsageSummary? {
        guard
            let text = try? String(contentsOf: fileURL, encoding: .utf8),
            !text.isEmpty
        else {
            return nil
        }

        var lastSummary: TokenUsageSummary?
        for line in text.split(whereSeparator: \.isNewline) {
            guard
                let data = String(line).data(using: .utf8),
                let record = try? JSONDecoder().decode(TokenLogRecord.self, from: data),
                record.payload?.type == "token_count",
                let summary = record.payload?.info.totalTokenUsage?.summary
            else {
                continue
            }

            if let date {
                guard
                    let timestamp = CodexDateParser.date(from: record.timestamp),
                    calendar.isDate(timestamp, inSameDayAs: date)
                else {
                    continue
                }
            }

            lastSummary = summary
        }

        return lastSummary
    }
}

private struct TokenLogRecord: Decodable {
    let timestamp: String?
    let payload: TokenPayload?
}

private struct TokenPayload: Decodable {
    let type: String?
    let info: TokenInfo
}

private struct TokenInfo: Decodable {
    let totalTokenUsage: TokenUsageRecord?

    enum CodingKeys: String, CodingKey {
        case totalTokenUsage = "total_token_usage"
    }
}

private struct TokenUsageRecord: Decodable {
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int

    var summary: TokenUsageSummary {
        TokenUsageSummary(
            inputTokens: inputTokens,
            cachedInputTokens: cachedInputTokens,
            outputTokens: outputTokens)
    }

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case cachedInputTokens = "cached_input_tokens"
        case outputTokens = "output_tokens"
    }
}

private extension TokenUsageSummary {
    static let zero = TokenUsageSummary(
        inputTokens: 0,
        cachedInputTokens: 0,
        outputTokens: 0)

    static func + (lhs: TokenUsageSummary, rhs: TokenUsageSummary) -> TokenUsageSummary {
        TokenUsageSummary(
            inputTokens: lhs.inputTokens + rhs.inputTokens,
            cachedInputTokens: lhs.cachedInputTokens + rhs.cachedInputTokens,
            outputTokens: lhs.outputTokens + rhs.outputTokens)
    }
}
