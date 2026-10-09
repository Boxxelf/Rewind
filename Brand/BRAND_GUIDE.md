# rewind — brand guidelines

Version 1.0 · October 2026

## Brand idea

Rewind makes photo cleanup feel like rediscovery. It brings personal memories back into view in short, finite decks and keeps decisions reversible until the user confirms deletion.

**Campaign line:** Keep the memories. Make room for more.

Use **Rewind** in prose and **rewind** in the supplied wordmark. The identity is warm, personal, restrained, and tactile. Lead with memory; explain storage as a practical benefit.

## Logo files

`logos/` contains five variants in outlined SVG and transparent PNG. SVG wordmarks contain paths, so they do not depend on installed fonts.

| File stem | Use |
|---|---|
| rewind-logo-primary | Mint mark and ink wordmark on cream or white |
| rewind-logo-reverse | Mint mark and cream wordmark on forest green |
| rewind-logo-ink | One-color ink applications |
| rewind-logo-white | One-color reverse applications |
| rewind-mark-mint | Compact symbol, avatars, or a decorative brand accent |

The symbol has two rounded triangles pointing left. Keep their proportions and spacing intact. Leave clear space of at least half the symbol height around the full lockup. Use the full logo at 120 CSS px or wider; use the symbol at 24 px or wider. Do not stretch, rotate individual letters, add outlines, recolor the two triangles independently, or replace the mark with typographic angle brackets.

These files match the motion film's vector identity. Generated campaign artwork is illustrative; use the SVGs as the master for exact logo reproduction. This marketing identity does not automatically replace the shipping app icon.

## Color

| Token | Hex | Role |
|---|---|---|
| Cream | `#F6F3ED` | Main canvas; warm neutral |
| Ink | `#151716` | Primary typography and monochrome logo |
| Forest | `#163E32` | Dark campaign background |
| Mint | `#3ECF8E` | Logo, keep gesture, small highlights |
| Coral | `#FF6B4A` | Delete gesture and occasional motion accent |

Use cream or forest for the large surfaces. Ink on cream and cream on forest are the primary text combinations. Mint and coral are accent colors, not small body-text colors on cream. Dark text may sit on a mint surface. Digital source files use sRGB.

## Typography

Display / wordmark direction: **Arial Black**, heavy weight, short lines, tight tracking around -0.045em to -0.06em. Supporting text: **Arial**, regular or medium, with normal tracking and generous line-height. Web fallbacks: Helvetica Neue, Helvetica, sans-serif. The logo is supplied as paths; no font binaries are distributed. Verify licensing before embedding a font file in a new product.

Keep claims short and readable. Sentence case works for headlines; small uppercase labels are occasional navigational accents. Do not apply display tracking to paragraph text.

## Photography and device imagery

Use real memories with natural color: people, pets, trips, and ordinary moments. Preserve believable skin tones and avoid oversaturated teal/orange grading. In product demonstrations, use genuine app screens. Generated project-cover imagery is campaign artwork and must not serve as evidence of shipped UI.

Use restrained device reflections, soft grounded shadows, rounded photo cards, and open space. Avoid crowded dashboards, extra badges, heavy outlines, and simulated App Store endorsements. The current editorial cover system combines a lightweight forest-green headline, compact heavy logo, and three staggered iPhones on warm ivory. Landscape is 16:9 and portrait is 3:4, separately composed. Device displays reference existing Clean, Explore, and Chapters screenshots; do not introduce unrelated stock imagery. The generated compositions are illustrative, not pixel-exact UI documentation. Keep the mint rewind symbol to the left of the wordmark. Preserve an 8% safe area for portrait headlines. The vector-only forest cover remains an alternate in `covers/rewind-card-brand.svg`.

## Motion

- Output master: 1920 × 1080, 60 fps, 29 seconds.
- Titles reveal by letter with a short stagger and smooth settling.
- Preserve object continuity between scenes; the device moves with the story.
- Link direction to behavior: right Keep, up staged Delete, left Skip, down Later.
- Show the entire deletion path, including staging and a separate final confirmation.
- Use forest/cream changes, restrained directional transitions, and photo depth sparingly.
- Beat-synchronized UI accents support the original 120 BPM music.
- Keep a readable end hold. On websites, provide playback controls and do not autoplay audible music.

## Product copy guardrails

Use “ready to free” for pending space. Do not imply a swipe immediately and permanently erases a photo. Undo is time-limited, so avoid “undo anytime.” Describe similar-photo groups without claiming universal AI duplicate detection. Do not invent App Store availability, account syncing, or guaranteed storage savings.

## Reusable files

- `brand-tokens.json`: platform-neutral palette, typography and motion values.
- `brand.css`: scoped CSS variables and utility classes.
- `covers/`: approved landscape and portrait project artwork.
- `COVER_PROMPTS.md`: generation provenance and exact prompts.
- `../Marketing/`: product film, video script, and asset attribution.
