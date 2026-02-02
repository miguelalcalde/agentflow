---
name: feature-workflow
description: |
  Structured workflow for taking features from backlog to implementation.
  Use when picking tasks, refining PRDs, planning implementation, or implementing features.
  Invokes specialized agents: picker, refiner, planner, implementer, conductor.
---

# Feature Workflow

A structured workflow for taking features from backlog to implementation using specialized agents.

## Workflow Overview

```
Backlog → /pick → PRD → /refine → PRD (refined) → /plan → Plan → /implement → Code
```

**Manual mode**: Each step is human-triggered. Agents do not auto-chain.

**Conductor mode**: Run `/conduct` to orchestrate all phases automatically until complete or blocked.

## Commands

| Command                | Agent       | Purpose                                    |
| ---------------------- | ----------- | ------------------------------------------ |
| `/pick`                | picker      | Select task from backlog, create blank PRD |
| `/refine [slug]`       | refiner     | Complete and validate PRD                  |
| `/plan [slug]`         | planner     | Create implementation plan                 |
| `/implement [slug]`    | implementer | Execute plan on feature branch             |
| `/conduct`             | conductor   | Orchestrate all phases in a loop           |
| `/conduct --phases X`  | conductor   | Run specific phases only (e.g., pick,plan) |
| `/conduct --slug X`    | conductor   | Process specific feature only              |

## Agents

| Agent           | Branch       | Writes To                    | Tools                              |
| --------------- | ------------ | ---------------------------- | ---------------------------------- |
| **picker**      | main         | `{paths.prds}/`, `{paths.backlog}` | Read, Write, Glob                  |
| **refiner**     | main         | `{paths.prds}/`              | Read, Write, Edit, Grep, Glob      |
| **planner**     | main         | `{paths.plans}/`, `{paths.prds}/` | Read, Write, Edit, Grep, Glob |
| **implementer** | feature/*    | Source code                  | Read, Write, Edit, Grep, Glob, Bash|
| **conductor**   | main         | `{paths.action_log}`, orchestrates| Read, Write, Grep, Glob            |

## Naming Convention

The workflow uses descriptive **slugs** instead of numeric IDs:

| Artifact      | Format           | Example                           |
| ------------- | ---------------- | --------------------------------- |
| Backlog entry | `[slug] Title`   | `[user-auth] User Authentication` |
| PRD file      | `PRD-[slug].md`  | `PRD-user-auth.md`                |
| Plan file     | `PLAN-[slug].md` | `PLAN-user-auth.md`               |
| Branch        | `feat/[slug]`    | `feat/user-auth`                  |

Slugs: lowercase kebab-case, max 30 characters.

## Status Flow

### PRD Statuses

```
blank → refined → needs_review → approved
```

### Plan Statuses

```
draft → needs_review → approved → implemented
```

## Human Checkpoints

- After **Pick**: Review selected task, adjust if needed
- After **Refine**: Review PRD, mark as `approved` if ready
- After **Plan**: Review plan, mark as `approved` if ready
- After **Implement**: Review code, create PR manually

## Project Setup

Each project using this workflow needs a workflow directory (configured in `paths`, default: `.workflow/`):

```
your-project/
└── .workflow/  # default; configurable via config.yaml paths
    ├── config.yaml
    ├── backlog.md
    ├── action-log.md
    ├── prds/
    └── plans/
```

## Example Usage

### Manual Mode (step-by-step)

```bash
# Pick the highest priority task
/pick

# Refine a specific PRD
/refine user-auth

# Create implementation plan
/plan user-auth

# Execute the plan
/implement user-auth
```

### Conductor Mode (automated)

```bash
# Run full pipeline until complete or blocked
/conduct

# Run only pick and plan phases
/conduct --phases pick,plan

# Process specific feature only
/conduct --slug user-auth

# Named conductor for parallel operation
/conduct --name frontend --phases pick,plan
```

### Parallel Conductors

Multiple conductors can run in parallel when handling different phases:

```bash
# Terminal 1: Create PRDs and plans
/conduct --name frontend --phases pick,plan

# Terminal 2: Review plans
/conduct --name reviewer --phases refine

# Terminal 3: Implement approved plans
/conduct --name builder --phases implement
```
