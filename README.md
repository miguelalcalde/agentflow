# Agent Workflow

A file-based multi-agent workflow system where AI agents (Picker, Planner, Refiner, Implementer) and humans work together on software tasks. Compatible with **Claude Code** and **Cursor**.

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

## What Gets Installed

```
your-project/
├── .workflow/
│   ├── config.yaml      # Workflow configuration
│   ├── backlog.md       # Task backlog
│   ├── questions.md     # Open questions tracker
│   ├── prds/            # PRD documents
│   └── plans/           # Implementation plans
├── .claude/agents/      # Claude Code agent definitions
│   ├── picker.md
│   ├── planner.md
│   ├── refiner.md
│   └── implementer.md
└── .cursor/rules/       # Cursor workflow rules
    └── workflow-agents.mdc
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

### Human + AI Collaboration

The workflow is designed so **humans and AI are interchangeable**:
- Any participant can advance a task by updating status
- Questions can be asked by anyone, answered by anyone
- Files are human-readable markdown - no special tools needed

## Usage

### With Claude Code

```bash
# Pick a task and create a PRD
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

Just edit the files directly:
1. Add tasks to `.workflow/backlog.md`
2. Change `status` and `assignee` fields to advance work
3. Answer questions in PRD/plan files
4. Review and approve before implementation

## Configuration

Edit `.workflow/config.yaml` to customize:

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
- File format specifications
- Status transition diagrams
- Troubleshooting guide

## License

MIT
