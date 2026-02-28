# dash-project-creator

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill for creating new [Dash Electron](https://github.com/trops/dash-electron) dashboard projects from the template repository.

## What is Dash?

Dash is a four-repo ecosystem for building dashboard applications:

| Repo | Purpose |
|------|---------|
| [dash-electron](https://github.com/trops/dash-electron) | Electron app template — your starting project |
| [dash-core](https://github.com/trops/dash-core) | Framework internals — widget system, MCP, providers |
| [dash-react](https://github.com/trops/dash-react) | UI component library |
| [dash-registry](https://github.com/trops/dash-registry) | Widget marketplace & project scaffolding |

## Installation

Clone this repo into your Claude Code skills directory:

```bash
git clone https://github.com/trops/dash-project-creator.git ~/.claude/skills/dash-project-creator
```

Once installed, Claude Code will automatically detect the skill and use it when you ask to create a new Dash project.

## Prerequisites

- **git** — [git-scm.com](https://git-scm.com)
- **Node.js** v18, v20, or v22 (LTS) — [nodejs.org](https://nodejs.org)
- **GitHub CLI** (`gh`) — only required for creating GitHub repos — [cli.github.com](https://cli.github.com)

## Usage

### Via Claude Code

Open Claude Code and say something like:

- "Create a new Dash project"
- "I want to build a dashboard app"
- "Scaffold a new dash-electron project"

The skill will walk you through naming the project, choosing between a GitHub repo or local-only setup, and running the full setup automatically.

### Standalone script

The bundled shell script can also be run directly:

```bash
bash ~/.claude/skills/dash-project-creator/create-dash-project.sh <project-name>
```

This runs an interactive flow that prompts for GitHub vs. local setup, handles cloning, package renaming, and dependency installation.

## What it does

1. Clones the [trops/dash-electron](https://github.com/trops/dash-electron) template
2. Renames the package from `@trops/dash-electron` to your project name (scoped with your GitHub username for GitHub repos, unscoped for local projects)
3. Removes template-specific config (`publishConfig`, broken `update_package_name.yml` workflow)
4. Copies `.env.default` to `.env`
5. Runs `npm run setup` to install dependencies

After setup, each project includes a built-in `dash-widget-builder` skill at `.claude/skills/dash-widget-builder/` for building widgets inside the project.
