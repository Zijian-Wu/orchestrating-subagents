---
name: orchestrating-subagents
description: Use when beginning or executing non-trivial coding work involving multiple steps, files, modules, unresolved uncertainty, substantial output, or distinct implementation and verification concerns
---

# Orchestrating Subagents

The main agent is the control plane. It owns planning, user communication, shared-file integration, final verification, and delivery; workers own bounded execution.

## Delegation check

Run this delegation check before non-trivial work: identify subtasks, dependencies, and file ownership. A task is non-trivial if it spans steps/files/modules, mixes research/implementation/testing/review, contains uncertainty or high-volume output, has meaningful risk, or would occupy the main agent substantially.

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

Independent reviewer contracts use `ownership: read-only` by default. A reviewer reports findings and may edit only after the main agent explicitly re-scopes it as an implementer.

## Failure rules

- Blocked or partial: resolve in scope, resume the same worker, or re-scope deliberately.
- Failed: diagnose before retrying or integrating.
- Stale/conflicting: reread current state and preserve newer user or agent changes.
- Capacity exhausted: finish useful active work, then reuse freed slots for dependent work or review.
