#!/usr/bin/env bash
# Install all skills from this repo into ~/.claude/skills/
# Run: ./setup.sh
# Re-run any time to pick up changes.

set -e

SKILLS_DIR="$HOME/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing skills from $REPO_DIR → $SKILLS_DIR"

for skill_dir in "$REPO_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  src="$skill_dir/SKILL.md"

  # Skip non-skill directories (no SKILL.md)
  [ -f "$src" ] || continue

  dest="$SKILLS_DIR/$skill_name"
  mkdir -p "$dest"
  cp "$src" "$dest/SKILL.md"
  echo "  ✓ $skill_name"
done

echo "Done. Restart Claude Code to pick up new skills."
