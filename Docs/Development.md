# Development

SpellClarity is maintained independently. See [source provenance](../UPSTREAM.md),
[contributor rules](../AGENTS.md), [architecture](Architecture.md),
[Git workflow](GitWorkflow.md), and [release preparation](Releasing.md).
The public README and CurseForge description share exactly the same product text.
Contributor details belong here and in AGENTS.md rather than in that description.

Use Python 3.12 and Lua 5.1. If Lua 5.1 is unavailable locally, the pinned Lupa
package provides an optional runtime:

```text
python -m pip install -r dev/requirements.txt
python dev/update_manifest.py
python dev/ci.py
```

CI uses Lua 5.1 directly. Checks load the real independent TOC, exercise native
tooltip behavior with simulated WoW APIs, and verify the packaged runtime and
release gates. They do not replace in-game validation.

The verified ZIP, build report and SHA256SUMS are generated in `dist/release/`.
Branding source assets and original image-generation prompts are retained under
`release/presentation/` and excluded from the addon ZIP.
