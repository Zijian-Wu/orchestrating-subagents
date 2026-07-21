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
if test -n "${ORCHESTRATING_SUBAGENTS_CODEX_HOME:-}"; then
  codex_home="$ORCHESTRATING_SUBAGENTS_CODEX_HOME"
elif test -n "${ORCHESTRATING_SUBAGENTS_USER_HOME:-}"; then
  codex_home="$user_home/.codex"
else
  codex_home="${CODEX_HOME:-$user_home/.codex}"
fi
codex_instructions="$codex_home/AGENTS.md"
codex_override="$codex_home/AGENTS.override.md"
start='<!-- orchestrating-subagents:start -->'
end='<!-- orchestrating-subagents:end -->'
bootstrap_line_1='Unless the runtime is explicitly Ultra, apply `$orchestrating-subagents` before substantive work on every non-atomic task.'
bootstrap_line_2='Let the skill decide which bounded subtasks to delegate and keep the main context focused on coordination, integration, and delivery.'
managed_marker='managed by orchestrating-subagents installer'
previous_canonical=''
canonical_changed=0
link_changed=0
instruction_backup_dir=''
uninstall_link_stage_dir=''
uninstall_canonical_stage=''
uninstall_backup_restored=0
declare -a instruction_targets=()
declare -a instruction_backup_existed=()

