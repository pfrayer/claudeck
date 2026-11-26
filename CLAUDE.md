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

**`src/claudeck`** (Python script, no extension) — `ThreadingHTTPServer` bound to `127.0.0.1` by default (`--bind` / `$CLAUDECK_BIND`), with a `Host` header check (DNS-rebinding guard: `localhost`/`127.0.0.1` plus `--allowed-host` / `$CLAUDECK_ALLOWED_HOSTS`). A non-loopback bind requires a token (`--token` / `$CLAUDECK_TOKEN`, else random) and prints ready-to-open URLs, no browser: `/?token=` sets an HttpOnly cookie, or `Authorization: Bearer`. In that mode, without `--allowed-host`, any `Host` is accepted (`ALLOWED_HOSTS = None`): the token is the guard. Four routes:
- `/` → serves `claudeck.html` (sibling file resolved via `__file__`, so it works through the `~/.local/bin` symlink).
- `/api/sessions` → `{home, sessions}`: metadata for each `*.jsonl` whose name is a UUID. `scan_file` reads the whole file and returns `(meta, text)`; both are cached in memory per path (`_entries`) and invalidated on `mtime`. Sessions with no real user prompt are excluded.
- `/api/search?q=` → ids of sessions containing every term of `q` (`terms_of`: words, or `"quoted phrases"` kept whole; lowercased substrings) in `text` + cwd + title + branch. `text` is exactly what `transcript` shows (user + assistant text + `→ Tool hint` lines), unclipped and lowercased: everything visible is searchable.
- `/api/session/<uuid>[?q=]` → simplified transcript `[{role, text, ts}]` (text clipped by `_clip` to `MAX_MSG_CHARS` with a `[… N more characters not shown]` line the page styles, except messages containing a term of `q`, kept whole so every hit can be highlighted), assistant tool calls summarized as `→ Tool hint` lines.

Claude Code JSONL filtering rules (shared by `scan_file` and `transcript`): skip `isSidechain`, `isMeta`, and "noise" texts (`<command-…`, `<local-command`, `<system-reminder`, `Caveat:`) via `_is_noise`, except slash commands typed with arguments, turned into `/name args` by `_command`. `isCompactSummary` user lines are role `summary` (searchable, not counted as prompts). Subagent runs live in `<project>/<session-id>/subagents/agent-*.jsonl` (+ `.meta.json`: `agentType`, `description`); `_subagent_msg` turns each into one role `agent` message, placed by start time; their mtimes count in the cache key. A session with a `continued-in` record is hidden when its continuation exists (the continuation holds a full copy). Title = `ai-title`, else `summary`. Format changes are handled in `_text_of` / `_is_noise` / `_command` / `scan_file`.

**`src/claudeck.html`** — single page, hand-compacted JS in one `<script>` block (dense style, roughly one function per line). Key points:
- `buildTree` builds the `cwd` tree (relative to `HOME`), collapses single-child folder chains, computes totals / last activity / "live" state (`LIVE_S` = 120 s).
- `assignHues` picks the folder groups; each group's hue is `hashHue(path)` (FNV-1a of the `~`-relative path, no state), so a folder keeps its colour across reloads and machines. `hueOf` resolves the hue of the longest matching prefix.
- Transcript roles: `user`, `assistant` (consecutive ones merged by `merge`), and folded `agent` / `summary` blocks (`.fold`, sharing the `.tools` fold styles).
- Search (`matches`): `terms()` mirrors the server's `terms_of` (keep both in sync); every term in cwd + title + branch is checked client-side instantly, OR'ed with full-text hits from `/api/search` (`search()`, debounced 250 ms, kept in `HITS` for query `HQ`); `loadThread` refetches the open transcript with `?q=` and `highlight` marks each term.
- Navigation state lives in the URL hash (`p` folder, `s` session, `q` search) via `syncHash`.
- `load()` re-polls `/api/sessions` every 30 s while the tab is visible.
- The session pane offers the resume command `cd <cwd> && claude --resume <id>`.
- Dates are formatted with the `LOCALE` constant (`en-US`).
- Dark by default (the OS preference is deliberately ignored); the header button switches to a warm beige light theme via `data-theme="light"` on `<html>`, persisted in `localStorage["ccs-theme"]` and applied by a tiny `<head>` script before paint. Colours are `:root` tokens, including the `--hl-*` lightness values used by the per-folder hue tints. Never hardcode an `oklch()` lightness in a rule; add a token with both variants.
- Persisted preferences: `localStorage["ccs-tools"]` and `localStorage["ccs-theme"]` (prefix from the project's former name, cc-sessions-web; kept so existing preferences survive).
- Shortcuts: `/` focuses search, `Esc` clears it, `Enter` / `Shift+Enter` cycle matches.

**`config/` + `scripts/`** — systemd user unit (`--no-browser`; port and remote-access settings via `EnvironmentFile` `~/.config/claudeck/env`) and install/uninstall scripts.

## Constraints to preserve

- Stay read-only on `~/.claude/projects` and dependency-free (no pip, no CDN).
- Default stays `127.0.0.1` with no token. Any non-loopback bind must keep the token mandatory, and `_host_ok` must only accept `localhost` plus explicit `--allowed-host` names (any `Host` only when exposed with a token and no allowlist): transcripts contain sensitive data.
- Port must stay within 1024–65535 (`port_arg`).
