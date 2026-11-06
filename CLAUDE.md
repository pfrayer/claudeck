# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Read-only local web view of Claude Code sessions (`~/.claude/projects/*/*.jsonl`), grouped as a tree by working directory (`cwd`). Zero dependencies: Python 3 stdlib on the server, vanilla HTML/CSS/JS in a single file on the client. No build, no tests, no linter configured. Everything (code, comments, UI, docs) is in English.

## Commands

```bash
# Run in dev (opens a browser; --port or $CC_SESSIONS_WEB_PORT, default 8765)
./src/cc-sessions-web --port 8766

# User install: symlink ~/bin/cc-sessions-web -> src/, systemd --user unit, ~/.config/cc-sessions-web/env
./scripts/install.sh
./scripts/uninstall.sh          # keeps ~/.config/cc-sessions-web/env

# Installed service
systemctl --user restart cc-sessions-web.service
journalctl --user -u cc-sessions-web.service -f

# Check the API
curl -s localhost:8765/api/sessions | python3 -m json.tool | head
curl -s localhost:8765/api/session/<uuid>
```

A project PostToolUse hook (`.claude/hooks/check-syntax.sh`) syntax-checks `src/cc-sessions-web` and the page's `<script>` block after every Edit/Write and reports errors with HTML line numbers.

The installed service runs `src/cc-sessions-web` straight through the symlink: Python changes need a `restart`, but `src/cc-sessions-web.html` is re-read on every request (just reload the browser). To test without disturbing the service on 8765, run a dev instance on another port.

## Architecture

**`src/cc-sessions-web`** (Python script, no extension) — `ThreadingHTTPServer` bound to `127.0.0.1` only, with a `Host` header check (DNS-rebinding guard: only `localhost`/`127.0.0.1` accepted). Three routes:
- `/` → serves `cc-sessions-web.html` (sibling file resolved via `__file__`, so it works through the `~/bin` symlink).
- `/api/sessions` → `{home, sessions}`: metadata for each `*.jsonl` whose name is a UUID. `scan_file` reads the whole file; results are cached in memory per path and invalidated on `mtime`. Sessions with no real user prompt are excluded.
- `/api/session/<uuid>` → simplified transcript `[{role, text, ts}]` (text truncated to 4000 chars), assistant tool calls summarized as `→ Tool hint` lines.

Claude Code JSONL filtering rules (shared by `scan_file` and `transcript`): skip `isSidechain`, `isMeta`, and "noise" texts (`<command-…`, `<local-command`, `<system-reminder`, `Caveat:`) via `_is_noise`. Title = `ai-title`, else `summary`. Format changes are handled in `_text_of` / `_is_noise` / `scan_file`.

**`src/cc-sessions-web.html`** — single page, hand-compacted JS in one `<script>` block (dense style, roughly one function per line). Key points:
- `buildTree` builds the `cwd` tree (relative to `HOME`), collapses single-child folder chains, computes totals / last activity / "live" state (`LIVE_S` = 120 s).
- `assignHues` gives one hue per folder group; `hueOf` resolves the hue of the longest matching prefix.
- Search (`matches`) covers cwd + title + `prompts` (truncated prompt concatenation sent by the server) + branch; `highlight` marks hits in the open transcript.
- Navigation state lives in the URL hash (`p` folder, `s` session, `q` search) via `syncHash`; the only persisted preference is `localStorage["ccs-tools"]`.
- `load()` re-polls `/api/sessions` every 30 s while the tab is visible.
- The session pane offers the resume command `cd <cwd> && claude --resume <id>`.
- Dates are formatted with the `LOCALE` constant (`en-US`).
- Shortcuts: `/` focuses search, `Esc` clears it, `Enter` / `Shift+Enter` cycle matches.

**`config/` + `scripts/`** — systemd user unit (`--no-browser`, port via `EnvironmentFile` `~/.config/cc-sessions-web/env`) and install/uninstall scripts.

## Constraints to preserve

- Stay read-only on `~/.claude/projects` and dependency-free (no pip, no CDN).
- Never widen listening beyond `127.0.0.1` nor relax `_host_ok`: transcripts contain sensitive data.
- Port must stay within 1024–65535 (`port_arg`).
