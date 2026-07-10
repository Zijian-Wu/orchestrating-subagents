#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SKILL="$ROOT"

test -f "$SKILL/SKILL.md"

grep -qx 'name: orchestrating-subagents' "$SKILL/SKILL.md"
grep -q '^description: Use when ' "$SKILL/SKILL.md"
grep -q 'delegation check' "$SKILL/SKILL.md"
grep -q 'nested_delegation' "$SKILL/SKILL.md"
grep -q 'independent reviewer' "$SKILL/SKILL.md"
grep -q 'ownership: read-only' "$SKILL/SKILL.md"
grep -q 'references/codex.md' "$SKILL/SKILL.md"
grep -q 'references/claude-code.md' "$SKILL/SKILL.md"

if grep -Eq '^(context:|agent:|allowed-tools:|disable-model-invocation:)' "$SKILL/SKILL.md"; then
  echo 'Claude-only frontmatter found in portable SKILL.md' >&2
  exit 1
fi

frontmatter_chars="$(awk 'BEGIN{n=0; d=0} NR==1 && $0=="---"{d=1; next} d && $0=="---"{print n; exit} d{n+=length($0)+1}' "$SKILL/SKILL.md")"
test "$frontmatter_chars" -le 1024

validator="${SKILL_VALIDATOR:-/root/.codex/skills/oai/skill-creator/scripts/quick_validate.py}"
if test -f "$validator"; then
  python3 "$validator" "$SKILL"
fi

test -f "$SKILL/references/codex.md"
test -f "$SKILL/references/claude-code.md"
grep -q 'spawn_agent' "$SKILL/references/codex.md"
grep -q 'multi_agent = true' "$SKILL/references/codex.md"
grep -q 'Agent tool' "$SKILL/references/claude-code.md"
grep -q 'SendMessage' "$SKILL/references/claude-code.md"
grep -q 'Do not add `context: fork`' "$SKILL/references/claude-code.md"
test -f "$SKILL/scripts/install.sh"

echo 'structure: PASS'
