---
name: init-project
description: |
  Set up a new GitHub repository from scratch or from an existing local directory.
  Creates the repo with gh CLI, pushes an initial commit, configures GitHub Issues
  as the ticket system, sets up branch protection on main, and writes a CLAUDE.md
  so the /new-work and /pr-ship skills work immediately.
  Use when: "init project", "initialise project", "new project", "create a repo",
  "set up GitHub", "start a project", "initialise a repo", "new repo", "create github repo".
allowed-tools:
  - Bash
  - AskUserQuestion
  - Write
  - Edit
  - Read
---

# /new-project — Create a GitHub Repo and Wire Up the Workflow

You are running the `/new-project` workflow. By the end, the user has a GitHub
repo with Issues enabled, a CLAUDE.md that tells future skills how to work,
and everything ready for `/new-work` to start the first ticket.

This is purely `gh` CLI + git — no browser needed.

---

## Step 1: Pre-flight

```bash
# Locate gh CLI (may not be on default PATH in sandboxed environments)
GH=$(which gh 2>/dev/null || ls /opt/homebrew/bin/gh /usr/local/bin/gh 2>/dev/null | head -1)
[ -n "$GH" ] && echo "GH_PATH: $GH" || echo "GH_MISSING"
# Check auth
$GH auth status 2>/dev/null && echo "GH_OK" || echo "GH_MISSING"
# Who is the authed user?
$GH api user --jq '.login' 2>/dev/null || echo "UNKNOWN_USER"
# Are we already in a git repo?
git rev-parse --show-toplevel 2>/dev/null && echo "ALREADY_GIT" || echo "NOT_GIT"
# What's in the current directory?
ls -1 | head -30
# Detect project type
[ -f package.json ] && echo "RUNTIME:node" && cat package.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('FRAMEWORK:' + ('nextjs' if 'next' in d.get('dependencies',{}) else 'node'))" 2>/dev/null || true
[ -f requirements.txt ] || [ -f pyproject.toml ] && echo "RUNTIME:python" || true
[ -f go.mod ] && echo "RUNTIME:go" || true
[ -f Cargo.toml ] && echo "RUNTIME:rust" || true
[ -f Gemfile ] && echo "RUNTIME:ruby" || true
```

If `GH_MISSING`: abort — "gh CLI not found or not authenticated. Run `gh auth login` first."

Store the GitHub username as `GH_USER`.
Store detected runtime/framework for use in Steps 3 and 5.

---

## Step 2: Project details

Use AskUserQuestion:

> What's this project?
>
> A) It already exists in this directory — just create the GitHub repo and push it
> B) I'm starting fresh — create a new directory and initialise it

Then ask:

> **Project name** — what should the GitHub repo be called? (kebab-case, e.g. `my-api`)
> **Description** — one sentence for the repo description on GitHub.
> **Visibility:**
> A) Private (recommended)
> B) Public

Store as `REPO_NAME`, `REPO_DESC`, `VISIBILITY` (private/public).

---

## Step 3: Initialise git (if needed)

If `NOT_GIT` or user chose "start fresh":

```bash
# If starting fresh, create the directory
mkdir -p "{REPO_NAME}" && cd "{REPO_NAME}" || true
git init
git branch -M main
```

If already a git repo with commits, skip init.

### Gitignore

Check if `.gitignore` already exists. If not, create one based on detected runtime:

**Node / Next.js:**
```
node_modules/
.next/
.env
.env.local
.env*.local
dist/
.DS_Store
*.log
.claude/work-brief.md
```

**Python:**
```
__pycache__/
*.py[cod]
.env
venv/
.venv/
dist/
*.egg-info/
.DS_Store
.claude/work-brief.md
```

**Go:**
```
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
vendor/
.DS_Store
.claude/work-brief.md
```

**Blank / unknown:**
```
.env
.env.local
.DS_Store
*.log
.claude/work-brief.md
```

Always include `.claude/work-brief.md` in the gitignore.

---

## Step 4: Write CLAUDE.md

Check if `CLAUDE.md` already exists. If it does, read it and add a `## Ticket System`
section only if one doesn't exist. If it doesn't exist, create it.

```markdown
# {REPO_NAME}

{REPO_DESC}

## Ticket System

This project uses **GitHub Issues** for tracking work.

- Reference issues as `#42` in branch names and PR descriptions
- The `/new-work` skill will ask for an issue number when starting work
- The `/pr-ship` skill will link PRs to issues automatically
- Bug fixes should include `Closes #N` in the PR body to auto-close on merge

