---
name: update-readme
description: |
  Update README.md based on what has actually changed in the project. Reads the
  git diff against main, checks if any changes affect what the README describes,
  and rewrites only the sections that are now out of date. No-ops if nothing
  in the diff affects the README.
  Use when: "update readme", "readme is out of date", "sync readme",
  "readme needs updating", "update the docs", "refresh readme".
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# /update-readme — Keep the README in Sync with the Code

You are running the `/update-readme` workflow. The goal is a README that
accurately reflects the current state of the project — nothing more.

Only update sections where the diff proves something has changed. Don't
rewrite for style. Don't add sections that don't need to exist.

---

## Step 1: Read the current state

```bash
# Current README
cat README.md 2>/dev/null || echo "NO_README"

# What's changed vs main (or the default branch)
_BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
git fetch origin "$_BASE" 2>/dev/null || true
git diff "origin/$_BASE"...HEAD --stat
git diff "origin/$_BASE"...HEAD --name-only
git log "origin/$_BASE"..HEAD --oneline

# Full diff for analysis
git diff "origin/$_BASE"...HEAD
```

If `NO_README`: stop — "No README found. Run `/create-readme` to create one first."

If the diff is empty (no changes vs base): stop — "Nothing has changed on this branch. README is already up to date."

---

## Step 2: Analyse what the diff changes

Read the full diff carefully. For each changed file or area, ask: does this
affect something the README currently describes?

Check each README section against the diff:

| README section | What would invalidate it |
|----------------|--------------------------|
| Overview | Core purpose changed, new major feature added, project renamed |
| Setup | Install steps changed, new prerequisites, env vars added/removed, config format changed |
| Usage | Commands renamed, new flags, new primary workflow, old examples now broken |
| Project structure | Directories added/removed, major files moved |
| Contributing | Workflow changed (branch naming, PR process, tools) |

**Be conservative.** A refactor that doesn't change the public interface doesn't
need a README update. An internal rename that doesn't affect install or usage
doesn't need a README update.

**Output your analysis** as a brief list before making any edits:

```
DIFF ANALYSIS
─────────────────────────────────
✓ Setup     — unchanged (no changes to install/config)
✗ Usage     — NEEDS UPDATE: /new-work now has a --ticket flag not mentioned in README
✓ Overview  — unchanged
✗ Structure — NEEDS UPDATE: added /update-readme skill directory
─────────────────────────────────
Sections to update: Usage, Structure
```

If no sections need updating: print "README is accurate — no updates needed." and stop.

---

## Step 3: Update only what needs updating

For each section flagged in the analysis, edit that section in place.

Use `Edit` to make targeted changes — don't rewrite the whole file.

Rules:
- Match the existing tone and style of the README
- Update facts, not prose style
- If a command changed, update the command — don't rewrite the paragraph around it
- If a new section is genuinely needed (e.g. a new major feature with its own usage),
  add it after the most relevant existing section
- If something was removed from the project, remove it from the README

---

## Step 4: Verify

After edits, read the full README back and do a quick sanity check:

- Every command shown actually exists in the current codebase
- Every file/directory mentioned actually exists
- No section contradicts another
- The overview still accurately describes what the project does

---

## Step 5: Report

Print a short summary of what changed:

```
README UPDATED
─────────────────────────────────
Updated: Usage (added --ticket flag to /new-work example)
Updated: Structure (added update-readme skill)
Unchanged: Overview, Setup, Contributing
─────────────────────────────────
```

---

## Rules

- Never rewrite sections that don't need updating — even if you'd write them differently
- Never add a section just because it "might be useful"
- If you're unsure whether something in the diff affects the README, err on the side of not updating
- The diff is the source of truth — don't update based on vibes, only on evidence from the diff
