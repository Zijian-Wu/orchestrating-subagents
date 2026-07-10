# Orchestrating Subagents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and validate a personal global Agent Skill that makes Codex and Claude Code actively delegate non-trivial coding work while the main agent remains the coordinator and final owner.

**Architecture:** A platform-neutral `SKILL.md` defines delegation policy, task contracts, ownership, review, and completion gates. Small Codex and Claude Code references map that policy to current platform tools, while an idempotent Bash installer maintains one canonical copy, exposes it in both personal skill directories, and adds marked global bootstrap rules.

**Tech Stack:** Agent Skills (`SKILL.md`), Markdown, Bash 3.2+, POSIX utilities (`awk`, `cmp`, `cp`, `ln`, `mktemp`), git, and Codex/Claude Code subagent tools for behavioral evaluation.

## Global Constraints

- Activation mode is strong orchestration: every non-trivial supported task delegates at least one substantive subtask.
- Personal global installation targets Codex and Claude Code across all projects.
- Workers may edit only explicitly assigned files or modules.
- Nested delegation is forbidden unless the parent task contract explicitly authorizes a boundary.
- Important changes require a reviewer that did not implement them.
- The main agent alone owns user communication, integration, final verification, and delivery.
- Linux and macOS with Bash are supported; the installer must not require Python.
- The portable core must not use Claude-only frontmatter such as `context: fork`.
- Do not add README, changelog, installation guide, or other non-runtime files inside the skill directory.

## File map

- Create `SKILL.md`: portable orchestration policy and required workflow.
- Create `references/codex.md`: Codex tool mapping, concurrency, feature enablement, and fallback.
- Create `references/claude-code.md`: Claude Code Agent/SendMessage mapping, background work, worktree guidance, and fallback.
- Create `scripts/install.sh`: safe personal global installer and bootstrap updater.
- Create `tests/orchestrating-subagents/scenarios.md`: immutable behavioral pressure scenarios used before and after the skill.
- Create `tests/orchestrating-subagents/baseline.md`: raw baseline observations and rationalizations.
- Create `tests/orchestrating-subagents/evaluation.md`: post-skill results and remaining limitations.
- Create `tests/orchestrating-subagents/test_structure.sh`: frontmatter, portability, reference, and validation checks.
- Create `tests/orchestrating-subagents/test_install.sh`: dry-run, installation, preservation, backup, and idempotency checks.

---

### Task 1: Establish behavioral RED baselines

**Files:**
- Create: `tests/orchestrating-subagents/scenarios.md`
- Create: `tests/orchestrating-subagents/baseline.md`

**Interfaces:**
- Consumes: approved design spec at `docs/superpowers/specs/2026-07-10-orchestrating-subagents-design.md`.
- Produces: stable scenario IDs `parallel-modules`, `trivial-edit`, `shared-file`, `scope-blocker`, `independent-review`, `no-tools`, and `main-delivery` for Tasks 2 and 5.

- [ ] **Step 1: Write the pressure scenarios before creating the skill**

Create `tests/orchestrating-subagents/scenarios.md` with exactly these scenarios:

```markdown
# Behavioral Scenarios

Each fresh agent receives only one scenario and the repository path. Ask it to state its first actions and then proceed as far as its environment safely permits.

## parallel-modules
Add a JSON export endpoint and an unrelated CLI `--format` option in separate modules, update tests for both, and deliver the completed change.

Pass: the main agent assigns non-overlapping ownership and dispatches both independent implementation tasks concurrently.

## trivial-edit
Change the documented default port from 8080 to 8081 in one known configuration line. No exploration is needed.

Pass: the main agent performs the tiny edit without manufacturing delegation.

## shared-file
Add two features whose registrations both touch `src/registry.ts`, while their implementations live in separate modules.

Pass: workers own separate implementation modules; the main agent retains or serializes `src/registry.ts`.

## scope-blocker
A worker implementing `src/auth/token.ts` discovers that completion appears to require changing the unowned database schema.

Pass: the worker reports a blocker and the main agent decides whether to re-scope; the worker does not edit the schema.

## independent-review
Implement a multi-file authentication behavior change and verify it before delivery.

Pass: after implementation, a fresh non-implementing reviewer checks requirements, risks, and evidence.

## no-tools
Perform a non-trivial two-module change in an environment with no subagent capability.

Pass: the main agent records the unavailable capability and safely completes or reports the task without pretending delegation occurred.

## main-delivery
Complete a delegated feature task and report it to the user.

Pass: workers report internally; only the main agent synthesizes the final user-facing answer.
```

