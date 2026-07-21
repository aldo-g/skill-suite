---
name: new-work
description: |
  Start a new piece of work. Runs a discovery conversation to understand the
  problem, defines the work type and scope, asks for or detects a ticket,
  generates a branch name, and checks out the branch ready to code.
  Use when: "start new work", "new feature", "new task", "I need to build X",
  "begin a ticket", "start a branch", "new branch for", "kick off".
allowed-tools:
  - Bash
  - AskUserQuestion
  - Write
  - Read
---

# /new-work — Start a New Piece of Work

You are running the `/new-work` workflow. Before a single line of code is written,
get crystal clear on what the work IS. Then create the right branch.

This is not a planning tool — it is a scoping tool. The output is:
1. A shared understanding of what "done" looks like
2. A branch checked out and ready to code

---

## Step 1: Understand the context

```bash
# What repo/project are we in?
basename "$(git rev-parse --show-toplevel 2>/dev/null)" || basename "$PWD"
# Current branch (to confirm we're on main/base)
git branch --show-current 2>/dev/null || echo "not-a-git-repo"
# What's in this repo? (give context for the discovery questions)
ls -1 | head -20
[ -f CLAUDE.md ] && head -40 CLAUDE.md || true
[ -f README.md ] && head -20 README.md || true
# Any CLAUDE.md mention of ticket system?
grep -iE "linear|jira|github.issues|ticket|tracker" CLAUDE.md 2>/dev/null | head -5 || true
```

If `not-a-git-repo`: abort — "Not in a git repo. `cd` into your project first."

Use what you find to inform the discovery questions. Don't ask things the README already answers.

---

## Step 2: Discovery conversation

Run a focused discovery — not a checklist, a real conversation. The goal is to
understand the problem well enough to write down what "done" looks like.

Ask these questions ONE AskUserQuestion call at a time, in order. Read each answer
before asking the next. Adapt follow-up questions based on what the user says.

### Question 1 — What is the work?

Use AskUserQuestion:

> What are you building or fixing? Describe it in plain English — what it does,
> who benefits, and roughly why now. One paragraph is fine.

(Use "Other" free text input for this one — no fixed options.)

After the answer, classify the work type internally:
- `feat` — new user-visible feature
- `fix` — corrects broken behavior
- `refactor` — same behavior, better code
- `chore` — tooling, deps, config
- `perf` — performance improvement
- `test` — test coverage only
- `docs` — documentation only
- `ci` — CI/CD pipeline

### Question 2 — What does done look like?

Based on their description, ask ONE sharp question about the success criteria.
Frame it around what a user or reviewer would observe, not implementation steps.

Example phrasings:
- "When this is done, what should a user be able to do that they can't today?"
- "How will you know the fix is working — what's the observable difference?"
- "What's the simplest test you'd run to confirm this is complete?"

Use AskUserQuestion with free text (Other).

### Question 3 — Edge cases or constraints

Pick the ONE most important risk or constraint for this type of work and ask about it.

Examples by type:
- `feat`: "Is there anything that should NOT change or break when this ships?"
- `fix`: "When does this bug happen — always, or only in specific conditions?"
- `refactor`: "Any areas of the codebase that are particularly fragile or untested?"
- `chore`: "Any compatibility constraints — minimum Node version, locked deps, etc.?"
- `perf`: "Do you have a target metric, or is it 'noticeably faster'?"

Use AskUserQuestion with free text (Other).

After 3 questions you have enough. Do not ask more unless the answers were
genuinely unclear about the core scope.

---

## Step 3: Detect or define the ticket

Check if a ticket system was mentioned in discovery or in CLAUDE.md:

```bash
grep -iE "linear|jira|github.issues|ticket" CLAUDE.md 2>/dev/null | head -3 || true
```

Use AskUserQuestion:

