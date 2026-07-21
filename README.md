# skill-suite

Claude Code skills for a clean GitHub-first development workflow.

## Overview

A collection of slash-command skills that wire together the full dev cycle — from creating a GitHub repo to opening a pull request. Each skill is a single `SKILL.md` file that Claude Code loads as an invocable command. Install them once with `setup.sh`, then use `/init-project`, `/new-work`, and `/pr-ship` in any project.

Requires Claude Code and the `gh` CLI authenticated to GitHub.

## Setup

```bash
git clone https://github.com/aldo-g/skill-suite
cd skill-suite
./setup.sh
```

Then restart Claude Code to pick up the new skills.

## Usage

### Start a new project

```bash
/init-project
```

Creates a GitHub repo, sets up Issues with a clean label set, adds branch protection on `main`, and writes a `CLAUDE.md` with the workflow baked in.

### Start a piece of work

```bash
/new-work
```

Runs a short discovery conversation (what are you building, what does done look like, what's the constraint), asks for a ticket number, and checks out a correctly named branch.

### Open a pull request

```bash
/pr-ship
```

Reads the diff, picks a gitmoji, detects the ticket from the branch name, and creates a PR via `gh` with a structured description and test plan.

### README management

```bash
/create-readme   # write a README from scratch
/update-readme   # sync README to match recent git changes
```

## Project structure

```
{skill-name}/
  SKILL.md      # the skill definition Claude Code loads
setup.sh        # copies skills into ~/.claude/skills/
```

## Contributing

Skills live in `{skill-name}/SKILL.md`. After editing, run `./setup.sh` to reinstall. Branch naming follows `{type}/gh-{issue}-short-description` — see `CLAUDE.md` for the full workflow.
