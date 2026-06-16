# Architecture

Codex Usage Meter uses a small native Swift architecture:

- `CodexUsageMeterCore`: data models, Codex auth parsing, quota fetching, token scanning, formatting, and watch-ready snapshots.
- `CodexUsageMeterApp`: SwiftUI views and AppKit integration for `NSStatusItem`, popovers, settings, and the floating ball.
- `CodexUsageMeterWatch`: SwiftUI watch glance and complication-ready views backed by the same normalized snapshot.

The UI consumes a single normalized `ProviderUsageSnapshot`. Provider-specific work stays behind `UsageProvider`, so future providers such as Claude Code can be added without rewriting the menu bar, popover, floating ball, or watch views.

## macOS Shell

- `NSStatusItem` is used instead of an icon-only menu extra so the menu bar can directly show `Codex  5h ...  7d ...  Sync ...`.
- `NSPopover` hosts the dashboard SwiftUI view with a frosted panel matching the provided prototype.
- `NSPanel` hosts the floating ball, using a separate SwiftUI layout from the popover.

## Refresh Model

- Quota refresh: short polling cadence plus manual refresh.
- Countdown text: updated locally from the last exact reset timestamp.
- Today's token scan: local JSONL scan from Codex session files.
- Stale data: keep the last known exact snapshot and clearly mark it stale.

The app must never estimate 5-hour or 7-day quota values when exact fetch fails.
