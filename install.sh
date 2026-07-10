#!/usr/bin/env bash
set -euo pipefail

install_codex=0
install_claude=0
dry_run=0

if test "$#" -eq 0; then
  install_codex=1
  install_claude=1
fi

while test "$#" -gt 0; do
  case "$1" in
    --all) install_codex=1; install_claude=1 ;;
    --codex) install_codex=1 ;;
    --claude) install_claude=1 ;;
    --dry-run) dry_run=1 ;;
    --help)
      echo 'Usage: install.sh [--all|--codex|--claude] [--dry-run]'
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if test "$install_codex" -eq 0 && test "$install_claude" -eq 0; then
  install_codex=1
  install_claude=1
fi

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
canonical="${AGENT_SKILLS_HOME:-$HOME/.local/share/agent-skills}/orchestrating-subagents"
start='<!-- orchestrating-subagents:start -->'
end='<!-- orchestrating-subagents:end -->'

say() { printf '%s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

copy_canonical() {
  if test "$dry_run" -eq 1; then
    say "Would install canonical skill at $canonical"
    return
  fi

  parent="$(dirname "$canonical")"
  mkdir -p "$parent"
  if test "$source_dir" = "$canonical"; then
    return
  fi

  stage="$(mktemp -d "$parent/.orchestrating-subagents.XXXXXX")"
  mkdir -p "$stage/adapters"
  cp "$source_dir/SKILL.md" "$stage/SKILL.md"
  cp "$source_dir/install.sh" "$stage/install.sh"
  cp -R "$source_dir/adapters/." "$stage/adapters/"
  printf '%s\n' 'managed by orchestrating-subagents installer' > "$stage/.orchestrating-subagents-managed"

  if test -e "$canonical" || test -L "$canonical"; then
    if test ! -d "$canonical" || test ! -f "$canonical/.orchestrating-subagents-managed"; then
      rm -rf "$stage"
      fail "refusing to replace unrecognized canonical path: $canonical"
    fi

    previous="$(mktemp -d "$parent/.orchestrating-subagents.previous.XXXXXX")"
    rmdir "$previous"
    mv "$canonical" "$previous"
    if mv "$stage" "$canonical"; then
      rm -rf "$previous"
    else
      mv "$previous" "$canonical"
      rm -rf "$stage"
      fail "could not replace canonical skill; previous installation restored"
    fi
  else
    mv "$stage" "$canonical"
  fi
}

link_skill() {
  target="$1"
  if test "$dry_run" -eq 1; then
    say "Would link $target -> $canonical"
    return
  fi

  mkdir -p "$(dirname "$target")"
  if test -L "$target" && test "$(readlink "$target")" = "$canonical"; then
    return
  fi

  if test -e "$target" || test -L "$target"; then
    backup="$target.orchestrating-subagents.bak"
    if test ! -e "$backup" && test ! -L "$backup"; then
      mv "$target" "$backup"
    else
      fail "refusing to replace occupied skill target because backup already exists: $target"
    fi
  fi
  ln -s "$canonical" "$target"
}

validate_legacy_bootstrap() {
  file="$1"
  if test ! -e "$file" && test ! -L "$file"; then
    return
  fi

  start_count=0
  end_count=0
  if test -f "$file" || test -L "$file"; then
    start_count="$(grep -Fxc "$start" "$file" || true)"
    end_count="$(grep -Fxc "$end" "$file" || true)"
  fi
  if test "$start_count" -ne "$end_count" || test "$start_count" -gt 1; then
    fail "malformed orchestrating-subagents marker block in $file"
  fi
  if test "$start_count" -eq 1 && ! awk -v start="$start" -v end="$end" '
    $0 == start { start_line=NR }
    $0 == end { end_line=NR }
    END { exit !(start_line > 0 && end_line > start_line) }
  ' "$file"; then
    fail "malformed orchestrating-subagents marker order in $file"
  fi
  if test "$start_count" -eq 0; then
    return
  fi
  if test -L "$file"; then
    fail "refusing to remove legacy bootstrap block through symlink-managed instruction file: $file"
  fi
}

remove_legacy_bootstrap() {
  file="$1"
  validate_legacy_bootstrap "$file"
  if test ! -f "$file" || ! grep -Fqx "$start" "$file"; then
    return
  fi
  if test "$dry_run" -eq 1; then
    say "Would remove legacy orchestrating-subagents bootstrap block from $file"
    return
  fi

  directory="$(dirname "$file")"
  new="$(mktemp "$directory/.orchestrating-subagents.XXXXXX")"
  cp -p "$file" "$new"

  awk -v start="$start" -v end="$end" '
    $0 == start {
      skipping=1
      next
    }
    skipping && $0 == end { skipping=0; next }
    skipping { next }
    { print }
  ' "$file" > "$new"

  backup="$file.orchestrating-subagents.bak"
  suffix=1
  while test -e "$backup" || test -L "$backup"; do
    backup="$file.orchestrating-subagents.bak.$suffix"
    suffix=$((suffix + 1))
  done
  cp -p "$file" "$backup"
  mv "$new" "$file"
}

if test "$install_codex" -eq 1; then
  validate_legacy_bootstrap "$HOME/.codex/AGENTS.md"
fi
if test "$install_claude" -eq 1; then
  validate_legacy_bootstrap "$HOME/.claude/CLAUDE.md"
fi

copy_canonical

if test "$install_codex" -eq 1; then
  link_skill "$HOME/.agents/skills/orchestrating-subagents"
  remove_legacy_bootstrap "$HOME/.codex/AGENTS.md"
  if test "$dry_run" -eq 0 && ! command -v codex >/dev/null 2>&1; then
    say 'Warning: codex executable not found; files were installed.' >&2
  fi
fi

if test "$install_claude" -eq 1; then
  link_skill "$HOME/.claude/skills/orchestrating-subagents"
  remove_legacy_bootstrap "$HOME/.claude/CLAUDE.md"
  if test "$dry_run" -eq 0 && ! command -v claude >/dev/null 2>&1; then
    say 'Warning: claude executable not found; files were installed.' >&2
  fi
fi

if test "$dry_run" -eq 1; then
  say 'orchestrating-subagents dry run complete; no files changed'
else
  say 'orchestrating-subagents installation complete'
fi
