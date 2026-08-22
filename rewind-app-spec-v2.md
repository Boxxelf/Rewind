# Rewind — Product & Design Specification v2 (iOS)

A premium iOS app that turns photo cleanup from a chore into a delightful, game-like experience. Users swipe through their photo library card by card, shown in randomized "blind box" order, deciding to delete, keep, or defer. Cleanup happens as a side effect of reliving memories.

**Name:** Rewind
**Positioning:** Not a photo cleaner. A time machine that happens to free up storage.
**Target platform:** iOS 17+, SwiftUI, iPhone first. Dynamic Island support required.

**v2 changes vs v1:** added Later Stack (deferred decisions with resurfacing), Chapters milestone system (replaces streak-style gamification), inline similar-photo batch actions inside the deck, strict two-color discipline rules, widget spec finalized. AI photo enhancement explicitly out of scope.

---

## 1. Competitive Stance (design guardrails)

Primary reference competitor: SwipeWipe (month-by-month, binary left/right swipe, streaks, colorful UI).

Rewind's differentiation, in priority order:
1. **Randomized blind-box decks** vs their chronological month-by-month sorting. Surprise is the product. Never add a "sort by month" mode to the core loop.
2. **Three-way gesture grammar + Dynamic Island absorb animation** vs binary swipe. The absorb animation is Rewind's signature moment.
3. **Radical visual restraint** vs their colorful, noisy UI. See Color Discipline (1.3).
4. **On-device privacy** as a first-class marketing claim: no photo data ever leaves the device.

Explicitly out of scope (do not build): AI photo enhancement, chronological browsing modes, streak counters, badge/trophy systems.

---

## 2. Design Language

### 2.1 Visual Direction
Minimal card stack aesthetic. Quiet, precise, premium. The UI recedes; photos are the hero. The single "showpiece" moment is the delete animation (card absorbed into the Dynamic Island). Everything else stays calm and disciplined.

### 2.2 Design Tokens

**Color (Light Mode)**
| Token | Value | Usage |
|---|---|---|
| `bg/primary` | `#FAFAFA` | App background (never pure white) |
| `surface/card` | `#FFFFFF` | Cards, sheets |
| `text/primary` | `#1A1A1A` | Headings |
| `text/secondary` | `#6B6B6B` | Body, captions |
| `accent/delete` | `#FF6B4A` (coral) | Delete-direction feedback ONLY |
| `accent/keep` | `#3ECF8E` (mint) | Keep-direction feedback ONLY |
| `border/hairline` | `#EBEBEB` | Dividers, 1px hairlines |

**Color (Dark Mode)** — designed from day one
| Token | Value |
|---|---|
| `bg/primary` | `#0E0E0F` |
| `surface/card` | `#1A1A1C` |
| `text/primary` | `#F5F5F5` |
| `text/secondary` | `#9A9A9E` |
| Accents | Same hues, +8% brightness |

### 2.3 Color Discipline (hard rules, anti-noise)

These rules exist because the reference competitor's UI is colorful and noisy. Rewind wins on restraint:

1. **Exactly two functional colors in the entire app.** Coral means delete-direction. Mint means keep-direction. Everything else is grayscale. No gradients, no colored category cards, no colored progress bars, no decorative color anywhere.
2. **Color is action feedback, not decoration.** Around a photo card, no persistent colored UI element is ever visible. Color appears only as a transient overlay during an active drag gesture, mapped to drag progress, and disappears on release.
3. **Hierarchy comes from whitespace and font weight, never from color.** Stats and data (storage freed, counts) render in monospaced digits, grayscale only. Precision is the luxury signal.
4. Primary CTAs use `text/primary` fill (near-black in light mode, near-white in dark). The accent colors are never used for generic buttons.

### 2.4 Typography
- Display & UI: SF Pro Rounded
- Numeric stats: monospaced digits via `.monospacedDigit()`
- Scale: Title 28/semibold, Heading 20/semibold, Body 16/regular, Caption 13/regular
- No oversized emotional headlines. Tone: calm confidence.

