# Marketing asset specs

Declarative specs that drive a generator for three kinds of assets:

1. **Store screenshots**: exact-pixel PNGs for App Store Connect and Play
   Console, no compositing (what the app really looks like).
2. **Marketing images**: the same captures composed into framed, captioned
   images (store "story" screenshots, social posts, the Play feature graphic).
3. **Videos**: scripted walkthroughs recorded from a real device or
   simulator, for App Store app previews and for social/web use.

Nothing here is executable. The files are the contract; a runner reads them.
The existing `integration_test/screenshot_test.dart` and
`test_driver/integration_test.dart` are the hand-written predecessor: they hard-code
seven screens and write raw PNGs to `screenshots/raw/<device>/`. The
generic driver replaces the hard-coded list with `specs/shots.yaml`, and
keeps the parts that already work (see "Capture mechanics" below).

## Layout

| File | Answers |
|------|---------|
| `specs/targets.yaml` | Where do assets go, and at what pixel size? Devices, status bar, store slots, video formats. |
| `specs/datasets.yaml` | What data is in the app when a shot is taken? Seed datasets, fixed clock, dashboard layouts. |
| `specs/screens.yaml` | Which widget is each screen id, and what does it need? |
| `specs/shots.yaml` | The shot list: screen, dataset, setup, which targets, which stores. |
| `specs/marketing.yaml` | Brand tokens, layouts, and per-shot headline/subhead copy. |
| `specs/videos.yaml` | Storyboards: scenes, actions, timing, captions, output formats. |

Resolution order for one asset: `shots.yaml` entry -> its `dataset` and
`layout` -> each `targets.yaml` target it lists -> capture -> (optionally)
compose using `marketing.yaml` -> write to `output` path.

## Output tree

```
screenshots/
  raw/<target_id>/<shot_id>.png             untracked scratch (already .gitignored)
  store/<store>/<slot>/<NN>_<shot_id>.png   what gets uploaded
  marketing/<layout_id>/<target_id>/<shot_id>.png
videos/                                     rendered videos (large: do not commit;
  <video_id>/<format_id>.mp4                add /videos/ to .gitignore with the runner)
```

The current committed `screenshots/app_store/`, `screenshots/play_store/`
sets predate this layout. The runner may write `screenshots/store/` beside
them; migrate or delete the old sets once the new ones are uploaded.

## Ground rules for content

These exist because store assets are the app's most public claims.

- **Every claim is grounded.** Headlines and captions may only restate what
  `docs/deployment/app-store-listing.md` / `play-store-listing.md` already
  claim, which are themselves checked against `docs/features/*.feature`.
  Adding a new claim means grounding it there first.
- **No medical or diagnostic claims** (CLAUDE.md, "Privacy-Centric"). No
  "know when you're fertile", no "detect", no health outcomes. Predictions
  are "estimates from your own history".
- **No fabricated social proof**: no ratings, review quotes, download counts,
  "#1", awards, or press logos.
- **Synthetic data only.** Screens show `buildDemoCycleLogs` output, never a
  real person's log. The persona behind it is "Jane Doe"; no name is ever
  written into the app (it has no profile field). No real names, photos, or
  identifiable devices in frames or footage.
- **Debug affordances never appear.** Each shot's `must_not_show` list is a
  review checklist, and `screens.yaml` lists the `debug_chrome` each screen
  carries (the dashboard's `DatabaseStatusIndicator`, Settings' Database and
  Demo data sections). The runner suppresses these with `SCREENSHOT_MODE`
  (see "Capture flag").
- **No em dashes** in any copy (project rule).
- **Light theme only.** `AppTheme` has no dark theme yet. When one exists,
  add `themes: [light, dark]` to shots and targets; the specs already carry
  a `theme` field for it.
- **English only** for now (no localization in the app).

## Capture mechanics (carried over from the existing pipeline)

Do not regress these; each fixed a real flake or bug:

- The database is the real encrypted SQLCipher file, opened with
  `AlwaysAllowBiometricGate` instead of the device biometric prompt
  (`lib/core/security/biometric_gate.dart`). Only the prompt is swapped.
- Screenshot shots pump each screen as the root of a fresh `MaterialApp`
  sharing one `ProviderContainer`, instead of navigating there. iOS's
  swipe-back detector can steal the next tap for a frame or two after a pop.
- Seeding goes through `cycleDayLogRepositoryProvider` (the real write
  path), oldest first, then invalidates the log-dependent providers
  (`invalidateLogDependentProviders`).
- Android needs `binding.convertFlutterSurfaceToImage()` before
  `takeScreenshot()`. Not needed while every capture is on iOS, but keep
  the call: it is a no-op there.
- Use `pumpAndSettle` for static screens only. No indeterminate spinner may
  be on screen (it never settles).
- The clock is fixed via `nowProvider` (see `datasets.yaml`), so output is
  reproducible and predictions never drift between runs.
- Cycle-math and dataset builders take `now` as a parameter; the runner
  must pass the fixed clock, never `DateTime.now()`.

