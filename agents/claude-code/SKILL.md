---
name: goal-mode
description: Execute a goal end-to-end autonomously — write code, run it, verify, document progress and problems in a timestamped work report (###OpenCodeWorkReport<timestamp>.md), and resume from checkpoints after interruption. Only interrupts the user for critical matters (irreversible destructive ops, missing credentials, real-money actions, unreachable goals, 3 failed paths). Use when user says "goal mode", "run until done", "do it in one go", "autonomous", or provides a goal to execute autonomously.
argument-hint: "<goal description> | resume"
---

# Goal Mode: Autonomous Goal Execution

Give the agent a goal and let it execute **autonomously in one go**: break down tasks → write code → run → verify → document → keep a work report throughout. Except for whitelisted critical matters, **do not disturb the user**.

> ⚠️ This skill **explicitly overrides** the default "get approval before implementing" behavior (the brainstorming HARD-GATE does not apply here). Except for the interrupt/escalation whitelist, you **must not** ask "may I start / shall I continue / is this OK". Just execute.

> 🔧 **Cross-agent**: this file is the agent-neutral version. Frontmatter has only `name` + `description`, tool names are generic, and it can be loaded by any skill-capable agent/harness. Agent-specific variants (with `argument-hint`, `allowed-tools`) live in `agents/` and are generated from this file with byte-identical bodies.

## Constants

- **REPORT_PREFIX** = `###OpenCodeWorkReport`
- **TIMESTAMP** = `YYYYMMDDHHMM` (e.g., `202608271902`)
- **REPORT_FILE** = `<REPORT_PREFIX><TIMESTAMP>.md` (written to the **session working directory**)
- **STATE_FILE** = `GOAL_STATE.json` (same directory, fixed name, used for resume)
- **RESUME_WINDOW** = 24 hours (state older than this is treated as stale → fresh start)
- **BLOCK_PATHS** = 3 (a blocker must exhaust **≥3 different paths** before escalation)
- **Report language** = match the user's language (default English); file name and content use the same language

## File Contract

**Work report `###OpenCodeWorkReport<timestamp>.md`** — the main deliverable; template below; appended as work progresses.

**Checkpoint `GOAL_STATE.json`** — basis for resume; overwritten at every milestone:

```json
{
  "goal": "<goal description>",
  "status": "in_progress",
  "report_file": "###OpenCodeWorkReport202608271902.md",
  "created_at": "2026-08-27T19:02:00",
  "last_updated": "2026-08-27T19:30:00",
  "success_criteria": ["..."],
  "todo": ["task A", "task B"],
  "done": ["task A"],
  "current_task": "task B",
  "next_action": "implement module X and verify",
  "problems": [{"desc": "...", "attempts": ["path 1", "path 2", "path 3"], "status": "solved|pending"}]
}
```

## Invocation (per agent)

- **opencode**: `/goal-mode <goal>` to start; `/goal-mode resume` to resume (variant in `agents/opencode/`)
- **Claude Code**: give the goal in natural language (e.g., "goal mode: do X") or use an installed command; resume with "continue the last goal" (variant in `agents/claude-code/`)
- **Codex**: `/goal <goal>` or natural language; Codex's native `/goal` is an OpenAI-gated capability — this skill is an independent generic implementation (use the root SKILL.md)
- **Other harnesses**: hand the goal to the agent as a prompt, e.g., "goal mode: <goal>"; to resume, give the same goal again and say "resume"

## Workflow

### Phase 0: Goal intake

- If the argument/intent is `resume` / `continue`:
  - `STATE_FILE` exists AND `status=in_progress` AND `last_updated` within 24h → **go to Phase 5 (resume)**
  - otherwise → state "no valid checkpoint, fresh start", go to Phase 1
- If it is a new goal:
  - If `STATE_FILE` exists AND `status=in_progress` AND within 24h → **ask once**: resume old goal / discard old goal and start new / merge (involves discarding in-progress work — a direction-level matter)
  - otherwise → fresh start, go to Phase 1

### Phase 1: Initialize

1. Read project context: **first read project convention files** (e.g., `AGENTS.md`, `CLAUDE.md`), directory structure, recent commits; identify language/scripts/conventions and the verification approach (test suite? sample scripts?)
2. Create `REPORT_FILE` with the skeleton (template below)
3. Create `STATE_FILE` (goal, success_criteria, initial todo, status=in_progress)
4. Record in the report: goal, constraints, success criteria, initial execution plan

### Phase 2: Execution loop (until success criteria met or escalation triggered)

Each round:

1. **Pick a task**: from `todo`, take the highest-value / most upstream next item
2. **Implement**: write code with necessary comments/docstrings; update project docs as needed
3. **Run and verify**: verify using the project's conventions (run tests if any; otherwise sample scripts / run commands; web projects can build/preview). Verification must be **actually executed**, never assumed
4. **Record**: write the outcome to the report's Progress Log; record success/failure/partial honestly
5. **Persist**: refresh `STATE_FILE` (`todo`/`done`/`current_task`/`next_action`/`problems`/`last_updated`) — **every milestone must be persisted**
6. **Judge**: check `success_criteria`; all satisfied → go to Phase 4; otherwise → next round

Blocker handling (when a task is blocked):
- First exhaust **≥3 different paths** (change implementation, switch tools, research, rethink), logging for each failure: what was tried / why it failed / next alternative
- If all 3 paths fail → escalate via whitelist item 5

### Phase 3: Interrupt / Escalation policy

**Only** pause and ask (one message: state the blocker + options; after the user replies, continue silently) in these cases:

1. **Irreversible destructive ops**: e.g., `rm -rf` of unversioned data, deleting user data files, `git reset --hard` discarding uncommitted work, force-pushing over remote, etc.
   - **Exception**: bulk deletion of old files in normal version iteration → first `git add` + `git commit` (or archive) to preserve, then delete — **no interruption**.
2. **Missing credentials/keys**: need an API key/password/token not present in the environment → ask; never guess or hardcode into code/repo.
3. **Real money/account actions**: payments, purchases, registrations, enabling external services, etc.
4. **Goal fundamentally unreachable / conflicting direction**: success criteria contradict each other, or the goal cannot proceed under real constraints → ask whether to adjust direction/scope.
5. **Repeated failure**: same blocker exhausted ≥3 different paths and still failing → report once (with tried approaches + suggested next step + open questions), wait for instructions.

Otherwise **never disturb**: no mid-progress reports, no "shall I continue?", no approval requests.

### Phase 4: Completion check

1. **Final verification**: re-run verification commands, confirm deliverables exist and are non-empty; check every `success_criteria` item
2. Complete the report's "Verification & Test Results" and "Final Summary" (goal / key results / open issues / report path)
3. Set `STATE_FILE` `status=completed`
4. Send the user **one** completion summary (goal / key results / report file path / open issues)

### Phase 5: Resume

1. Read `STATE_FILE` and `REPORT_FILE` to restore context
2. **First verify the real on-disk state** (`git status`, files exist, outputs/artifacts generated, processes running), **then** decide where to continue — never based on stale assumptions
3. Continue from `next_action`; if interrupted mid-write/mid-run, redo that step first
4. Append to the report: `Resumed from checkpoint (<time>), next: <next_action>`
5. Return to the Phase 2 loop

## Work report template

```markdown
### OpenCodeWorkReport 202608271902

## Goal
<goal description>

## Constraints & Success Criteria
- Constraints: <environment/resource/time limits>
- Success criteria:
  - [ ] <verifiable criterion 1>
  - [ ] <verifiable criterion 2>

## Execution Plan
- [ ] task 1 …
- [ ] task 2 …

## Progress Log
| Time | Task | Result |
|---|---|---|

## Problems & Solutions
### <problem title>
- Symptom:
- Attempted paths:
  1. …
  2. …
  3. …
- Solved / Pending:
- Alternatives:

## Verification & Test Results

## Final Summary
```

## Key Rules

- **No-disturb principle**: except the Phase 3 whitelist, stay fully autonomous; never ask "shall I / may I / continue?"
- **Honest recording**: failures, negative results, and blockers must be recorded truthfully in the report; never fabricate test results, run output, or a "looks successful" illusion
- **Exhaust before escalating**: blockers first go through ≥3 different paths; don't give up easily; log alternatives for each failure
- **Forced persistence**: after every completed task and important log entry, immediately refresh `STATE_FILE` and the report — a power/network/output-limit cut loses at most the current step
- **Self-healing**: if interrupted by LLM output limits, network issues, or session end, triggering resume intent again restores from the checkpoint
- **Large file writes**: if the file-write tool fails, fall back to a shell heredoc (`cat << 'EOF' > file`) chunked write, without asking
- **Docs & comments**: produced code gets necessary comments/docstrings; docs updated as needed and logged in the report
- **Credential safety**: secrets come only from environment variables or by asking; never written into code or committed to a repo
- **Environment first**: read project convention files (e.g., `AGENTS.md`) before acting; use sample scripts/run commands when no test suite exists
- **Honest stop**: when all paths are exhausted and the user must be waited on, write down "todo / tried / suggested" clearly before interrupting — don't let the work hang