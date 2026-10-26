---
name: ship-it
description: Complete this dotfiles repository's PR workflow when Kevin says "ship it" or requests shipping a PR. Merge the intended PR, switch to main, pull latest, and prune stale branches. Do not trigger for a request to create or review a PR alone.
---

# Ship It

In this project, "ship it" authorizes the complete Git workflow: merge the
intended PR, return the checkout to `main`, fast-forward to the latest remote
commit, and clean up stale branches. Finish all four parts before reporting
completion. If the PR is already merged, continue with checkout and cleanup.
This authorization covers Git branch cleanup, not package pruning, file
deletion, deployment, or unrelated repository changes.

## Merge and synchronize

1. Inspect `git status -sb`, the current branch, and the intended PR. Infer the
   PR from the conversation or branch; ask only if multiple candidates remain.
   Preserve unrelated working changes; do not reset, discard, or auto-stash them.
2. Check the PR's current head SHA, state, mergeability, and required checks.
   Resolve routine failures within the authorized scope; do not bypass failing
   checks or branch protections. If checks are pending, wait for their outcome.
3. Squash-merge the reviewed head using
   `gh pr merge NUMBER --squash --match-head-commit SHA`, unless the user or
   repository requires another merge strategy. Verify GitHub reports `MERGED`.
   If the head changed, inspect the new changes before attempting another merge.
4. Run `git switch main`, `git pull --ff-only origin main`, then
   `git fetch --prune origin`. If switching or fast-forwarding would conflict
   with local work, preserve it and explain the specific blocker.

## Clean up stale branches

Inspect `git branch -vv`, `git worktree list`, and the remote branch list after
fetching. Preserve `main`, branches checked out in any worktree, and branches
with open PRs or unshipped work. A missing upstream alone does not prove a local
branch is safe to delete.

- Delete local branches merged into `main` with `git branch -d BRANCH` after
  checking that no active work depends on them.
- Squash merges may fail Git's ancestry check. Before using `git branch -D`,
  verify that GitHub marks the branch's PR merged, the local branch SHA matches
  that PR's head SHA, and the merge commit is contained in current `main`.
  Inspect the diff if any additional commits or uncertainty remain. Do not
  force-delete a branch with unshipped commits.
- Remove a remaining remote PR branch only after confirming the same merged
  head and that the remote still points at it. Leave unrelated remote branches
  alone. Fetch with `--prune` again after remote cleanup.

This explicitly authorized Git cleanup is the narrow exception to the
repository's operator-only deletion/pruning guidance. Do not run broad cleanup
scripts, package pruning, or branch-deletion pipelines.

Verify the final branch is `main`, it matches `origin/main`, and the working
tree status and remaining branches are understood. Report the PR link, merge
commit, synchronization result, branches removed, and any preserved local work
or unfinished step. Do not claim completion merely because the PR merged.
