# cc-sessions-web

A local, read-only web view of your Claude Code sessions, organized as a tree of the folders you worked in.

- Browse sessions by folder, with the most recently active ones first and a live indicator on sessions that are still running
- Search folder paths, titles, branches and your prompts, with highlighted matches in the transcript
- Read transcripts with tool calls folded away
- Copy the `claude --resume` command for any session

It reads `~/.claude/projects` and never writes to it. The server listens on `127.0.0.1` only.

## Requirements

Python 3.9+, nothing else. The systemd install assumes Linux with a user systemd instance.

## Run

```bash
./src/cc-sessions-web              # opens http://localhost:8765/
./src/cc-sessions-web --port 9000 --no-browser
```

Port: `--port`, else `$CC_SESSIONS_WEB_PORT`, else `8765`.

## Install as a user service

```bash
./scripts/install.sh     # symlinks ~/bin/cc-sessions-web, installs and starts a systemd --user unit
./scripts/uninstall.sh   # removes the unit and the symlink, keeps the config
```

To change the port, edit `~/.config/cc-sessions-web/env` and run `systemctl --user restart cc-sessions-web`.

## Keyboard

| Key | Action |
| --- | --- |
| `/` | Focus search |
| `Esc` | Clear search |
| `Enter` / `Shift+Enter` | Next / previous match in the open transcript |
