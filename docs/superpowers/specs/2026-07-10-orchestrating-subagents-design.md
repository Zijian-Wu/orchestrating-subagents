# Orchestrating Subagents Skill Design

Date: 2026-07-10

## Goal

Create a personal, global Agent Skill for Codex and Claude Code that makes the main agent actively delegate non-trivial coding work while retaining responsibility for planning, user communication, integration, review, verification, and final delivery.

The skill uses one portable core workflow plus thin platform adapters. It must degrade safely when subagent features are unavailable.

## Scope and decisions

- Activation mode: strong orchestration.
- Installation scope: personal and global across projects.
- Worker permissions: implementation workers may edit only explicitly owned files or modules.
- Nested delegation: forbidden by default; allowed only when the parent task contract defines a boundary.
- Review: important changes require a reviewer that did not implement them.
- Supported installation environment: Linux/macOS with Bash.

## Package architecture

```text
orchestrating-subagents/
├── SKILL.md
├── references/
│   ├── codex.md
│   └── claude-code.md
└── scripts/
    └── install.sh
```

`SKILL.md` contains platform-independent orchestration rules. At runtime, the agent detects its platform and reads the matching adapter. Platform adapters map abstract operations such as spawn, message, wait, resume, and close to available tools without duplicating policy.

The same canonical skill is exposed in the personal skill locations used by Codex and Claude Code. The installer also adds a short, marked bootstrap rule to each platform's personal global instruction file so non-trivial coding tasks reliably load the skill.

## Roles and ownership

### Main agent

The main agent is the default control plane. It:

1. Performs a delegation check before non-trivial coding work.
2. Builds a task graph with dependencies and file ownership.
3. Dispatches independent work in parallel when safe.
4. Gives each worker a bounded task contract.
5. Continues useful integration or investigation while workers run.
6. Receives status and blocker messages and adjusts assignments.
7. Owns shared files, cross-module integration, conflict resolution, and user communication.
8. Assigns an independent reviewer for important changes.
9. Inspects the actual workspace and verification evidence before final delivery.

The main agent must not forward the entire user request unchanged to one worker. It must retain substantive orchestration and acceptance responsibility.

### Subagents

Subagents are bounded execution units. They may research, analyze, implement, test, or review only within their assigned scope. A worker must not expand requirements, modify unowned files, or deliver directly to the user.

Nested delegation is permitted only when the task contract explicitly contains `nested_delegation: allowed:<boundary>`. The delegating worker remains responsible for consolidating descendants' results before reporting to the main agent.

## Delegation policy

The main agent must perform a delegation check. A task is non-trivial when any of these apply:

- It spans multiple steps, files, or modules.
- It combines two or more of research, implementation, testing, documentation, or review.
- It contains unresolved technical uncertainty.
- It would produce high-volume searches, logs, or test output that should be isolated.
- It has meaningful regression, security, or compatibility risk.
- Completing it alone would occupy the main agent for a substantial interval.

When subagents are available, a non-trivial task must delegate at least one substantive subtask. Two independent subtasks with non-overlapping ownership must be dispatched concurrently. Strongly dependent work on the same file remains sequential unless isolated worktrees and a merge plan make parallelism safe.

Delegation is normally unnecessary for a concise explanation, a known one-line configuration change, a low-risk local edit requiring no exploration, or a short process with no meaningful independent subtask. Explicit user instructions not to use subagents override the skill.

If subagents are unavailable, capacity is exhausted, or delegation would clearly cost more than the task, the main agent may degrade to local execution and record the reason.

## Task contract

Every dispatch includes:

```yaml
task: one clear objective
why: role in the parent task
scope:
  allowed: readable or writable files and modules
  forbidden: areas that must not change
context: known facts, constraints, and entry points
acceptance: observable completion criteria
validation: tests or checks to run
ownership: read-only | write:<files/modules>
nested_delegation: forbidden | allowed:<boundary>
report: findings, changes, validation, risks, blockers
```