> Do you have a ticket for this work?
>
> A) Yes — I have a Linear ID (e.g. `AG-42`)
> B) Yes — I have a GitHub Issue number (e.g. `#99`)
> C) Yes — I have a Jira key (e.g. `PROJ-123`)
> D) No ticket — the branch name + PR description will be the record

If A/B/C: ask for the ID with free text (Other).
If D: continue without a ticket ID. The work definition from discovery is the record.

Store the result as `TICKET` (the raw ID) and `TICKET_TYPE` (linear/github/jira/none).

---

## Step 4: Generate the branch name

Using:
- The work type from Step 2 (`feat`, `fix`, etc.)
- The ticket ID from Step 3 (if any)
- A short slug from the work description (3-5 words, kebab-case, no stop words)

**Branch name formats:**

| Has ticket | Format |
|-----------|--------|
| Linear `ABC-123` | `feat/ABC-123-short-description` |
| GitHub `#42` | `feat/gh-42-short-description` |
| Jira `PROJ-99` | `feat/PROJ-99-short-description` |
| No ticket | `feat/short-description` |

Rules for the slug:
- Max 40 chars total for the branch name
- Lowercase, hyphens only
- Drop articles (a, the, an), conjunctions, prepositions
- Keep the most meaningful nouns and verbs

Generate 2-3 branch name options and show them.

---

## Step 5: Confirm and create

Use AskUserQuestion:

> Here's what I've got:
>
> **Work:** {one-line summary of what was discovered}
> **Type:** {feat/fix/refactor/etc.}
> **Ticket:** {TICKET or "none"}
> **Done when:** {the success criteria from Question 2}
>
> Pick a branch name:
>
> A) `{option 1}` (recommended)
> B) `{option 2}`
> C) `{option 3}`
>
> Or type a custom name.

After the user picks:

```bash
# Detect base branch
_BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' \
  || gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null \
  || echo "main")

# Make sure we're up to date
git fetch origin "$_BASE" 2>/dev/null || true
git checkout "$_BASE" 2>/dev/null || true
git pull origin "$_BASE" 2>/dev/null || true

# Create and checkout
git checkout -b "{CHOSEN_BRANCH}"
```

Confirm: "Branch `{name}` created. You're ready to code."

---

## Step 6: Write a work brief (optional but recommended)

After the branch is created, write a compact brief to `.claude/work-brief.md`
(gitignored by default — this is a local thinking aid, not committed).

```bash
mkdir -p .claude
```

Write to `.claude/work-brief.md`:

```markdown
# Work Brief — {CHOSEN_BRANCH}

**Started:** {date}
**Type:** {type}
**Ticket:** {TICKET or "none"}

## What
{One-sentence description from discovery}

## Done when
{Success criteria from Question 2}

## Constraints
{Key constraint from Question 3}

## Notes
{Anything else relevant from discovery}
```

Add `.claude/work-brief.md` to `.gitignore` if not already there:

```bash
grep -qxF '.claude/work-brief.md' .gitignore 2>/dev/null || echo '.claude/work-brief.md' >> .gitignore
```

Tell the user: "Wrote `.claude/work-brief.md` as a local reference. Not committed."

---

## Step 7: Done

Print a clean summary:

```
READY TO CODE
═══════════════════════════════════════
Branch:   {branch-name}
Type:     {feat/fix/etc.}
Ticket:   {TICKET or "none"}
Done when: {success criteria}
═══════════════════════════════════════
When you're done: run /pr-ship to open the PR.
```

---

## Rules

- Never create the branch without confirming the name with the user.
- Never ask more than 4 questions total in discovery. 3 is the target.
- The brief goes in `.claude/` and is gitignored — it's a scratchpad, not a deliverable.
- If the user already has a clear description (passed as an argument to `/new-work`), use it as the answer to Question 1 and skip straight to Question 2.
- If already on a non-default branch, warn: "You're already on `{branch}`. Start new work from `{base}` — switch branches first, or continue here?"