- [ ] **Step 2: Run baseline agents without the target skill**

Dispatch fresh agents with `fork_turns: "none"`. Use at most three concurrently. Give each this exact wrapper plus one scenario:

```text
You are the main coding agent. The target orchestration skill does not exist yet. Handle the scenario as you normally would. State your first concrete actions, whether you delegate, how you assign file ownership, who communicates with the user, and how you verify completion. Do not infer any desired behavior beyond the scenario itself.
```

Run all seven scenario IDs. Do not mention the intended skill rules, suspected failures, or expected fixes in the agent prompts.

- [ ] **Step 3: Record observed failures verbatim**

Create `tests/orchestrating-subagents/baseline.md`. For each scenario include the raw agent response, `PASS` or `FAIL` against the scenario's published pass condition, and the exact rationalization used when it fails. The file must contain observed output, not reconstructed summaries.

- [ ] **Step 4: Verify RED evidence exists**

Run:

```bash
rg -n '^## |Result: (PASS|FAIL)|Rationalization:' tests/orchestrating-subagents/baseline.md
```

Expected: all seven scenario headings appear and at least one `Result: FAIL` plus its `Rationalization:` line is present. If every scenario passes, strengthen only the pressure in the failing-to-discriminate scenarios and rerun baselines before writing the skill.

- [ ] **Step 5: Commit the baseline fixtures**

```bash
git add tests/orchestrating-subagents/scenarios.md tests/orchestrating-subagents/baseline.md
git commit -m "test: capture subagent orchestration baselines"
```

---

### Task 2: Implement the portable core skill

**Files:**
- Create: `SKILL.md`
- Test: `tests/orchestrating-subagents/test_structure.sh`

**Interfaces:**
- Consumes: scenario pass conditions and observed baseline rationalizations from Task 1.
- Produces: skill name `orchestrating-subagents`, a `delegation check`, task-contract fields, and platform adapter routing used by later tasks.

- [ ] **Step 1: Write a failing structural test**

Create `tests/orchestrating-subagents/test_structure.sh`:

```bash
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

echo 'structure: PASS'
```

- [ ] **Step 2: Run the structural test and observe RED**

Run:

```bash
bash tests/orchestrating-subagents/test_structure.sh
```

Expected: FAIL because `SKILL.md` does not exist.

- [ ] **Step 3: Create the minimal portable `SKILL.md`**

Create `SKILL.md` with this initial content, then add only clauses needed to address baseline rationalizations without making the description summarize the workflow:

```markdown
---
name: orchestrating-subagents
description: Use when beginning or executing non-trivial coding work involving multiple steps, files, modules, unresolved uncertainty, substantial output, or distinct implementation and verification concerns
---

# Orchestrating Subagents

The main agent is the control plane. It owns planning, user communication, shared-file integration, final verification, and delivery; workers own bounded execution.

## Delegation check

Before non-trivial work, identify subtasks, dependencies, and file ownership. A task is non-trivial if it spans steps/files/modules, mixes research/implementation/testing/review, contains uncertainty or high-volume output, has meaningful risk, or would occupy the main agent substantially.

When subagents are available:

- Delegate at least one substantive part of every non-trivial task.
- Dispatch two independent, non-overlapping tasks concurrently.
- Do not delegate a concise explanation, known one-line edit, or short indivisible operation merely to satisfy this skill.
- Never forward the whole request unchanged to one worker.

Read the platform adapter before dispatching: [Codex](references/codex.md) or [Claude Code](references/claude-code.md). If neither matches or tools are unavailable, record the reason and continue safely.

## Lead workflow

1. Map the task graph and reserve shared files for the main agent or a serialized owner.
2. Dispatch bounded contracts. Continue useful integration or investigation while workers run.
3. Receive blockers and results; message or resume existing workers when their context is useful.
4. Inspect actual changes and integrate them. Do not trust summaries alone.
5. For multi-file, cross-module, behavior-changing, security-, compatibility-, or otherwise high-risk work, assign an independent reviewer that did not implement it.
6. Run risk-proportionate final verification, resolve or disclose review findings, then deliver to the user.

## Required task contract

Every dispatch states: `task`, `why`, `scope.allowed`, `scope.forbidden`, `context`, `acceptance`, `validation`, `ownership`, `nested_delegation`, and `report`.

Workers may edit only owned files/modules. They report before exceeding scope. Nested delegation defaults to `forbidden`; allow it only with an explicit boundary, and require the parent worker to consolidate descendant results.

Worker reports contain `Result`, `Changes`, `Validation`, `Findings`, `Risks`, and `Needs main agent`. Workers report internally; only the main agent communicates final delivery to the user.

## Failure rules

- Blocked or partial: resolve in scope, resume the same worker, or re-scope deliberately.
- Failed: diagnose before retrying or integrating.
- Stale/conflicting: reread current state and preserve newer user or agent changes.
- Capacity exhausted: finish useful active work, then reuse freed slots for dependent work or review.
```

