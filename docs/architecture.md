# Architecture

Codex Usage Meter uses a small native Swift architecture:

- `CodexUsageMeterCore`: data models, Codex auth parsing, quota fetching, token scanning, formatting, and watch-ready snapshots.
- `CodexUsageMeterApp`: SwiftUI views and AppKit integration for `NSStatusItem`, popovers, and settings.
- `CodexUsageMeterWatch`: SwiftUI watch glance and complication-ready views backed by the same normalized snapshot.

The UI consumes a single normalized `ProviderUsageSnapshot`. Provider-specific work stays behind `UsageProvider`, so future providers such as Claude Code can be added without rewriting the menu bar, popover, or watch views.

## macOS Shell

- `NSStatusItem` is used instead of an icon-only menu extra so the menu bar can directly show `Codex  5h ...  7d ...  Sync ...`.
- `NSPopover` hosts the dashboard SwiftUI view with a frosted panel matching the provided prototype.

## Refresh Model

- Quota refresh: short polling cadence plus manual refresh.
- Countdown text: updated locally from the last exact reset timestamp.
- Today's token scan: local JSONL scan from Codex session files.
- Stale data: keep the last known exact snapshot and clearly mark it stale.

The app must never estimate 5-hour or 7-day quota values when exact fetch fails.