To create an issue before starting work:
```bash
gh issue create --title "Short title" --body "Description"
```

## Workflow

1. `/new-work` — start a ticket, create a branch
2. Code the thing
3. `/pr-ship` — open a PR linked to the ticket
4. Get a review, merge

## Branch naming

`{type}/{issue-number}-short-description`

Examples:
- `feat/gh-42-add-auth`
- `fix/gh-99-broken-login`
- `chore/gh-12-upgrade-deps`

## Skills

- `/new-work` — start work on a ticket, create a branch
- `/pr-ship` — wrap up work, open a PR with gitmoji and ticket link
```

---

## Step 5: Initial commit

```bash
git add -A
git status --short
```

If there are files to commit:

```bash
git commit -m "🎉 initial commit"
```

If the repo already had commits, skip this.

---

## Step 6: Create the GitHub repo and push

```bash
gh repo create "{REPO_NAME}" \
  --{VISIBILITY} \
  --description "{REPO_DESC}" \
  --source=. \
  --remote=origin \
  --push
```

If the repo already has a remote (ALREADY_GIT with remote), just push:

```bash
gh repo create "{REPO_NAME}" --{VISIBILITY} --description "{REPO_DESC}" 2>/dev/null || true
git remote add origin "https://github.com/{GH_USER}/{REPO_NAME}.git" 2>/dev/null || true
git push -u origin main
```

Print the repo URL: `https://github.com/{GH_USER}/{REPO_NAME}`

---

## Step 7: Enable GitHub Issues and set up labels

```bash
# Enable Issues (on by default, but confirm)
gh repo edit "{GH_USER}/{REPO_NAME}" --enable-issues 2>/dev/null || true

# Create useful labels (delete defaults first to avoid clutter)
gh label delete "documentation" --yes 2>/dev/null || true
gh label delete "duplicate" --yes 2>/dev/null || true
gh label delete "good first issue" --yes 2>/dev/null || true
gh label delete "help wanted" --yes 2>/dev/null || true
gh label delete "invalid" --yes 2>/dev/null || true
gh label delete "question" --yes 2>/dev/null || true
gh label delete "wontfix" --yes 2>/dev/null || true

# Create clean label set
gh label create "feat" --color "0075ca" --description "New feature" 2>/dev/null || true
gh label create "fix" --color "d73a4a" --description "Bug fix" 2>/dev/null || true
gh label create "chore" --color "e4e669" --description "Maintenance, deps, config" 2>/dev/null || true
gh label create "perf" --color "0e8a16" --description "Performance improvement" 2>/dev/null || true
gh label create "refactor" --color "cfd3d7" --description "Code cleanup, no behaviour change" 2>/dev/null || true
gh label create "blocked" --color "b60205" --description "Blocked on something external" 2>/dev/null || true
```

---

## Step 8: Branch protection on main

```bash
gh api repos/{GH_USER}/{REPO_NAME}/branches/main/protection \
  --method PUT \
  --field required_status_checks=null \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":0}' \
  --field restrictions=null \
  2>/dev/null && echo "BRANCH_PROTECTION_OK" || echo "BRANCH_PROTECTION_SKIPPED"
```

If `BRANCH_PROTECTION_SKIPPED`: note "Branch protection requires the repo to be on a paid plan or have specific settings — skipping. You can enable it in Settings > Branches."

This sets up: PRs required to merge to main (no direct pushes), 0 required reviewers (since this may be a solo project — user can add reviewers later).

---

## Step 9: Summary

Print:

```
PROJECT READY
═══════════════════════════════════════════════
Repo:       https://github.com/{GH_USER}/{REPO_NAME}
Issues:     https://github.com/{GH_USER}/{REPO_NAME}/issues
Visibility: {private/public}
Branch:     main (protected — PRs required)
Labels:     feat, fix, chore, perf, refactor, blocked
═══════════════════════════════════════════════

Next steps:
  1. Create your first issue:
     gh issue create --title "..." --label feat
  2. Start work:
     /new-work
```

---

## Rules

- Never push to a repo without confirming the repo name with the user.
- If the directory already has a remote pointing somewhere else, warn and stop before overwriting.
- The `🎉` initial commit emoji is a gitmoji convention for repo initialisation — keep it.
- CLAUDE.md is the source of truth for skills — always write it, never skip it.
- Branch protection with 0 required reviewers means the user can still self-merge via `gh pr merge` but can't push directly — this enforces the PR workflow without blocking solo work.
