# UI Reference

The high-fidelity visual reference is stored at:

```text
docs/assets/reference.png
```

The app-owned UI should match this reference as closely as SwiftUI/AppKit allows:

- Top menu bar Codex segment: icon, `Codex`, `5h 62%`, `7d 41%`, `Sync 2m`.
- Drop-down usage dashboard: frosted rounded panel, provider tabs, left quota column, right token/ring/sync/actions column.
- Apple Watch direction: dark glance UI using the shared snapshot model.

Implementation notes:

- The real macOS menu bar, Wi-Fi, battery, clock, and Siri controls are system chrome; the app only renders its own status item.
- The top menu bar status item is text-first, not icon-only.
- Watch UI currently lives as a package target so it can be moved into a real watchOS app target later.

OS-owned chrome shown in the reference, such as Wi-Fi, battery, search, system clock, Siri, watch hardware, and desktop wallpaper, is context only and is not drawn by this app.

Before calling the UI complete, capture and compare:

- menu bar item.
- popover.