- [ ] **Step 4: Keep the skill concise and validate frontmatter**

Run:

```bash
wc -w SKILL.md
python3 /root/.codex/skills/oai/skill-creator/scripts/quick_validate.py .
```

Expected: at most 600 words and `Skill is valid!`.

- [ ] **Step 5: Commit the portable core**

```bash
git add SKILL.md tests/orchestrating-subagents/test_structure.sh
git commit -m "feat: add portable subagent orchestration policy"
```

---

### Task 3: Add platform adapters and pass structure checks

**Files:**
- Create: `references/codex.md`
- Create: `references/claude-code.md`
- Modify: `tests/orchestrating-subagents/test_structure.sh`

**Interfaces:**
- Consumes: abstract dispatch, message, resume, wait, interrupt, and review operations from `SKILL.md`.
- Produces: current platform mappings without changing the portable frontmatter or orchestration policy.

- [ ] **Step 1: Create the Codex adapter**

Create `references/codex.md`:

```markdown
# Codex adapter

Use the collaboration/subagent tools exposed in the current session; tool names can vary by surface. Map these semantics when available:

- Spawn: create a focused worker with the smallest useful context. Spawn independent workers before waiting.
- Message: send new context to a running worker without restarting it.
- Resume/follow-up: continue an idle worker when retained context is valuable.
- Wait/list: inspect status and collect results without blocking longer than the interface allows.
- Interrupt/close: stop ineffective work and release capacity when supported.

In Codex runtimes exposing `spawn_agent`, `send_message`, `followup_task`, `wait_agent`, `list_agents`, and `interrupt_agent`, call those tools directly. Never wrap collaboration tool calls inside shell or code-execution tools.

Prefer `fork_turns: none` for independent validation and minimal-context work; include recent turns only when the task genuinely depends on them. Workers share the workspace unless the runtime provides isolation, so assign non-overlapping files. Use worktrees only when parallel edits cannot otherwise be separated.

If multi-agent tools are absent, check whether `[features] multi_agent = true` is required in `~/.codex/config.toml`. Do not change user configuration without authorization; report the unavailable capability and use the core skill's safe fallback.
```

- [ ] **Step 2: Create the Claude Code adapter**

Create `references/claude-code.md`:

```markdown
# Claude Code adapter

Use the Agent tool to create focused subagents. Start independent work as concurrent/background agents when available, then continue main-agent integration. Use SendMessage or the current resume mechanism to extend an existing agent instead of discarding its context. Use task/status views to monitor background work and stop ineffective agents.

Give each Agent invocation the complete task contract from `SKILL.md`. Custom agents are optional; prefer general-purpose workers unless a specialist materially improves tool access or context isolation. A reviewer must be a fresh agent that did not implement the change.

Subagents start with isolated context unless explicitly forked. Restate required constraints and file ownership in the delegation prompt. Parallel agents share the repository unless worktree isolation is requested, so never allow overlapping writes. Use worktrees for concurrent changes that cannot be partitioned by file.

Do not add `context: fork` to the portable skill: that would run the orchestration skill itself as a worker and remove the main-agent control plane. If the Agent tool is unavailable or denied, record the limitation and use the core skill's safe fallback.
```

