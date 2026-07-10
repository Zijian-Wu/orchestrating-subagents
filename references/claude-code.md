# Claude Code adapter

Use the Agent tool to create focused subagents. Start independent work as concurrent/background agents when available, then continue main-agent integration. Use SendMessage or the current resume mechanism to extend an existing agent instead of discarding its context. Use task/status views to monitor background work and stop ineffective agents.

Give each Agent invocation the complete task contract from `SKILL.md`. Custom agents are optional; prefer general-purpose workers unless a specialist materially improves tool access or context isolation. A reviewer must be a fresh agent that did not implement the change.

Subagents start with isolated context unless explicitly forked. Restate required constraints and file ownership in the delegation prompt. Parallel agents share the repository unless worktree isolation is requested, so never allow overlapping writes. Use worktrees for concurrent changes that cannot be partitioned by file.

Do not add `context: fork` to the portable skill: that would run the orchestration skill itself as a worker and remove the main-agent control plane. If the Agent tool is unavailable or denied, record the limitation and use the core skill's safe fallback.
