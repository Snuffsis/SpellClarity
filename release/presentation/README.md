# SpellClarity presentation assets

Prepared on 2026-10-24. The owner accepted the logo visual direction and requested
SVG format. The SVG is the editable logo master; its reconstruction awaits visual
review. Assets have not been published and do not change the addon runtime.

| File | Purpose | Actual dimensions |
| --- | --- | --- |
| [spellclarity-logo.svg](spellclarity-logo.svg) | Editable vector logo master | Scalable; viewBox 0 0 1254 1254 |
| [spellclarity-logo-vector-preview.png](spellclarity-logo-vector-preview.png) | Preview rendered from the SVG | 800 × 800 px |
| [spellclarity-logo.png](spellclarity-logo.png) | Original generated reference, preserved | 1254 × 1254 px |
| [spellclarity-banner-800.png](spellclarity-banner-800.png) | Banner for the project description | 800 × 267 px |
| [spellclarity-banner.png](spellclarity-banner.png) | Full-resolution banner source | 2172 × 724 px |
| [../summary.txt](../summary.txt) | English Summary field, 145 characters | Plain text |
| [../description.md](../description.md) | Full English project description | Markdown |
| [../../README.md](../../README.md) | GitHub README, identical to the full description | Markdown |
| [artwork.json](artwork.json) | Original prompts, image roles and alt text | JSON |

## Visual identity

A gold tooltip outline contains a cyan four-point spell spark and two short text
lines. The shape connects spell information with readable tooltips. A dark blue
background and warm gold wordmark give the two assets a consistent fantasy style.
The banner was generated using the logo as its identity reference.

The original logo PNG and banner PNG were created with the built-in image_gen tool. The full prompts are
preserved in artwork.json. Dimensions above were read from the actual PNGs; they
include both full-resolution originals and the smaller description export. The requested
1024-pixel logo was returned at 1254 pixels. No third-party game screenshots,
artwork or existing Aevum logo were used as image inputs.

## SVG master

`spellclarity-logo.svg` reconstructs the accepted emblem using editable paths,
rounded rectangles and gradients. The broad silhouette, colors, speech pointer,
spark and two text lines follow the reference. Fine raster grain is replaced by
smooth vector surfaces. There are no embedded images, external resources, fonts,
scripts or raster filters. `spellclarity-logo-vector-preview.png` is rendered from
this SVG and is not a reference embedded inside it.

## Placement

Use the SVG master where SVG is supported. For upload fields requiring a raster
image, export a square PNG from that master; the included preview is one such export. Put `spellclarity-banner-800.png` above the
long description on the project page. In a GitHub README, its repository-relative
path is `release/presentation/spellclarity-banner-800.png` once the artwork is approved
and uploaded. The text-only README is kept identical to the CurseForge description
and remains self-contained inside the addon ZIP.

For CurseForge, upload the artwork with its image controls and check the current
editor's file/dimension limits. The earlier Aevum description editor required an
image narrower than 850 pixels; use the new 800 × 267 export for the description.
It preserves the complete original composition, with no cropping or content changes.
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
