import Foundation
import Testing
@testable import CodexUsageMeterCore

@Test func codexTokenScannerUsesLastTotalUsagePerSessionFile() throws {
    let codexHome = try makeTemporaryCodexHome()
    let fileURL = codexHome
        .appendingPathComponent("sessions/2026/06/16", isDirectory: true)
        .appendingPathComponent("session.jsonl")
    try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true)
    try """
    {"type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":100,"cached_input_tokens":20,"output_tokens":10,"total_tokens":130}}}}
    {"type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":300,"cached_input_tokens":40,"output_tokens":20,"total_tokens":360}}}}
    """.write(to: fileURL, atomically: true, encoding: .utf8)

    let scanner = CodexTokenScanner(codexHome: codexHome, calendar: utcCalendar)
    let summary = try scanner.tokensForDay(Date(timeIntervalSince1970: 1_781_568_000))

    #expect(summary.inputTokens == 300)
    #expect(summary.cachedInputTokens == 40)
    #expect(summary.outputTokens == 20)
    #expect(summary.totalTokens == 360)
}

@Test func codexTokenScannerIncludesArchivedSessionRowsForDay() throws {
    let codexHome = try makeTemporaryCodexHome()
    let archivedURL = codexHome
        .appendingPathComponent("archived_sessions", isDirectory: true)
        .appendingPathComponent("archived.jsonl")
    try FileManager.default.createDirectory(
        at: archivedURL.deletingLastPathComponent(),
        withIntermediateDirectories: true)
    try """
    {"timestamp":"2026-06-15T23:59:59Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":100,"cached_input_tokens":0,"output_tokens":0,"total_tokens":100}}}}
    {"timestamp":"2026-06-16T08:00:00Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":500,"cached_input_tokens":50,"output_tokens":25,"total_tokens":575}}}}
    """.write(to: archivedURL, atomically: true, encoding: .utf8)

    let scanner = CodexTokenScanner(codexHome: codexHome, calendar: utcCalendar)
    let summary = try scanner.tokensForDay(Date(timeIntervalSince1970: 1_781_568_000))

    #expect(summary.totalTokens == 575)
}

private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

private func makeTemporaryCodexHome() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
