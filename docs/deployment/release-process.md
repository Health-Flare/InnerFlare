# Release process: Google Play, Apple App Store (TestFlight), F-Droid

The ordered runbook for shipping a version to every store. It doesn't repeat
one-time setup; that lives in `android-release.md`, `ios-release.md` and
`fdroid/README.md`. Per-version copy and checklists live in
`release-notes/vX.Y.Z.md`; cross-cutting status lives in
`release-tasklist.md`.

One tag drives both CI release jobs, so all three stores ship the same
commit: pushing `vX.Y.Z` builds a signed Android AAB/APK
(`android-release.yml`) and a signed iOS IPA uploaded to App Store Connect
(`ios-release.yml`). F-Droid builds the same tag on its own infrastructure.

Nothing below is automated past the tag. Everything outward-facing
(tagging, store submission, MRs) is a deliberate human step.

## 0. Prepare (on a release branch)

1. Branch `release/vX.Y.Z` from `main`.
2. Bump `version:` in `pubspec.yaml` (`X.Y.Z+N`). `N` becomes Android
   `versionCode` and iOS `CFBundleVersion`; it must be higher than every
   build already uploaded to that store, or the upload is rejected.
3. Write `release-notes/vX.Y.Z.md`: store "What's new" (Play limit 500
   characters), full notes, and the version-specific checklist. Rules for
   copy: no medical or diagnostic claims, no invented social proof, no em
   dashes (see `docs/marketing/README.md`).
4. Update the F-Droid draft build entry (`fdroid/org.healthflare.app.innerflare.yml`)
   to the new `versionName`, `versionCode` and tag.
5. If the schema version changed, do the upgrade test below.
6. Regenerate store screenshots and videos from `docs/marketing/` if the UI
   changed, or confirm the existing ones are still accurate.
7. `flutter analyze`, `dart format --set-exit-if-changed .`, `flutter test`
   all clean. Merge the branch to `main` through a PR (CI must pass).

## 1. Pre-flight on a real device

- **Upgrade test** (required whenever `schemaVersion` in
  `lib/data/database/schema.dart` changed): install the previous released
  build, create data and a customized dashboard, install the new build over
  it, and confirm data, layout and unlock all survive. Import a backup
  exported by the previous version.
- **Release-mode check:** build in release mode (not debug) and confirm no
  debug-only UI is visible: the dashboard database status icon, Settings'
  Database and Demo data sections.
- Unlock, log a day, and idle re-lock all work on both an iPhone and an
  Android device.

## 2. Tag

From an up-to-date `main`, after the PR is merged:

```bash
git tag vX.Y.Z
git push <remote> vX.Y.Z
```

The `release-bundle` job attaches `app-release.aab` and `app-release.apk` to
a GitHub Release. The `release-ipa` job signs and uploads the IPA to App
Store Connect. Watch both; a failure in one does not stop the other.

## 3. Google Play

1. Upload the `.aab` to Play Console. Use the **Internal testing** track
   first and install from it on a device.
2. Paste "What's new" from the release notes.
3. Promote the same release to **Production** (or **Closed/Open testing**
   first, if you want testers before everyone). Play reviews each release.
4. Choose a staged rollout percentage if you want a gradual release.

## 4. Apple App Store (TestFlight first)

1. Wait for the build to finish processing in App Store Connect
   (**TestFlight**). Answer any export compliance prompt; the app declares
   `ITSAppUsesNonExemptEncryption = false`.
2. **Internal testing** (up to 100 App Store Connect users): add yourself
   and install via TestFlight. No review needed.
3. **External testing** (first TestFlight users): create a group, add the
   build, fill in "Test Information" and what to test, add testers by email
   or public link. The first build of a version goes through Apple's beta
   app review.
4. When happy, open the version under **App Store**, select the build,
   paste "What's New", confirm screenshots for the iPhone 6.5" and iPad 13"
   slots (`docs/marketing/`), and **Submit for Review**. Choose manual or
   automatic release after approval.
5. First submission only: App Privacy answers ("Data Not Collected"), age
   rating, category, privacy policy URL, support URL. See the checklist in
   `ios-release.md`.

## 5. F-Droid

F-Droid builds from the tag itself; there's no upload.

1. Confirm the tag builds cleanly from a clean checkout with no secrets.
2. First time only: open the merge request against `fdroid/fdroid-data`
   with the metadata file (see `fdroid/README.md`, and clear the build
   spike first). Later versions: with `UpdateCheckMode: Tags`, F-Droid
   picks up new tags on its own; confirm the new version appears once its
   build cycle runs (it can take days).

## 6. After release

- Verify the live listing on each store shows the new version and "What's
  new" text.
- Update `release-tasklist.md`, tick the version's checklist, and record the
  release date.
- Note any store-review feedback here or in the release notes so the next
  release avoids it.

## Rolling back

Stores can't be unpublished back to an older binary. To fix a bad release,
ship `X.Y.Z+1` (or a patch version) with the fix, and use Play's staged
rollout halt or App Store's phased-release pause to limit exposure while
that's prepared. Never reuse a version or build number.
