# TODO

## Website

- [ ] Take app screenshots for the website (workspace view, sidebar, terminal, environment tab)

## Future

- [ ] Swift 6 migration (strict concurrency) - scoped in docs/swift6-migration.md
- [ ] External Chrome integration: launch with --remote-debugging-port for WebMCP/CDP
- [ ] PR management: create and manage PRs from workstreams (currently view-only)
- [ ] Auto-update mechanism (Sparkle or similar) - strategy in docs/distribution-strategy.md
- [ ] Crash reporting
- [ ] Horizontal terminal splits within a tab (ghostty C API supports splits via action_cb, but surface lifecycle needs investigation)
- [ ] Drag-and-drop to reorder tabs
- [ ] System notifications when agent needs attention (bell/urgency from Ghostty)
- [ ] Restore full app state on launch (active tab within workstream; sidebar selection and expanded state already persisted)

## Done

- [x] Embedded Ghostty terminals (Metal GPU-rendered via libghostty)
- [x] Project and workstream management with sidebar tree
- [x] Git worktrees for workstreams (branch off default branch)
- [x] .env/.env.local symlinks in worktrees (guarded by setting)
- [x] Tmux mode for Coding Agent session persistence
- [x] Claude session resume via --session-id/--resume
- [x] Auto-respawn agent on process exit (tmux pane-died hook)
- [x] Auto-rename branch via --append-system-prompt
- [x] Per-workstream permission mode (bypass prompts, context menu on +)
- [x] Agent Teams setting (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
- [x] Deterministic port allocation per workstream (FF_PORT env var, DJB2 hash)
- [x] Dynamic workspace tabs (Info + Agent + Environment, Terminal/Browser on demand)
- [x] Terminal tabs auto-close on shell exit, agent respawns
- [x] Multi-terminal support with proper Ghostty focus management
- [x] Embedded WKWebView browser with nav bar, loading indicator
- [x] Cmd+L address bar focus, auto-focus on new browser
- [x] PR badge in workspace toolbar (links to GitHub PR)
- [x] Info tab with README.md, CLAUDE.md, AGENTS.md (cmark-gfm WKWebView, skip files < 20 bytes)
- [x] GitHub integration: repo info, open PRs, branch PR status (via gh CLI)
- [x] Keyboard shortcuts: Cmd+Return (agent), Cmd+I (info), Cmd+E (environment), Cmd+T (terminal), Cmd+B (browser), Cmd+W (close tab), Cmd+1-9 (switch tabs), Ctrl+1-9 (switch workstreams), Cmd+Shift+[/] (cycle), Cmd+/ (help)
- [x] Cmd+Shift+O external browser, Cmd+Shift+E external terminal
- [x] Ctrl+Cmd+S sidebar toggle, Esc closes settings/help
- [x] Cmd+W closes tab (overrides macOS window close)
- [x] Help view with app icon, skyline, shortcuts, credits, sponsor link
- [x] Settings: environment, CLI install, tmux, bypass, teams, auto-rename, appearance, language, base dir, branch prefix, external apps (with icons), bleeding edge, danger zone
- [x] Project overview with editable name, centered header, directory with copy/terminal icons, git info, GitHub info, worktree list with prune
- [x] Workstream info with pinned header (project icon, name, branch with copy, directory), PR status, scripts, scrollable docs
- [x] Drag-and-drop directories to sidebar
- [x] factoryfloor:// URL scheme for single-instance behavior
- [x] CLI launcher (ff) with install from Settings, sponsor message
- [x] Auto-generated workstream names (operation-adjective-component)
- [x] Workstream name syncs from branch rename (every 15s)
- [x] Sidebar state persisted across restarts (selection + expanded)
- [x] Async git repo info, path validity, branch names with periodic refresh (parallelized via TaskGroup)
- [x] Auto-remove projects with missing directories (with user notification)
- [x] Worktree path validation with visual feedback
- [x] Archive warning for uncommitted changes
- [x] Workstream sorting in project view (recent / A-Z)
- [x] Sidebar branch names per workstream
- [x] Sidebar credit line with sponsor link
- [x] Localization: en, ca, es, sv (all strings translated, native-quality website copy)
- [x] Script config: .factoryfloor.json / .factoryfloor/config.json
- [x] Environment tab: split-pane setup (auto) / run (on-demand) with re-execute buttons
- [x] Preload agent and setup terminals in background on workstream open
- [x] Occlude non-visible terminal surfaces to save GPU (ghostty_surface_set_occlusion)
- [x] Teardown script runs before worktree removal on archive
- [x] CommandBuilder with proper shell quoting (25 tests)
- [x] App icon with Poblenou skyline
- [x] Project icon detection (icon.svg, icon.png, logo.svg, logo.png in root or .github/)
- [x] Rename to Factory Floor (bundle ID, URL scheme, config, all references)
- [x] Ghostty submodule pinned to v1.3.1, weekly CI compatibility test
- [x] Bridging header moved to Resources/
- [x] Code signing and notarization (scripts/release.sh)
- [x] Release-please for automated versioning
- [x] MIT license
- [x] README with marketing-first layout, credits, support section
- [x] Website: Hugo + Tailwind, i18n (4 languages), language switcher, skyline, sponsor page (translated), open source section, Umami analytics, canonical/hreflang SEO, privacy policy, favicon, OG image
- [x] GitHub Pages deploy workflow
- [x] GitHub repo (alltuner/factoryfloor, public, topics, description)
- [x] Distribution guide (docs/distribution.md) with release routine
- [x] Distribution strategy (docs/distribution-strategy.md)
- [x] Debug builds: different icon and bundle ID so debug/release can run in parallel
- [x] Confirm before quit (Cmd+Q) with setting to disable
- [x] Browser tab: show page title in tab label
- [x] Terminal tab: show running command in tab label (via ghostty SET_TITLE action)
- [x] Homebrew tap (alltuner/homebrew-tap) and cask formula
- [x] CI: automate build, sign, notarize, DMG, upload, Homebrew cask update (per-job permissions, keychain profile)
- [x] CONTRIBUTING.md, CODE_OF_CONDUCT.md
- [x] Funding: Buy Me a Coffee, GitHub Sponsors (website + FUNDING.yml + CLI message)
- [x] Onboarding view with prerequisites, getting started, key concepts
- [x] Move persistence from UserDefaults to JSON files (~/.config/factoryfloor/) with auto-migration
- [x] Security: disable JS in markdown WKWebView, restrict browser to http/https, fix AppleScript injection, fix PortAllocator hash stability, shell-escape tmux commands, deinit race fix, git flag injection, .env symlink validation
- [x] Accessibility: labels on all interactive elements, focus rings (.borderless), hover-only actions visible via opacity
- [x] Code quality: deduplicated abbreviatePath, performArchive, dead code removal, parallelized git calls, cached claudeCommand/projectIndex, consolidated polling timers, FilePersistence error propagation, derivedUUID/Identifiable in PathUtilities
- [x] Error feedback: worktree creation, non-git directory, ghostty init, project removal notification, Claude not found banner
