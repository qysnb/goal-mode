# goal-mode — Autonomous Goal Execution (multi-agent)

A cross-agent skill: set a goal, and the agent executes **autonomously in one go** — break down tasks, write code, run, verify, write docs/comments, and keep a work report throughout. Except for critical matters, it **does not disturb the user**, and it auto-resumes after interruption.

Compatible with **opencode / Claude Code / Codex / any skill-capable harness**.

## Features

- **Autonomous execution**: goal → tasks → implement → run & verify → record, looping until the success criteria are met
- **Work report**: generates `###OpenCodeWorkReport<YYYYMMDDHHMM>.md` in the session working directory with a full audit trail (progress log / problems / solutions / verification results)
- **Problem logging**: every problem records "symptom / ≥3 attempted paths / solved-or-pending / alternatives"
- **No-disturb principle**: only interrupts for critical matters (irreversible destructive ops, missing credentials/keys, real-money/account actions, unreachable goal, same blocker exhausting 3 paths); bulk deletion of old files during version iteration is done after `git` archival — **no interruption**
- **Self-healing**: every milestone persists a checkpoint (`GOAL_STATE.json`); after interruption (LLM output limit / network / session end), `resume` restores from the checkpoint and first verifies real on-disk state

## Install

### Option 1: pick the variant for your agent

```bash
git clone https://github.com/qysnb/goal-mode.git
```

| Agent | Source | Target directory |
|---|---|---|
| opencode | `agents/opencode/` | `~/.config/opencode/skills/goal-mode/` |
| Claude Code | `agents/claude-code/` | `~/.claude/skills/goal-mode/` |
| Codex / generic | root `SKILL.md` | `~/.codex/skills/goal-mode/` or any `**/SKILL.md` skills dir |

Example (opencode, global):

```bash
mkdir -p ~/.config/opencode/skills/goal-mode
cp goal-mode/agents/opencode/SKILL.md ~/.config/opencode/skills/goal-mode/SKILL.md
```

### Option 2: `npx skills` (vercel-labs/skills CLI)

```bash
npx skills add qysnb/goal-mode -a claude-code -a codex -y
```

### Option 3: opencode `skills.paths` (no copy)

```json
{
  "skills": { "paths": ["C:/path/to/goal-mode"] }
}
```

> Restart the target agent after installing — config is loaded at startup.

## Usage

```
/goal-mode <goal>     # opencode: start autonomous execution
/goal-mode resume     # opencode: resume from checkpoint after interruption
```

For other agents use natural language: `goal mode: <goal>` / `run until done` / `do it in one go` / `autonomous`; to resume, say "continue the last goal".

## Artifacts

| File | Description |
|---|---|
| `###OpenCodeWorkReport<YYYYMMDDHHMM>.md` | Work report (main deliverable): goal / constraints & success criteria / execution plan / progress log / problems & solutions / verification results / final summary |
| `GOAL_STATE.json` | Checkpoint for resume; overwritten at every milestone |

## Interrupt / escalation whitelist

The agent pauses and asks **only** in these cases; otherwise it runs silently:

1. Irreversible destructive ops (e.g., `rm -rf` of unversioned data, `git reset --hard` discarding uncommitted work, force push)
2. API key / password / token needed but not available in the environment
3. Real money / account actions (payments, purchases, registrations, enabling services)
4. Goal fundamentally unreachable / conflicting direction
5. Same blocker exhausted ≥3 different paths (report once with tried approaches + suggestion)

On completion it sends a single summary (goal / key results / report path / open issues).

## Repository layout

```
goal-mode/
├── SKILL.md                  # canonical (agent-neutral; loadable by any harness)
├── agents/
│   ├── opencode/SKILL.md     # opencode variant (argument-hint / allowed-tools)
│   └── claude-code/SKILL.md  # Claude Code variant
└── scripts/
    └── verify-skill.ps1      # regenerate variants + full validation
```

Variants are auto-generated from the root `SKILL.md` (`pwsh scripts/verify-skill.ps1`) so bodies stay byte-identical. To customize the work-report name, change `REPORT_PREFIX` in the skill's Constants.

## License

MIT