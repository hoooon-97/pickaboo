# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Pickaboo — a Mac-native AI assistant. A floating avatar (`NSPanel`) tracks the cursor, retreats to the menu bar when the active app goes full-screen, and surfaces Reminders / weather / AI features.

Currently at **Stage 1**: skeleton only (menu bar item + cursor-following avatar). See `README.md` for the full roadmap.

## Build

```bash
xcodegen generate                                   # regenerate Pickaboo.xcodeproj from project.yml
open Pickaboo.xcodeproj                             # open in Xcode (preferred for run/debug)
xcodebuild -scheme Pickaboo -configuration Debug build   # CLI build (requires full Xcode)
```

`project.yml` is the source of truth. `Pickaboo.xcodeproj`, `Resources/Info.plist`, and `Resources/Pickaboo.entitlements` are **generated** by `xcodegen` and git-ignored — never edit them directly. To change bundle ID, entitlements, Info.plist keys, deployment target, etc., edit `project.yml` and re-run `xcodegen generate`.

## Architecture

The app is an accessory (`LSUIElement = true`, `NSApp.setActivationPolicy(.accessory)`) — no Dock icon. Two surfaces:

1. **MenuBarExtra** (SwiftUI) — declared in `PickabooApp.swift`. Always present.
2. **FloatingPanel** (`NSPanel` subclass) — created imperatively in `AppDelegate.applicationDidFinishLaunching`. SwiftUI content via `NSHostingView`. Uses `.nonactivatingPanel` style and `canBecomeKey = false` so it **never steals focus**.

Data flow (Stage 1):

```
NSEvent global monitor  →  MouseTrackerService (Combine PassthroughSubject)
                              ↓ .throttle(33ms, latest)
                          PositionEngine.targetFrame(mouse, avatarSize)
                              ↓
                          FloatingAvatarController.move(to:)
                              ↓
                          NSPanel.setFrame
```

**Why these choices:**
- SwiftUI `Window` cannot become an `NSPanel`, so the floating avatar is built in AppKit and hosts a SwiftUI view. Don't try to migrate it to a SwiftUI Scene.
- The throttle at ~30 Hz is intentional — `NSEvent.mouseMoved` fires per-pixel; ungated it pegs CPU.
- `AXUIElement` calls (Stage 2+) are synchronous and expensive (1–10 ms). They must NOT be made on the mouse path. Cache window frames in `WindowMonitorService` and only refresh on `NSWorkspace.didActivateApplicationNotification` / `activeSpaceDidChangeNotification` plus a low-frequency poll.

## Conventions

- Korean responses by default; technical terms may stay in English (see workspace `CLAUDE.md`).
- Many small files, ~200–400 lines each (workspace coding-style rule).
- Immutability where practical — services own state, views render it.
- No comments explaining *what* code does; only *why* when non-obvious.
- Stage boundaries are real — do not bundle Stage 2 (window monitor) work into Stage 1 PRs.
