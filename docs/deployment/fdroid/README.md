# F-Droid submission

Unlike Play/App Store, there's no CI pipeline of ours to build for
F-Droid — F-Droid's own build servers clone the tagged commit and build
the APK themselves, independently, using a metadata file that lives in a
separate repo (`fdroid/fdroid-data`), not this one. Our job is (1) make
sure that build actually succeeds in their environment and (2) submit the
metadata.

## Why this is more involved than it sounds

Inner Flare is well-suited to F-Droid on paper — GPLv3, no analytics, no
network calls, no proprietary dependencies (see `NOTICE.md`: every direct
dependency is MIT/BSD, and SQLCipher's own license is a permissive
BSD-style license too). That's the easy part.

The real open risk is that **F-Droid's build servers run with network
access tightly restricted** (mirroring their reproducible-build,
supply-chain-security goals), and a Flutter app's build needs `flutter pub
get` to pull packages from `pub.dev`, plus the Flutter SDK itself.

This is a known, actively-supported path today, not a dead end: F-Droid's
own [Flutter build
template](https://gitlab.com/fdroid/fdroiddata/-/blob/master/templates/build-flutter.yml)
pulls the Flutter SDK in via `srclibs: [flutter@<version>]` and runs
`flutter pub get --enforce-lockfile` against a relocated `PUB_CACHE` during
`prebuild` (pub.dev access for that specific step is allowlisted), then
excludes the SDK/cache from the reproducible-build source scan via
`scanignore`/`scandelete`. `de.wger.flutter` (a real shipping F-Droid app,
[metadata
here](https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/de.wger.flutter.yml))
has been built and updated this way across 40+ releases, which is decent
evidence this is a maintained path, not a two-year-stale one-off. This
repo's draft metadata (below) has been rewritten to follow that template.

What *hasn't* been verified yet, and is exactly what issue #34's spike
needs to confirm:

- That this app's specific dependency set (`sqflite_sqlcipher`,
  `local_auth`, `flutter_secure_storage`, native platform channels) builds
  cleanly through that recipe — the wger precedent proves the mechanism
  works in general, not that it works for *this* app's Gradle/plugin
  config.
- That `--enforce-lockfile` against our checked-in `pubspec.lock` doesn't
  hit anything F-Droid's allowlist rejects.
- An exact Flutter version to pin in `srclibs:` — this repo's own CI
  (`.github/workflows/*.yml`, via `subosito/flutter-action`) floats on
  `channel: stable` rather than a pinned version, so there isn't yet a
  single "the version we build with" to point `flutter@` at.

- [ ] **Spike first**: try building a release APK using F-Droid's own
      tooling before writing the metadata for real. F-Droid provides
      `fdroidserver` (`pip install fdroidserver`) with a `fdroid build
      --local` / test-build mode that approximates their sandboxed
      environment. If this doesn't work cleanly, the metadata PR isn't
      worth opening yet — raise it on F-Droid's `#fdroid` chat or their
      forum first. (Tracked as issue #34 — this README's job is to leave
      that spike a good starting recipe, not to run it.)

## Metadata

F-Droid metadata is a YAML file submitted as a PR to `fdroid/fdroid-data`,
at `metadata/org.healthflare.app.innerflare.yml` (package id matches the
Android `applicationId` in `android/app/build.gradle.kts`). A draft is at
`docs/deployment/fdroid/org.healthflare.app.innerflare.yml` in *this* repo, to be
copied over into that PR once the build spike above passes — treat it as a
starting point to adapt against F-Droid's current metadata schema
(`https://f-droid.org/docs/Build_Metadata_Reference/`), not a
copy-paste-ready file, since their schema does evolve.

## Checklist

- [ ] Build spike above passes against this app's actual dependency set
      (issue #34) — the draft recipe below is a starting point adapted
      from F-Droid's own template and a real shipping Flutter app, not a
      confirmed-working one yet.
- [x] Draft metadata file reviewed against F-Droid's current Build
      Metadata Reference and the current official Flutter build template
      (see "Why this is more involved than it sounds" above) — notably,
      the previous draft's `commit: v1.0.0` was wrong: F-Droid requires a
      full commit hash, never a tag/branch name.
- [x] Confirm no anti-features apply: no ads, no tracking, no non-free
      network services, no non-free dependencies, no "promotes non-free
      software" — `NOTICE.md` lists every direct dependency as MIT/BSD and
      SQLCipher's own license as permissive BSD-style; nothing in
      `pubspec.yaml` contradicts that. F-Droid's own reviewers still check
      independently once the merge request is open (they can flag things a
      normal store review wouldn't, e.g. a permissive-but-non-OSI-approved
      license buried in a transitive dependency), so this isn't a
      guarantee, just nothing left to fix on our side today.
- [ ] Which tagged commit is "the" first store release is still open
      (issue #29) — `pubspec.yaml` is at `1.1.0+3` while `v1.0.0` is
      already live on the Play Store (submitted 2026-09-10) and `v1.1.0`
      has since shipped too, so "reuse `v1.0.0`" and "use whatever's
      current" now give different answers. The metadata's `commit`,
      `versionName`/`versionCode`, and `CurrentVersion`/`CurrentVersionCode`
      all key off whatever this resolves to.
- [ ] `<chosen>` tag exists and builds cleanly from a clean checkout with
      no repo secrets or CI-only environment assumptions (true of every
      tag cut so far — the Android/iOS release workflows only add signing
      material, they don't change what's compiled).
- [ ] Reuse `screenshots/play_store/phone/` for F-Droid's listing (the
      files exist: `01_dashboard.png` … `05_log_entry.png`) — F-Droid
      pulls screenshots/description from the metadata repo or an app's own
      repo depending on setup; check their current convention rather than
      assuming one when the merge request is actually opened.
- [ ] Open the merge request against `fdroid/fdroid-data`.
- [ ] Track reviewer feedback — F-Droid inclusion review is manual and
      often slow (weeks, not days); don't block the Play/App Store launch
      on it.