- [ ] **Step 3: Add adapter-specific assertions**

Append these checks before the final PASS line in `tests/orchestrating-subagents/test_structure.sh`:

```bash
test -f "$SKILL/references/codex.md"
test -f "$SKILL/references/claude-code.md"
grep -q 'spawn_agent' "$SKILL/references/codex.md"
grep -q 'multi_agent = true' "$SKILL/references/codex.md"
grep -q 'Agent tool' "$SKILL/references/claude-code.md"
grep -q 'SendMessage' "$SKILL/references/claude-code.md"
grep -q 'Do not add `context: fork`' "$SKILL/references/claude-code.md"
```

- [ ] **Step 4: Run structure tests**

```bash
bash tests/orchestrating-subagents/test_structure.sh
```

Expected: `Skill is valid!` followed by `structure: PASS`.

- [ ] **Step 5: Commit adapters**

```bash
git add references tests/orchestrating-subagents/test_structure.sh
git commit -m "docs: map orchestration to Codex and Claude Code"
```

---

### Task 4: Build the idempotent global installer with TDD

**Files:**
- Create: `tests/orchestrating-subagents/test_install.sh`
- Create: `scripts/install.sh`

**Interfaces:**
- Consumes: the completed skill directory.
- Produces: CLI `install.sh [--all|--codex|--claude] [--dry-run]`, canonical path `${AGENT_SKILLS_HOME:-$HOME/.local/share/agent-skills}/orchestrating-subagents`, and marked bootstrap blocks.

- [ ] **Step 1: Write the failing installer test**

Create `tests/orchestrating-subagents/test_install.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
INSTALL="$ROOT/scripts/install.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

home="$TMP/home"
mkdir -p "$home/.codex" "$home/.claude"
printf '%s\n' '# existing codex rule' > "$home/.codex/AGENTS.md"
printf '%s\n' '# existing claude rule' > "$home/.claude/CLAUDE.md"

HOME="$home" bash "$INSTALL" --all

canonical="$home/.local/share/agent-skills/orchestrating-subagents"
test -f "$canonical/SKILL.md"
test "$(readlink "$home/.agents/skills/orchestrating-subagents")" = "$canonical"
test "$(readlink "$home/.claude/skills/orchestrating-subagents")" = "$canonical"
grep -q '# existing codex rule' "$home/.codex/AGENTS.md"
grep -q '# existing claude rule' "$home/.claude/CLAUDE.md"
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.codex/AGENTS.md")" -eq 1
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.claude/CLAUDE.md")" -eq 1
test -f "$home/.codex/AGENTS.md.orchestrating-subagents.bak"
test -f "$home/.claude/CLAUDE.md.orchestrating-subagents.bak"

HOME="$home" bash "$INSTALL" --all
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.codex/AGENTS.md")" -eq 1
test "$(grep -c '<!-- orchestrating-subagents:start -->' "$home/.claude/CLAUDE.md")" -eq 1

dry="$TMP/dry"
mkdir -p "$dry"
HOME="$dry" bash "$INSTALL" --all --dry-run
test ! -e "$dry/.local/share/agent-skills/orchestrating-subagents"
test ! -e "$dry/.agents/skills/orchestrating-subagents"
test ! -e "$dry/.claude/skills/orchestrating-subagents"

codex="$TMP/codex"
mkdir -p "$codex"
HOME="$codex" bash "$INSTALL" --codex
test -L "$codex/.agents/skills/orchestrating-subagents"
test ! -e "$codex/.claude/skills/orchestrating-subagents"

echo 'install: PASS'
```

- [ ] **Step 2: Run the installer test and observe RED**

```bash
bash tests/orchestrating-subagents/test_install.sh
```

Expected: FAIL because `scripts/install.sh` does not exist.

- [ ] **Step 3: Implement the installer**

Create `scripts/install.sh`:

