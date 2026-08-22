# Devpost copy — Rewind (Reverie Hacks 2026)

Paste these fields into the Devpost submission form. The official project documentation file to upload is [`DOCUMENTATION.md`](DOCUMENTATION.md).

---

## Project name

Rewind

## Tagline (optional, keep short)

A time machine for your camera roll that happens to free up storage.

## Elevator pitch

Rewind turns photo cleanup from a chore into rediscovery. You swipe through randomized blind-box decks of your own photos, videos, and screenshots—keep, skip, delete, or decide later. Deletes are staged and reversible. All processing stays on-device. Storage is the side effect; the product is remembering.

---

## Project story

Paste the Markdown below into Devpost (LaTeX math is supported).

```markdown
## Inspired by a camera roll nobody finishes

Most of us do not have a photo problem. We have a *decision* problem. Bursts, screenshots, and years of videos pile up until iOS nags about storage. Existing cleaners treat that as a chore: month-by-month grids, binary left/right swipe, streak counters, noisy color. We tried those apps. We quit them. The feed never ended, the order was predictable, and “I’m not sure” was not a legal move.

Rewind started from a different sentence: **not a photo cleaner — a time machine that happens to free up storage.** If the first card in a session is an old photo you forgot existed, the session is already worth opening. Cleanup becomes a side effect of looking.

## What we learned

- **Finite decks beat infinite feeds.** Twenty to thirty cards create a completion moment and a “one more deck” pull. An endless stack recreates the chore.
- **Four directions are a product decision, not a flourish.** Keep, skip, delete, and later map onto real states of mind. A Later Stack with a seven-day cool-down exists because the second encounter with a photo is faster and more confident than the first.
- **Restraint is a feature.** Exactly two functional colors (coral for delete, mint for keep) and grayscale everywhere else. Color is gesture feedback, never decoration. Hierarchy comes from whitespace and type, not badges.
- **Privacy has to be architectural.** PhotoKit, on-device Vision OCR, SwiftData on device, no backend. If a photo never leaves the phone, we can move quickly without asking people to trust a server.

## How we built it

Native **SwiftUI** on iOS, with **PhotoKit** for the library, **SwiftData** for the local ledger (processed items, Later, favorites, staging, chapters), **AVFoundation** for looping video cards, **Vision** for screenshot kind, **MapKit** for trip clusters, and **WidgetKit / ActivityKit / App Intents** so Rewind can live on the Lock Screen, Dynamic Island, and Siri.

The “blind box” is a weighted shuffle. If a photo’s age in days is $d$, its sampling weight is

$$
w(d)=\max(1,d)^{0.55}
$$

Older media is likelier to appear; recent shots are not banned. After sampling, we separate consecutive items that share a burst identifier or fall inside a $3$-second moment window, so retakes do not stack.

Gestures lock to an axis after about $24$ pt of travel, using a $15^{\circ}$ bias off the $45^{\circ}$ diagonal. A card commits when progress exceeds $\sim 30\%$ of travel **or** flick speed exceeds $\sim 900$ pt/s. Rotation is capped at $\pm 12^{\circ}$. Deletes never hit the system immediately: they land in a staging bin and flush through `PHAssetChangeRequest.deleteAssets` once per session (one dialog). Undo is a three-second pill *and* a two-finger swipe left.

Explore clusters photos that are contiguous in time and space ($\leq 18$ hours and $\leq 80$ km) into trips you can clean as a scoped deck. Profile replaces streaks with **Chapters**: when a time slice of the library is processed, you get a quiet card — one kept hero, grayscale stats — not a guilt badge.

## Challenges we faced

**Four-way swipe without accidental commits.** A diagonal drag wants to be both “delete” and “keep.” Axis locking, commit thresholds, and velocity flicks had to feel physical and still be undoable. We wrote unit tests for lock angles and shuffle invariants so the ritual would not drift.

**Making PhotoKit feel instant.** Full-resolution assets in a card stack drop frames. The budget was display-size decode, prefetch of the next five items, and never putting originals in the stack. Videos needed a muted loop *and* a scrub mode that suspends swipe.

**Trust vs. speed.** Instant deletion is fast and terrifying. Staging + batch confirm + iOS Recently Deleted is slower by one dialog and much more honest. Designing the Dynamic Island absorb animation as the signature delete moment — then falling back on non-island devices and Reduce Motion — was a motion-design problem as much as an engineering one.

**Scope discipline.** We specified AI photo enhancement, chronological browse modes, and streak trophies as *out of scope*. The hard part was not adding them when they would have been easy. Rewind wins if the photos stay the hero and the UI stays quiet.
```

---

## Built with (tags, ≤ 25)

Copy these into Devpost one at a time, or paste as a list:

1. Swift
2. SwiftUI
3. SwiftData
4. iOS
5. Xcode
6. PhotoKit
7. MapKit
8. Vision
9. AVFoundation
10. WidgetKit
11. ActivityKit
12. App Intents
13. StoreKit
14. Core Location
15. Core Image
16. UIKit
17. GitHub
18. Apple
19. Mobile
20. Privacy
21. Dynamic Island
22. Siri
23. Core Graphics
24. Human Interface Guidelines
25. MIT License

If Devpost’s autocomplete is picky, prioritize: **Swift, SwiftUI, iOS, Xcode, PhotoKit, MapKit, Vision, WidgetKit, ActivityKit, App Intents, AVFoundation, SwiftData, StoreKit, Mobile, GitHub**.

---

## Try it out links

| Label | URL | Notes |
| --- | --- | --- |
| GitHub (required) | https://github.com/Boxxelf/Rewind | Public code + README + documentation |
| Documentation | https://github.com/Boxxelf/Rewind/blob/main/DOCUMENTATION.md | Installation, user manual, setup |

There is no web demo (on-device photos). Judges should clone, open `Rewind.xcodeproj` in Xcode 26, and run on an iPhone. Add a **TestFlight** or YouTube **demo video** URL here when you have it.

---

## Other Devpost fields

- **Track:** App Development
- **Code repository:** https://github.com/Boxxelf/Rewind
- **Project documentation file:** upload `DOCUMENTATION.md` (or export it to PDF)
- **Demo video:** record from a physical iPhone using the shot list in `DOCUMENTATION.md` §12
