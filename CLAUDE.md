# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Read-only local web view of Claude Code sessions (`~/.claude/projects/*/*.jsonl`), grouped as a tree by working directory (`cwd`). Zero dependencies: Python 3 stdlib on the server, vanilla HTML/CSS/JS in a single file on the client. No build, no tests, no linter configured. Everything (code, comments, UI, docs) is in English.

## Commands

```bash
# Run in dev (opens a browser; --port or $CLAUDECK_PORT, default 8765)
./src/claudeck --port 8766

# User install: symlink ~/.local/bin/claudeck -> src/; if a systemd user session exists,
# also a systemd --user unit + ~/.config/claudeck/env (skipped cleanly on macOS)
./scripts/install.sh
./scripts/uninstall.sh          # keeps ~/.config/claudeck/env

# Installed service
systemctl --user restart claudeck.service
journalctl --user -u claudeck.service -f

# Check the API
curl -s localhost:8765/api/sessions | python3 -m json.tool | head
curl -s localhost:8765/api/session/<uuid>
```

A project PostToolUse hook (`.claude/hooks/check-syntax.sh`) syntax-checks `src/claudeck` and the page's `<script>` block after every Edit/Write and reports errors with HTML line numbers.

The installed service runs `src/claudeck` straight through the symlink: Python changes need a `restart`, but `src/claudeck.html` is re-read on every request (just reload the browser). To test without disturbing the service on 8765, run a dev instance on another port.

## Architecture

**`src/claudeck`** (Python script, no extension) — `ThreadingHTTPServer` bound to `127.0.0.1` by default (`--bind` / `$CLAUDECK_BIND`), with a `Host` header check (DNS-rebinding guard: `localhost`/`127.0.0.1` plus `--allowed-host` / `$CLAUDECK_ALLOWED_HOSTS`). A non-loopback bind requires a token (`--token` / `$CLAUDECK_TOKEN`, else random and printed): `/?token=` sets an HttpOnly cookie, or `Authorization: Bearer`. Three routes:
- `/` → serves `claudeck.html` (sibling file resolved via `__file__`, so it works through the `~/.local/bin` symlink).
- `/api/sessions` → `{home, sessions}`: metadata for each `*.jsonl` whose name is a UUID. `scan_file` reads the whole file; results are cached in memory per path and invalidated on `mtime`. Sessions with no real user prompt are excluded.
- `/api/session/<uuid>` → simplified transcript `[{role, text, ts}]` (text clipped by `_clip` to `MAX_MSG_CHARS` with a `[… N more characters not shown]` line the page styles), assistant tool calls summarized as `→ Tool hint` lines.

Claude Code JSONL filtering rules (shared by `scan_file` and `transcript`): skip `isSidechain`, `isMeta`, and "noise" texts (`<command-…`, `<local-command`, `<system-reminder`, `Caveat:`) via `_is_noise`. Title = `ai-title`, else `summary`. Format changes are handled in `_text_of` / `_is_noise` / `scan_file`.

**`src/claudeck.html`** — single page, hand-compacted JS in one `<script>` block (dense style, roughly one function per line). Key points:
- `buildTree` builds the `cwd` tree (relative to `HOME`), collapses single-child folder chains, computes totals / last activity / "live" state (`LIVE_S` = 120 s).
- `assignHues` picks the folder groups; each group's hue is `hashHue(path)` (FNV-1a of the `~`-relative path, no state), so a folder keeps its colour across reloads and machines. `hueOf` resolves the hue of the longest matching prefix.
- Search (`matches`) covers cwd + title + `prompts` (truncated prompt concatenation sent by the server) + branch; `highlight` marks hits in the open transcript.
- Navigation state lives in the URL hash (`p` folder, `s` session, `q` search) via `syncHash`.
- `load()` re-polls `/api/sessions` every 30 s while the tab is visible.
- The session pane offers the resume command `cd <cwd> && claude --resume <id>`.
- Dates are formatted with the `LOCALE` constant (`en-US`).
- Dark by default (the OS preference is deliberately ignored); the header button switches to a warm beige light theme via `data-theme="light"` on `<html>`, persisted in `localStorage["ccs-theme"]` and applied by a tiny `<head>` script before paint. Colours are `:root` tokens, including the `--hl-*` lightness values used by the per-folder hue tints. Never hardcode an `oklch()` lightness in a rule; add a token with both variants.
- Persisted preferences: `localStorage["ccs-tools"]` and `localStorage["ccs-theme"]` (prefix from the project's former name, cc-sessions-web; kept so existing preferences survive).
- Shortcuts: `/` focuses search, `Esc` clears it, `Enter` / `Shift+Enter` cycle matches.

**`config/` + `scripts/`** — systemd user unit (`--no-browser`, port via `EnvironmentFile` `~/.config/claudeck/env`) and install/uninstall scripts.

## Constraints to preserve

- Stay read-only on `~/.claude/projects` and dependency-free (no pip, no CDN).
- Default stays `127.0.0.1` with no token. Any non-loopback bind must keep the token mandatory, and `_host_ok` must only accept `localhost` plus explicit `--allowed-host` names: transcripts contain sensitive data.
- Port must stay within 1024–65535 (`port_arg`).
