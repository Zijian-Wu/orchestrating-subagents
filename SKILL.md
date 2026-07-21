---
name: orchestrating-subagents
description: Use proactively for most non-atomic Codex tasks below Ultra, including feature implementation, bug fixing, refactoring, code review, testing, research, documentation lookup, and repository exploration. Delegate every eligible bounded subtask—even a single one—to keep the main agent clean, focused, and information-dense. Use when explicitly invoked or requested by applicable AGENTS.md guidance. Do not use for Ultra, atomic or quick tasks, tightly coupled iterative work, or delegation whose handoff and verification cost outweighs its isolation value.
---

# Orchestrating Subagents

Design around one principle: delegate every eligible bounded subtask to protect the main context. Parallelism is optional; context isolation is the primary objective. Keep the main agent focused on requirements, decisions, coordination, integration, verification, and delivery. Keep detailed exploration and execution inside subagents and return only information-dense results.

## Entry gates

1. Stop when the runtime explicitly identifies Ultra; let Ultra orchestrate natively, even if this skill was invoked. Do not infer Ultra from the model name alone.
2. Otherwise, apply when the user explicitly invokes `$orchestrating-subagents`, applicable `AGENTS.md` guidance requests it, or implicit matching selects it.
3. Delegate when at least one substantive bounded subtask is eligible. Do not require a second ready task or concurrent main-agent work; one isolated subagent is sufficient.

A subtask is eligible when it can be given a clear objective, boundary, deliverable, and validation; can proceed without frequent interaction; can return a distilled result instead of a raw trace; and its context-isolation, specialization, or review value exceeds handoff and verification cost. Strong signals include:

- Read-heavy codebase exploration or dependency mapping.
- High-volume tests, logs, searches, generated output, or documentation lookup.
- Implementation with exact, non-overlapping ownership.
- A fresh independent review that materially reduces correctness, security, compatibility, migration, or regression risk.

If the level is unavailable, apply the normal conditions. Keep work in the main agent only when it is atomic or quick, needs the full conversation or frequent back-and-forth, is tightly coupled to immediate decisions, requires nearly all context to be handed off, or would need to be repeated by the main agent to verify.

## Lead workflow

1. Make a lightweight map of dependencies, ready tasks, shared files, and ownership. If boundaries are unclear, delegate a read-only explorer instead of filling the main context with discovery output.
2. Delegate every eligible ready subtask. Dispatch independent tasks together when several exist; dispatch one when only one qualifies. Give each worker a bounded objective, scope, minimal context, deliverable, validation, exact ownership, and report format. Never forward the whole request unchanged.
3. Use collaboration tools directly. Workers share the workspace, so prohibit overlapping writes. Nested delegation defaults to forbidden.
4. Require distilled reports: conclusion, key evidence and paths, changes, validation, risks or uncertainty, and needs from the main agent. Exclude raw logs, search traces, and lengthy reasoning unless specifically needed.
5. While workers run, continue useful orchestration or non-duplicative critical-path work. Waiting is acceptable when no clean main-agent work remains. Reuse retained context for follow-ups; use a fresh read-only worker for independent high-risk review.
6. Verify actual diffs and artifacts before integration, but load raw output only when a summary is insufficient or a failure needs diagnosis.
7. Reuse freed capacity for newly unblocked work, then run final verification and deliver from the main agent only.

If tools or capacity are unavailable, continue safely in the main agent. Resolve partial or failed work deliberately; preserve newer external changes.
