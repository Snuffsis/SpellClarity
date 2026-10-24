# SpellClarity

**Clearer tooltips. Understand what your spell power adds.**

SpellClarity makes equipment bonuses easier to read and adds a closer look at your learned spells and abilities. See supported base values, bonus contributions and coefficients without replacing the game's familiar tooltips.

Built for the **World of Warcraft Classic beta / Forever client**, SpellClarity works independently and requires no other addons.

## Read equipment bonuses at a glance

Known equipment bonuses become short, readable lines such as `+19 Fire spell dmg` or `+24 Ranged attack power`. Combined spell damage and healing bonuses are separated so each value is clear.

For example, a supported bonus granting **3 spell damage and 9 healing** becomes:

- **+3 Spell dmg**
- **+9 Healing**

Equipment comparisons use the same concise labels while preserving the game's positive and negative values and their colors. Unknown descriptions, conditional effects and procs keep their original text.

## Hold Shift for the details

Hover over a learned spell or ability and hold **Shift** to expand its supported details. Depending on the spell, you can see:

- Base damage, healing or absorption.
- The contribution from your current spell power or healing power.
- Spell coefficients and calculated estimates.
- Periodic values per tick and available tick intervals.
- Known weapon-ability components and relevant attack power.

Release Shift to return to the compact tooltip. The original spell description stays in place.

## Familiar tooltips, independent addon

SpellClarity keeps the game's tooltip frames, fonts and native text colors. It adds readable information without a replacement interface or a separate settings panel.

English labels are enabled by default. To switch labels, use:

- `/spellclarity sv` for Swedish.
- `/spellclarity en` for English.

Run `/reload` after changing the language. Your selection is saved between sessions. Equipment-text recognition currently supports English descriptions; the Swedish option translates SpellClarity's own labels.

## Compatibility and calculation limits

The included spell data targets **client build 1.60.1.70338** with **Interface 16001**. Numerical spell estimates are guarded by this exact build. On a different build, SpellClarity shows an update notice instead.

Calculations cover supported formulas and are estimates before talents, critical strikes and target effects. They are not a prediction of your final combat damage or healing. Periodic values are shown per tick; weapon abilities may show components rather than a final total. When a formula is unavailable, SpellClarity says so and leaves the original description available.

If **Aevum Tooltips**, **ForeverUI Tooltips** or **ForeverSkin Tooltips** is loaded, SpellClarity pauses to avoid duplicate additions. Disable that tooltip addon and reload to use SpellClarity. Other Aevum addons can remain enabled.

## Installation

1. Place the `SpellClarity` folder directly in your client's `Interface/AddOns` folder.
2. Fully restart the game after the first installation.
3. Enable **SpellClarity** in the addon list.

**Status:** Initial beta preparation. Automated tests pass; in-game validation is still pending.

**License:** All Rights Reserved.
