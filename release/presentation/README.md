# SpellClarity presentation assets

Prepared on 2026-10-24. These are proposed project assets, not yet published or
owner-approved. They do not change the addon runtime or its in-game appearance.

| File | Purpose | Actual dimensions |
| --- | --- | --- |
| [spellclarity-logo.png](spellclarity-logo.png) | Square project logo | 1254 × 1254 px |
| [spellclarity-banner.png](spellclarity-banner.png) | Horizontal project banner | 2172 × 724 px |
| [../summary.txt](../summary.txt) | English Summary field, 145 characters | Plain text |
| [../description.md](../description.md) | Full English project description | Markdown |
| [../../README.md](../../README.md) | GitHub README, identical to the full description | Markdown |
| [artwork.json](artwork.json) | Original prompts, image roles and alt text | JSON |

## Visual identity

A gold tooltip outline contains a cyan four-point spell spark and two short text
lines. The shape connects spell information with readable tooltips. A dark blue
background and warm gold wordmark give the two assets a consistent fantasy style.
The banner was generated using the logo as its identity reference.

Both PNGs were created with the built-in image_gen tool. The full prompts are
preserved in artwork.json. Dimensions above were read from the actual PNGs; they
are full-resolution generated originals, not smaller upload exports. The requested
1024-pixel logo was returned at 1254 pixels. No third-party game screenshots,
artwork or existing Aevum logo were used as image inputs.

## Placement

Use the square logo for the CurseForge project image. Put the banner above the
long description on the project page. In a GitHub README, its repository-relative
path is `release/presentation/spellclarity-banner.png` once the artwork is approved
and uploaded. The text-only README is kept identical to the CurseForge description
and remains self-contained inside the addon ZIP.

For CurseForge, upload the artwork with its image controls and check the current
editor's file/dimension limits. The earlier Aevum description editor required an
image narrower than 850 pixels, so a smaller banner export may be needed at upload.
Do not paste a local filesystem path as a public image URL. No uploaded image URL
has been invented, and the current CurseForge logo/description have not been replaced.

The description is Markdown. Paste it in a Markdown editor, or use the rendered
formatted text in a rich-text editor; do not paste raw Markdown into a plain rich-text
surface and expect it to render. The short Summary text is separate.

## Publishing status

GitHub repository bootstrap still awaits the one-time approval recorded in
Docs/GitWorkflow.md. Review/merge, client acceptance and release publication remain
separate decisions. These branding files stay out of the addon ZIP; the updated
text-only README is included. No runtime test is established by these images.