### 2.5 Shape & Depth
- Card corner radius: 24pt
- Card shadow at rest: `0 2px 12px rgba(0,0,0,0.06)`
- Card shadow while dragging: `0 12px 32px rgba(0,0,0,0.14)` (physical lift)
- Sheets: 28pt top radius, `.ultraThinMaterial` backgrounds, never opaque scrims

### 2.6 Iconography
SF Symbols, single weight (medium), outline variant only. Never mix filled and outline icons in one view.

### 2.7 Motion Spec
- All transitions are springs: `spring(response: 0.35–0.45, dampingFraction: 0.8)`. No bezier ease curves.
- Micro-interactions ≈ 200–250ms; view transitions ≤ 350ms
- Card drag: 1:1 finger tracking, dynamic rotation derived from horizontal translation and grab point, max ±12°
- Next card pre-scales 0.94 → 1.0 as top card leaves
- Hero animation: on delete, the card scales down and is absorbed into the Dynamic Island with a slight stretch/suction path. Graceful fallback on non-island devices (shrink toward top-center).
- Respect `Reduce Motion`: crossfade fallbacks everywhere.

### 2.8 Haptics Spec
| Action | Haptic |
|---|---|
| Skip | None |
| Keep | Light tick (`.impact(.light)`) |
| Delete | Soft impact (`.impact(.soft)`) |
| Send to Later | Light tick |
| Deck complete | `.notification(.success)` |
| Undo | Rigid tick (`.impact(.rigid)`) |

Never heavy haptics on repeated actions.

---

## 3. Information Architecture

```
Root (TabView, 3 tabs)
├── Clean (home, default)
│   ├── Category selector: Photos / Screenshots / Videos
│   ├── Deck session (card stack)
│   ├── Session summary
│   ├── Later Stack (deferred items)
│   └── Staging bin (pending deletions)
├── Explore
│   ├── Map view (trip clusters)
│   └── Calendar view (+ On This Day)
└── Profile
    ├── Stats (lifetime storage freed)
    ├── Chapters (milestone gallery)
    ├── Favorites collection
    ├── Settings
    └── Paywall / subscription management
```

Tab bar: 3 icons, floating pill style, `.ultraThinMaterial` background, labels fade on scroll.

---

## 4. Screens & Features

### 4.1 Home (Clean Tab)

**Category selector:** horizontal segmented pill: Photos / Screenshots / Videos.
- Selected: `text/primary` fill with inverted text (NOT accent color; see Color Discipline)
- Unselected: transparent, secondary text
- Each segment shows a thin (2pt) grayscale progress ring with a count badge
- Category switch crossfades the stack

**Card stack:** centered, ~70% of screen height, generous negative space. Two cards visible: top card full, next peeking at 0.94 scale. The always-visible next card is the key to perceived smoothness.

**Bottom info strip:** remaining count + storage pending release, monospaced, grayscale. Tapping it opens the Staging Bin.

### 4.2 Deck Session Mechanics

**Deck model:** finite decks of 20–30 items, randomized (blind-box core). Never an infinite feed. Finite decks create completion moments and a "one more deck" pull; infinite feeds recreate the "never done" chore feeling.

**Randomization rules:**
- Shuffle across the full library timespan, weighted slightly toward older photos
- Never show two photos from the same burst/moment consecutively
- Exclude already-processed items
- Later Stack items re-enter the shuffle pool after their cool-down (see 4.4)

**Session summary (deck complete):**
- Large monospaced stat: storage to be freed
- Secondary: X deleted, Y kept, Z skipped, W sent to Later
- Primary CTA: "Free up 1.2 GB" (executes staged deletions, one system dialog)
- Secondary CTA: "One more deck"
- If a Chapter milestone was crossed this session, the Chapter card presents here (see 4.5)

### 4.3 Gesture System (Three Directions + Later)

| Gesture | Action | Feedback |
|---|---|---|
| **Swipe up** | Delete (to staging bin) | Absorbed into Dynamic Island, coral trail |
| **Swipe right** | Keep / favorite | Star tick, card flies to a favorites counter top-right |
| **Swipe left** | Skip (no decision) | Neutral slide-out, no haptic |
| **Swipe down** | Send to Later | Card drops below the stack with a soft settle |

