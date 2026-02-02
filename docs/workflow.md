# Agent Workflow - Complete Documentation

A file-based multi-agent workflow system where AI agents and humans work together on software tasks.

## Table of Contents

- [Overview](#overview)
- [Core Principles](#core-principles)
- [Tool Compatibility](#tool-compatibility)
- [Directory Structure](#directory-structure)
- [Status Lifecycle](#status-lifecycle)
- [Agents](#agents)
- [Conductor](#conductor)
- [File Formats](#file-formats)
- [Usage](#usage)
- [Configuration](#configuration)
- [Git Workflow](#git-workflow)
- [Parallel Conductors](#parallel-conductors)
- [Troubleshooting](#troubleshooting)

---

## Overview

Agent Workflow is a system for managing software development tasks through a structured pipeline:

```
Backlog → Picker → PRD → Planner → Plan → Refiner → Refined Plan → Implementer → Done
```

The key insight is that **humans and AI agents are interchangeable participants**. Both can:
- Pick up tasks based on status
- Create and modify documents
- Ask and answer questions
- Advance work through the pipeline

All state lives in human-readable markdown files, making the process transparent and debuggable.

---

## Core Principles

1. **File-based coordination** - All state lives in readable markdown/yaml files
2. **Status-driven workflow** - Clear status markers guide what happens next
3. **Agent/human interchangeable** - Any participant can advance the workflow
4. **One agent type at a time** - No concurrent conflicts by design
5. **Questions flow naturally** - Any participant can ask, any can answer

---

## Tool Compatibility

Agent Workflow is designed to work with both **Cursor** and **Claude Code**. The installer sets up both tools.

### Directory Locations

| Purpose | Claude Code | Cursor | Scope |
|---------|-------------|--------|-------|
| Agent definitions | `.claude/agents/` | `.cursor/agents/` | Project |
| Workflow state | `{paths.*}` (default: `.workflow/`) | `{paths.*}` (default: `.workflow/`) | Project |
| Rules | - | `.cursor/rules/` | Project |
| Skills | - | `~/.cursor/skills/` | User (global) |
| Instructions | `CLAUDE.md` or `~/.claude/CLAUDE.md` | - | Project or User |

### What Gets Installed

The installer creates identical agent definitions in both locations:

```
your-project/
├── .workflow/              # Shared workflow state (default; configurable via config.yaml paths)
│   ├── config.yaml
│   ├── backlog.md
│   ├── action-log.md
│   ├── prds/
│   └── plans/
├── .claude/agents/         # Claude Code reads from here
│   ├── picker.md
│   ├── planner.md
│   ├── refiner.md
│   ├── implementer.md
│   └── conductor.md
├── .cursor/agents/         # Cursor reads from here
│   ├── picker.md
│   ├── planner.md
│   ├── refiner.md
│   ├── implementer.md
│   └── conductor.md
└── .cursor/rules/
    └── workflow-agents.mdc

~/.cursor/skills/           # User-level (shared across projects)
└── feature-workflow/
    └── SKILL.md
```

### Using Each Tool

**Claude Code:**
```bash
# Invoke agents directly
claude "Use the picker agent to select the next task"
claude "Use the conductor agent to run the full pipeline"

# Or use /agent command
claude /agent picker
```

**Cursor:**
```bash
# Use slash commands (from skill)
/pick
/plan user-auth
/conduct --phases pick,plan

# Or reference agents directly
@picker select the next task from backlog
```

### Keeping Tools in Sync

The agent definitions are identical in both `.claude/agents/` and `.cursor/agents/`. If you customize an agent, update both locations or re-run the installer.

---

## Directory Structure (defaults)

```
.workflow/  # Default workflow directory; configurable via config.yaml paths
├── config.yaml              # Project workflow configuration
├── backlog.md               # Task backlog (Picker reads from here)
├── action-log.md            # Conductor audit trail
├── questions.md             # Open questions for human review
├── prds/                    # PRDs created by Picker
│   ├── feat-user-auth.md
│   └── fix-login-bug.md
└── plans/                   # Plans created by Planner
    ├── feat-user-auth.md
    └── fix-login-bug.md
```

---

## Status Lifecycle

Each PRD/Plan file has a frontmatter status field:

```yaml
---
status: not_started | ready | in_progress | blocked | done
assignee: picker | planner | refiner | implementer | human
created: 2024-01-15
updated: 2024-01-15
questions: []
---
```

### Status Definitions

| Status | Meaning |
|--------|---------|
| `not_started` | Task exists but no one has begun work |
| `ready` | Ready for the next participant to pick up |
| `in_progress` | Currently being worked on |
| `blocked` | Cannot proceed, has unanswered questions |
| `done` | Completed |

### Status Transitions

```
┌─────────────┐     ┌─────────┐     ┌─────────────┐     ┌──────┐
│ not_started │ ──► │  ready  │ ──► │ in_progress │ ──► │ done │
└─────────────┘     └─────────┘     └─────────────┘     └──────┘
                          ▲               │
                          │               ▼
                          │          ┌─────────┐
                          └───────── │ blocked │
                                     └─────────┘
                                  (needs human input)
```

### Typical Flow

1. **Backlog task** (`not_started`) → Picker picks it up
2. **PRD created** (`ready`, assignee: `planner`) → Planner picks it up
3. **Plan created** (`ready`, assignee: `refiner`) → Refiner reviews
4. **Plan refined** (`ready`, assignee: `implementer`) → Implementer builds
5. **Code committed** → Plan marked `done`

At any point, if questions arise → status becomes `blocked`, assignee becomes `human`

---

## Agents

### Picker Agent

**Purpose**: Select a task from backlog, analyze codebase, create a PRD

**Workflow**:
1. Read backlog file from config (`paths.backlog`, default: `.workflow/backlog.md`), find first task with status `not_started`
2. Mark task as `in_progress` with assignee `picker`
3. Analyze codebase to understand context
4. Create PRD in `{paths.prds}/{slug}.md` (from config, default: `.workflow/prds/{slug}.md`) with status `ready`
5. Mark backlog task as `done`, link to PRD

**Agent file**: `.claude/agents/picker.md`

### Planner Agent

**Purpose**: Take a PRD and create an implementation plan

**Workflow**:
1. Find PRD with status `ready`, assignee `planner` in PRDs directory (from `paths.prds`)
2. Update PRD status to `in_progress`
3. Create detailed implementation plan
4. If questions arise, set status `blocked`
5. Otherwise, create plan with status `ready`
6. Update PRD status to `done`

**Agent file**: `.claude/agents/planner.md`

### Refiner Agent

**Purpose**: Review plan, refine it, or flag questions

**Workflow**:
1. Find plan with status `ready`, assignee `refiner` in plans directory (from `paths.plans`)
2. Update status to `in_progress`
3. Review for completeness, accuracy, edge cases
4. Try to answer existing questions
5. If blocked, set status `blocked`, assignee `human`
6. Otherwise, update status `ready`, assignee `implementer`

**Agent file**: `.claude/agents/refiner.md`

### Implementer Agent

**Purpose**: Execute a refined plan, write code, tests, commit

**Workflow**:
1. Find plan with status `ready`, assignee `implementer` in plans directory (from `paths.plans`)
2. Update status to `in_progress`
3. Implement according to plan
4. Write tests, run tests and linting
5. If blocked, set status `blocked`
6. Otherwise, commit changes, set status `done`

**Agent file**: `.claude/agents/implementer.md`

---

## Conductor

The conductor is an orchestration agent that runs other agents in a loop until all work is complete or blocked.

### Purpose

Instead of manually invoking each agent, the conductor:
- Scans workflow state from files
- Runs phases in order (pick → plan → refine → implement)
- Skips blocked items and continues processing
- Logs all actions to `action-log.md`
- Reports a summary when done

### Core Principles

- **File-based state**: All state lives in files - single source of truth
- **Stateless execution**: Fresh context each run, relies only on file state
- **Skip-blocked-continue**: Blocked items don't stop the loop
- **Never merge**: Creates PRs but never merges them

### Configuration

Configure the conductor in the config file (typically `.workflow/config.yaml`):

```yaml
orchestration:
  name: default                              # conductor name for logging
  phases: [pick, plan, refine, implement]    # phases to run
  max_iterations: 20                         # safety limit
  stop_on_first_block: false                 # continue on blocked items
```

### Phases

| Phase | Reads | Writes |
|-------|-------|--------|
| pick | `backlog: status=not_started` | `PRD: assignee=planner` |
| plan | `PRD: assignee=planner` | `plan: assignee=refiner` |
| refine | `plan: assignee=refiner` | `plan: assignee=implementer` |
| implement | `plan: assignee=implementer` | `plan: status=done`, opens PR |

### Usage

```bash
# Run full pipeline (uses config default)
/conduct

# Override phases for this run
/conduct --phases pick
/conduct --phases pick,plan

# Run on specific slug only
/conduct --slug user-auth

# Named conductor (for parallel operation tracking)
/conduct --name frontend-conductor --phases pick,plan
```

### Action Log

The conductor logs all actions to the action log file (from `paths.action_log`, default: `.workflow/action-log.md`):

```markdown
## 2024-01-15 14:30 - Conductor Run

- Conductor: default
- Phases: [pick, plan, refine, implement]
- Initial state: 3 backlog items, 1 PRD ready, 0 plans ready
- Actions:
  - [x] pick: user-auth → PRD created
  - [x] pick: payment-flow → PRD created
  - [ ] pick: notifications → blocked (question about provider)
  - [x] plan: user-auth → plan created
- Completed: 3 actions
- Blocked: 1 item (notifications - needs human input)
- Handoff: 1 plan ready for refiner
```

**Agent file**: `.claude/agents/conductor.md`

---

## File Formats

### Backlog Task

```markdown
### Task title
- status: not_started
- priority: high
- description: |
    Detailed description of what needs to be done.
```

### PRD Format

```markdown
---
status: ready
assignee: planner
created: 2024-01-15
updated: 2024-01-15
source_task: "Task title from backlog"
questions: []
---

# PRD: Feature Name

## Problem Statement

What problem are we solving?

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Context

Relevant code, patterns, constraints discovered during analysis.

## Out of Scope

What we're explicitly NOT doing.
```

### Plan Format

```markdown
---
status: ready
assignee: implementer
created: 2024-01-15
updated: 2024-01-15
prd: ../prds/feature-name.md
questions: []
---

# Plan: Feature Name

## Summary

Brief description of what will be implemented.

## Implementation Steps

- [ ] Step 1: Description
- [ ] Step 2: Description
- [ ] Step 3: Description

## Files to Modify

| File | Action |
|------|--------|
| src/foo.ts | Create |
| src/bar.ts | Modify |

## Testing Approach

How to test the implementation.

## Definition of Done

- [ ] All steps completed
- [ ] Tests pass
- [ ] Linting passes
```

### Questions Format

In PRD/Plan frontmatter:
```yaml
questions:
  - question: "What authentication method should we use?"
    asked_by: planner
    date: 2024-01-15
    answer: "Use JWT with refresh tokens"
    answered_by: human
    answered_date: 2024-01-16
```

Or simpler format:
```yaml
questions:
  - "What authentication method should we use? (asked by planner)"
```

---

## Usage

### With Claude Code

```bash
# Pick a task and create PRD
claude "Use the picker agent to select the next task from backlog"

# Create an implementation plan
claude "Use the planner agent to create a plan for the ready PRD"

# Review and refine the plan
claude "Use the refiner agent to review the ready plan"

# Implement the plan
claude "Use the implementer agent to implement the ready plan"
```

### With Cursor

In Cursor chat:
```
Pick the next task from backlog and create a PRD

Create an implementation plan for the ready PRD

Review and refine the ready plan

Implement the ready plan
```

### As a Human

Edit files directly:
1. **Add tasks**: Edit backlog file from config (`paths.backlog`, default: `.workflow/backlog.md`)
2. **Advance work**: Change `status` and `assignee` fields
3. **Answer questions**: Update the `questions` field
4. **Review**: Read PRDs and plans, add comments

---

## Configuration

Config file (typically `.workflow/config.yaml`):
All agents can accept an optional config file path; when provided, use it for `paths.*` and `commands.*` instead of the default.
Paths shown below are defaults; update `paths` to move workflow files.

```yaml
workflow:
  name: "My Project"
  version: "1.0"

paths:
  backlog: ".workflow/backlog.md"
  prds: ".workflow/prds"
  plans: ".workflow/plans"
  questions: ".workflow/questions.md"
  action_log: ".workflow/action-log.md"

agents:
  picker:
    enabled: true
    auto_browser: true
  planner:
    enabled: true
    strictness: high  # high|medium|low
  refiner:
    enabled: true
    strictness: high  # high|medium|low
  implementer:
    enabled: true
    auto_commit: true
    run_tests: true
    run_lint: true

commands:
  test: "npm test"
  lint: "npm run lint"
  build: "npm run build"

boundaries:
  never_touch:
    - "*.lock"
    - ".git/**"
    - "node_modules/**"

# Conductor orchestration settings
orchestration:
  name: default
  phases: [pick, plan, refine, implement]
  max_iterations: 20
  stop_on_first_block: false

# Git settings for implementer
git:
  branch_prefix: "feat/"
  create_pr: true
  pr_draft: true
  commit_per_step: false
  never_merge: true
```

---

## Git Workflow

The implementer agent follows a strict git workflow:

### Branch Strategy

- One branch per feature: `feat/[slug]`
- Implementer creates branch if it doesn't exist
- All commits go to the feature branch

### Commit Behavior

- Commits after completing implementation steps
- Commit messages reference the plan: `feat(user-auth): implement step 2 - add auth middleware`

### PR Workflow

- Opens PR when feature is complete (draft if configured)
- **Agents NEVER merge** - only humans (or future review agents) merge
- PR link is saved to plan frontmatter

### Configuration

```yaml
git:
  branch_prefix: "feat/"       # prefix for feature branches
  create_pr: true              # auto-create PR when implementation complete
  pr_draft: true               # create as draft PR
  commit_per_step: false       # true = commit after each step, false = batch commits
  never_merge: true            # safety: agents cannot merge PRs
```

---

## Parallel Conductors

Multiple conductors can run in parallel when assigned **different phases**.

### Phase Isolation

Each phase reads and writes different status/assignee combinations, so there are no conflicts:

| Phase | Reads status | Writes status | Safe to parallelize with |
|-------|--------------|---------------|--------------------------|
| pick | `backlog: not_started` | `PRD: assignee=planner` | plan, refine, implement |
| plan | `PRD: assignee=planner` | `plan: assignee=refiner` | pick, refine, implement |
| refine | `plan: assignee=refiner` | `plan: assignee=implementer` | pick, plan, implement |
| implement | `plan: assignee=implementer` | `plan: status=done` | pick, plan, refine |

### Rules

- Each phase should only run on ONE conductor at a time
- Multiple conductors with different phases can run in parallel
- The `action-log.md` tracks which conductor ran which phases

### Example Setup

```bash
# Terminal 1: Pick and plan
/conduct --name frontend --phases pick,plan

# Terminal 2: Review
/conduct --name reviewer --phases refine

# Terminal 3: Build
/conduct --name builder --phases implement
```

### Example Configurations

```yaml
# Single conductor - all phases (default)
orchestration:
  name: default
  phases: [pick, plan, refine, implement]

# Split across conductors
# conductor-frontend.yaml
orchestration:
  name: frontend
  phases: [pick, plan]

# conductor-review.yaml
orchestration:
  name: reviewer
  phases: [refine]

# conductor-build.yaml
orchestration:
  name: builder
  phases: [implement]
```

---

## Troubleshooting

### Agent says "No tasks/PRDs/plans ready"

Check that files have the correct status and assignee:
- Tasks in backlog need `status: not_started`
- PRDs for planner need `status: ready`, `assignee: planner`
- Plans for refiner need `status: ready`, `assignee: refiner`
- Plans for implementer need `status: ready`, `assignee: implementer`

### Task is stuck in "blocked"

1. Check the `questions` field in the PRD/plan
2. Answer the questions
3. Change `status: ready` and set appropriate `assignee`

### Agent modified files it shouldn't have

Add the files to `boundaries.never_touch` in config.yaml.

### Tests/linting commands are wrong

Update `commands.test` and `commands.lint` in config.yaml for your project.

### Want to skip a stage

You can manually change status/assignee to skip stages:
- Skip refiner: Set plan `assignee: implementer` directly
- Skip planning: Create plan manually, set `status: ready`, `assignee: implementer`

---

## Best Practices

1. **Keep tasks small** - Large tasks lead to large PRDs and plans that are hard to review
2. **Be specific in acceptance criteria** - Vague criteria lead to vague implementations
3. **Answer questions promptly** - Blocked items slow down the whole pipeline
4. **Review before implementing** - Catching issues in planning is cheaper than in code
5. **Use the questions system** - Don't guess, ask and document the answer
