# Google Play Store listing copy

Canonical copy for the Play Console store listing. Keep this file in sync
with whatever's actually live in Play Console. It's the source of truth
for what "the app does" claims are grounded in (checked against
`docs/features/*.feature` and `CLAUDE.md`, not aspirational).

## Short description (max 80 characters)

```
Private, offline cycle tracking. Encrypted on-device. No account, no cloud.
```

(75/80 characters)

## Full description (max 4000 characters)

```
Inner Flare is a menstrual cycle tracking app built around one idea: your cycle data is yours, and nobody else's. Not an app company's, not an advertiser's, not a data broker's.

WHY INNER FLARE IS DIFFERENT

Most cycle trackers ask you to create an account and sync to the cloud. Inner Flare doesn't have a cloud to sync to. There's no account, no login, no server anywhere in the picture. Every log, every note, every prediction is computed and stored entirely on your device.

- No account or sign-up, ever
- No internet permission: the app cannot phone home even if it wanted to
- No ads, no analytics, no tracking SDKs of any kind
- Your data leaves your device only if you deliberately export it

ENCRYPTED WHERE IT LIVES

Your logs are stored in a database encrypted at rest, unlocked with your fingerprint or face using your device's built-in biometrics (with a device passcode fallback). Leave the app in the background too long and it locks itself again automatically. This isn't a marketing claim. It's how the app is actually built.

LOGGING THAT DOESN'T FEEL LIKE A CHORE

Log a day in one screen, with nothing required. Track period flow, symptoms, and a note when you want to, or just confirm the day with zero taps beyond that. No mandatory fields, no forced multi-step forms.

A CALENDAR AND DASHBOARD THAT SHOW WHAT YOU CARE ABOUT

Browse your history on a calendar with flow intensity visible at a glance. Build your own dashboard from gauge and trend-chart cards: show only the stats that matter to you, hide the rest, and reorder everything to fit how you actually think about your cycle.

PREDICTIONS YOU CAN ACTUALLY CHECK

Cycle length, variability, and predicted fertile/period windows are calculated from your own logged history using plain, transparent statistics, not an opaque model you have to trust blindly. If you haven't logged enough to predict from yet, Inner Flare tells you that honestly instead of guessing.

YOUR DATA, PORTABLE ON YOUR TERMS

Moving to a new phone? Export your full history to a single file whenever you choose, and import it on your next device. No cloud step in between, just you, moving your own file, over whatever method you trust: a cable, your own cloud storage, a file transfer app, however you prefer.

Inner Flare is a tracking tool, not a diagnostic one, and it's not a substitute for medical advice. It simply shows you your own data, clearly, and keeps it private by default rather than by setting.
```

(~2470/4000 characters)

## Not yet written

- App icon / feature graphic (1024×500 banner Play requires beyond the
  launcher icon), not part of this doc, needs actual design work.
- Play's Data safety form answers (should be straightforward "no data
  collected/shared" given the above, but it's a structured form in Play
  Console, not free-text copy).
- Content rating questionnaire answers.
