#!/bin/sh
# Removes worktrees flagged as finished: a worktree under .claude/worktrees/
# whose root holds a `.prunable` marker is removed (and its branch deleted if
# merged), but only after the safety gates below prove nothing can be lost.
# Ported from AirPlay Controller's scripts/housekeeping.sh (its prune job only).
#
# Called best-effort from scripts/test.sh and scripts/build.sh, so it runs on
# every build and test run. Also runnable by hand.
#
# Flag a worktree once its branch is merged, or abandoned with everything
# pushed:
#     touch .claude/worktrees/<slug>/.prunable
# The flag alone is not enough. Every gate must also pass, so a mistaken flag
# on a dirty or unpushed worktree is refused loudly, not obeyed.
#
# Safety gates for a prune (all required):
#   - not the checkout running this script, and not the primary checkout
#   - no running process is working out of the worktree
#   - `git status --porcelain` clean apart from the marker itself
#   - no gitignored files worth keeping (pending review replies, handoffs)
#   - HEAD is merged into origin/main, or identical to its pushed upstream
#   - the branch is deleted only when merged (`git branch -d`, never -D)
#
# Usage: sh scripts/housekeeping.sh [--current <repo-root>] [--dry-run]
#   --current  the checkout to protect (default: the one this runs from)
#   --dry-run  report what would happen, touch nothing
#
# Env: FLUIDITY_NO_HOUSEKEEPING=1  do nothing
set -u

[ "${FLUIDITY_NO_HOUSEKEEPING:-0}" = "1" ] && exit 0

dry_run=0
current=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) dry_run=1 ;;
        --current) shift; current=${1:-} ;;
        *) echo "housekeeping: unknown arg '$1'" >&2; exit 2 ;;
    esac
    shift
done

# The common git dir is always <primary>/.git, even when run from a worktree.
common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
primary=$(dirname "$common_dir")
worktrees_dir="$primary/.claude/worktrees"
[ -d "$worktrees_dir" ] || exit 0
[ -n "$current" ] || current=$(git rev-parse --show-toplevel 2>/dev/null || echo "$primary")

# One run at a time: two builds starting together must not race to prune the
# same worktree. shlock reclaims the lock if the recorded PID is dead.
lock=/tmp/fluidity-housekeeping.lock
if [ "$dry_run" -eq 0 ]; then
    /usr/bin/shlock -f "$lock" -p $$ || exit 0
    trap 'rm -f "$lock"' EXIT HUP INT TERM
fi

say() { echo "  housekeeping: $*" >&2; }

# A worktree is in use when a live process runs out of it: its program is
# inside the path, or its working directory is. `pgrep -f` alone also matches
# a process that merely names the path in an argument (a `du` from some
# agent's shell), so it only supplies candidates.
in_use() {
    for pid in $(pgrep -f "$1" 2>/dev/null); do
        cmd=$(ps -o command= -p "$pid" 2>/dev/null)
        case "$cmd" in "$1"/*) return 0 ;; esac
        cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
        case "$cwd" in "$1" | "$1"/*) return 0 ;; esac
    done
    return 1
}

for wt in "$worktrees_dir"/*/; do
    wt=${wt%/}
    [ -f "$wt/.prunable" ] || continue
    name=$(basename "$wt")
    if [ "$wt" = "$current" ] || [ "$wt" = "$primary" ]; then
        say "SKIP prune $name: it is the checkout running this script."
        continue
    fi
    if in_use "$wt"; then
        say "SKIP prune $name: a running process is working in it."
        continue
    fi
    dirt=$(git -C "$wt" status --porcelain 2>/dev/null | grep -v '^?? \.prunable$' || true)
    if [ -n "$dirt" ]; then
        say "SKIP prune $name: uncommitted changes (flag it again once clean):"
        printf '%s\n' "$dirt" | sed 's/^/      /' >&2
        continue
    fi
    # Gitignored files never show in `status`, and `git worktree remove`
    # deletes them without a word.
    # razor: covers review-branch.sh's pending replies and handoff notes; add
    # a pathspec here if another kind of gitignored file worth keeping turns up.
    kept=$(git -C "$wt" ls-files --others --ignored --exclude-standard -- \
        .review-pending ':(glob,icase)**/*handoff*.md' ':(glob,icase)**/*handover*.md' \
        2>/dev/null || true)
    if [ -n "$kept" ]; then
        say "SKIP prune $name: it holds gitignored files worth keeping; move or delete them first:"
        printf '%s\n' "$kept" | sed 's/^/      /' >&2
        continue
    fi
    merged=0
    git -C "$wt" merge-base --is-ancestor HEAD origin/main 2>/dev/null && merged=1
    if [ "$merged" -eq 0 ]; then
        up=$(git -C "$wt" rev-parse '@{upstream}' 2>/dev/null || true)
        if [ -z "$up" ] || [ "$up" != "$(git -C "$wt" rev-parse HEAD)" ]; then
            say "SKIP prune $name: HEAD neither merged into origin/main nor pushed."
            continue
        fi
    fi
    branch=$(git -C "$wt" symbolic-ref --short HEAD 2>/dev/null || true)
    if [ "$dry_run" -eq 1 ]; then
        if [ "$merged" -eq 1 ] && [ -n "$branch" ]; then
            say "would prune worktree $name and delete merged branch $branch."
        else
            say "would prune worktree $name (branch kept: pushed but not merged)."
        fi
        continue
    fi
    # `worktree remove` refuses untracked files without --force. Deleting the
    # marker first keeps --force out of this script: any other untracked file
    # still blocks the removal.
    rm -f "$wt/.prunable"
    if git -C "$primary" worktree remove "$wt" 2>/dev/null; then
        say "pruned worktree $name."
        if [ "$merged" -eq 1 ] && [ -n "$branch" ]; then
            git -C "$primary" branch -d "$branch" >/dev/null 2>&1 \
                && say "deleted merged branch $branch."
        fi
    else
        touch "$wt/.prunable" 2>/dev/null
        say "SKIP prune $name: git worktree remove refused (locked or untracked files)."
    fi
done

exit 0
