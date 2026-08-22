# Rewind — Project Documentation

**Hackathon:** Reverie Hacks 2026  
**Track:** App Development  
**Platform:** iOS 26+, iPhone first  
**Repository:** https://github.com/Boxxelf/Rewind

This document is the project documentation required by the App Development track: purpose, audience, features, installation, user manual, configuration, and references.

---

## 1. Purpose

Smartphone camera rolls grow faster than people can review them. Duplicate bursts, screenshots of receipts, and years of forgotten videos sit on-device until storage warnings appear. Existing “photo cleaner” apps treat this as a chore: chronological month grids, binary swipe, streak counters, noisy color.

**Rewind’s purpose is to make cleanup a side effect of rediscovery.**

Users work through short, randomized decks of their own media. Each card is a memory first and a storage decision second. Deletes are staged, batched, and reversible. Progress is framed as *chapters of a life*, not daily streaks.

**Positioning:** not a photo cleaner. A time machine that happens to free up storage.

---

## 2. Target audience

| Segment | Why Rewind fits |
| --- | --- |
| People with 2,000–50,000 photos who have tried and abandoned cleanup apps | Finite 20–30 card decks create completion, not an infinite feed |
| Users who care about privacy | All processing is on-device; photos never leave the phone |
| People who want a calm, premium UI | Two functional colors only (coral = delete, mint = keep); photos are the hero |
| Occasional nostalgia seekers | Explore map, calendar, and On This Day turn cleanup into remembering |

Not the audience: power users who want AI enhancement, cloud backup managers, or chronological “sort by month” browsers. Those are explicitly out of scope.

---

## 3. Problem and solution

**Problem.** Cleanup tools recreate the feeling of never being done. Chronological order is predictable (and boring). Binary swipe cannot express “I’m not sure.” Guilt mechanics (streaks) make people avoid the app.

**Solution.**

1. **Blind-box decks** — shuffle across the full library, weighted toward older photos, never showing two shots from the same burst/moment in a row.
2. **Four-direction grammar** — keep / skip / delete / later, with a 7-day Later Stack resurfacing loop.
3. **Safety** — staging bin + undo + iOS Recently Deleted, so speed does not require trust-breaking instant deletion.
4. **Restraint** — grayscale UI; color appears only as transient gesture feedback.

---

## 4. Main features

### 4.1 Clean (home)

- Category selector: **Photos / Screenshots / Videos**, with grayscale progress.
- Card stack: top card + next card peeking at 0.94 scale.
- Gestures:
  - **Swipe up** — stage for delete; card is absorbed toward the Dynamic Island.
  - **Swipe right** — keep / favorite.
  - **Swipe left** — skip (no decision).
  - **Swipe down** — Later Stack.
- Fallback buttons under the stack for accessibility and one-handed use.
- Bottom strip: remaining count + pending storage (monospaced).
- **Undo** pill (~3s) and two-finger swipe left to undo.
- Session summary: storage to free, counts, “one more deck,” batch delete via a single system dialog.

### 4.2 Later Stack

Deferred items resurface after a **7-day** cool-down, labeled “Seen before.” After three deferrals, the UI gently suggests keeping. Designed around a simple behavioral idea: the second encounter produces a faster, more confident decision.

### 4.3 Similar photos (inline)

If a card belongs to a burst or a tight time window, a grayscale strip (“N similar”) expands into a tray: keep this one and delete the rest, or pick individually. Detection stays in the deck — no separate “duplicate mode.”

### 4.4 Screenshots and video

- Screenshots: on-device OCR (Vision) tags receipts, chats, webpages, tickets.
- Videos: muted 3-second loop; tap for sound; long-press to scrub the timeline.

### 4.5 Explore

- **Map:** trip clusters from time + location (contiguous photos within ~18 hours and ~80 km). Tap a trip to open a scoped deck.
- **Calendar:** month grid with photo dots; **On This Day** nostalgia mini-decks.

### 4.6 Profile

