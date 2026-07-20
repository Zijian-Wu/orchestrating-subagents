#!/usr/bin/env bash
set -euo pipefail

dry_run=0
mode='install'

while test "$#" -gt 0; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --uninstall) mode='uninstall' ;;
    --help)
      echo 'Usage: install.sh [--dry-run] [--uninstall]'
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

script_source="${BASH_SOURCE[0]:-}"
case "$script_source" in
  ''|/dev/stdin|/dev/fd/*) source_dir='' ;;
  *) source_dir="$(cd "$(dirname "$script_source")" && pwd -P)" ;;
esac
payload_dir="$source_dir"
download_dir=''
remote_ref="${ORCHESTRATING_SUBAGENTS_REF:-main}"
default_remote_base="https://raw.githubusercontent.com/Zijian-Wu/orchestrating-subagents/$remote_ref"
remote_base="${ORCHESTRATING_SUBAGENTS_BASE_URL:-$default_remote_base}"
user_home="${ORCHESTRATING_SUBAGENTS_USER_HOME:-$HOME}"
skills_home="${AGENT_SKILLS_HOME:-$user_home/.local/share/agent-skills}"
canonical="$skills_home/orchestrating-subagents"
codex_link="$user_home/.agents/skills/orchestrating-subagents"
codex_instructions="$user_home/.codex/AGENTS.md"
start='<!-- orchestrating-subagents:start -->'
end='<!-- orchestrating-subagents:end -->'
managed_marker='managed by orchestrating-subagents installer'
previous_canonical=''
canonical_changed=0

say() { printf '%s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

cleanup_download() {
  case "$download_dir" in
    */orchestrating-subagents-download.*) rm -rf "$download_dir" ;;
  esac
}
trap cleanup_download EXIT

prepare_payload() {
  if test -n "$payload_dir" && test -f "$payload_dir/SKILL.md" && test -f "$payload_dir/agents/openai.yaml"; then
    return
  fi
  if ! command -v curl >/dev/null 2>&1; then
    fail 'curl is required for remote installation'
  fi

  download_dir="$(mktemp -d "${TMPDIR:-/tmp}/orchestrating-subagents-download.XXXXXX")"
  mkdir -p "$download_dir/agents"
  curl -fsSL --retry 3 "$remote_base/SKILL.md" -o "$download_dir/SKILL.md"
  curl -fsSL --retry 3 "$remote_base/agents/openai.yaml" -o "$download_dir/agents/openai.yaml"
  payload_dir="$download_dir"
}

