#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): syntax-check the server script and the page's inline JS.
# On failure, exits 2 so the error is fed back to Claude. Silent on success and for any other file.
set -uo pipefail

f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

case "$f" in
  "$root/src/claudeck")
    # ast.parse instead of py_compile: same check, no __pycache__ left behind
    out=$(python3 -c '
import ast, sys
try:
    ast.parse(open(sys.argv[1]).read(), sys.argv[1])
except SyntaxError as e:
    print(f"{e.filename}:{e.lineno}:{e.offset}: {e.msg}\n  {(e.text or "").rstrip()}")
' "$f" 2>&1)
    ;;
  "$root/src/claudeck.html")
    tmp=$(mktemp --suffix=.js)
    trap 'rm -f "$tmp"' EXIT
    # Keep every inline <script> block, blank out the rest but keep its newlines,
    # so node's line numbers match the HTML file
    python3 -c '
import re, sys
s = open(sys.argv[1]).read()
out, pos = [], 0
for m in re.finditer(r"<script>(.*?)</script>", s, re.S):
    out.append("\n" * s[pos:m.start(1)].count("\n"))
    out.append(m[1])
    pos = m.end(1)
sys.stdout.write("".join(out))
' "$f" >"$tmp"
    out=$(node --check "$tmp" 2>&1)
    out=${out//$tmp/$f}
    ;;
  *)
    exit 0
    ;;
esac

if [ -n "$out" ]; then
  printf 'Syntax check failed for %s:\n%s\n' "$f" "$out" >&2
  exit 2
fi