- Lifetime storage freed and review stats.
- **Chapters:** time-segmented milestone cards (hero keep + grayscale stats), shareable as 4:5 images.
- Soft paywall: free users get the full-quality core loop with a daily deck cap; premium unlocks unlimited decks, Explore extras, Later resurfacing, and chapter export.

### 4.7 System integration

- Lock Screen / Home Screen widgets: one old photo + “Remember this?”
- Live Activity on Dynamic Island during a session.
- App Intent: “Start a Rewind deck” from Spotlight / Siri.
- At most one memory-framed notification per week.

---

## 5. Technical architecture

| Layer | Choice |
| --- | --- |
| UI | SwiftUI (UIKit only for haptics, island animation, some media) |
| Persistence | SwiftData (processed ledger, Later, favorites, staging, chapters, stats) |
| Photos | PhotoKit (`PHPhotoLibrary`, `PHAsset`, `PHCachingImageManager`) |
| Video | AVFoundation (`AVPlayer`, `AVAssetImageGenerator`) |
| OCR / similar | Vision + Core Image, on-device |
| Map | MapKit + Core Location |
| Widgets / Island | WidgetKit, ActivityKit |
| Voice / Spotlight | App Intents |
| Monetization | StoreKit |

**Shuffle.** Candidate age in days $d$ is mapped to a sampling weight

$$
w(d) = \max(1,\, d)^{0.55}
$$

so older media is more likely to appear, without excluding recent photos. Consecutive items that share a burst identifier or fall inside a 3-second moment window are separated after sampling.

**Gestures.** Direction locks after ~24 pt of travel and a $15^\circ$ axis bias from the $45^\circ$ diagonal. Commit when progress exceeds ~30% of card travel **or** flick speed exceeds ~900 pt/s. Card rotation is capped at $\pm 12^\circ$.

**Deletion.** Items accumulate in an in-app staging bin. `PHAssetChangeRequest.deleteAssets` runs once per session (one system confirmation). iOS Recently Deleted remains the OS-level safety net.

**Performance.** Prefetch the next five deck items at display size; never load full-resolution originals into the stack. Springs (`response` 0.35–0.45) instead of ease curves. Reduce Motion uses crossfades.

---

## 6. Installation and setup

### 6.1 Prerequisites

- Mac with **Xcode 26** (project `IPHONEOS_DEPLOYMENT_TARGET` is **26.4**)
- Apple ID (free developer account is enough to run on your own iPhone)
- Physical iPhone recommended

### 6.2 Clone and open

```bash
git clone https://github.com/Boxxelf/Rewind.git
cd Rewind
open Rewind.xcodeproj
```

### 6.3 Signing

1. Select the **Rewind** target → *Signing & Capabilities*.
2. Enable *Automatically manage signing* and pick your Team.
3. If the bundle ID `com.tinajiang.Rewind` is unavailable, change:
   - App: `com.YOURNAME.Rewind`
   - Widget: `com.YOURNAME.Rewind.Widgets`
   - App Group: `group.com.YOURNAME.Rewind` (must match `Rewind.entitlements` and the widget entitlements)

### 6.4 Permissions

The app requests **Photos Read & Write**. Usage copy is already in the target Info keys:

- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

No extra API keys, `.env` files, or cloud dashboards are required.

### 6.5 Run

1. Choose a connected iPhone (or simulator).
2. Product → Run (`⌘R`).
3. On first launch, complete onboarding and allow Photos access.

### 6.6 Tests

In Xcode: Product → Test (`⌘U`). Unit tests cover deck size, burst separation, age weighting, first-card bias, and gesture axis locking (`RewindTests`).

---

## 7. User manual

### First launch

1. Read the one-screen promise: *Rediscover your photos. Free up space along the way.*
2. Learn the four swipe directions.
3. Allow Photos access (Read & Write).
4. The first card is biased toward an older photo on purpose.

### During a deck

