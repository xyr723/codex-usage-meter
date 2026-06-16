import Foundation

enum CodexDateParser {
    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else {
            return nil
        }

        return formatter(fractionalSeconds: true).date(from: string)
            ?? formatter(fractionalSeconds: false).date(from: string)
    }

    private static func formatter(fractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractionalSeconds
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter
    }
}
