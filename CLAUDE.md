# Fluidity — Claude Code orientation

A native Mac dictation app that pastes what you say into whatever app you are typing in, with speech-to-text running on the Mac.

**Read [`AGENTS.md`](AGENTS.md) before doing anything.** It holds the
architectural rules, constraints and traps the code alone cannot convey. Each
subdirectory may have its own `AGENTS.md` — read the nearest one before
editing **or tracing** code in that folder.

## First steps in a fresh clone

```bash
sh scripts/setup.sh               # enables the git hooks
sh scripts/setup.sh --sync-main   # macOS: also keep local main mirroring origin/main
```

## Build & test

```bash
sh scripts/build.sh               # compile / typecheck
sh scripts/test.sh                # fast run (what Guard 4 runs at commit)
sh scripts/test.sh --full         # full suite (what the `tests` workflow runs)
```

**Always go through these wrappers, never the bare build or test command.**
The Claude hook in `.claude/hooks/guard-bash.sh` denies the bare commands.

The full suite runs on GitHub: the `tests` workflow
(`.github/workflows/tests.yml`), on every pull request and every push to
`main`. On a runner (`CI=true`) the wrappers run the command bare instead of
through `~/.claude/scripts/remote-run`.

## Critical workflow rules

- **Never commit on or push to `main`.** Guard 1, pre-push and the ruleset
  refuse it.
- **Work in worktrees, not the `main` checkout.** Worktrees live in
  `.claude/worktrees/<slug>/`:
  ```bash
  git fetch origin
  git worktree add .claude/worktrees/<slug> -b claude/<slug> origin/main
  cd .claude/worktrees/<slug>
  git push -u origin claude/<slug>
  ```
- **Finish every task with** a push, `gh pr create --fill`, and
  `bash scripts/review-branch.sh` (run the passes it prints as subagents,
  then `bash scripts/review-branch.sh --continue`).
- **Then stop and ask the owner before merging.** Only after a clear yes, run
  `gh pr merge --merge --auto`; it lands once the required `tests` and
  `review` checks are green. The hook asks on any merge either way.
- **Uncommitted edits in the `main` checkout: stop and ask.** Never stash,
  reset or discard them — they belong to another session.

## Agent skills

- **Issue tracker:** Linear, project Fluidity. Record ideas, work, status and
  milestones there first — see `docs/agents/issue-tracker.md`.
- **Triage labels:** `docs/agents/triage-labels.md`.
- **Domain docs:** `CONTEXT.md` plus `docs/adr/` — see `docs/agents/domain.md`.
- **`/pr-review`:** manual adversarial PR review (`.claude/skills/pr-review/`).
