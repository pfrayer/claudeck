# Claudeck

*Your Claude Code sessions, as a deck you can flip through.*

A read-only web view of your [Claude Code](https://docs.claude.com/en/docs/claude-code) sessions, organized as a tree of the folders you worked in.

- Browse sessions by folder, most recently active first, with a live indicator on sessions still running
- Search whole conversations (your messages and slash commands, Claude's replies, tool calls, subagent runs, compaction summaries) plus folder paths, titles and branches, with highlighted matches in the transcript
- Read transcripts with tool calls folded away
- Copy the `claude --resume` command for any session

It only reads `~/.claude/projects` and never writes to it. No dependencies: a single Python 3 script and a single HTML page, nothing to `pip install`, no CDN.

## Requirements

- Python 3.9 or newer, available as `python3`
- Linux or macOS
- Claude Code sessions in `~/.claude/projects`

## Quick start

```bash
git clone https://github.com/pfrayer/claudeck.git
./claudeck/src/claudeck
```

Your browser opens http://localhost:8765/. Stop it with `Ctrl+C`.

Options:

| Flag | Variable | Default | Effect |
| --- | --- | --- | --- |
| `--port N` | `CLAUDECK_PORT` | `8765` | HTTP port (1024–65535) |
| `--no-browser` | | | Do not open a browser tab |
| `--bind ADDR` | `CLAUDECK_BIND` | `127.0.0.1` | Listen address, see [Remote access](#remote-access) |
| `--token T` | `CLAUDECK_TOKEN` | random | Access token when not on loopback |
| `--allowed-host H[,H]` | `CLAUDECK_ALLOWED_HOSTS` | any | Accepted `Host` names when not on loopback |

### Keep your history

By default, Claude Code deletes transcripts not touched for 30 days, and claudeck can only show what is still on disk. To keep them longer, set `cleanupPeriodDays` in `~/.claude/settings.json`:

```json
{
  "cleanupPeriodDays": 3650
}
```

## Install

```bash
./scripts/install.sh
```

- Links `~/.local/bin/claudeck`, so `claudeck` runs from anywhere (make sure `~/.local/bin` is in your `PATH`).
- On Linux with systemd, also installs and starts a user service, so the page is always up at http://localhost:8765/. Settings live in `~/.config/claudeck/env`; after editing it, run `systemctl --user restart claudeck`.
- Elsewhere (macOS…), no service is installed: run `claudeck` when you need it.

To remove it: `./scripts/uninstall.sh` (keeps `~/.config/claudeck/env`).

## Remote access

By default claudeck only listens on `127.0.0.1`. To reach it on a remote machine, for example a dev server behind a reverse proxy, listen on all interfaces:

```bash
claudeck --bind 0.0.0.0 --port 8765
```

Nothing to answer or confirm: a random token is generated, no browser is launched, and the URLs to open are printed:

```
claudeck listening on 0.0.0.0:8765 (token required, Ctrl+C to stop)
Open one of (the token is then kept in a cookie):
  http://devserver.example.com:8765/?token=0S78rxSEUeECZOLknAFsK2LE_7pmiTjg
  http://10.0.0.12:8765/?token=0S78rxSEUeECZOLknAFsK2LE_7pmiTjg
  http://localhost:8765/?token=0S78rxSEUeECZOLknAFsK2LE_7pmiTjg
Token generated for this run; set $CLAUDECK_TOKEN to keep it across restarts.
```

Open one of them, or the same `/?token=…` path on your proxy's address, once. It sets an `HttpOnly` cookie (`Secure` when the proxy sends `X-Forwarded-Proto: https`) and redirects to `/`, so the token leaves the address bar. Scripts send a header instead:

```bash
curl -H "Authorization: Bearer $CLAUDECK_TOKEN" https://devserver.example.com/api/sessions
```

Good to know:

- Once bound outside loopback, every request needs the token, including from `localhost`.
- Without `--allowed-host`, any `Host` header is accepted and the token is the only guard. With it, only those names (plus `localhost`) are.
- A token must be at least 16 characters of `[A-Za-z0-9_-]`. Generate one with `python3 -c "import secrets; print(secrets.token_urlsafe(24))"`.
- The proxy must serve claudeck at the root of a host (the page calls `/api/...`); a sub-path such as `/claudeck/` does not work.
- With the systemd service, put `CLAUDECK_BIND` and a fixed `CLAUDECK_TOKEN` in `~/.config/claudeck/env`, `chmod 600` it, and restart. Otherwise the token changes on each restart (`journalctl --user -u claudeck` shows it).

## Privacy

Transcripts can contain anything Claude read or printed: code, file contents, command output, secrets. claudeck keeps everything on your machine and sends nothing anywhere. If you expose it, anyone with the token can read every transcript: keep the token private, and rotate it by changing `CLAUDECK_TOKEN` and restarting.

## Search

Type words to find the sessions that contain all of them, in any order, anywhere in the conversation, folder path, title or branch. Put `"quotes"` around words that must appear together as an exact phrase. Search ignores case, and every hit is highlighted in the open transcript.

| Query | Finds sessions containing |
| --- | --- |
| `uvicorn root` | both `uvicorn` and `root`, anywhere |
| `"root path" uvicorn` | the phrase `root path`, and `uvicorn` |

## Keyboard

| Key | Action |
| --- | --- |
| `/` | Focus search |
| `Esc` | Clear search |
| `Enter` / `Shift+Enter` | Next / previous match in the open transcript |

## License

[MIT](LICENSE). claudeck is an independent project, not affiliated with or endorsed by Anthropic.
