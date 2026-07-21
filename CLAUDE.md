# skill-suite

A collection of Claude Code skills for a clean GitHub-first development workflow.

## Ticket System

This project uses **GitHub Issues** for tracking work.

- Reference issues as `#42` in branch names and PR descriptions
- The `/new-work` skill will ask for an issue number when starting work
- The `/pr-ship` skill will link PRs to issues automatically
- Bug fixes should include `Closes #N` in the PR body to auto-close on merge

To create an issue before starting work:
```bash
gh issue create --title "Short title" --body "Description" --label feat
```

## Workflow

1. `/new-work` — start a ticket, create a branch
2. Edit the skill files in the relevant directory
3. Run `./setup.sh` to install changes into `~/.claude/skills/`
4. `/pr-ship` — open a PR linked to the ticket
5. Get a review, merge

## Branch naming

`{type}/{issue-number}-short-description`

Examples:
- `feat/gh-42-add-new-skill`
- `fix/gh-99-broken-branch-detection`
- `chore/gh-12-update-setup-script`

## Skills in this repo

Each skill lives in its own directory as `{skill-name}/SKILL.md`.

| Skill | Command | Purpose |
|-------|---------|---------|
| init-project | `/init-project` | Create a new GitHub repo with Issues, labels, branch protection, and CLAUDE.md |
| new-work | `/new-work` | Discovery conversation, ticket detection, branch creation |
| pr-ship | `/pr-ship` | Wrap up work into a PR with gitmoji + ticket link |

## Installing skills

```bash
./setup.sh
```

Copies all `{skill}/SKILL.md` files into `~/.claude/skills/`. Re-run after any edits.

## Skills

- `/new-work` — start work on a ticket, create a branch
- `/pr-ship` — wrap up work, open a PR with gitmoji and ticket link
- `/init-project` — initialise a new project on GitHub