**Smoothness details:**
- Commit threshold ~30% of travel OR velocity flick
- Directional intent locking after >15° axis bias
- Transient edge overlays during drag (trash up, star right, clock down), opacity mapped to progress, color per discipline rules
- Fallback buttons below the stack (skip / delete / later / keep) for accessibility and one-handed use; VoiceOver gets full functionality through these

### 4.4 Later Stack (upgrade over competitor's static bookmarks)

Deferred decisions, designed around a psychological truth: the second encounter with a photo produces a faster, more confident decision.

- Any item swiped down enters the Later Stack
- **Resurfacing:** after a 7-day cool-down, Later items automatically re-enter the deck shuffle pool, tagged with a subtle "Seen before" caption on the card
- Later Stack screen: grid, accessible from Clean tab; items can be resolved directly (tap to open a mini-deck of only Later items)
- Later items never resurface more than once per 7 days; after 3 deferrals, the card gently offers "Keep this one?" as a default action

### 4.5 Chapters (replaces streaks)

No streaks, no daily-guilt mechanics. Progress is framed as narrative accomplishment:

- The library is silently segmented into time-based chapters (e.g., "Summer 2023", "Spring 2024") derived from photo density and date ranges
- When all items in a chapter are processed, a **Chapter Card** is generated: one hero photo (the user's kept favorite from that period), the chapter title, and grayscale monospaced stats (photos reviewed, space freed)
- Chapter Cards live in a gallery on the Profile tab and are exportable/shareable as a clean 4:5 image
- Emotional register: achievement and closure, never guilt or obligation

### 4.6 Media-Type-Specific Interactions

**Photos:** fast decisions, standard thresholds, snappy springs.

**Videos:**
- Auto-plays first 3 seconds, muted, looping; tap toggles sound
- Long-press enters scrub mode (horizontal drag previews the timeline; swipe gestures suspended)
- Commit threshold +15% vs photos
- Duration + file size badge (grayscale) on card

**Screenshots:**
- On-device OCR (Vision) auto-tags content (receipt, chat, webpage, ticket)
- Serial/duplicate detection with inline batch action (see 4.7)
- Fastest tuning: lowest thresholds, quickest springs

### 4.7 Inline Similar-Photo Batch Actions (deck seasoning, not a separate mode)

The competitor exposes similar/blurry/screenshot detection as separate cleanup modes: more chore menus. Rewind weaves detection into the deck so the user never leaves flow:

- When a drawn card has near-duplicates (burst shots, retakes, serial screenshots), a small grayscale thumbnail strip appears at the card's bottom edge: "5 similar"
- Tapping the strip expands an inline tray: "Keep this one, delete the other 5" as a single action, or pick individually
- After resolution, the deck continues seamlessly. No mode switch, no separate screen.
- Detection: on-device perceptual hashing + Vision feature prints, computed incrementally in background

### 4.8 Safety System (trust enables speed)

- **Staging bin:** deletes accumulate in-app; batch-executed at session end via `PHAssetChangeRequest.deleteAssets` (one system dialog per session)
- **Undo:** floating "Undo" pill top-center for 3 seconds after each delete; two-finger swipe left also undoes
- **Staging bin screen:** grid of pending deletions, tap to rescue
- Onboarding mentions iOS's own 30-day "Recently Deleted" safety net once

### 4.9 Explore: Map

- MapKit, clustered pins, merge/split on zoom
- **Trip clustering:** photos contiguous in time + location grouped into named trips ("Tokyo · Mar 2024 · 247 photos"); tapping opens a trip-scoped deck
- Pin tap: `.ultraThinMaterial` bottom sheet with photo grid + "Clean this place" CTA
- Map tint: grayscale-muted map style to keep photos as the only colorful content

### 4.10 Explore: Calendar

- Month grid; dates with photos get a tiny thumbnail dot
- Tap a date → mini-deck of that day
- **On This Day** strip at top: photos from this date in previous years, entry into a nostalgia mini-deck

### 4.11 Onboarding (first 30 seconds)

1. One-screen promise: "Rediscover your photos. Free up space along the way."
2. Permission priming screen before the system dialog (request `.readWrite`)
3. Drop straight into the first deck, first card biased to an old photo. Target: a "whoa, I forgot about this" moment within 30 seconds
4. Ghost-hand gesture coaching on the first 3 cards only

### 4.12 System Integration (productizing the "airplane moment")

- **Widgets (Lock + Home):** one random old photo thumbnail + "Remember this?" and a pending count. NO streak numbers, NO guilt copy.
- **Live Activity:** session progress in the Dynamic Island (items left, storage pending)
- **App Intents:** "Start a Rewind deck" via Spotlight and Siri
- **Notifications:** max one per week, memory-framed ("A photo from 3 years ago today"), never chore-framed

### 4.13 Empty & Edge States

- All caught up: small checkmark + "All caught up." + quiet suggestion chip for another category. No confetti.
- Permission denied: plain explanation + deep link to Settings
- Empty category: "No videos here." + suggestion chip
- Errors state what happened and the fix; never apologize, never vague

### 4.14 Monetization (soft paywall)

- Free: full core loop quality, capped quantity (e.g., 3 decks/day)
- Premium: unlimited decks, Map trips, Calendar/On This Day, screenshot smart-assist, Later Stack resurfacing, Chapter card export
- Paywall placement: after session summary (peak satisfaction) and on locked Explore features (blurred previews)
- Paywall design: one screen, monthly/annual toggle, single near-black CTA. No countdown timers, no dark patterns.

---

## 5. Technical Notes

- **Framework:** SwiftUI; UIKit interop only where needed (Dynamic Island animation coordination)
- **Photos:** PhotoKit (`PHPhotoLibrary`, `PHAsset`, `PHCachingImageManager`); pre-fetch next 5 deck items at display size. Prefetch is what makes the stack feel instant.
- **Deletion:** `PHAssetChangeRequest.deleteAssets`, one batch per session
- **Video:** `AVPlayer` muted looping; scrub previews via `AVAssetImageGenerator`
- **OCR/tagging:** Vision framework, on-device only. No photo data leaves the device; state this in onboarding and App Store copy.
- **Similar detection:** perceptual hashing + `VNGenerateImageFeaturePrintRequest`, incremental background processing
- **Trip clustering:** DBSCAN-style on (timestamp, lat/long), incremental
- **Dynamic Island:** ActivityKit Live Activities; absorb animation targets the island frame with spring path, fallback shrink-to-top-center on non-island devices
- **Persistence:** SwiftData for processed-item ledger, Later Stack, favorites, staging bin, chapters, stats. CloudKit sync as a premium candidate.
- **Performance budget:** 120fps card transitions on ProMotion; downsample to display size, decode off-main-thread, never load full-resolution originals into the stack

---

## 6. Accessibility Baseline

- Full VoiceOver via fallback buttons (every gesture has a button equivalent)
- Dynamic Type up to accessibility sizes on non-card text
- Reduce Motion: crossfades everywhere, including the hero animation
- Color never the only signal: every direction pairs color with an icon
- Minimum touch targets 44×44pt

---

## 7. Copy & Tone

- Voice: calm, light, a touch playful. Never sentimental, never nagging.
- Buttons state exactly what happens: "Free up 1.2 GB", not "Confirm"
- One name per action across the app ("Keep" everywhere)
- Nostalgia is shown, not told: the old photo does the emotional work, the UI stays quiet

---

## 8. Build Order

1. **M1, Core loop:** permissions, deck generation + randomization, four-direction swipe stack, staging bin + undo, session summary, batch delete
2. **M2, Polish:** Dynamic Island absorb animation, haptics, category selector, dark mode, color-discipline audit
3. **M3, Media types + assists:** video cards, screenshot OCR, inline similar-photo batch tray, Later Stack with resurfacing
4. **M4, Explore + Chapters:** map with trip clustering, calendar + On This Day, Chapters milestone system
5. **M5, System & growth:** widgets, Live Activity, App Intents, notifications, paywall