Agents must report a blocker before exceeding scope. The main agent can provide context, shrink or reassign work, resume an existing worker, or stop ineffective work. Dependent tasks start only when their prerequisites are available.

Final worker reports use:

```markdown
Result: completed | partial | blocked
Changes: modified files and behavior
Validation: commands and outcomes
Findings: relevant conclusions
Risks: assumptions and remaining concerns
Needs main agent: integration or decisions still required
```

## Failure and conflict handling

- `blocked`: the main agent first attempts an in-scope resolution; new authority or changed goals go to the user.
- `partial`: resume the same worker when its retained context is useful, otherwise re-scope the remainder.
- `failed`: do not integrate blindly; diagnose and then retry, reassign, revert only the agent-owned change, or handle centrally.
- `stale/conflict`: reread current state and preserve newer user or agent changes. Never overwrite them from stale assumptions.

When a worker's evidence is insufficient, resume that worker for targeted validation instead of starting a context-free replacement.

## Review and completion gates

Multi-file, cross-module, behavior-changing, security-sensitive, compatibility-sensitive, or otherwise high-risk changes require an independent reviewer. The reviewer checks requirement compliance, scope, correctness, regression risk, evidence, and integration consistency. Reviewers report issues and do not edit by default.

The main agent may claim completion only after:

- Required subtasks are complete or remaining items are disclosed.
- The integrated workspace has been inspected directly.
- Risk-proportionate final verification has run.
- Important review findings are resolved or disclosed.
- The main agent has prepared the user-facing final response.

## Installation behavior

`scripts/install.sh` is idempotent and supports `--all`, platform-specific installation, and `--dry-run`. It maintains one canonical skill and exposes it at:

- Codex: `~/.agents/skills/orchestrating-subagents/`
- Claude Code: `~/.claude/skills/orchestrating-subagents/`

It updates marked blocks in:

- Codex: `~/.codex/AGENTS.md`
- Claude Code: `~/.claude/CLAUDE.md`

Before modifying an existing global instruction file, the installer creates a backup and preserves unrelated content. Repeated runs update only the marked block. Missing platform executables or subagent support produce actionable warnings rather than destructive changes.

## Verification strategy

Skill development follows RED-GREEN-REFACTOR:

1. Run pressure scenarios against an agent without the skill and record baseline failures or rationalizations.
2. Run equivalent scenarios with the skill loaded.
3. Add only the minimum instruction needed to close observed loopholes.
4. Repeat until the required behavior is reliable.

Behavioral scenarios cover:

- Parallel implementation across two independent modules.
- A trivial one-line edit that should not be delegated.
- Conflicting same-file work that must be serialized or repartitioned.
- A worker requesting an out-of-scope change.
- Important multi-file work requiring an independent reviewer.
- Safe degradation when subagent tools are unavailable.
- Final user communication performed only by the main agent.

Static and installer checks cover YAML frontmatter, internal references, shell syntax, dry-run behavior, idempotency, preservation of existing configuration, and installation under a temporary `HOME`.

## Success criteria

- The same core workflow behaves consistently in Codex and Claude Code.
- Non-trivial tasks reliably produce at least one bounded delegation when supported.
- Independent work is parallelized without overlapping ownership.
- The main agent remains the sole default coordinator and user-facing deliverer.
- Important changes receive independent review and evidence-based final verification.
- Trivial work and unsupported environments avoid wasteful or unsafe delegation.

## Source compatibility notes

- Codex skills use the Agent Skills format and personal skills under `~/.agents/skills/`: https://developers.openai.com/codex/skills/
- Codex personal global guidance uses `~/.codex/AGENTS.md`: https://developers.openai.com/codex/guides/agents-md
- Claude Code skills use `SKILL.md` and personal skills under `~/.claude/skills/`: https://code.claude.com/docs/en/skills
- Claude Code personal global guidance uses `~/.claude/CLAUDE.md`: https://code.claude.com/docs/en/memory
- Current subagent capabilities are documented at https://developers.openai.com/codex/subagents and https://code.claude.com/docs/en/sub-agents