preflight_paths() {
  case "$user_home" in
    /*) ;;
    *) fail "ORCHESTRATING_SUBAGENTS_USER_HOME must be an absolute path: $user_home" ;;
  esac
  case "$skills_home" in
    /*) ;;
    *) fail "AGENT_SKILLS_HOME must be an absolute path: $skills_home" ;;
  esac
}

preflight_install() {
  preflight_paths

  for required in SKILL.md agents/openai.yaml; do
    if test ! -f "$payload_dir/$required"; then
      fail "required skill payload is missing: $payload_dir/$required"
    fi
  done

  if test -e "$canonical" || test -L "$canonical"; then
    if test ! -d "$canonical" || test ! -f "$canonical/.orchestrating-subagents-managed" ||
      test "$(< "$canonical/.orchestrating-subagents-managed")" != "$managed_marker"; then
      fail "refusing to replace unrecognized canonical path: $canonical"
    fi
  fi

  if test -e "$codex_link" || test -L "$codex_link"; then
    if ! test -L "$codex_link" || test "$(readlink "$codex_link")" != "$canonical"; then
      backup="$codex_link.orchestrating-subagents.bak"
      backup_marker="$backup.orchestrating-subagents-managed"
      if test -e "$backup" || test -L "$backup" || test -e "$backup_marker"; then
        fail "refusing to replace occupied skill target because backup already exists: $codex_link"
      fi
    fi
  fi
}

preflight_uninstall() {
  preflight_paths
  if test -e "$canonical" || test -L "$canonical"; then
    if test ! -d "$canonical" || test ! -f "$canonical/.orchestrating-subagents-managed" ||
      test "$(< "$canonical/.orchestrating-subagents-managed")" != "$managed_marker"; then
      fail "refusing to remove unrecognized canonical path: $canonical"
    fi
  fi
}

copy_canonical() {
  if test "$dry_run" -eq 1; then
    say "Would install canonical skill at $canonical"
    return
  fi

  parent="$(dirname "$canonical")"
  mkdir -p "$parent"
  if test "$payload_dir" = "$canonical"; then
    return
  fi

  stage="$(mktemp -d "$parent/.orchestrating-subagents.XXXXXX")"
  mkdir -p "$stage/agents"
  cp "$payload_dir/SKILL.md" "$stage/SKILL.md"
  cp "$payload_dir/agents/openai.yaml" "$stage/agents/openai.yaml"
  printf '%s\n' "$managed_marker" > "$stage/.orchestrating-subagents-managed"

  if test -e "$canonical" || test -L "$canonical"; then
    previous_canonical="$(mktemp -d "$parent/.orchestrating-subagents.previous.XXXXXX")"
    rmdir "$previous_canonical"
    mv "$canonical" "$previous_canonical"
    if mv "$stage" "$canonical"; then
      canonical_changed=1
      return
    else
      mv "$previous_canonical" "$canonical"
      previous_canonical=''
      rm -rf "$stage"
      fail "could not replace canonical skill; previous installation restored"
    fi
  else
    mv "$stage" "$canonical"
    canonical_changed=1
  fi
}

commit_canonical() {
  if test -n "$previous_canonical"; then
    rm -rf "$previous_canonical"
    previous_canonical=''
  fi
  canonical_changed=0
}

rollback_canonical() {
  if test "$canonical_changed" -eq 1 && { test -e "$canonical" || test -L "$canonical"; }; then
    rm -rf "$canonical"
  fi
  if test -n "$previous_canonical"; then
    mv "$previous_canonical" "$canonical"
    previous_canonical=''
  fi
  canonical_changed=0
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
    backup_marker="$backup.orchestrating-subagents-managed"
    mv "$target" "$backup"
    if ! printf '%s\n' "$managed_marker" > "$backup_marker"; then
      mv "$backup" "$target"
      return 1
    fi
  else
    backup=''
    backup_marker=''
  fi
  if ln -s "$canonical" "$target"; then
    return
  fi
  if test -n "$backup"; then
    mv "$backup" "$target"
    rm "$backup_marker"
  fi
  return 1
}

unlink_skill() {
  backup="$codex_link.orchestrating-subagents.bak"
  backup_marker="$backup.orchestrating-subagents-managed"

  if test -L "$codex_link" && test "$(readlink "$codex_link")" = "$canonical"; then
    if test "$dry_run" -eq 1; then
      say "Would remove Codex skill link $codex_link"
    else
      rm "$codex_link"
    fi
  elif test -e "$codex_link" || test -L "$codex_link"; then
    say "Preserving unrecognized Codex skill target: $codex_link"
    return
  fi

  if { test -e "$backup" || test -L "$backup"; } && test -f "$backup_marker" &&
    test "$(< "$backup_marker")" = "$managed_marker"; then
    if test "$dry_run" -eq 1; then
      say "Would restore previous Codex skill target from $backup"
    else
      mv "$backup" "$codex_link"
      rm "$backup_marker"
    fi
  elif test -e "$backup" || test -L "$backup"; then
    say "Preserving unrecognized backup: $backup"
  fi
}

remove_canonical() {
  if test ! -e "$canonical" && test ! -L "$canonical"; then
    return
  fi
  if test ! -d "$canonical" || test ! -f "$canonical/.orchestrating-subagents-managed" ||
    test "$(< "$canonical/.orchestrating-subagents-managed")" != "$managed_marker"; then
    fail "refusing to remove unrecognized canonical path: $canonical"
  fi
  if test "$dry_run" -eq 1; then
    say "Would remove canonical skill at $canonical"
  else
    rm -rf "$canonical"
  fi
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

if test "$mode" = 'uninstall'; then
  preflight_uninstall
else
  prepare_payload
  preflight_install
fi

validate_legacy_bootstrap "$codex_instructions"

if test "$mode" = 'uninstall'; then
  unlink_skill
  remove_canonical
  remove_legacy_bootstrap "$codex_instructions"
  if test "$dry_run" -eq 1; then
    say 'orchestrating-subagents uninstall dry run complete; no files changed'
  else
    say 'orchestrating-subagents uninstalled'
  fi
else
  copy_canonical
  if link_skill "$codex_link"; then
    commit_canonical
  else
    rollback_canonical
    fail "could not link Codex skill; canonical installation rolled back"
  fi
  remove_legacy_bootstrap "$codex_instructions"
  if test "$dry_run" -eq 0 && ! command -v codex >/dev/null 2>&1; then
    say 'Warning: codex executable not found; skill files were installed.' >&2
  fi
  if test "$dry_run" -eq 1; then
    say 'orchestrating-subagents install dry run complete; no files changed'
  else
    say 'orchestrating-subagents installed'
  fi
fi