say() { printf '%s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

cleanup_download() {
  case "$download_dir" in
    */orchestrating-subagents-download.*) rm -rf "$download_dir" ;;
  esac
  case "$instruction_backup_dir" in
    */orchestrating-subagents-instructions.*) rm -rf "$instruction_backup_dir" ;;
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
  case "$codex_home" in
    /*) ;;
    *) fail "Codex home must be an absolute path: $codex_home" ;;
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

  mkdir -p "$(dirname "$target")" || return 1
  if test -L "$target" && test "$(readlink "$target")" = "$canonical"; then
    return
  fi

  if test -e "$target" || test -L "$target"; then
    backup="$target.orchestrating-subagents.bak"
    backup_marker="$backup.orchestrating-subagents-managed"
    mv "$target" "$backup" || return 1
    if ! printf '%s\n' "$managed_marker" > "$backup_marker"; then
      mv "$backup" "$target" || true
      return 1
    fi
  else
    backup=''
    backup_marker=''
  fi
  if ln -s "$canonical" "$target"; then
    link_changed=1
    return
  fi
  if test -n "$backup"; then
    mv "$backup" "$target" || return 1
    rm "$backup_marker" || return 1
  fi
  return 1
}

commit_link() {
  link_changed=0
}

rollback_link() {
  if test "$link_changed" -ne 1; then
    return
  fi

  backup="$codex_link.orchestrating-subagents.bak"
  backup_marker="$backup.orchestrating-subagents-managed"
  if test -L "$codex_link" && test "$(readlink "$codex_link")" = "$canonical"; then
    rm "$codex_link"
  fi
  if { test -e "$backup" || test -L "$backup"; } && test -f "$backup_marker" &&
    test "$(< "$backup_marker")" = "$managed_marker"; then
    mv "$backup" "$codex_link"
    rm "$backup_marker"
  fi
  link_changed=0
}

stage_uninstall_payload() {
  backup="$codex_link.orchestrating-subagents.bak"
  backup_marker="$backup.orchestrating-subagents-managed"
  can_restore_backup=1

  if test -L "$codex_link" && test "$(readlink "$codex_link")" = "$canonical"; then
    if test "$dry_run" -eq 1; then
      say "Would remove Codex skill link $codex_link"
    else
      uninstall_link_stage_dir="$(mktemp -d "$(dirname "$codex_link")/.orchestrating-subagents-uninstall.XXXXXX")" || return 1
      mv "$codex_link" "$uninstall_link_stage_dir/link" || return 1
    fi
  elif test -e "$codex_link" || test -L "$codex_link"; then
    say "Preserving unrecognized Codex skill target: $codex_link"
    can_restore_backup=0
  fi

  if test -e "$canonical" || test -L "$canonical"; then
    if test "$dry_run" -eq 1; then
      say "Would remove canonical skill at $canonical"
    else
      parent="$(dirname "$canonical")"
      uninstall_canonical_stage="$(mktemp -d "$parent/.orchestrating-subagents-uninstall.XXXXXX")" || return 1
      rmdir "$uninstall_canonical_stage" || return 1
      mv "$canonical" "$uninstall_canonical_stage" || return 1
    fi
  fi

  if test "$can_restore_backup" -eq 1 && { test -e "$backup" || test -L "$backup"; } && test -f "$backup_marker" &&
    test "$(< "$backup_marker")" = "$managed_marker"; then
    if test "$dry_run" -eq 1; then
      say "Would restore previous Codex skill target from $backup"
    else
      mv "$backup" "$codex_link" || return 1
      uninstall_backup_restored=1
      rm "$backup_marker" || return 1
    fi
  elif test -e "$backup" || test -L "$backup"; then
    say "Preserving unrecognized backup: $backup"
  fi
}

rollback_uninstall_payload() {
  if test "$dry_run" -eq 1; then
    return
  fi

  backup="$codex_link.orchestrating-subagents.bak"
  backup_marker="$backup.orchestrating-subagents-managed"
  if test "$uninstall_backup_restored" -eq 1; then
    if test -e "$codex_link" || test -L "$codex_link"; then
      mv "$codex_link" "$backup" || return 1
    fi
    printf '%s\n' "$managed_marker" > "$backup_marker" || return 1
    uninstall_backup_restored=0
  fi
  if test -n "$uninstall_canonical_stage" && { test -e "$uninstall_canonical_stage" || test -L "$uninstall_canonical_stage"; }; then
    mv "$uninstall_canonical_stage" "$canonical" || return 1
    uninstall_canonical_stage=''
  fi
  if test -n "$uninstall_link_stage_dir" && { test -e "$uninstall_link_stage_dir/link" || test -L "$uninstall_link_stage_dir/link"; }; then
    mkdir -p "$(dirname "$codex_link")" || return 1
    mv "$uninstall_link_stage_dir/link" "$codex_link" || return 1
    rmdir "$uninstall_link_stage_dir" || return 1
    uninstall_link_stage_dir=''
  fi
}

cleanup_uninstall_payload() {
  if test "$dry_run" -eq 1; then
    return
  fi

  if test -n "$uninstall_canonical_stage"; then
    if rm -rf "$uninstall_canonical_stage"; then
      uninstall_canonical_stage=''
    else
      say "Warning: inactive canonical staging data could not be removed: $uninstall_canonical_stage" >&2
    fi
  fi
  if test -n "$uninstall_link_stage_dir"; then
    if rm -rf "$uninstall_link_stage_dir"; then
      uninstall_link_stage_dir=''
    else
      say "Warning: inactive link staging data could not be removed: $uninstall_link_stage_dir" >&2
    fi
  fi
  uninstall_backup_restored=0
}

validate_bootstrap_file() {
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
    fail "refusing to manage orchestrating-subagents bootstrap through symlinked instruction file: $file"
  fi
}

validate_bootstrap_target() {
  file="$1"
  validate_bootstrap_file "$file"
  if test -L "$file"; then
    fail "refusing to modify symlinked instruction file: $file"
  fi
  if test -e "$file" && test ! -f "$file"; then
    fail "instruction path is not a regular file: $file"
  fi
}

select_install_instruction_targets() {
  instruction_targets=("$codex_instructions")
  if test -s "$codex_override"; then
    instruction_targets+=("$codex_override")
  fi
}

select_uninstall_instruction_targets() {
  instruction_targets=("$codex_instructions" "$codex_override")
}

prepare_instruction_backups() {
  if test "$dry_run" -eq 1; then
    return
  fi

  instruction_backup_dir="$(mktemp -d "${TMPDIR:-/tmp}/orchestrating-subagents-instructions.XXXXXX")" || return 1
  instruction_backup_existed=()
  index=0
  for file in "${instruction_targets[@]}"; do
    instruction_backup_existed[$index]=-1
    index=$((index + 1))
  done

  index=0
  for file in "${instruction_targets[@]}"; do
    if test -e "$file" || test -L "$file"; then
      cp -p "$file" "$instruction_backup_dir/$index" || return 1
      instruction_backup_existed[$index]=1
    else
      instruction_backup_existed[$index]=0
    fi
    index=$((index + 1))
  done
}

commit_instructions() {
  if test -n "$instruction_backup_dir"; then
    rm -rf "$instruction_backup_dir"
    instruction_backup_dir=''
  fi
  instruction_backup_existed=()
}

rollback_instructions() {
  if test "$dry_run" -eq 1 || test -z "$instruction_backup_dir"; then
    return
  fi

  index=0
  for file in "${instruction_targets[@]}"; do
    case "${instruction_backup_existed[$index]:--1}" in
      1)
        mkdir -p "$(dirname "$file")"
        cp -p "$instruction_backup_dir/$index" "$file"
        ;;
      0)
        if test -e "$file" || test -L "$file"; then
          rm "$file"
        fi
        ;;
    esac
    index=$((index + 1))
  done
  commit_instructions
}

render_without_bootstrap() {
  input="$1"
  output="$2"

  if test ! -f "$input"; then
    : > "$output"
    return
  fi

  awk -v start="$start" -v end="$end" '
    $0 == start { skipping=1; next }
    skipping && $0 == end { skipping=0; next }
    skipping { next }
    { print }
  ' "$input" > "$output"
}

write_bootstrap() {
  file="$1"
  if test "$dry_run" -eq 1; then
    say "Would install orchestrating-subagents bootstrap block in $file"
    return
  fi

  directory="$(dirname "$file")"
  mkdir -p "$directory" || return 1
  new="$(mktemp "$directory/.orchestrating-subagents.XXXXXX")" || return 1
  if test -f "$file"; then
    cp -p "$file" "$new" || { rm -f "$new"; return 1; }
  fi
  if test -f "$file" && grep -Fqx "$start" "$file"; then
    awk -v start="$start" -v end="$end" -v line1="$bootstrap_line_1" -v line2="$bootstrap_line_2" '
      $0 == start {
        print start
        print line1
        print line2
        print end
        skipping=1
        next
      }
      skipping && $0 == end { skipping=0; next }
      skipping { next }
      { print }
    ' "$file" > "$new" || { rm -f "$new"; return 1; }
  else
    if test -s "$new"; then
      printf '\n' >> "$new" || { rm -f "$new"; return 1; }
    fi
    printf '%s\n%s\n%s\n%s\n' "$start" "$bootstrap_line_1" "$bootstrap_line_2" "$end" >> "$new" || {
      rm -f "$new"
      return 1
    }
  fi
  mv "$new" "$file" || { rm -f "$new"; return 1; }
}

install_bootstraps() {
  prepare_instruction_backups || return 1
  for file in "${instruction_targets[@]}"; do
    write_bootstrap "$file" || return 1
  done
}

remove_bootstrap() {
  file="$1"
  if test ! -f "$file" || ! grep -Fqx "$start" "$file"; then
    return
  fi
  if test "$dry_run" -eq 1; then
    say "Would remove orchestrating-subagents bootstrap block from $file"
    return
  fi

  directory="$(dirname "$file")"
  new="$(mktemp "$directory/.orchestrating-subagents.XXXXXX")" || return 1
  cp -p "$file" "$new" || { rm -f "$new"; return 1; }
  render_without_bootstrap "$file" "$new" || { rm -f "$new"; return 1; }
  mv "$new" "$file" || { rm -f "$new"; return 1; }
}

remove_bootstraps() {
  prepare_instruction_backups || return 1
  for file in "${instruction_targets[@]}"; do
    remove_bootstrap "$file" || return 1
  done
}

if test "$mode" = 'uninstall'; then
  select_uninstall_instruction_targets
  preflight_uninstall
  for file in "${instruction_targets[@]}"; do
    validate_bootstrap_file "$file"
  done
else
  prepare_payload
  select_install_instruction_targets
  preflight_install
  for file in "${instruction_targets[@]}"; do
    validate_bootstrap_target "$file"
  done
fi

if test "$mode" = 'uninstall'; then
  if ! stage_uninstall_payload; then
    rollback_uninstall_payload || true
    fail 'could not stage skill removal; installation preserved where possible'
  fi
  if ! remove_bootstraps; then
    rollback_instructions
    rollback_uninstall_payload || true
    fail 'could not remove global bootstrap; installation restored where possible'
  fi
  commit_instructions
  cleanup_uninstall_payload
  if test "$dry_run" -eq 1; then
    say 'orchestrating-subagents uninstall dry run complete; no files changed'
  else
    say 'orchestrating-subagents uninstalled'
  fi
else
  copy_canonical
  if ! link_skill "$codex_link"; then
    rollback_canonical
    fail "could not link Codex skill; canonical installation rolled back"
  fi
  if ! install_bootstraps; then
    rollback_instructions
    rollback_link
    rollback_canonical
    fail 'could not install global bootstrap; skill installation rolled back'
  fi
  commit_instructions
  commit_link
  commit_canonical
  if test "$dry_run" -eq 0 && ! command -v codex >/dev/null 2>&1; then
    say 'Warning: codex executable not found; skill files were installed.' >&2
  fi
  if test "$dry_run" -eq 1; then
    say 'orchestrating-subagents install dry run complete; no files changed'
  else
    say 'orchestrating-subagents installed'
  fi
fi
