# App Store Connect listing copy

Canonical copy for the App Store Connect "Prepare for Submission" page and
App Information tab. Companion to `docs/deployment/play-store-listing.md`
— same claims, adapted to App Store's fields and iOS-specific details
(Face ID/Touch ID, AirDrop) instead of Play's.

## Subtitle (max 30 characters, under the app name on the App Store)

```
Private, offline, encrypted.
```

(28/30 characters)

## Promotional text (max 170 characters, shown above the description; editable any time without a new build)

```
Fully offline and encrypted. No account, no cloud, no ads, ever. Your data stays yours.
```

(87/170 characters)

## Description (max 4000 characters)

```
Inner Flare is a menstrual cycle tracking app built around one idea: your cycle data is yours, and nobody else's. Not an app company's, not an advertiser's, not a data broker's.

WHY INNER FLARE IS DIFFERENT

Most cycle trackers ask you to create an account and sync to the cloud. Inner Flare doesn't have a cloud to sync to. There's no account, no login, no server anywhere in the picture. Every log, every note, every prediction is computed and stored entirely on your device.

- No account or sign-up, ever
- No internet permission: the app cannot phone home even if it wanted to
- No ads, no analytics, no tracking SDKs of any kind
- Your data leaves your device only if you deliberately export it

ENCRYPTED WHERE IT LIVES

Your logs are stored in a database encrypted at rest, unlocked with Face ID or Touch ID (with a device passcode fallback). Leave the app in the background too long and it locks itself again automatically. This isn't a marketing claim. It's how the app is actually built.

LOGGING THAT DOESN'T FEEL LIKE A CHORE

Log a day in one screen, with nothing required. Track period flow, symptoms, and a note when you want to, or just confirm the day with zero taps beyond that. No mandatory fields, no forced multi-step forms.

A CALENDAR AND DASHBOARD THAT SHOW WHAT YOU CARE ABOUT

Browse your history on a calendar with flow intensity visible at a glance. Build your own dashboard from gauge and trend-chart cards: show only the stats that matter to you, hide the rest, and reorder everything to fit how you actually think about your cycle.

PREDICTIONS YOU CAN ACTUALLY CHECK

Cycle length, variability, and predicted fertile/period windows are calculated from your own logged history using plain, transparent statistics, not an opaque model you have to trust blindly. If you haven't logged enough to predict from yet, Inner Flare tells you that honestly instead of guessing.

YOUR DATA, PORTABLE ON YOUR TERMS

Moving to a new phone? Export your full history to a single file whenever you choose, and import it on your next device. No cloud step in between, just you, moving your own file with AirDrop, the Files app, or however you prefer.

Inner Flare is a tracking tool, not a diagnostic one, and it's not a substitute for medical advice. It simply shows you your own data, clearly, and keeps it private by default rather than by setting.
```

(~2370/4000 characters)

## Screenshots

`screenshots/app_store/iphone_6.5in/` — captured 2026-09-10 against the
iPhone 11 Pro Max simulator specifically because that's the device whose
native resolution (1242×2688) exactly matches one of the four pixel sizes
Apple's "iPhone 6.5" Display" screenshot slot accepts. The previously
captured `screenshots/app_store/iphone_17_pro/` set is 1206×2622, which
doesn't match any of Apple's required screenshot bucket sizes — don't
upload those to the 6.5" slot. If App Store Connect's screenshot section
shows additional size tiers beyond 6.5" (e.g. a 6.7" or 6.9" slot for
newer devices), those will need their own capture run against a matching
simulator (iPhone 14/15 Plus or 13/14 Pro Max → 1284×2778; check whichever
tier ASC is actually asking for before capturing).

`screenshots/app_store/ipad_pro_13/` (2064×2752) matches the 13-inch M4
iPad Pro's native resolution exactly and is expected to satisfy whatever
iPad screenshot slot is current, but this hasn't been confirmed against
App Store Connect directly — try uploading it and see whether ASC accepts
it before assuming.

## Not yet written

- App Information tab: Name ("Inner Flare"), Category (Health & Fitness or
  Medical — pick one; Medical often draws more review scrutiny for
  diagnostic-sounding claims, and this app deliberately makes none, so
  Health & Fitness is probably the safer/faster fit), age rating, and
  copyright.
- App Privacy ("nutrition label") questionnaire.
