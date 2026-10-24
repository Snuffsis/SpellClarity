# SpellClarity contributor instructions

## Required Git workflow

These rules apply to every change, including documentation, tools and these rules.

1. Inspect branch, worktree and staged changes. Preserve unrelated work. Never silently discard, stash or commit another task's changes.
2. Fetch `origin`; create `feature/<short-kebab-case-name>` from current `origin/master` for a new task. Continue the same unfinished task on its existing branch/PR.
3. Make meaningful Conventional Commits (`type(scope): description`). Keep separate purposes in separate commits. Finish completed work committed.
4. Run appropriate checks, including `python dev/ci.py` for runtime/build/release changes. Update `MANIFEST.sha256` with `python dev/update_manifest.py`, verify it with `--check`, and inspect the staged diff. Never report unrun checks as passed.
5. Push feature branches and open/update PRs targeting `master`. Normal feature pushes and task PRs are authorized. Never merge a feature branch into local `master` or push directly to `master`.
6. Merge in GitHub only after explicit owner/designated-reviewer approval of the finished changes and test results, required CI on the latest revision and current base, and accepted or explicitly deferred client checks. Implementation instructions, self-review and green CI are not merge approval. Substantive changes require renewed approval/checks; never bypass required checks/reviews.
7. If `master` advances, integrate it into the feature branch and rerun relevant PR checks. A green run against an older base is insufficient.
8. After GitHub merge, update the installed checkout to clean `master` by fast-forward only. Fetch and use `git merge --ff-only origin/master`. Report divergence; never reset or force-push. Preserve other worktrees. If another clean worktree owns master, detach it first; never move unfinished dirty work.
9. An explicitly requested unmerged installation/playtest may use the feature branch. Report its revision and differences; reconcile after acceptance/merge. Keep useful branches unless cleanup is requested.
10. Release publication and history rewriting require explicit authorization. Publish only an approved commit reachable from `master`, with a new `<version>` or `v<version>` tag. Never reuse/move published tags or invent historical releases. A published GitHub Release retests the exact revision and supplies package version/notes without changing source. No version-only PR is needed; bare tag pushes do not publish.

See [Docs/GitWorkflow.md](Docs/GitWorkflow.md) and [Docs/Releasing.md](Docs/Releasing.md).
There is no blanket client-test deferral. Wayfarer's temporary deferral and product architecture do not apply.

## Product and data ownership

SpellClarity is an independent addon. Its root TOC loads its own private namespace,
translations and data; `SpellClarityDB` owns the saved language choice. Preserve
saved data and test schema/migration changes. Keep behavior-preserving refactors
separate from new features or schemas; update TOC, package references and tests together.

Preserve native tooltip frames, fonts and colors. Only known complete equipment
bonuses/comparison labels and supported Shift spell details are changed. Unknown,
conditional, protected and unreadable content remains native. Calculations are
estimates, guarded by the supported build, not promises of actual damage.
Retain the conflict guard for Aevum/ForeverUI/ForeverSkin Tooltips.

Read [Docs/Architecture.md](Docs/Architecture.md), [UPSTREAM.md](UPSTREAM.md) and the
relevant component source before editing. Aevum's exported copy remains in its
repository; this repository is maintained independently and is never overwritten
by its exporter. Synchronizations require an explicit reviewed diff with provenance.
