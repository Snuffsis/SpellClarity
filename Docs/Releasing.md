# GitHub and CurseForge preparation

One archive, `SpellClarity-<version>.zip`, contains one top-level `SpellClarity/`
folder. It has no Aevum dependency and is never included in Aevum's release bundle.
Development tools, Git metadata, tests and saved player data are excluded.

## Complete once before publishing

1. GitHub: [Snuffsis/SpellClarity](https://github.com/Snuffsis/SpellClarity), public
   and currently empty. Approve the one-time initial baseline `2e8d04e` upload,
   then push the preparation branch and review its PR to master.
2. The owner supplied CurseForge project **1763928**, slug **spellclarity**:
   [project preview](https://www.curseforge.com/wow/addons/spellclarity/preview).
   Its ID/slug are set in `release/config.json`. The owner preview was verified
   on 2026-10-24: new/unlisted project, awaiting moderator approval, no files.
3. The existing CurseForge project selects **All Rights Reserved**. Root `LICENSE`
   preserves that choice; spell data source attribution remains in
   `spell-data-sources.json`. Publication rejects a missing or empty LICENSE.
   No unrelated Aevum artwork or artwork licenses are included.
4. Configure GitHub secret `CF_API_TOKEN` in repository settings. Never paste it
   into source or chat. Set variable `CURSEFORGE_PUBLISH_ENABLED=true` only when ready.
   Keep CurseForge's separate repository packager disabled to avoid duplicate uploads.
5. Confirm the intended client mapping: 1.60.1, Interface 16001, candidate CurseForge
   version ID 17053 (inherited from Aevum). The uploader checks the ID/name against
   the live CurseForge API before posting. This does not establish client acceptance.
6. Complete or explicitly defer the client checklist below and record the decision
   in the implementation PR. Do not borrow Wayfarer's temporary test deferral.

## Validate and publish

Use Python 3.12 and Lua 5.1 (`python -m pip install -r dev/requirements.txt` provides
an optional Lua 5.1 runtime for local machines). Run `python dev/update_manifest.py`
and `python dev/ci.py`. The latter checks the manifest, runtime, release gates,
ZIP layout/bytes and build report. CI downloads its artifact into a second job
and verifies it again. PR jobs have no publishing secret.

After explicit owner approval, GitHub merge and explicit release authorization,
publish a GitHub Release at an approved master commit using a new `0.1.0-beta`
or `v0.1.0-beta` style tag. Alpha/beta must be pre-releases. Fill in release notes
before publishing. Release events retest the exact tagged revision, inject the tag
version into only the packaged TOC, and include the notes as CHANGELOG.md.
No source version-only commit is required. A bare tag push, draft release or
normal source push never uploads to CurseForge.

The upload job uses the exact verified ZIP, checks tag/commit/master ancestry,
project configuration and live game-version mapping. One POST is made; it is never
automatically retried. The receipt is written before sending and retained even
if the response is uncertain. Reruns are blocked. Inspect the project file list
and receipt before any recovery. API success means receipt, not moderation or
successful addon-manager installation. Verify those separately.

## Client acceptance checklist (pending)

- Restart WoW completely after first installation; SpellClarity is listed separately.
- With Aevum Tooltips disabled, known Equip bonuses and comparisons are shortened.
- Shift expands/collapses known spell details without flicker or duplicate rows.
- Damage, healing, ticks, absorbs and weapon examples are sensible; unsupported
  builds/spells show guarded fallbacks instead of invented numbers.
- English/Swedish choice persists after reload; existing saved data is preserved.
- With Aevum Tooltips enabled, SpellClarity pauses and does not duplicate rows.
- Check combat, cooldowns, linked tooltips, protected content and error/taint logs.
- Confirm a clean CurseForge installation and upgrade after the first approved release.

## Official references

- [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)
- [GitHub release workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#release)
