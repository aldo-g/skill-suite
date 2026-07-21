---
name: pr-ship
description: |
  Create a pull request linked to a ticket (Linear, GitHub Issues, Jira)
  with a clear description and gitmoji prefix. Detects ticket from branch name,
  picks the right emoji for the change type, writes a concise PR body, and
  opens the PR with gh CLI. Use when: "make a PR", "open a pull request",
  "ship this branch", "create PR", "wrap up this branch", "link ticket to PR".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# /pr-ship — Create a Ticket-Linked PR with Gitmoji

You are running the `/pr-ship` workflow. Create a well-formatted pull request
linked to a ticket, using a gitmoji prefix that matches the change type.

Do NOT ask for confirmation at every step. Detect what you can, ask only for
what you can't determine, then create the PR.

---

## Step 1: Pre-flight

```bash
# Check we're in a git repo with a remote
git remote get-url origin 2>/dev/null || echo "NO_REMOTE"
# Current branch
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
# Check if gh is available and authed
gh auth status 2>/dev/null && echo "GH_OK" || echo "GH_MISSING"
# Check if PR already exists
gh pr view --json number,url 2>/dev/null || echo "NO_PR"
```

If `NO_REMOTE`: abort with "No git remote found. Push this branch to a remote first."
If `GH_MISSING`: abort with "gh CLI not found or not authenticated. Run `gh auth login` first."
If a PR already exists: show the URL and ask "A PR already exists. Do you want to update its description, or stop?"

---

## Step 2: Detect the ticket

Parse the ticket from the branch name. Common patterns:

- `feat/ABC-123-some-description` → ticket `ABC-123`
- `fix/GH-42-bug-title` → ticket `GH-42` (GitHub issue)
- `chore/PROJ-99-cleanup` → ticket `PROJ-99`
- `AG-12/feature-name` → ticket `AG-12`
- Any segment matching `[A-Z]+-[0-9]+` or `#[0-9]+`

```bash
_BRANCH=$(git branch --show-current 2>/dev/null)
# Extract ticket-style IDs from branch name
echo "$_BRANCH" | grep -oE '[A-Z]+-[0-9]+' | head -1
echo "$_BRANCH" | grep -oE '#[0-9]+' | head -1
```

If a ticket is found, store it as `TICKET`. If none found, ask:

> I couldn't find a ticket number in your branch name (`{branch}`).
>
> What's the ticket for this PR? Enter a Linear ID (e.g. `AG-42`), a GitHub issue number (e.g. `#99`), a Jira key (e.g. `PROJ-123`), or leave blank if there's no ticket.

Use AskUserQuestion with free-text option (Other). If the user provides one, use it. If blank/skip, set `TICKET` to empty.

---

## Step 3: Understand the diff

```bash
# Detect base branch
_BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null \
  || gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null \
  || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' \
  || echo "main")
echo "BASE: $_BASE"

# Get change summary
git fetch origin "$_BASE" 2>/dev/null || true
git diff "origin/$_BASE"...HEAD --stat
git log "origin/$_BASE"..HEAD --oneline
# Files changed by category
git diff "origin/$_BASE"...HEAD --name-only
```

Read the diff to understand:
1. What type of change is this? (feature, fix, refactor, docs, chore, test, style, perf, build, ci)
2. What's the main thing it does? (1 sentence, plain English, user-outcome framing)
3. What are the 2-3 most important things it changes?

---

## Step 4: Pick the gitmoji

Based on the primary change type detected in Step 3, pick ONE gitmoji prefix:

| Change type | Emoji | When to use |
|-------------|-------|-------------|
| New feature | ✨ | Adds new user-visible functionality |
| Bug fix | 🐛 | Fixes broken behavior |
| Performance | ⚡️ | Makes something faster |
| Refactor | ♻️ | Same behavior, better code |
| UI / style | 💄 | Visual or styling changes |
| Tests | ✅ | Adds or fixes tests |
| Docs | 📝 | Documentation only |
| Chore / build | 🔧 | Config, tooling, dependencies |
| CI/CD | 👷 | Pipeline or automation changes |
| Security | 🔒 | Security fixes or hardening |
| Remove code | 🔥 | Deletes code or files |
| Database | 🗃️ | Migrations or schema changes |
| i18n | 🌐 | Internationalization |
| Accessibility | ♿️ | a11y improvements |
| WIP | 🚧 | Work in progress (avoid for final PRs) |

If the change spans multiple types (e.g. feature + tests), pick the most prominent one.

---

## Step 5: Write the PR title and body

**Title format:** `{emoji} {concise title} [{TICKET}]`
- If no ticket: `{emoji} {concise title}`
- Title should complete the sentence "This PR..." in plain English
- Max 72 characters
- No trailing punctuation

**Body format:**

```markdown
## What

{1-2 sentence plain-English description of what this does and why}

## Changes

- {bullet: specific thing changed}
- {bullet: specific thing changed}
- {bullet: specific thing changed, max 5}

## Ticket

{ticket link or "No ticket"}

## Test plan

- [ ] {specific thing to manually verify}
- [ ] {edge case to check}
```

**Ticket link rules:**
- Linear `ABC-123` → `https://linear.app/team/issue/ABC-123` (use if you can infer team slug from the ticket prefix, otherwise just the ID)
- GitHub `#42` → references it inline so GitHub auto-links it; also add `Closes #42` if it's a fix
- Jira `PROJ-123` → just the key, no link (you don't know the instance URL)
- No ticket → write "No ticket"

For GitHub Issues: if the change is a bug fix, add `Closes #{number}` at the top of the body so GitHub auto-closes the issue on merge.

---

## Step 6: Show the draft and confirm

Print the draft title and body to the user. Say:

> Here's the PR draft. Creating it now...

Then immediately create it — do NOT stop to ask for approval unless something is clearly wrong. The user can edit after.

---

## Step 7: Create the PR

```bash
gh pr create \
  --title "{TITLE}" \
  --body "$(cat <<'PREOF'
{BODY}
PREOF
)" \
  --base "{BASE}"
```

Print the PR URL when done.

If the base branch isn't pushed yet, push first:
```bash
git push -u origin "$(git branch --show-current)"
```

---

## Step 8: Post-creation

After the PR is created:

1. Print the URL clearly: "PR created: {url}"
2. If a Linear ticket was detected, note: "Link the PR to your Linear ticket if your Linear workspace has the GitHub integration — it may auto-link via branch name."
3. Suggest next steps in one line: "Next: get a review, then run `/land-and-deploy` to merge."

---

## Rules

- If there are no commits on the branch vs base: abort with "Nothing to PR — no commits ahead of {base}."
- Never push to main/master directly.
- Never create a PR from main/master.
- If `gh pr create` fails due to an untracked branch, push first then retry once.
- Keep the PR body concise — 5 bullets max, no walls of text.
- The emoji goes at the START of the title, not in the body.
