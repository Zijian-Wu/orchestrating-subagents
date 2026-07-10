# Orchestrating Subagents

A cross-platform Agent Skill that makes Codex and Claude Code actively delegate non-trivial coding work while keeping the main agent responsible for planning, coordination, integration, verification, user communication, and final delivery.

## What it enforces

- Delegate at least one substantive part of non-trivial coding tasks when subagents are available.
- Run independent, non-overlapping work concurrently.
- Give every worker explicit scope, ownership, acceptance criteria, and validation requirements.
- Keep shared files and final integration under main-agent control.
- Require an independent read-only reviewer for important changes.
- Degrade transparently when subagent tools or capacity are unavailable.
- Avoid unnecessary delegation for atomic, low-risk work.

## Repository layout

```text
.
├── README.md
├── SKILL.md
├── install.sh
└── adapters/
    ├── codex.md
    └── claude-code.md
```

## Install

```bash
git clone https://github.com/Zijian-Wu/orchestrating-subagents.git
cd orchestrating-subagents

bash install.sh --dry-run --all
bash install.sh --all
```

Install for one agent only:

```bash
bash install.sh --codex
bash install.sh --claude
```

Restart Codex or Claude Code if the new skill is not detected in the current session.

## Manual use

Codex can invoke the skill explicitly through its skill selector. In Claude Code, use:

```text
/orchestrating-subagents
```
