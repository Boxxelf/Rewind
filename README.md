# Rewind

**Not a photo cleaner. A time machine that happens to free up storage.**

Rewind is an iOS app that turns camera-roll cleanup into a quiet, game-like ritual. You swipe through randomized “blind box” decks of your own photos, videos, and screenshots — keep, skip, delete, or decide later. Storage is freed as a side effect of reliving memories. Nothing ever leaves the device.

Built for [Reverie Hacks 2026](https://reverie-hacks-2026.devpost.com/) · App Development track.

![Platform](https://img.shields.io/badge/iOS-26%2B-black) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-native-blue) ![Privacy](https://img.shields.io/badge/photos-on--device%20only-lightgrey)

## Product film and brand

[Watch the 29-second product film](https://tinajiang.dev/work/rewind/) · [Download the video](Marketing/Rewind_29s_1080p60.mp4) · [Brand guidelines and logos](Brand/README.md)

## Why it exists

Most people never finish cleaning their camera roll. Month-by-month tools feel like chores: chronological, binary, guilt-driven. Rewind is the opposite.

- **Surprise, not chronology.** Finite decks of 20–30 items, shuffled across your whole library, slightly biased toward older photos.
- **Four-direction gestures.** Up = delete (staged). Right = keep. Left = skip. Down = later.
- **Privacy as a product claim.** PhotoKit + on-device Vision. No photo data is uploaded.

## Core features

| Area | What you get |
| --- | --- |
| Clean | Card stack, category pills (Photos / Screenshots / Videos), staging bin, undo |
| Later Stack | Defer a decision; items resurface after a 7-day cool-down |
| Similar photos | Inline burst/near-duplicate tray without leaving the deck |
| Explore | MapKit trip clusters + calendar with On This Day |
| Chapters | Time-based milestone cards instead of streaks |
| System | Home/Lock widgets, Dynamic Island Live Activity, Siri App Intent |

Full product, setup, and user documentation lives in [`DOCUMENTATION.md`](DOCUMENTATION.md). Design spec: [`rewind-app-spec-v2.md`](rewind-app-spec-v2.md).

## Requirements

- macOS with **Xcode 26** (iOS 26 SDK)
- An **iPhone** (physical device strongly recommended — PhotoKit needs a real library)
- Apple ID for code signing

## Quick start

```bash
git clone https://github.com/Boxxelf/Rewind.git
cd Rewind
open Rewind.xcodeproj
```

1. Select the **Rewind** scheme and an iPhone destination.
2. In *Signing & Capabilities*, choose your Team and unique bundle identifier if `com.tinajiang.Rewind` is taken.
3. Build and run (`⌘R`).
4. Grant **Read and Write** Photos access when prompted.
5. Complete the short onboarding, then swipe the first deck.

**Simulator note:** the UI runs, but the Photos library is empty or sparse. Use a device for a real demo.

## Project layout

```
Rewind/                 App target (SwiftUI)
  App/                  Root tab shell
  Features/             Clean, Explore, Profile, Onboarding
  Components/           Cards, media, empty states
  Services/             PhotoKit, shuffle, clustering, widgets
  Models/               Deck, decisions, SwiftData records
  Design/               Theme + haptics
RewindWidgets/          WidgetKit + Live Activities
RewindTests/            Shuffle and gesture unit tests
```

## Privacy

Rewind requests `PHPhotoLibrary` read/write access only. Screenshots are classified with the **Vision** framework on-device. There is no backend, no analytics SDK, and no cloud photo sync in this build.

## License

MIT. See [LICENSE](LICENSE).
