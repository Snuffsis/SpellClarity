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

The owner supplied [Snuffsis/SpellClarity](https://github.com/Snuffsis/SpellClarity),
a public repository with default branch `master`. It was initially empty.
On 2026-10-24 the owner explicitly approved uploading the exact imported baseline
`2e8d04eda027ec2178c99c67f00986158ca44fc7` to `master`, then pushing the preparation
branch and opening its PR. That baseline has now been uploaded and verified on
`origin/master`. No release has been published.

`feature/standalone-release` contains the independent project preparation,
release tooling, documentation and branding. The one-time bootstrap authorization
is exhausted; all subsequent changes follow the PR workflow. Approval to push
and open this PR is not approval to merge it or publish a release.

The initial installation is the requested unmerged playtest. Runtime function
bodies are unchanged from the imported Aevum revision; only source-header comments
are adjusted. Client acceptance remains pending.
