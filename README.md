# Claudeck

*Your Claude Code sessions, as a deck you can flip through.*

A local, read-only web view of your Claude Code sessions, organized as a tree of the folders you worked in.

- Browse sessions by folder, with the most recently active ones first and a live indicator on sessions that are still running
- Search folder paths, titles, branches and your prompts, with highlighted matches in the transcript
- Read transcripts with tool calls folded away
- Copy the `claude --resume` command for any session

It reads `~/.claude/projects` and never writes to it. The server listens on `127.0.0.1` only.

## Quick try

Needs Python 3.9+ and nothing else (no pip install). Works on Linux and macOS.

```bash
git clone <repo-url> claudeck
./claudeck/src/claudeck     # opens http://localhost:8765/ in your browser
```

Options: `--port 9000` (or `$CLAUDECK_PORT`), `--no-browser`.

## Install

```bash
./scripts/install.sh
```

- Links `~/.local/bin/claudeck`, so you can run `claudeck` from anywhere.
- On Linux with systemd, also installs and starts a user service, so the page is always up at http://localhost:8765/. To change its port, edit `~/.config/claudeck/env`, then run `systemctl --user restart claudeck`.
- Elsewhere (macOS…), no service is installed: just run `claudeck` when you need it.

`./scripts/uninstall.sh` removes the link and the service and keeps your config.

## Keyboard

| Key | Action |
| --- | --- |
| `/` | Focus search |
| `Esc` | Clear search |
| `Enter` / `Shift+Enter` | Next / previous match in the open transcript |
