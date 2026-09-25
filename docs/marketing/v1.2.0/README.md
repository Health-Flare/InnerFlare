# Inner Flare 1.2: launch copy

Marketing copy for the 1.2.0 release. The product source of truth is
[`docs/deployment/release-notes/v1.2.0.md`](../../deployment/release-notes/v1.2.0.md);
if this file and the release notes disagree, the release notes win and this
file is wrong. Short-form video scripts are in
[`video-scripts.md`](video-scripts.md).

## The one-line pitch

> **Inner Flare 1.2: a dashboard you shape yourself, charts that admit when
> they don't know, and still nothing leaves your phone.**

## Positioning

1.1 was about trust: a calmer unlock, backups, choosing your symptoms. 1.2 is
about **reading your own data**. The dashboard became one grid you arrange
and resize, and the new gauge and trend cards show your history at a glance.

What makes that worth talking about is not "we added charts." Every cycle app
has charts. The difference is what these charts refuse to do:

1. **They scale to you.** The gauge fills against your own average cycle,
   not a textbook 28 days.
2. **They say "not enough data yet."** Thin or irregular history gets a
   labelled range or an honest empty state, never a made-up number.
3. **They don't diagnose.** The cycle table shows what you logged, newest
   first, for you to take to an appointment. No interpretation attached.
4. **They stay on your phone.** No account, no internet permission, no
   analytics. Unchanged, and still the reason the app exists.

## Messaging pillars

| Pillar | Say | Proof in the app |
|---|---|---|
| Yours to arrange | "One grid. Drag it, resize it, hide what you don't use." | Customize dashboard live preview, corner-drag resize, reorder across the whole grid |
| Honest by default | "When it doesn't know, it says so." | Gauge range state; trend card needs 2 complete cycles |
| Ready for the appointment | "Every cycle, its length, and the change from the last. Nothing added." | Cycle detail table from a trend card, newest first, no diagnostic text |
| Private, still | "No account. No cloud. No internet permission." | Android manifest has no `INTERNET`; first-run statement; export is manual |

## Claims guardrails

Every claim here is checked against the code on `main` as of this release.
Keep it that way.

**Safe to say**

- No account, no login, no cloud sync, no ads, no analytics or tracking SDKs.
- No internet permission. (The privacy policy link hands off to your browser
  when you tap it; the app itself fetches nothing.)
- Encrypted on your device, unlocked with Face ID, Touch ID, fingerprint, or
  your passcode; re-locks after a timeout you choose.
- Free and open source; the code is public.
- Predictions are estimates from plain statistics on your own logs.

**Do not say**

- Anything about "accurate," "precise," or "smart" predictions, or AI/ML.
  The app uses averages and says so.
- Anything that implies contraceptive reliability or fertility guidance.
  The app is explicitly not a medical device. Do not show the fertile window
  as a selling point in 1.2 material.
- That symptom-frequency, flow-intensity, or variability charts are
  available. They are "Coming soon" in the catalog, not shipped. Keep them
  out of screenshots and video frames.
- That the dashboard suggests cards for you. The cleanup suggestion (6+
  cards) ships; the "add this card" suggestion is still an open spec.
- "Military-grade," "unhackable," "100% secure," or any absolute.
- Menopause or perimenopause support. There's a perimenopause *demo dataset*
  for screenshots, not a feature.

**Style**

- No em dashes. Use a colon, a full stop, or a comma.
- Plain words. "Estimate," not "prediction engine." "Your phone," not "the
  device" in consumer copy.
- Don't write "we value your privacy." Say what the app does or can't do.

### A problem to fix in the existing store listings

The App Store description in `docs/deployment/app-store-listing.md` has
advertised "gauge and trend-chart cards" since 10 September, nine days
before they were merged; no released build (1.0.x or 1.1.0) contains them. 1.2 makes
that sentence true. It also means "new gauge and trend cards" reads oddly to
anyone who read the listing. The copy below leads with the grid, resizing,
and honesty, and treats the cards as new *in the app*, which is accurate.
Going forward, listing copy should describe the shipped build only.

