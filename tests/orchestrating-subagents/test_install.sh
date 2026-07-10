#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
INSTALL="$ROOT/scripts/install.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
skills="$TMP/agent-skills-home"

home="$TMP/home"
mkdir -p "$home/.codex" "$home/.claude"
printf '%s\n' '# existing codex rule' > "$home/.codex/AGENTS.md"
printf '%s\n' '# existing claude rule' > "$home/.claude/CLAUDE.md"

HOME="$home" AGENT_SKILLS_HOME="$skills" bash "$INSTALL" --all

canonical="$skills/orchestrating-subagents"
test -f "$canonical/SKILL.md"
test "$(readlink "$home/.agents/skills/orchestrating-subagents")" = "$canonical"
test "$(readlink "$home/.claude/skills/orchestrating-subagents")" = "$canonical"
grep -q '# existing codex rule' "$home/.codex/AGENTS.md"
grep -q '# existing claude rule' "$home/.claude/CLAUDE.md"
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.codex/AGENTS.md")" -eq 1
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.claude/CLAUDE.md")" -eq 1
test -f "$home/.codex/AGENTS.md.orchestrating-subagents.bak"
test -f "$home/.claude/CLAUDE.md.orchestrating-subagents.bak"

snapshot="$TMP/snapshot"
cp -R "$canonical" "$snapshot"
cp "$home/.codex/AGENTS.md" "$TMP/codex-agents.after-first"
cp "$home/.claude/CLAUDE.md" "$TMP/claude-instructions.after-first"
cp "$home/.codex/AGENTS.md.orchestrating-subagents.bak" "$TMP/codex-backup.after-first"
cp "$home/.claude/CLAUDE.md.orchestrating-subagents.bak" "$TMP/claude-backup.after-first"

HOME="$home" AGENT_SKILLS_HOME="$skills" bash "$INSTALL" --all
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.codex/AGENTS.md")" -eq 1
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.claude/CLAUDE.md")" -eq 1
diff -r "$snapshot" "$canonical"
cmp "$TMP/codex-agents.after-first" "$home/.codex/AGENTS.md"
cmp "$TMP/claude-instructions.after-first" "$home/.claude/CLAUDE.md"
cmp "$TMP/codex-backup.after-first" "$home/.codex/AGENTS.md.orchestrating-subagents.bak"
cmp "$TMP/claude-backup.after-first" "$home/.claude/CLAUDE.md.orchestrating-subagents.bak"

dry="$TMP/dry"
mkdir -p "$dry"
dry_skills="$TMP/dry-skills"
HOME="$dry" AGENT_SKILLS_HOME="$dry_skills" bash "$INSTALL" --all --dry-run
test ! -e "$dry_skills/orchestrating-subagents"
test ! -e "$dry/.agents/skills/orchestrating-subagents"
test ! -e "$dry/.claude/skills/orchestrating-subagents"

codex="$TMP/codex"
mkdir -p "$codex"
HOME="$codex" AGENT_SKILLS_HOME="$TMP/codex-skills" bash "$INSTALL" --codex
test -L "$codex/.agents/skills/orchestrating-subagents"
test ! -e "$codex/.claude/skills/orchestrating-subagents"

unknown="$TMP/unknown"
unknown_skills="$TMP/unknown-skills"
mkdir -p "$unknown" "$unknown_skills/orchestrating-subagents"
printf sentinel > "$unknown_skills/orchestrating-subagents/user-data"
if HOME="$unknown" AGENT_SKILLS_HOME="$unknown_skills" bash "$INSTALL" --codex; then
  echo 'unknown canonical directory should block installation' >&2
  exit 1
fi
test "$(cat "$unknown_skills/orchestrating-subagents/user-data")" = sentinel

collision="$TMP/collision"
collision_skills="$TMP/collision-skills"
mkdir -p "$collision"
HOME="$collision" AGENT_SKILLS_HOME="$collision_skills" bash "$INSTALL" --codex
collision_target="$collision/.agents/skills/orchestrating-subagents"
rm "$collision_target"
mkdir -p "$collision_target"
printf sentinel > "$collision_target/user-data"
mkdir -p "$collision_target.orchestrating-subagents.bak"
printf older > "$collision_target.orchestrating-subagents.bak/user-data"
if HOME="$collision" AGENT_SKILLS_HOME="$collision_skills" bash "$INSTALL" --codex; then
  echo 'occupied skill target with existing backup should block installation' >&2
  exit 1
fi
test "$(cat "$collision_target/user-data")" = sentinel
test "$(cat "$collision_target.orchestrating-subagents.bak/user-data")" = older

malformed="$TMP/malformed"
malformed_skills="$TMP/malformed-skills"
mkdir -p "$malformed/.codex"
printf '%s\n%s\n' '<!-- orchestrating-subagents:start -->' 'keep this line' > "$malformed/.codex/AGENTS.md"
cp "$malformed/.codex/AGENTS.md" "$TMP/malformed.before"
if HOME="$malformed" AGENT_SKILLS_HOME="$malformed_skills" bash "$INSTALL" --codex; then
  echo 'malformed marker block should block instruction update' >&2
  exit 1
fi
cmp "$TMP/malformed.before" "$malformed/.codex/AGENTS.md"

linked="$TMP/linked"
linked_skills="$TMP/linked-skills"
mkdir -p "$linked/.codex" "$linked/dotfiles"
printf '%s\n' '# managed elsewhere' > "$linked/dotfiles/AGENTS.md"
ln -s "$linked/dotfiles/AGENTS.md" "$linked/.codex/AGENTS.md"
if HOME="$linked" AGENT_SKILLS_HOME="$linked_skills" bash "$INSTALL" --codex; then
  echo 'symlink-managed instruction file should block instruction update' >&2
  exit 1
fi
test -L "$linked/.codex/AGENTS.md"
grep -q '# managed elsewhere' "$linked/dotfiles/AGENTS.md"

echo 'install: PASS'
