# Android release pipeline

## Getting a build onto your phone right now

`.github/workflows/android-release.yml` builds a **debug APK** on every push
to `main`, and can also be run on demand:

1. GitHub repo → **Actions** → **Android build & release** → **Run workflow**.
2. When it finishes, open the run and download the `inner-flare-debug-apk`
   artifact.
3. Unzip it, copy `app-debug.apk` to your phone, and install it (you'll need
   to allow installs from your file manager / browser — "unknown sources").

No signing setup is needed for this path. It's for sideloading during
development, not for the Play Store.

## Signed release build (for the Play Store)

Pushing a tag matching `v*.*.*` (e.g. `v1.0.0`) builds a **signed** release
App Bundle (`.aab`, what you upload to Play Console) and a signed release
APK, and attaches both to a GitHub Release. This requires a real upload
keystore and four repo secrets — one-time setup:

### 1. Generate an upload keystore

Do this once, on your own machine, and keep the resulting file somewhere
safe outside the repo (it is **never** committed — `android/.gitignore`
already excludes `key.properties` and `*.jks`/`*.keystore`):

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for a store password, a key password, and identity
details. **Back this file up.** If you lose it, you cannot publish updates
to an app already live under this keystore — Play Console cannot re-issue
it for you.

### 2. Add repo secrets

GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New
repository secret**. Add:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` (macOS: `base64 -i upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | the store password you set above |
| `ANDROID_KEY_ALIAS` | `upload` (or whatever alias you used) |
| `ANDROID_KEY_PASSWORD` | the key password you set above |

The workflow decodes the keystore into `android/app/upload-keystore.jks` and
writes `android/key.properties` at build time, then deletes both once the
build finishes.

### 3. Cut a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the `release-bundle` job, which builds and attaches
`app-release.aab` and `app-release.apk` to a GitHub Release for that tag.
Upload the `.aab` to Play Console.

### Local release builds

To build a signed release locally instead (e.g. to test the exact bundle
before tagging), create `android/key.properties` yourself, pointing at your
keystore:

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Then `flutter build appbundle --release`. Without this file, release builds
fall back to debug signing so `flutter run --release` keeps working with no
setup.

## Play Store checklist before v1 goes live

The pipeline above gets you a signed bundle; these are the non-CI things
Play Console will ask for and aren't set up yet:

- [ ] Play Console developer account (one-time $25 registration)
- [ ] App listing: title, short/full description, icon, feature graphic,
      phone screenshots
- [ ] Privacy policy URL — required, and non-negotiable for an app that
      logs health data even though it's fully offline/on-device
- [ ] Data safety form — declare what's collected (should be "no data
      collected/shared" given the offline-only design, but Play still
      requires the form)
- [ ] Content rating questionnaire
- [ ] Target audience / ads declaration
- [x] Confirm `applicationId` in `android/app/build.gradle.kts` is the one
      you want permanently, since it cannot be changed after the first
      Play Store upload — set to `org.healthflare.app.innerflare`,
      matching the app already created in Play Console
- [ ] Decide on Play App Signing (Google-managed) vs. self-managed signing
      when you first upload the bundle