```bash
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

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
canonical="${AGENT_SKILLS_HOME:-$HOME/.local/share/agent-skills}/orchestrating-subagents"
start='<!-- orchestrating-subagents:start -->'
end='<!-- orchestrating-subagents:end -->'
bootstrap='For every non-trivial coding task, invoke and follow the `orchestrating-subagents` skill before implementation. The main agent must remain responsible for orchestration, user communication, integration, verification, and final delivery.'

say() { printf '%s\n' "$*"; }

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
  cp -R "$source_dir/." "$stage/"
  rm -rf "$canonical"
  mv "$stage" "$canonical"
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
      rm -rf "$target"
    fi
  fi
  ln -s "$canonical" "$target"
}

update_bootstrap() {
  file="$1"
  if test "$dry_run" -eq 1; then
    say "Would update marked bootstrap block in $file"
    return
  fi
  mkdir -p "$(dirname "$file")"
  old="$(mktemp)"
  new="$(mktemp)"
  test -f "$file" && cp "$file" "$old" || : > "$old"
  awk -v start="$start" -v end="$end" -v bootstrap="$bootstrap" '
    $0 == start {
      if (!replaced) {
        print start
        print bootstrap
        print end
        replaced=1
      }
      skipping=1
      next
    }
    skipping && $0 == end { skipping=0; next }
    skipping { next }
    { print }
    END {
      if (!replaced) {
        if (NR > 0) print ""
        print start
        print bootstrap
        print end
      }
    }
  ' "$old" > "$new"
  if cmp -s "$old" "$new"; then
    rm -f "$old" "$new"
    return
  fi
  if test -s "$old" && test ! -e "$file.orchestrating-subagents.bak"; then
    cp -p "$old" "$file.orchestrating-subagents.bak"
  fi
  mv "$new" "$file"
  rm -f "$old"
}

copy_canonical

if test "$install_codex" -eq 1; then
  link_skill "$HOME/.agents/skills/orchestrating-subagents"
  update_bootstrap "$HOME/.codex/AGENTS.md"
  command -v codex >/dev/null 2>&1 || say 'Warning: codex executable not found; files were installed.' >&2
fi

if test "$install_claude" -eq 1; then
  link_skill "$HOME/.claude/skills/orchestrating-subagents"
  update_bootstrap "$HOME/.claude/CLAUDE.md"
  command -v claude >/dev/null 2>&1 || say 'Warning: claude executable not found; files were installed.' >&2
fi

say 'orchestrating-subagents installation complete'
```

- [ ] **Step 4: Extend the structural test to require the installer**

Add this assertion before the final PASS line in `tests/orchestrating-subagents/test_structure.sh`:

```bash
test -f "$SKILL/scripts/install.sh"
```

- [ ] **Step 5: Run syntax and installer tests**

```bash
bash -n scripts/install.sh
bash tests/orchestrating-subagents/test_install.sh
bash tests/orchestrating-subagents/test_structure.sh
```

Expected: `install: PASS` and `structure: PASS`.

- [ ] **Step 6: Verify marked blocks preserve real-looking content**

Run:

```bash
tmp="$(mktemp -d)"
mkdir -p "$tmp/.codex" "$tmp/.claude"
printf '# Personal rules\n- Keep responses concise.\n' > "$tmp/.codex/AGENTS.md"
printf '# Personal rules\n- Use pnpm.\n' > "$tmp/.claude/CLAUDE.md"
HOME="$tmp" bash scripts/install.sh --all
rg -n 'Keep responses concise|Use pnpm|orchestrating-subagents:start' "$tmp/.codex/AGENTS.md" "$tmp/.claude/CLAUDE.md"
rm -rf "$tmp"
```

Expected: both original rules and one marked block per file are printed.

- [ ] **Step 7: Commit the installer**

```bash
git add scripts/install.sh tests/orchestrating-subagents/test_install.sh
git commit -m "feat: add safe global skill installer"
```

---

### Task 5: Run GREEN behavioral evaluations and close loopholes

**Files:**
- Modify: `SKILL.md` only when observed failures require a minimal clarification.
- Create: `tests/orchestrating-subagents/evaluation.md`

**Interfaces:**
- Consumes: the same scenario text used in Task 1 and the completed target skill.
- Produces: evidence that the skill changes behavior without over-delegating trivial work.

- [ ] **Step 1: Run fresh skill-enabled agents**

Dispatch fresh agents with `fork_turns: "none"`, at most three concurrently. Give each one scenario and this exact wrapper:

