# Port Detection for Run Scripts

## Goal

When the run script starts a dev server (e.g., `npm run dev`, `flask run`, `uvicorn`), detect the port it listens on and automatically point the embedded browser to it.

## Current State

- Each workstream gets a deterministic port via `FF_PORT` env var (40001-49999)
- The embedded browser defaults to `http://localhost:$FF_PORT/`
- Users are expected to configure their dev server to use `$FF_PORT`
- If the dev server uses a different port, the browser shows a connection error

## Proposed Feature

Monitor the run script's process for new listening TCP sockets. When a port opens, automatically update the browser URL or show a notification.

## Implementation Options

### Option 1: Poll `lsof` for the process tree

After the run script starts, periodically run:
```bash
lsof -iTCP -sTCP:LISTEN -P -n -a -p <pid>
```

This lists all TCP LISTEN sockets for the process. Parse the output for the port number.

**Pros:** Simple, no special permissions needed, works with any server.
**Cons:** Polling (every 1-2 seconds), needs the PID of the child process, `lsof` can be slow.

**Getting the PID:** Ghostty surfaces don't expose the child PID directly. We'd need to either:
- Parse `ps` output to find processes in the working directory
- Use the tmux session to get the pane PID (`tmux display -p -t session '#{pane_pid}'`)
- Track process groups started in the working directory

### Option 2: Monitor with `netstat` / `ss`

Similar to lsof but using `netstat -an -p tcp | grep LISTEN`.

**Pros:** Slightly faster than lsof.
**Cons:** Same PID issue, macOS `netstat` doesn't show PIDs.

### Option 3: Use `dtrace` / `libproc`

Use macOS's `proc_pidinfo` API (libproc) to enumerate file descriptors for a process and check for listening sockets.

```swift
import Darwin

func listeningPorts(for pid: pid_t) -> [UInt16] {
    // Use proc_pidinfo with PROC_PIDLISTFDS to get file descriptors
    // Filter for socket FDs, check if LISTEN state
}
```

**Pros:** No subprocess overhead, fast, native Swift.
**Cons:** Requires knowing the PID, needs to handle process trees (the server might be a grandchild of the shell).

### Option 4: Watch for port bind in the working directory

Instead of tracking a specific PID, scan all listening ports and match against the workstream's working directory by checking which process owns the socket and what its cwd is.

**Pros:** No need to know the PID upfront.
**Cons:** Expensive scan, false positives from other processes.

## Recommended Approach

**Option 1 (lsof polling) for v1, with Option 3 (libproc) as a future upgrade.**

### v1 Implementation Plan

1. **After the run script starts**, begin polling every 2 seconds
2. **Get the process tree** from the tmux session or by finding the shell PID:
   - With tmux: `tmux display -p -t <session> '#{pane_pid}'` gives the shell PID
   - Without tmux: track the ghostty surface's child PID (needs ghostty API investigation)
3. **Run lsof** to find LISTEN ports for the process and its children:
   ```bash
   lsof -iTCP -sTCP:LISTEN -P -n -a -g <pgid>
   ```
   (`-g` matches the process group, which catches child processes)
4. **Detect new ports**: compare against previous scan, identify newly opened ports
5. **Auto-navigate browser**: if a browser tab exists and shows an error or default URL, navigate to the detected port
6. **Show notification**: if no browser tab, show a small badge "Server running on port 3000" with a click-to-open action

### Files to modify

- `Sources/Models/PortDetector.swift` (new) - polling logic, lsof parsing
- `Sources/Views/EnvironmentTabView.swift` - trigger detection when run starts
- `Sources/Views/TerminalContainerView.swift` - receive detected port, update browser
- `Sources/Views/BrowserView.swift` - accept port navigation from outside

### Complexity estimate

- v1 (lsof polling): ~1 day
- v2 (libproc native): ~2 days (needs PID tracking infrastructure)

### Open questions

- Should we auto-open a browser tab when a port is detected, or just update an existing one?
- What if multiple ports are detected (e.g., API server + frontend)?
- Should the detected port override `FF_PORT` or be shown alongside it?
- How do we handle the case where the server takes a few seconds to start listening?