---

## Store copy

"What's new" text is in the release notes. Promotional text for the App Store
(170 max, editable without a new build) for the launch window:

```
New in 1.2: a dashboard you arrange and resize, with charts that say "not enough data yet" instead of guessing. Still no account, no cloud.
```

(139/170 characters.) Revert to the evergreen promo text a few weeks after
launch.

---

## Website

Announcement post: `src/inner-flare/blog/posts/inner-flare-1-2.md` in
`Health-Flare/website`. It is committed but held back from publishing
(`permalink: false`, excluded from collections). To publish on release day,
remove those two front-matter lines and set `date`.

---

## Social posts

Written to fit Bluesky's 300-character limit, so they work unedited on
Mastodon too. Add the store link or the post link at the end.

**Launch post**

```
Inner Flare 1.2 is out.

Your dashboard is now one grid you arrange and resize. New gauge and trend cards scale to your own cycle, not a textbook one, and say "not enough data yet" when that's the truth.

Still no account. Still no cloud. Free and open source.
```

**Honesty angle**

```
Most cycle apps will give you a date even when they have nothing to base it on.

Inner Flare 1.2's charts won't. Fewer than two complete cycles, or cycles that swing a lot? You get a labelled range or an honest "not enough data yet."
```

**Appointment angle**

```
New in Inner Flare 1.2: tap your cycle length chart and get a plain table. Each cycle's start date, its length, and how much it changed from the last one. Newest first.

No interpretation. No diagnosis. Just what you logged, ready to show your doctor.
```

**Privacy angle**

```
Inner Flare now tells you on first launch, in plain words: it isn't a medical device, your logs stay on your phone unless you export them, and there's no account to make.

It has no internet permission. That was true before 1.2 and it's still true.
```

**Open source / builder angle** (for the Health Flare account, dev audiences)

```
Inner Flare 1.2 shipped: unified dashboard grid, resizable cards, gauge + trend charts, a cycle table for appointments.

Every claim in the release notes is checked against the code, and the code is public. Go look.
```

---

## Video plan

Five vertical (9:16) videos, 15 to 35 seconds each, one idea per video.
Screen recordings of a real build over simple typography, no stock footage,
no faces required. Full scripts in [`video-scripts.md`](video-scripts.md).

| # | Title | Length | Pillar | Hook |
|---|---|---|---|---|
| 1 | Make it yours | 30s | Yours to arrange | "Your cycle app's dashboard was designed for someone else." |
| 2 | It says "I don't know" | 30s | Honest by default | "Your period app is guessing. Mine admits it." |
| 3 | Before your appointment | 25s | Ready for the appointment | "'How long are your cycles?' Stop guessing in the exam room." |
| 4 | Nothing to sign up for | 20s | Private, still | "The first thing this app asks you for: nothing." |
| 5 | What's new in 1.2 | 35s | All | Release roundup, for the store preview slot and the launch post |

**Order:** post #5 on release day with the launch post, then #1, #2, #3, #4
roughly two to three days apart. #2 is the strongest differentiator; if you
only make two, make #5 and #2.

**Recording setup (all videos)**

- Use a **debug** build and Settings → Demo data → "Load demo data". It is
  debug-only, so it will never appear in a release build, and it keeps real
  logs out of frame. The dataset covers five complete cycles of 27 to 30 days,
  so gauges and trend cards show real values.
- For the "not enough data" shots in #2, use a fresh install with one or two
  logged periods instead.
- Hide the status-bar clock and notifications (Android demo mode, or iOS
  Simulator's clean status bar). Record at native resolution; crop to 9:16
  in edit.
- Brand: cream `#F3E9DB` background, teal `#17272C` text, ember `#E0834A`
  accent. On-screen type in Fraunces (headlines) and DM Sans (body), the
  same self-hosted fonts as the website.
- Always burn in captions. Most short-form video is watched muted.
- End card on every video: app icon, "Inner Flare", "Free. Offline.
  Open source.", and "App Store · Google Play".
