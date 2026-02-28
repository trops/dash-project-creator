#!/bin/bash

# create-dash-project.sh
# Creates a new Dash Electron project from the trops/dash-electron template.
# Usage: ./create-dash-project.sh <project-name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helper: rename package.json for the new project ---
# Usage: rename_package <new-name> <repo-url> <author>
#   new-name:  e.g. "@owner/my-project" or "my-project"
#   repo-url:  e.g. "https://github.com/owner/my-project" or "" to clear
#   author:    e.g. "Jane Doe" — the new project author
rename_package() {
    local NEW_NAME="$1"
    local REPO_URL="$2"
    local AUTHOR="$3"
    node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.name = '$NEW_NAME';
pkg.author = '$AUTHOR';
pkg.repository = pkg.repository || {};
pkg.repository.url = '$REPO_URL';
delete pkg.publishConfig;
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
    rm -f .github/workflows/update_package_name.yml
}

# --- Validation ---

if [ -z "$1" ]; then
    echo -e "${RED}Error: Project name required.${NC}"
    echo "Usage: ./create-dash-project.sh <project-name>"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_DIR="$(pwd)/$PROJECT_NAME"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory '$PROJECT_NAME' already exists.${NC}"
    exit 1
fi

# --- Check for git ---

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    echo "Install it from https://git-scm.com"
    exit 1
fi

# --- Check Node.js version ---

if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed.${NC}"
    echo "Install v18, v20, or v22 (LTS) from https://nodejs.org"
    exit 1
fi

NODE_MAJOR=$(node -v | cut -d'.' -f1 | tr -d 'v')
if [ "$NODE_MAJOR" -gt 22 ]; then
    echo -e "${YELLOW}Warning: Node.js v${NODE_MAJOR} detected. Dash requires v18, v20, or v22 (LTS).${NC}"
    echo "Use nvm to switch: nvm install 20 && nvm use 20"
    exit 1
fi

# --- Ask user: GitHub repo or local only ---

echo ""
echo "How would you like to create the project?"
echo ""
echo "  1) Create a GitHub repo from the template (requires gh CLI)"
echo "     → Creates a remote repo on your GitHub and clones it locally"
echo ""
echo "  2) Local only (no remote repo)"
echo "     → Downloads the template into a local folder, no GitHub repo created"
echo ""
read -p "Choose [1/2]: " CHOICE

case "$CHOICE" in
    1)
        # --- GitHub repo from template ---

        if ! command -v gh &> /dev/null; then
            echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
            echo "Install it from https://cli.github.com"
            echo "Then run: gh auth login"
            exit 1
        fi

        if ! gh auth status &> /dev/null; then
            echo -e "${RED}Error: GitHub CLI is not authenticated.${NC}"
            echo "Run: gh auth login"
            exit 1
        fi

        echo ""
        read -p "Create as public or private repo? [public/private]: " VISIBILITY
        VISIBILITY=${VISIBILITY:-public}

        if [ "$VISIBILITY" != "public" ] && [ "$VISIBILITY" != "private" ]; then
            echo -e "${RED}Error: Choose 'public' or 'private'.${NC}"
            exit 1
        fi

        echo ""
        echo -e "${GREEN}Creating GitHub repo from trops/dash-electron template...${NC}"
        gh repo create "$PROJECT_NAME" --template trops/dash-electron --"$VISIBILITY" --clone

        cd "$PROJECT_DIR"

        # Rename package to @owner/project-name
        GH_OWNER=$(gh api user --jq .login)
        GH_AUTHOR=$(gh api user --jq '.name // .login')
        rename_package "@${GH_OWNER}/${PROJECT_NAME}" "https://github.com/${GH_OWNER}/${PROJECT_NAME}" "$GH_AUTHOR"
        git add -A && git commit -m "Rename package to @${GH_OWNER}/${PROJECT_NAME}" && git push origin HEAD
        ;;

    2)
        # --- Local only ---

        echo ""
        echo -e "${GREEN}Downloading trops/dash-electron template...${NC}"

        # Clone the template, then disconnect from the original remote
        git clone https://github.com/trops/dash-electron.git "$PROJECT_DIR"
        cd "$PROJECT_DIR"

        # Rename package to project-name (no scope for local projects)
        GIT_AUTHOR=$(git config user.name 2>/dev/null || echo "")
        rename_package "$PROJECT_NAME" "" "$GIT_AUTHOR"

        rm -rf .git
        git init
        git add .
        git commit -m "Initial commit from dash-electron template"
        ;;

    *)
        echo -e "${RED}Invalid choice. Please run again and choose 1 or 2.${NC}"
        exit 1
        ;;
esac

# --- Project setup ---

echo ""
echo -e "${GREEN}Setting up project...${NC}"

cp .env.default .env 2>/dev/null || echo -e "${YELLOW}Note: No .env.default found, skipping .env setup.${NC}"

echo ""
echo -e "${GREEN}Installing dependencies...${NC}"
npm run setup

echo ""
echo -e "${GREEN}✓ Project '$PROJECT_NAME' created successfully!${NC}"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  npm run dev                              # Start the dev server"
echo "  node ./scripts/widgetize MyWidget        # Scaffold a new widget"
echo ""
