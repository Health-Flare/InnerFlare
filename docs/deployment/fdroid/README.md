# F-Droid submission

Unlike Play/App Store, there's no CI pipeline of ours to build for
F-Droid: F-Droid's own build servers clone the tagged commit and build
the APK themselves, independently, using a metadata file that lives in a
separate repo (`fdroid/fdroid-data`), not this one. Our job is (1) make
sure that build actually succeeds in their environment and (2) submit the
metadata.

## Why this is more involved than it sounds

Inner Flare is well-suited to F-Droid on paper: GPLv3, no analytics, no
network calls, no proprietary dependencies (see `NOTICE.md`: every direct
dependency is MIT/BSD, and SQLCipher's own license is a permissive
BSD-style license too). That's the easy part.

The real open risk is that **F-Droid's build servers run with network
access tightly restricted** (mirroring their reproducible-build,
supply-chain-security goals), and a Flutter app's build needs `flutter pub
get` to pull packages from `pub.dev`, plus the Flutter SDK itself. F-Droid
has supported this before via their `srclibs` mechanism (a pinned Flutter
SDK checkout) and allowlisted `pub.dev` access for `flutter pub get`
specifically, but support and allowlist rules have shifted over time and
should be re-checked against F-Droid's current docs rather than assumed.
This is exactly the kind of "worked for someone's app two years ago" detail
that goes stale.

- [ ] **Spike first**: try building a release APK using F-Droid's own
      tooling before writing the metadata for real. F-Droid provides
      `fdroidserver` (`pip install fdroidserver`) with a `fdroid build
      --local` / test-build mode that approximates their sandboxed
      environment. If this doesn't work cleanly, the metadata PR isn't
      worth opening yet: raise it on F-Droid's `#fdroid` chat or their
      forum first; Flutter-app support is a known, occasionally-discussed
      edge case for them, not a solved default path the way a plain
      Gradle Android app is.

## Signing: build an unsigned release APK

F-Droid signs every APK with its own key, so its build has to produce an
*unsigned* release APK. `android/app/build.gradle.kts` has no silent
fallback for this: a release build with no `android/key.properties` stops
with an error instead of signing with the debug key. The F-Droid recipe
opts in explicitly:

```bash
flutter build apk --release --android-project-arg=unsignedRelease=true
```

That sets the release buildType's `signingConfig` to `null` and skips the
missing-key check. AGP writes `build/app/outputs/apk/release/app-release-unsigned.apk`,
and Flutter's Gradle plugin copies it to
`build/app/outputs/flutter-apk/app-release.apk`. The recipe's `output`
points at that copy, the same path fdroiddata's
`templates/build-flutter.yml` uses. The file is unsigned despite its name:
`apksigner verify` on it reports `DOES NOT VERIFY` / `Missing META-INF/MANIFEST.MF`.

How the release-signing properties combine:

| Build | Signed with |
|---|---|
| `key.properties` present | the upload key (Play, `android-release.yml`) |
| `-PunsignedRelease=true` | nothing: unsigned, for F-Droid (wins over `key.properties`) |
| `-PallowDebugSigning=true`, no `key.properties` | the debug key (local only, never distribute) |
| no `key.properties`, neither flag | build fails |
| both flags | build fails (they contradict each other) |

Debug builds (`flutter build apk --debug`, `flutter run`) use the debug key
as before and need none of this.

We don't use the other common F-Droid approach, a `prebuild` step that runs
`sed` to delete `signingConfig` lines. Our `signingConfig` is a multi-line
Kotlin `if`/`else` expression, so deleting single lines would break the
Gradle script, and the fix would live in fdroiddata, not here. An explicit
property is visible in the recipe and can't break silently. fdroidserver's
`gradleprops` field isn't usable either: it only applies to the `gradle:`
build method, and Flutter apps build through a manual `build:` command.

`-PunsignedRelease` only exists from the release after v1.3.0. The draft
recipe's `commit` has to point at a tag that includes it.

## Metadata

F-Droid metadata is a YAML file submitted as a PR to `fdroid/fdroid-data`,
at `metadata/org.healthflare.app.innerflare.yml` (package id matches the
Android `applicationId` in `android/app/build.gradle.kts`). A draft is at
`docs/deployment/fdroid/org.healthflare.app.innerflare.yml` in *this* repo, to be
copied over into that PR once the build spike above passes, treat it as a
starting point to adapt against F-Droid's current metadata schema
(`https://f-droid.org/docs/Build_Metadata_Reference/`), not a
copy-paste-ready file, since their schema does evolve.

## Checklist

- [ ] Build spike above passes (or a documented workaround, e.g. vendoring
      a `pub` cache, is in place).
- [ ] Draft metadata file reviewed against F-Droid's current Build Metadata
      Reference.
- [ ] Confirm no anti-features apply: no ads, no tracking, no non-free
      network services, no non-free dependencies, no "promotes non-free
      software"; all expected to be clean given `NOTICE.md`, but F-Droid's
      own reviewers check independently and can flag things a normal store
      review wouldn't (e.g. a permissive-but-non-OSI-approved license
      buried in a transitive dependency).
- [ ] The tag the metadata points at exists, includes `-PunsignedRelease`
      (so not `v1.3.0`, which the draft still names), and builds an unsigned
      APK from a clean checkout with no repo secrets or CI-only environment
      assumptions (the Android/iOS release workflows only add signing
      material, they don't change what's compiled).
- [ ] Reuse `screenshots/play_store/phone/` for F-Droid's listing:
      F-Droid pulls screenshots/description from the metadata repo or an
      app's own repo depending on setup; check their current convention
      rather than assuming one.
- [ ] Open the merge request against `fdroid/fdroid-data`.
- [ ] Track reviewer feedback: F-Droid inclusion review is manual and
      often slow (weeks, not days); don't block the Play/App Store launch
      on it.
