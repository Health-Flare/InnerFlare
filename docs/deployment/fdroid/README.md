# F-Droid and IzzyOnDroid

Two FOSS Android repositories, two different models:

- **F-Droid** builds the APK itself from a tagged commit, using the recipe
  in `org.healthflare.app.innerflare.yml` (this folder), and signs it with
  F-Droid's key. The recipe lives in `fdroid/fdroiddata` once the merge
  request is accepted; this copy is the one we keep tested.
- **IzzyOnDroid** takes our signed APK from the GitHub release. It caps
  a file at about 30 MB, so each release also carries
  `innerflare-vX.Y.Z-arm64-v8a.apk` (about 26 MB; the universal APK is
  about 70 MB). Same versionCode and signing key as the universal APK.

Both read the store listing from `fastlane/metadata/android/en-US/`: title,
short and full description (copied from `docs/deployment/play-store-listing.md`),
icon, screenshots, and `changelogs/<versionCode>.txt`.

## The build is verified, not assumed

`.github/workflows/fdroid-build.yml` runs `scripts/fdroid_build.sh` in
F-Droid's own `fdroidserver:buildserver-trixie` image, the same steps as the
"fdroid build" job on an fdroiddata merge request: fetch the Flutter srclib,
run the recipe, scan the source and pub cache for non-free and prebuilt
binaries, build, then `fdroid lint`. It points the recipe's first build entry
at the commit under test, so every PR that touches Android, the lockfile or
the recipe proves the next release still builds there.

First run (#34), on main at 93e6986: built
`org.healthflare.app.innerflare_6.apk`, unsigned, 70.7 MB. Checked on the
output: no `INTERNET` permission, no Play Services or Firebase classes,
`apksigner verify` says unsigned, as F-Droid expects.

What made that work:

- `flutter pub get --enforce-lockfile` with `PUB_CACHE` inside the source
  tree, so the scanner sees every package. It removes the prebuilt files it
  finds there (example apps, devtools bundles, test archives); none of them
  are part of the app.
- `dart run build_runner build` in prebuild: Riverpod's generated files
  aren't committed.
- `--android-project-arg=unsignedRelease=true` (#116): a release build
  without our key and without the debug key.
- Flutter pinned to `FLUTTER_VERSION` from `android-release.yml`, so F-Droid
  builds with the same Flutter as our release.
- `ndk: 28.2.13676358`, the NDK this Flutter version asks for.

SQLCipher comes from Maven Central as an AAR (`net.zetetic:sqlcipher-android`,
BSD-style). The scanner accepts Maven Central; reviewers may still ask, and
the answer is that its source is public and the license is free.

## Anti-features

None expected: no ads, no tracking, no network access at all (no `INTERNET`
permission in the release manifest), no non-free dependencies.

## Submitting (needs a GitLab account)

1. Cut the release that will be the first F-Droid version. It must include
   #116 (the unsigned build flag), so `v1.3.0` can't be used: the first
   candidate is the next tag.
2. In `org.healthflare.app.innerflare.yml`, set `versionName`,
   `versionCode` and `commit` (full hash of the tag's commit, never the tag
   name) and `CurrentVersion`/`CurrentVersionCode`. Add
   `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`.
3. Fork https://gitlab.com/fdroid/fdroiddata, copy the file to
   `metadata/org.healthflare.app.innerflare.yml`, run `fdroid rewritemeta
   org.healthflare.app.innerflare` and `fdroid lint org.healthflare.app.innerflare`,
   open the merge request using their "App inclusion" template. Their CI
   runs the same build as ours.
4. After that, `AutoUpdateMode: Version` + `UpdateCheckMode: Tags` means
   F-Droid picks up new `vX.Y.Z` tags itself. Nothing to do per release
   beyond the changelog file.

IzzyOnDroid: open a request at https://codeberg.org/IzzyOnDroid/repo/issues
naming the repo and the `-arm64-v8a.apk` asset. Izzy can show a
reproducible-build badge later if we make the GitHub APK reproducible; not
in scope yet.
