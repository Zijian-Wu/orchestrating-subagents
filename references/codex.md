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
