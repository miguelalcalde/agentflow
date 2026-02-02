# Agent Workflow

A file-based multi-agent workflow system where AI agents (Picker, Planner, Refiner, Implementer, Conductor) and humans work together on software tasks. Compatible with **Claude Code** and **Cursor**.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/miguelalcalde/agentworkflow/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/miguelalcalde/agentworkflow.git
cd agentworkflow
./install.sh /path/to/your/project
```

## What Gets Installed (defaults)

```
your-project/
├── .workflow/           # Default workflow location (configurable via config.yaml paths)
│   ├── config.yaml      # Workflow configuration
│   ├── backlog.md       # Task backlog
│   ├── action-log.md    # Conductor audit trail
│   ├── questions.md     # Open questions tracker
│   ├── prds/            # PRD documents
│   └── plans/           # Implementation plans
├── .claude/agents/      # Claude Code agent definitions
│   ├── picker.md
│   ├── planner.md
│   ├── refiner.md
│   ├── implementer.md
│   └── conductor.md
├── .cursor/agents/      # Cursor agent definitions (same as above)
└── .cursor/rules/       # Cursor workflow rules
    └── workflow-agents.mdc

~/.cursor/skills/        # User-level (global)
└── feature-workflow/
    └── SKILL.md
```

## How It Works

### The Workflow

```
Backlog → Picker → PRD → Planner → Plan → Refiner → Refined Plan → Implementer → Done
```

Each stage uses **status markers** in files:
- `not_started` - No work begun
- `ready` - Ready for next participant  
- `in_progress` - Currently being worked on
- `blocked` - Has unanswered questions
- `done` - Completed

### The Agents

| Agent | Role |
|-------|------|
| **Picker** | Selects tasks from backlog, analyzes codebase, creates PRDs |
| **Planner** | Takes PRDs, creates detailed implementation plans |
| **Refiner** | Reviews plans, catches issues, asks/answers questions |
| **Implementer** | Executes plans, writes code and tests, commits |
| **Conductor** | Orchestrates all phases in a loop until complete or blocked |

### Human + AI Collaboration

The workflow is designed so **humans and AI are interchangeable**:
- Any participant can advance a task by updating status
- Questions can be asked by anyone, answered by anyone
- Files are human-readable markdown - no special tools needed

## Usage

### With Claude Code

```bash
# Manual mode - step by step
claude "Use the picker agent to select the next task from backlog"
claude "Use the planner agent to create a plan for the ready PRD"
claude "Use the refiner agent to review the ready plan"
claude "Use the implementer agent to implement the ready plan"

# Conductor mode - automated
claude "Use the conductor agent to run the full pipeline"
claude "Use the conductor agent with phases pick,plan only"
```

### With Cursor

```bash
# Manual mode - slash commands
/pick
/plan user-auth
/refine user-auth
/implement user-auth

# Conductor mode - automated
/conduct                          # Run full pipeline
/conduct --phases pick,plan       # Run specific phases
/conduct --slug user-auth         # Process specific feature
```

### As a Human

Just edit the files directly:
1. Add tasks to backlog file from config (`paths.backlog`, default: `.workflow/backlog.md`)
2. Change `status` and `assignee` fields to advance work
3. Answer questions in PRD/plan files
4. Review and approve before implementation

## Configuration

Edit the config file (typically `.workflow/config.yaml`) to customize:

```yaml
workflow:
  name: "My Project"

commands:
  test: "npm test"        # Your test command
  lint: "npm run lint"    # Your lint command

boundaries:
  never_touch:
    - "*.lock"
    - "vendor/**"
```

## File Formats

### Backlog Task

```markdown
### Task title here
- status: not_started
- priority: high
- description: |
    What needs to be done...
```

### PRD/Plan Frontmatter

```yaml
---
status: ready
assignee: planner
created: 2024-01-15
updated: 2024-01-15
questions: []
---
```

## Documentation

See [docs/workflow.md](docs/workflow.md) for complete documentation including:
- Detailed agent instructions
- Conductor orchestration and parallel conductors
- Git workflow (branches, PRs)
- Tool compatibility (Claude Code vs Cursor)
- File format specifications
- Status transition diagrams
- Troubleshooting guide

## License

MIT
