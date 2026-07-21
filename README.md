# Orchestrating Subagents

## Design philosophy

Bring proactive subagent delegation to non-Ultra Codex while keeping the main agent clean, focused, and information-dense.

The main agent owns requirements, decisions, coordination, integration, and verification. Subagents handle bounded execution and noisy investigation, returning distilled results instead of raw working context. Ultra already provides native proactive delegation.

One eligible bounded subtask is enough to delegate; parallelism is optional. The primary objective is context isolation, provided its value exceeds handoff and verification cost.

The installation uses three layers:

- A minimal managed block in the global Codex `AGENTS.md` reliably requests the skill for non-atomic, non-Ultra work.
- `SKILL.md` owns delegation decisions and orchestration.
- `agents/openai.yaml` keeps implicit invocation enabled.

## Install

```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/Zijian-Wu/orchestrating-subagents/main/install.sh | bash'
```

The installer preserves existing instructions. If a non-empty global `AGENTS.override.md` exists, it updates both that active override and the base `AGENTS.md`. Start a new Codex task after installation.

## Uninstall

```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/Zijian-Wu/orchestrating-subagents/main/install.sh | bash -s -- --uninstall'
```

Within global instruction files, uninstall removes only the managed bootstrap block and preserves all other content. It also removes the installed skill and restores any skill target that the installer backed up.

## Use

Codex can invoke the skill automatically. To force it for a non-Ultra task, use:

```text
$orchestrating-subagents
```