| You want to… | Do this |
| --- | --- |
| Delete (later, in a batch) | Swipe **up** or tap Delete |
| Keep / favorite | Swipe **right** or tap Keep |
| Skip | Swipe **left** or tap Skip |
| Decide later | Swipe **down** or tap Later |
| Undo a delete | Tap **Undo**, or two-finger swipe left |
| Preview full media | Open the preview overlay on the card |
| See similar shots | Expand the similar strip on the card |
| Inspect staged deletes | Tap the bottom storage strip |

At deck complete, review counts, optionally start another deck, then confirm **Free up [size]** to run the system delete dialog.

### Explore

- Map: pinch to zoom clusters; tap a trip → “clean this place” as a scoped deck.
- Calendar: tap a day for that day’s mini-deck; use On This Day for the same date in past years.

### Profile

- Check lifetime storage freed.
- Open completed Chapter cards and export if unlocked.
- Manage premium from the paywall (monthly / annual).

### Empty and permission states

- **All caught up** — try another category.
- **Photos denied** — open iOS Settings → Rewind → Photos.
- **No videos / screenshots** — switch category.

---

## 8. Configuration

| Setting | Where | Default |
| --- | --- | --- |
| Deck size | `DeckRandomizer.deckSizeRange` | 20…30 |
| Age weight exponent | `DeckRandomizer.weight` | $0.55$ |
| Moment window | `DeckRandomizer.momentWindow` | 3 seconds |
| Gesture lock / flick | `GestureMath` | 24 pt, $15^\circ$, 900 pt/s |
| Later cool-down | session / Later stack logic | 7 days |
| Free daily decks | `EntitlementStore` | 3 / day |
| Photo access | iOS Settings | Read & Write required for delete |
| Dark mode | follows system | designed from day one |
| Reduce Motion | iOS Accessibility | crossfade fallbacks |

There is no server-side configuration.

---

## 9. Privacy and data

- **No backend.** No accounts, no analytics, no photo upload.
- **Local ledger** via SwiftData (which items you already processed, Later, favorites, staging, chapters, stats).
- **Widgets** share a snapshot through the App Group `group.com.tinajiang.Rewind`.
- Deletes use Apple’s PhotoKit APIs and iOS Recently Deleted.

---

## 10. Known limits (honest for judges)

- Requires **iOS 26 / Xcode 26** to build this project as-is.
- Simulator is a poor demo; use a device with a real photo library.
- Similar-photo matching currently uses burst IDs + a tight time window (plus Vision OCR for screenshot *kind*). Full perceptual-hash feature prints are specified; time-window clustering is what ships in this build.
- Trip titles are date-based (`Trip · Mar 2024 · N photos`); reverse-geocoded city names are a natural next step.
- StoreKit paywall UI is present; App Store Connect products must be configured for a live purchase.

---

## 11. References

- Apple PhotoKit — https://developer.apple.com/documentation/photokit
- SwiftUI — https://developer.apple.com/documentation/swiftui
- SwiftData — https://developer.apple.com/documentation/swiftdata
- Vision (on-device OCR) — https://developer.apple.com/documentation/vision
- MapKit — https://developer.apple.com/documentation/mapkit
- WidgetKit / ActivityKit — https://developer.apple.com/documentation/widgetkit
- App Intents — https://developer.apple.com/documentation/appintents
- Human Interface Guidelines — https://developer.apple.com/design/human-interface-guidelines
- Product & design spec in this repo: [`rewind-app-spec-v2.md`](rewind-app-spec-v2.md)

---

## 12. Demo video shot list (for judges)

1. Onboarding promise + Photos permission (10s)
2. First old photo on the stack; four-direction gestures (25s)
3. Similar-photo tray on a burst (10s)
4. Video loop + screenshot tag (10s)
5. Undo / staging bin / batch free-up (15s)
6. Explore map trip → scoped deck (15s)
7. Calendar / On This Day (10s)
8. Chapter card on Profile + widget / Dynamic Island (15s)

Keep the UI quiet in the recording: photos should do the emotional work.
