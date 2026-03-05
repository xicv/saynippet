#!/bin/bash
# Install starter snippets to ~/.claude/snippets/
SNIPPETS_DIR="${1:-$HOME/.claude/snippets}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$SNIPPETS_DIR"

for f in "$SCRIPT_DIR"/examples/*.md; do
  name=$(basename "$f")
  if [ ! -f "$SNIPPETS_DIR/$name" ]; then
    cp "$f" "$SNIPPETS_DIR/$name"
    echo "Installed: $name"
  else
    echo "Skipped (exists): $name"
  fi
done

echo "Done. $(ls "$SNIPPETS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') snippets total."
