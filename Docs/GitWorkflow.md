# Git workflow

SpellClarity follows the same review, commit and release rules as Aevum and Wayfarer,
with `master` as the base. [AGENTS.md](../AGENTS.md) is the full contributor policy.

```text
git status --short --branch
git diff
git diff --cached
git fetch origin
git switch -c feature/short-task-name origin/master
python dev/update_manifest.py
python dev/ci.py
git diff --check
git add <intended-files>
git diff --cached --check
git diff --cached
git commit -m "type(scope): meaningful change"
git push -u origin feature/short-task-name
```

Open a PR targeting master. Keep each agreed work unit on the same branch/PR across
follow-ups and playtest fixes. Required checks: **Test and build standalone addon**
and **Verify downloaded bundle**, against the latest revision and base. Configure
GitHub branch protection/rulesets to require PRs, current-base checks and prevent
force pushes/deletion when the repository is created. These written rules do not
by themselves configure server enforcement.

Owner approval of the finished diff/results, required CI and accepted/deferred
client checks precede a GitHub-only merge. Then fetch and fast-forward the installed
checkout to origin/master; inspect its clean status and manifest. Do not reset a
diverged checkout or leave only a secondary development checkout up to date.

## Initial preparation, 2026-10-24

No accessible `Snuffsis/SpellClarity` repository was found. The local `master`
reference contains only the imported, existing standalone source snapshot.
`feature/standalone-release` contains the independent project preparation.
No remote master has been pushed and no release has been published.

Creating a new GitHub repository and initially uploading this baseline requires an
explicit one-time bootstrap decision, as for Aevum. That exception must identify
the exact baseline; it never authorizes later direct pushes. After bootstrap,
fetch origin, push the feature branch and open its PR targeting master.

The initial installation is the requested unmerged playtest. Runtime function
bodies are unchanged from the imported Aevum revision; only source-header comments
are adjusted. Client acceptance remains pending.
