---
name: create-readme
description: |
  Generate a README.md for the current project. Reads the codebase structure,
  CLAUDE.md, and package files to understand what the project is, then writes
  a clear, concise README with overview, setup, and usage sections.
  Use when: "create readme", "write a readme", "add readme", "generate readme",
  "I need a readme", "make a readme".
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# /create-readme — Generate a Project README

You are running the `/create-readme` workflow. Read the project, understand what
it is, ask one focused question, then write a README that a new contributor could
use to get started in under 5 minutes.

---

## Step 1: Read the project

```bash
# Structure
find . -maxdepth 2 -not -path './.git/*' -not -path './node_modules/*' | sort
# Existing docs
[ -f CLAUDE.md ] && cat CLAUDE.md || true
[ -f README.md ] && echo "README_EXISTS" && head -20 README.md || true
# Package metadata
[ -f package.json ] && cat package.json || true
[ -f pyproject.toml ] && cat pyproject.toml || true
[ -f Cargo.toml ] && cat Cargo.toml || true
[ -f go.mod ] && cat go.mod || true
# Git context
git log --oneline -10 2>/dev/null || true
git remote get-url origin 2>/dev/null || true
```

If `README_EXISTS`: use AskUserQuestion — "A README already exists. Use `/update-readme`
to update it, or continue here to overwrite it. Which do you want?"
Options: A) Overwrite with a fresh README, B) Stop — I'll use `/update-readme` instead.
If B: stop.

---

## Step 2: Ask one question

Based on what you've read, there's likely one thing you can't infer from the code.
Pick the single most important unknown and ask it.

Common unknowns:
- Who is the intended audience? (developers, end users, internal team)
- Is there a hosted demo or live URL?
- Any specific install requirements not obvious from the package files?

Use AskUserQuestion with free text. Don't ask more than one question.

---

## Step 3: Write the README

Write `README.md` with these sections, in this order. Keep it tight — no fluff,
no corporate voice, no "this project aims to...". Write like a senior engineer
who respects the reader's time.

```markdown
# {project-name}

{One sentence: what it is and who it's for.}

## Overview

{2-4 sentences: the problem it solves, how it works at a high level, and what
makes it worth using. If there's a live URL or demo, link it here.}

## Setup

{Exact commands to get from zero to running. Use code blocks. If there are
prerequisites, list them first.}

## Usage

{The most common thing someone would do with this project. Show real commands
or real code — not placeholders. Cover the 1-2 most important use cases.}

## Project structure

{Only if the structure is non-obvious. A short table or bullet list of the
key directories/files and what they do. Skip if it's a single-file project.}

## Contributing

{Only if this is open source or a team project. One short paragraph on how
to contribute — branch naming, PR process, etc. Reference CLAUDE.md if it
exists for the full workflow.}
```

Sections to SKIP if not applicable:
- Project structure — skip for simple projects
- Contributing — skip for solo/private projects unless CLAUDE.md defines a workflow

Do NOT add:
- Badges (unless the project already has CI set up)
- A changelog (that's CHANGELOG.md's job)
- A license section (unless there's already a LICENSE file)
- Filler like "feel free to", "please don't hesitate", "we'd love to hear from you"

---

## Step 4: Confirm

Print the README to the user and say: "Writing README.md."
Then write it. Don't ask for approval — they can edit it after.

---

## Rules

- Write in second person ("Run `npm install`") not first person ("We recommend...")
- Use real commands from the actual project, not generic placeholders
- If you can't find the install command, look harder before making one up
- Max 80 lines — a README that requires scrolling to find the install command has failed
