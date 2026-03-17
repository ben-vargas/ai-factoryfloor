# Swift 6 Strict Concurrency Migration

## Overview

Factory Floor currently targets Swift 5.10. Swift 6 enforces strict
concurrency checking at compile time, turning data race warnings into
errors. This document scopes the migration effort.

## Recommended approach

1. Enable `SWIFT_STRICT_CONCURRENCY = complete` under Swift 5.10 first
2. Fix all warnings incrementally (they become errors in Swift 6)
3. Flip `SWIFT_VERSION` to `6.0` in `project.yml` when clean
4. Regression-test terminal/ghostty integration thoroughly

## Phase 1: Sendable conformances (low risk, mechanical)

Add `: Sendable` to all value types that cross concurrency boundaries.
These are all structs/enums with only value-type stored properties.

| Type | File | Notes |
|------|------|-------|
| `Project` | Project.swift | All value-type fields |
| `Workstream` | Project.swift | All value-type fields |
| `ProjectSortOrder` | Project.swift | Raw-value enum |
| `GitRepoInfo` | GitOperations.swift | All value-type fields |
| `WorktreeInfo` | GitOperations.swift | All value-type fields |
| `GitHubRepoInfo` | GitHubOperations.swift | All value-type fields |
| `GitHubPR` | GitHubOperations.swift | All value-type fields |
| `ScriptConfig` | ScriptConfig.swift | All value-type fields |
| `ToolStatus` | SettingsView.swift | Contains BinaryStatus enum |
| `BinaryStatus` | SettingsView.swift | Enum with String associated value |
| `SidebarSelection` | SidebarSelection.swift | Enum with UUID values |
| `WorkspaceTab` | TerminalContainerView.swift | Enum with UUID |
| `AppInfo` | SettingsView.swift | Has computed NSImage property, needs `@unchecked Sendable` |

Estimated: ~13 one-line additions.

## Phase 2: MainActor annotations (low risk)

Add `@MainActor` to classes that are only accessed from the main thread.

| Type | File | Why |
|------|------|-----|
| `TerminalApp` | TerminalApp.swift | Singleton, accesses NSApp/NSPasteboard, owns ghostty_app_t |
| `TerminalSurfaceCache` | TerminalContainerView.swift | ObservableObject, mutates surfaces dict |
| `AppDelegate` | FF2App.swift | NSApplicationDelegate |

`TerminalView` is an NSView subclass, which is implicitly `@MainActor`
in Swift 6. The `static var surfaceRegistry` will inherit this.

`AppEnvironment` already has `@MainActor`.

Estimated: ~3 annotations.

## Phase 3: Task.detached closure fixes (medium risk)

All `Task.detached` closures must capture only `Sendable` values.
Current captures that need attention:

| Location | Issue | Fix |
|----------|-------|-----|
| Environment.swift refreshPathValidity | Captures `[Project]` | Add Sendable to Project |
| ProjectOverviewView.swift pruneWorktrees | Captures `@Binding` in `MainActor.run` | Move mutation to a `@MainActor` method |
| WorkstreamInfoView.swift loadInfo | Returns `NSImage?` across boundary | Use `@preconcurrency import AppKit` or `nonisolated(unsafe)` |

Estimated: ~3-5 refactors.

## Phase 4: Ghostty C callbacks (high risk, needs testing)

The ghostty C callbacks in `TerminalApp.init()` are the trickiest part.
They are `@convention(c)` function pointers that reconstruct Swift
objects via `Unmanaged`.

| Callback | Thread safety | Action needed |
|----------|---------------|---------------|
| `wakeup_cb` | Dispatches to main via `DispatchQueue.main.async` | Safe |
| `action_cb` | Called during `ghostty_app_tick` on main thread | Safe, but accesses `surfaceRegistry` |
| `read_clipboard_cb` | Accesses `NSPasteboard.general` directly | May need main dispatch |
| `write_clipboard_cb` | Accesses `NSPasteboard.general` directly | May need main dispatch |
| `close_surface_cb` | Dispatches to main via `DispatchQueue.main.async` | Safe |

C function pointers are exempt from most Swift concurrency checks,
but the `Unmanaged` reconstruction and subsequent method calls will
be flagged if the reconstructed type is `@MainActor`. Solutions:
- `MainActor.assumeIsolated` where we know we're on main
- `nonisolated(unsafe)` for the registry access
- Wrap clipboard callbacks in `DispatchQueue.main.async`

Estimated: 3-5 careful changes, needs manual testing.

## Other considerations

- `String: @retroactive Identifiable` and `UUID: @retroactive Identifiable`
  in PathUtilities.swift: Swift 6 warns more aggressively about retroactive
  conformances. These may need `@retroactive` annotation (already present).

- `@AppStorage` in views: these are `@MainActor`-isolated, no issue.

- `NotificationCenter.default.post` calls: main-thread-only by convention.
  If the posting type is `@MainActor`, these are fine.

- `DispatchQueue.main.async/asyncAfter` patterns: compile under strict
  concurrency but may generate warnings about capturing self.

## Effort estimate

| Phase | Effort | Risk |
|-------|--------|------|
| Phase 1: Sendable | 2 hours | Low |
| Phase 2: MainActor | 1 hour | Low |
| Phase 3: Task closures | 3 hours | Medium |
| Phase 4: C callbacks | 4 hours | High |
| Testing | 2 hours | - |
| **Total** | **~1.5 days** | |

## Recommendation

Do this after the first release. The codebase is small (31 Swift files)
so it won't get harder over time. Enable `SWIFT_STRICT_CONCURRENCY = complete`
as a build setting first to see all warnings without hard errors, then
fix them incrementally.
