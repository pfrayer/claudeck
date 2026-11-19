# Claudeck

*Your Claude Code sessions, as a deck you can flip through.*

A local, read-only web view of your Claude Code sessions, organized as a tree of the folders you worked in.

- Browse sessions by folder, with the most recently active ones first and a live indicator on sessions that are still running
- Search folder paths, titles, branches and your prompts, with highlighted matches in the transcript
- Read transcripts with tool calls folded away
- Copy the `claude --resume` command for any session

It reads `~/.claude/projects` and never writes to it. The server listens on `127.0.0.1` by default; it can also be [exposed behind a reverse proxy](#remote-access-reverse-proxy), with a token.

## Quick try

Needs Python 3.9+ and nothing else (no pip install). Works on Linux and macOS.

```bash
git clone https://github.com/pfrayer/claudeck.git
./claudeck/src/claudeck     # opens http://localhost:8765/ in your browser
```

Options: `--port 9000` (or `$CLAUDECK_PORT`), `--no-browser`, and `--bind` / `--token` / `--allowed-host` for [remote access](#remote-access-reverse-proxy).

## Install

```bash
./scripts/install.sh
```

- Links `~/.local/bin/claudeck`, so you can run `claudeck` from anywhere.
- On Linux with systemd, also installs and starts a user service, so the page is always up at http://localhost:8765/. To change its port, edit `~/.config/claudeck/env`, then run `systemctl --user restart claudeck`.
- Elsewhere (macOS…), no service is installed: just run `claudeck` when you need it.

`./scripts/uninstall.sh` removes the link and the service and keeps your config.

## Remote access (reverse proxy)

On a dev server reached through a reverse proxy, listen on all interfaces:

```bash
claudeck --bind 0.0.0.0 --port 8765
```

Nothing to answer or confirm: a random token is generated, no browser is launched, and the URLs to open are printed on stdout:

```
claudeck listening on 0.0.0.0:8765 (token required, Ctrl+C to stop)
Open one of (the token is then kept in a cookie):
  http://devserver.example.com:8765/?token=0S78rxSEUeECZOLknAFsK2LE_7pmiTjg
  http://10.0.0.12:8765/?token=0S78rxSEUeECZOLknAFsK2LE_7pmiTjg
  http://localhost:8765/?token=0S78rxSEUeECZOLknAFsK2LE_7pmiTjg
Token generated for this run; set $CLAUDECK_TOKEN to keep it across restarts.
```

Open one of them, or the same `/?token=…` path on your proxy's address, once: it sets an `HttpOnly` cookie (`Secure` when the proxy sends `X-Forwarded-Proto: https`) and redirects to `/`, so the token leaves the address bar. Scripts send `Authorization: Bearer <TOKEN>` instead:

```bash
curl -H "Authorization: Bearer $CLAUDECK_TOKEN" https://devserver.example.com/api/sessions
```

| Flag | Variable | Effect |
| --- | --- | --- |
| `--bind ADDR` | `CLAUDECK_BIND` | IPv4 address to listen on (default `127.0.0.1`). Any non-loopback address turns the token on and the browser off. |
| `--token T` | `CLAUDECK_TOKEN` | Fixed token, at least 16 characters of `[A-Za-z0-9_-]`. Without it, a new random token is generated on every start. |
| `--allowed-host H[,H]` | `CLAUDECK_ALLOWED_HOSTS` | Only accept these `Host` names (plus `localhost`). Without it, any `Host` is accepted in this mode and the token is the only guard. |

Good to know:

- Once bound outside loopback, every request needs the token, including from `localhost`.
- The proxy must serve claudeck at the root of a host (the page calls `/api/...`); a sub-path such as `/claudeck/` does not work.
- With the systemd service, put the settings in `~/.config/claudeck/env` with a fixed token, `chmod 600` that file, and restart. Otherwise the generated token changes on each restart (`journalctl --user -u claudeck` shows it).
- Generate a token with `python3 -c "import secrets; print(secrets.token_urlsafe(24))"`.
- There is no other authentication: anyone with the token reads every transcript. Keep it private, and rotate it by changing `CLAUDECK_TOKEN` and restarting.

## Keyboard

| Key | Action |
| --- | --- |
| `/` | Focus search |
| `Esc` | Clear search |
| `Enter` / `Shift+Enter` | Next / previous match in the open transcript |