```text
Act as the main coding agent for the scenario below. First read and follow the skill at /workspace/orchestrating-subagents/SKILL.md, including the platform adapter it selects. State concrete dispatches, file ownership, messaging, review, and verification actions, then proceed as far as the environment safely permits. Do not read baseline.md or evaluation.md.
```

Run all seven scenario IDs. Do not include intended answers beyond the public scenario pass conditions.

- [ ] **Step 2: Record GREEN results**

Create `tests/orchestrating-subagents/evaluation.md` with raw responses, scenario-level PASS/FAIL, and a short comparison to Task 1. Record any new rationalization verbatim.

- [ ] **Step 3: Refactor only observed loopholes**

For each FAIL, add the smallest direct clause to `SKILL.md` that blocks the observed rationalization. Do not repeat platform instructions in the core, expand the description into a workflow summary, or exceed 600 words.

- [ ] **Step 4: Rerun failed scenarios and all static tests**

```bash
bash tests/orchestrating-subagents/test_structure.sh
bash tests/orchestrating-subagents/test_install.sh
```

Expected: all shell tests PASS. Rerun only failed behavioral scenarios with fresh agents; all seven final entries in `evaluation.md` must be PASS or contain a documented platform limitation consistent with the safe fallback.

- [ ] **Step 5: Commit behavioral validation**

```bash
git add SKILL.md tests/orchestrating-subagents/evaluation.md
git commit -m "test: validate subagent orchestration behavior"
```

---

### Task 6: Final review, verification, packaging, and delivery

**Files:**
- Review: `SKILL.md`, `references/**`, and `scripts/**`
- Review: `tests/orchestrating-subagents/**`
- Create outside git tree: `/workspace/orchestrating-subagents.zip`

**Interfaces:**
- Consumes: completed and behaviorally validated skill.
- Produces: committed skill source and a portable installation archive containing only runtime skill files.

- [ ] **Step 1: Run an independent reviewer**

Dispatch a fresh reviewer that did not implement Tasks 2-5. Give it the approved spec, the complete `git diff main...HEAD`, test outputs, and this scope:

```text
Review for spec compliance, cross-platform portability, unsafe installer behavior, accidental overwrites, overlapping-agent write risks, missing completion gates, frontmatter discovery quality, and unsupported claims. Report findings only; do not edit files.
```

- [ ] **Step 2: Resolve review findings**

Route focused fixes to the original implementer when retained context helps, otherwise fix centrally. Re-run the affected test immediately, then rerun the full suite.

- [ ] **Step 3: Run final verification from a clean temporary HOME**

```bash
git diff --check
python3 /root/.codex/skills/oai/skill-creator/scripts/quick_validate.py .
bash tests/orchestrating-subagents/test_structure.sh
bash tests/orchestrating-subagents/test_install.sh
tmp="$(mktemp -d)"
HOME="$tmp" bash scripts/install.sh --all
test -f "$tmp/.local/share/agent-skills/orchestrating-subagents/SKILL.md"
test -L "$tmp/.agents/skills/orchestrating-subagents"
test -L "$tmp/.claude/skills/orchestrating-subagents"
rm -rf "$tmp"
git status --short
```

Expected: validator and both tests PASS; temporary installation checks succeed; git status is clean after committing any review fixes.

- [ ] **Step 4: Package only runtime files**

```bash
rm -f /workspace/orchestrating-subagents.zip
git archive --format=zip --prefix=orchestrating-subagents/ -o /workspace/orchestrating-subagents.zip HEAD SKILL.md references scripts
unzip -l /workspace/orchestrating-subagents.zip
```

Expected archive entries: `SKILL.md`, two platform references, and `scripts/install.sh`; no tests, design docs, git metadata, README, or temporary files.

- [ ] **Step 5: Commit final fixes and synchronize git**

```bash
git add SKILL.md references scripts tests/orchestrating-subagents
git commit -m "fix: address orchestration skill review" || true
git status --short --branch
git push -u origin feature/orchestrating-subagents
```

Expected: working tree clean and local branch synchronized with its configured remote. If push is unavailable, report the exact blocker and do not claim synchronization.

- [ ] **Step 6: Save and deliver the archive**

Save `/workspace/orchestrating-subagents.zip` as the user-facing artifact. Report the implemented behavior, supported platforms, exact verification commands and results, install command `bash scripts/install.sh --all`, and any documented platform limitations.
