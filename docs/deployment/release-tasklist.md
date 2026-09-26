# Release task list: Google Play, F-Droid, Apple App Store

Master checklist for getting Inner Flare live on all three stores, and the
CI needed to push subsequent versions out. Each platform has its own doc
with detail; this file is the index and tracks cross-cutting work. The
ordered, repeatable steps for shipping any version are in
`docs/deployment/release-process.md`; per-version copy and checklists are in
`docs/deployment/release-notes/`.

| Platform | CI workflow | Status | Detail doc |
|---|---|---|---|
| Google Play | `.github/workflows/android-release.yml` | Signs on `v*.*.*` tag push and uploads to the internal track (needs `PLAY_SERVICE_ACCOUNT_JSON`) | `docs/deployment/android-release.md` |
| Apple App Store | `.github/workflows/ios-release.yml` | Working: Apple secrets are configured; signed IPAs uploaded to App Store Connect for v1.0.1 and v1.1.0 | `docs/deployment/ios-release.md` |
| F-Droid | none (F-Droid builds from source on its own infra) | Not started, metadata PR to `fdroid/fdroid-data` | `docs/deployment/fdroid/README.md` |

## Cross-cutting, before any store submission

- [x] Decide the public app name shown to users (`Inner Flare`) and the package/bundle ID it's keyed off: `org.healthflare.app.innerflare` now, confirmed and set on both Android (`applicationId`/`namespace`) and iOS (`PRODUCT_BUNDLE_IDENTIFIER`), matching the app already created in Play Console. F-Droid's package id (see `docs/deployment/fdroid/`) is derived from the same value.
- [x] Version/build numbers in `pubspec.yaml` (currently `1.2.0+4` on the `release/v1.2.0` branch): Android's `versionCode`/`versionName` and iOS's `CFBundleVersion`/`CFBundleShortVersionString` both derive from it (`flutter.versionCode`/`flutter.versionName` in `android/app/build.gradle.kts`; Flutter's Xcode build phase does the equivalent for iOS).
- [x] Write (or confirm final) app description / "what this app does" copy: Play Store short/full description written, see `docs/deployment/play-store-listing.md`. Still needed verbatim for the App Store listing and the F-Droid summary/description fields. Reuse the same copy rather than writing three different versions.
- [ ] Publish a privacy policy and host it somewhere stable (e.g. GitHub Pages from this repo, or a plain page in `docs/`). Required by Play (non-negotiable for health data) and by Apple; F-Droid doesn't require one but it's good practice to link it from the metadata anyway.
- [ ] Confirm the GitHub repo stays public: F-Droid requires buildable public source; Play/App Store don't require it but a dead/private source link would break the F-Droid submission later.
- [ ] Store screenshots current. The existing `screenshots/play_store/`, `screenshots/app_store/` sets predate the customizable dashboard and the lock screen shot. New sets are specced in `docs/marketing/` (iPhone 6.5" and iPad 13" capture devices; Play reuses them), pending the runner. Reuse the Play phone set as F-Droid's screenshots too rather than producing a fourth set.

## Google Play

CI is done. Remaining work is entirely Play Console data-entry, tracked in
the checklist at the bottom of `docs/deployment/android-release.md`:
developer account, store listing copy/assets, privacy policy URL, data
safety form, content rating questionnaire, target audience/ads
declaration, confirming `applicationId` is final, and choosing Play App
Signing vs. self-managed.

- [ ] Work through that checklist and cut the `v1.0.0` tag once ready: see "Cut a release" in that doc.

## Apple App Store

See `docs/deployment/ios-release.md` for full detail. Summary of what's
left:

- [x] Enroll in the Apple Developer Program ($99/yr) if not already done.
- [x] Register the `org.healthflare.app.innerflare` bundle ID and create the app record in App Store Connect.
- [x] Generate a Distribution certificate + App Store provisioning profile (or switch the Xcode project to automatic signing with a CI-usable Apple ID/API key, see the doc for the tradeoff).
- [x] Generate an App Store Connect API key for CI uploads (avoids storing an Apple ID password/2FA in CI).
- [x] Add the resulting secrets to the repo (`APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISIONING_PROFILE_BASE64`, `APPLE_PROVISIONING_PROFILE_NAME`, `APPLE_TEAM_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`). See the doc for exact names, matching the `ios-release.yml` workflow.
- [ ] Fill in App Privacy ("nutrition label") in App Store Connect: should be "Data Not Collected" given the offline design, but every category still needs an explicit answer.
- [x] Set the export compliance answer for using encryption (SQLCipher): `ITSAppUsesNonExemptEncryption` is now in `ios/Runner/Info.plist` so this doesn't have to be answered manually on every upload (re-verify the `false` value against Apple's current guidance before first submission, see doc).
- [ ] Complete the age rating questionnaire and write App Store listing copy (subtitle, promotional text, keywords; Play doesn't have exact equivalents for these).
- [ ] Do at least one TestFlight internal build before the first public release.
- [ ] Cut the same `v1.0.0` tag (or a separate iOS-specific tag scheme, see doc) once ready.

## F-Droid

See `docs/deployment/fdroid/README.md`. Summary:

- [ ] Verify the app actually builds in F-Droid's sandboxed (network-restricted) build environment: this is the real open risk for a Flutter app and needs a spike before anything else here, since F-Droid's build server can't freely reach `pub.dev` the way normal CI can.
- [ ] Write the F-Droid metadata file (draft at `docs/deployment/fdroid/org.healthflare.app.innerflare.yml`) describing how to build a release APK from a tagged commit.
- [ ] Confirm no anti-features apply (no ads, no tracking, no non-free dependencies, no non-free network services; all true today per `NOTICE.md`, but F-Droid's reviewers check independently).
- [ ] Open a merge request against `fdroid/fdroid-data` adding the metadata file, referencing this repo and the `v1.0.0` tag.
- [ ] Respond to F-Droid reviewer feedback (their merge request review is usually the slowest part: budget weeks, not days).

## v1.2.0 (first TestFlight release)

Copy, version and per-version checklist: `docs/deployment/release-notes/v1.2.0.md`.
Process: `docs/deployment/release-process.md`.

- [x] Version bumped to `1.2.0+4`, release notes and store "What's new" written, F-Droid draft points at `v1.2.0`.
- [ ] Upgrade test from a real 1.1.0 install (schema 5 to 7).
- [ ] Release build confirmed free of debug-only UI.
- [x] Apple secrets are in the repo and `release-ipa` uploads to App Store Connect. Build number `4` is higher than the last upload (`3`), which is the only thing that would fail the upload step.
- [ ] TestFlight: internal build tested, then external group for first testers.
- [ ] Play: internal testing, then promote to production.
- [ ] Marketing assets regenerated from `docs/marketing/`.
- [ ] `v1.2.0` tag pushed from `main`.
- [ ] F-Droid: metadata MR opened (blocked on the build spike).

## CI/CD summary

- [x] `ci.yml`: format/analyze/URL-scan/test on every push and PR to `main`.
- [x] `android-release.yml`: debug APK on manual dispatch; signed AAB+APK GitHub Release plus Play internal-track upload on `v*.*.*` tag (upload step needs the `PLAY_SERVICE_ACCOUNT_JSON` secret, not yet set).
- [x] `ios-release.yml`: simulator build on manual dispatch; signed IPA uploaded to App Store Connect on `v*.*.*` tag (working since v1.0.1). Build numbers must strictly increase per upload.
- [ ] F-Droid has no CI of ours to build. It clones the tagged commit and builds independently. Our job is just making sure the tag builds cleanly with only what's checked into the repo (no CI-only secrets baked into the app itself, which is already true here).
- [ ] Once both stores are live, decide whether `v*.*.*` tags should trigger *both* release jobs together (simplest) or whether Android/iOS ever need to ship out of step (e.g. an iOS-only hotfix). If so, consider platform-scoped tags (`android-v1.0.1`, `ios-v1.0.1`) instead. Not needed for v1; revisit if it comes up.
