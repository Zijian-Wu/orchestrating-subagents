# Orchestrating Subagents

## Design philosophy

Bring proactive subagent delegation to non-Ultra Codex while keeping the main agent clean, focused, and information-dense.

The main agent owns requirements, decisions, coordination, integration, and verification. Subagents handle bounded execution and noisy investigation, returning distilled results instead of raw working context. Ultra already provides native proactive delegation.

One eligible bounded subtask is enough to delegate; parallelism is optional. The primary objective is context isolation, provided its value exceeds handoff and verification cost.

## Install

```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/Zijian-Wu/orchestrating-subagents/main/install.sh | bash'
```

## Uninstall

```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/Zijian-Wu/orchestrating-subagents/main/install.sh | bash -s -- --uninstall'
```

## Use

Codex can invoke the skill automatically. To force it for a task, use:

```text
$orchestrating-subagents
```