**Video shots differ:** a walkthrough must show real navigation (taps,
transitions), so videos run the real `InnerFlareApp` shell with the same
overrides, not root-pumped screens. Expect the swipe-back flake; scenes
avoid back-swipes and use the AppBar back button (`tap: {tooltip: Back}`).

## Status bar and device state

Set before capture, restore after. Values live in `targets.yaml`. There
are only two capture devices (iPhone 6.5" and iPad 13"), both iOS.

- iOS Simulator: `xcrun simctl status_bar <udid> override --time 9:41
  --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4`
- Do Not Disturb on, no keyboard, no pending permission dialogs.

## Schema notes

All files are YAML with a top-level `version: 1`. IDs are `snake_case` and
referenced across files by exact match; the runner must fail on an unknown
id rather than skip it.

- `shots.yaml` `setup` is an ordered list of steps run after seeding and
  before capture. Step kinds: `seed_layout: <layout_id>`, `select_date:
  <selector>`, `scroll_to: {finder}`, `tap: {finder}`, `wait_ms: <int>`,
  `set_symptoms: [ids]`. A **finder** is exactly one of `text`, `tooltip`,
  `key`, `icon`, `type`.
- **Date selectors** resolve against the seeded data and fixed clock:
  `latest_period_start`, `previous_period_start`, `today`, `yesterday`,
  `mid_cycle_of: <selector>`, or a literal `YYYY-MM-DD`.
- `stores` values: `app_store`, `play_store`, `fdroid`, `web`. F-Droid
  reuses the Play phone set (release-tasklist.md), so a shot listing
  `play_store` phone needs no separate `fdroid` entry.
- `status: needs_review` marks a shot whose screen has not been visually
  checked at target size; the runner still produces it but flags it.

## Capture flag

Every capture run passes `--dart-define=SCREENSHOT_MODE=true`. It turns off
the debug-only UI (`showDebugChrome` in `lib/core/debug/debug_chrome.dart`)
that a debug build would otherwise show: the dashboard status indicator and
Settings' Database and Demo data sections. The iOS Simulator can only run
debug builds, so this is what keeps those captures clean.

## Recording your own videos

`scripts/video_mode.sh` launches the app on a simulator looking like a
release build, for screen recordings made by hand:

```bash
scripts/video_mode.sh              # iPhone 11 Pro Max (App Store 6.5")
scripts/video_mode.sh ipad         # iPad Pro 13-inch (M4)
scripts/video_mode.sh "iPhone 17"  # any simulator name or UDID
scripts/video_mode.sh --fixed-clock  # freeze "now" at the spec's clock
scripts/video_mode.sh --keep-data    # don't replace the app's data
```

It runs `tool/video_mode.dart` with `SCREENSHOT_MODE`, so there is no debug
chrome or DEBUG ribbon, seeds the demo dataset and the `customized`
dashboard layout, uses the always-allow biometric gate (no Face ID prompt;
tapping Unlock is safe), acknowledges the first-run disclaimer, and sets
the status bar to 9:41. By default it **replaces** the simulator app's logs
and dashboard layout; use `--keep-data` to avoid that. The greeting on the
dashboard follows the real time of day ("Good morning" vs "Winding down?"),
so use `--fixed-clock` if the take should read as morning.

Record with Cmd+R in the Simulator (File > Record Screen) or
`xcrun simctl io booted recordVideo out.mov`. Turn on Do Not Disturb by
hand; `simctl` can't. This does not replace the scripted storyboards in
`specs/videos.yaml` (see #72).

## Decisions made

- **Capture devices:** iPhone 6.5" and iPad 13" only. Play reuses them.
- **Lock screen:** in the set, second position, on every slot.
- **Frames:** plain drawn bezels (`simple_bezel`), no proprietary artwork.
- **Fonts:** Fraunces and DM Sans, copied from the website into `fonts/`.
- **Onboarding:** being built on another branch. Add its shots and scenes
  (and remove the empty-`onboarding/` note) when it merges.
- Everything else below is left as is for now.

## Open items (not blocking; revisit when building the runner)

1. **Store slot sizes** in `targets.yaml` marked `verify: true` are from
   memory of Apple/Google requirements. Confirm against App Store Connect
   and Play Console before upload (Apple changes these; the previous batch
   was checked directly, see `docs/deployment/app-store-listing.md`).
2. **Play reuses the iOS captures.** Play's long side may be at most 2x the
   short side, and the iPhone 6.5" capture is 2.16:1, so Play phone images
   are the composed `story_play` layout at 1080x1920 rather than raw
   captures (the iPad 13" captures, at 1.33:1, go to Play's tablet slot
   raw). This shows the iOS status bar inside the bezel; check it reads
   acceptably on Play, and if not, crop it in the frame or add an Android
   capture device later.
3. **App preview rules.** Apple requires app previews to show the app in
   use; the `store_app_preview` video therefore contains no overlaid
   marketing footage. The looser `social_*` cuts can use titled scenes.
4. **Recording start/stop sync** between the `flutter drive` test and
   `simctl io recordVideo` / `adb screenrecord` is unspecced on purpose: the
   runner owns it. `videos.yaml` only requires a `lead_in_ms`/`tail_ms` trim.
