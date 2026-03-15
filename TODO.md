# TODO

## Pre-release
- [ ] Choose final app name (currently "ff2" is a working name)
- [ ] Update bundle ID (`com.ff2.app` in project.yml)
- [ ] Update URL scheme (`ff2://` in Info.plist) to match final name
- [ ] Build and ship a standalone CLI binary (like `code` for VS Code)
- [ ] Code signing and notarization for distribution
- [ ] App icon
- [ ] Credits: Poblenou skyline from alltuner.com, All Tuner Labs logo

## Features
- [ ] Sidebar visual polish (custom styling beyond default SwiftUI)
- [ ] Split panes within a workstream
- [ ] Reorder projects via drag-and-drop in sidebar
- [ ] External Chrome integration: launch Chrome with --remote-debugging-port, connect via CDP for WebMCP/Claude browser interaction
- [ ] Setup scripts: run commands when a worktree is created (e.g., npm install, pip install)
- [ ] Run scripts: configurable ways to start dev servers, build, or run the app (multiple per project)
- [ ] Teardown scripts: cleanup commands when archiving a workstream
- [ ] PR management: create and manage PRs from workstreams (currently view-only)
- [ ] Archive warning: warn if worktree has uncommitted changes
- [ ] Workstream sorting in project view (by name or recent use)
- [ ] Extract env var injection logic to a shared module

## Terminal
- [ ] Sidebar toggle animation still causes minor flicker at the end
- [ ] Occlude non-visible terminal surfaces to save GPU (reverted, needs careful timing with initial render)

## Infrastructure
- [ ] Auto-update mechanism (Sparkle or similar)
- [ ] Crash reporting
- [ ] Move persistence from UserDefaults to a proper file (for larger state)

## Localization
- [ ] Add more translations (copy en.lproj to xx.lproj, translate strings)

## Done
- [x] Embedded Ghostty terminals (Metal GPU-rendered)
- [x] Project and workstream management with sidebar tree
- [x] Git worktrees for workstreams (branch off default branch)
- [x] .env/.env.local symlinks in worktrees
- [x] Tmux mode for session persistence across app restarts
- [x] Claude session resume via --session-id/--resume
- [x] Auto-respawn on process exit (tmux hook)
- [x] Auto-rename branch via system prompt injection
- [x] Per-workstream permission mode (bypass prompts)
- [x] Agent Teams setting (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
- [x] --teammate-mode tmux flag
- [x] Deterministic port allocation per workstream (FF_PORT)
- [x] Four workstream tabs: Info, Coding Agent, Terminal, Browser
- [x] Embedded WKWebView browser with nav bar
- [x] Info tab with rendered README.md and CLAUDE.md (MarkdownView SPM)
- [x] GitHub integration: repo info, open PRs, branch PR status
- [x] Context-sensitive Cmd+0-9 shortcuts
- [x] Cmd+Shift+[/] tab cycling
- [x] Cmd+Shift+O external browser, Cmd+Shift+E external terminal
- [x] Help view with grouped shortcuts and credits
- [x] Settings: environment detection, tmux, bypass, teams, auto-rename, appearance, language, base dir, branch prefix, external apps
- [x] Danger zone: clear project list
- [x] Project overview with editable alias, git/GitHub info, workstream cards
- [x] Drag-and-drop directories to sidebar
- [x] ff2:// URL scheme for single-instance behavior
- [x] CLI launch with directory argument
- [x] Auto-generated workstream names (operation-adjective-component)
- [x] Async git repo info, path validity, GitHub data
- [x] Auto-remove projects with missing directories
- [x] Localization: en, ca, es, sv
- [x] Performance: cached sorted IDs, O(1) lookups, debounced saves, deferred init
- [x] Terminal resize flicker fix
- [x] CommandBuilder for clean shell command composition

## Probably not needed
- [ ] Claude Agent SDK integration (TypeScript): CLI + tmux + session-id covers our needs
