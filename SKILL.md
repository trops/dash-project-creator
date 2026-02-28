---
name: dash-project-creator
description: >
  Create new Dash Electron dashboard projects from the trops/dash-electron template.
  Use this skill when the user wants to create a new Dash project, scaffold a new
  dashboard app, or set up a fresh dash-electron repo. Trigger when the user mentions
  "new dash project", "create a dashboard", "dash-electron template", "new widget project",
  or says something like "I want to build a dashboard app".
  Do NOT use this skill for building widgets inside an existing project — that is
  handled by the dash-widget-builder skill which ships inside the project itself.
---

# Dash Project Creator

Creates new [Dash Electron](https://github.com/trops/dash-electron) dashboard projects
from the template repository.

## What is Dash?

Dash is a **four-repo ecosystem** for building dashboard applications:

| Repo | Purpose |
|------|---------|
| [dash-electron](https://github.com/trops/dash-electron) | Electron app template — your starting project |
| [dash-core](https://github.com/trops/dash-core) | Framework internals — widget system, MCP, providers |
| [dash-react](https://github.com/trops/dash-react) | UI component library |
| [dash-registry](https://github.com/trops/dash-registry) | Widget marketplace & project scaffolding |

New projects are created from the dash-electron template. The template includes
sample widgets, a widget scaffold generator (`widgetize`), and a built-in skill
for building widgets (`.claude/skills/dash-widget-builder/`).

---

## Workflow

When the user asks to create a new Dash project, follow these steps in order:

### Step 1: Check prerequisites (silently)

```bash
git --version
node --version
```

- **git** is required. If missing, tell the user to install from https://git-scm.com
- **Node.js** must be v18, v20, or v22 (LTS). If v24+, tell the user to switch:
  `nvm install 20 && nvm use 20`

Do not ask the user anything until prerequisites pass.

### Step 2: Ask the project name

Ask as a plain text question: "What would you like to name the project?"

### Step 3: Ask GitHub repo vs local

Give the user a choice:
- **Create a GitHub repo from the template** — requires `gh` CLI installed and
  authenticated. Creates a remote repo on their GitHub and clones it locally.
- **Local only** — clones the template and disconnects from the upstream remote.
  Only requires `git`, no GitHub account needed.

### Step 4: Check additional prerequisites (if GitHub repo)

If they chose GitHub repo:
```bash
gh --version
gh auth status
```

If either fails, explain what's needed:
- **No `gh`**: Install from https://cli.github.com, then run `gh auth login`
- **Not authenticated**: Run `gh auth login`

Offer to fall back to local-only if they don't want to set up `gh` right now.

### Step 5: Confirm before executing

Show the user a summary of what will happen:

```
Here's what I'm going to do:

- Create project "<name>" in <current directory>/<name>/
- [GitHub repo from template / Clone locally and initialize fresh git history]
- Rename package from @trops/dash-electron to <name> and remove template-specific config
- Copy .env.default → .env
- Run npm run setup to install dependencies

This will take a few minutes. Ready to proceed?
```

Wait for confirmation before running any commands.

### Step 6: Execute

**Local only:**
```bash
git clone https://github.com/trops/dash-electron.git <project-name>
cd <project-name>
# Rename package and clean up template-specific config
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.name = '<project-name>';
pkg.author = '$(git config user.name)';
pkg.repository = pkg.repository || {};
pkg.repository.url = '';
delete pkg.publishConfig;
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
rm -f .github/workflows/update_package_name.yml
rm -rf .git
git init
git add . && git commit -m "Initial commit from dash-electron template"
cp .env.default .env
npm run setup
```

**GitHub repo from template:**
```bash
gh repo create <project-name> --template trops/dash-electron --public --clone
cd <project-name>
# Rename package and clean up template-specific config
GH_OWNER=$(gh api user --jq .login)
GH_AUTHOR=$(gh api user --jq '.name // .login')
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.name = '@${GH_OWNER}/<project-name>';
pkg.author = '${GH_AUTHOR}';
pkg.repository = pkg.repository || {};
pkg.repository.url = 'https://github.com/${GH_OWNER}/<project-name>';
delete pkg.publishConfig;
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
rm -f .github/workflows/update_package_name.yml
git add -A && git commit -m "Rename package to @${GH_OWNER}/<project-name>" && git push origin HEAD
cp .env.default .env
npm run setup
```

If the user chose GitHub repo, ask them whether it should be `--public` or `--private`.

### Step 7: Report success

Tell the user the project is ready and suggest next steps:

```
✓ Project "<name>" created at <path>

Next steps:
  cd <name>
  npm run dev                              # Start the dev server
  node ./scripts/widgetize MyWidget        # Scaffold a new widget

The project includes a widget-building skill in .claude/skills/.
When you open this project in Claude Code, you can ask me to build
widgets and I'll know exactly how to do it.
```

---

## If the user is already in a Dash project

If you detect the user is already inside a Dash project (by checking for
`scripts/widgetize.js`, `src/Widgets/`, and `@trops/dash-core` in `package.json`),
do NOT create a new project. Instead, tell the user:

"You're already inside a Dash project. Would you like me to build some widgets
instead?"

The widget-building skill ships inside the project at `.claude/skills/dash-widget-builder/`.

---

## Reference

The `create-dash-project.sh` script bundled with this skill automates the entire
flow above interactively. It can be run standalone:

```bash
bash create-dash-project.sh <project-name>
```
