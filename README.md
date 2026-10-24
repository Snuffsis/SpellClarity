# SpellClarity

Clearer equipment bonuses and spell calculations in your original tooltips.

SpellClarity is a lightweight, independent addon for the Classic beta / Forever
client. It keeps the game's tooltip frames, fonts and colors while making known
equipment bonuses easier to read.

- Compact known equipment bonuses, including school damage and attack power.
- Separate spell damage and healing lines and clear comparison labels.
- Hold Shift over learned spells for supported base values, bonus contributions,
  coefficients and calculated estimates.
- Damage, healing, periodic effects, absorbs and supported weapon components.
- English labels by default; optional Swedish labels with `/spellclarity sv`.
- No required addons. Your language choice is saved independently.

The included spell data targets **1.60.1.70338**. Other builds receive an update
notice instead of numerical estimates. Calculations are estimates before talents,
criticals and target effects. Unknown/conditional equipment descriptions stay
unchanged. English equipment descriptions are supported; Swedish changes labels.

If Aevum Tooltips or its older ForeverUI/ForeverSkin versions are loaded,
SpellClarity pauses to avoid duplicate additions. Disable that tooltip addon and
reload to use SpellClarity; other Aevum addons may stay enabled.

Install the SpellClarity folder directly under Interface/AddOns and fully restart
the game for the first installation. Use `/spellclarity en` or `/spellclarity sv`
then `/reload` to change labels.

## Development

This is the independent SpellClarity repository. See [source provenance](UPSTREAM.md),
[contributor rules](AGENTS.md), [architecture](Docs/Architecture.md),
[Git workflow](Docs/GitWorkflow.md) and [releasing](Docs/Releasing.md).
[Svensk dokumentation](README-sv.md).

```text
python -m pip install -r dev/requirements.txt
python dev/update_manifest.py
python dev/ci.py
```

Python 3.12 plus Lua 5.1 (or the optional pinned Lupa runtime) are used for local
checks. CI runs Lua 5.1 directly. Tests exercise the actual independent TOC and
packaged runtime. The ZIP, build report and SHA256SUMS are in `dist/release/`.

The project is prepared for review, not publicly released. In-game acceptance,
initial GitHub upload and CurseForge publishing credentials remain pending.
The license is All Rights Reserved, matching the existing CurseForge project.
