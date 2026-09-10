# iOS release pipeline

Mirrors `docs/deployment/android-release.md`. The workflow lives at
`.github/workflows/ios-release.yml`.

## Getting a build onto a simulator right now

`ios-release.yml` builds an **unsigned iOS Simulator build** on every manual
run, no signing setup required:

1. GitHub repo → **Actions** → **iOS build & release** → **Run workflow**.
2. When it finishes, download the `inner-flare-simulator-build` artifact —
   a `.app` bundle you can drag onto a booted simulator, or install with
   `xcrun simctl install <device> Runner.app`.

This exists purely to keep the iOS build green in CI without needing any
Apple credentials. It does not install on a physical device — iOS requires
every build to be signed by a provisioning profile to run on real hardware,
even for local testing, unlike Android's unsigned debug APKs.

## Signed release build (for TestFlight / the App Store)

Pushing a tag matching `v*.*.*` builds a **signed** `.ipa` and uploads it to
App Store Connect. This requires a real Apple Developer Program enrollment
and several repo secrets — one-time setup:

### 1. Apple Developer Program + App Store Connect setup

Do this once, in your Apple Developer / App Store Connect account:

1. Enroll in the Apple Developer Program ($99/yr) if not already enrolled.
2. Register the bundle ID `org.healthflare.app.innerflare` under **Certificates,
   Identifiers & Profiles** (it must match `PRODUCT_BUNDLE_IDENTIFIER` in
   `ios/Runner.xcodeproj/project.pbxproj` exactly).
3. Create the app record in **App Store Connect** using that bundle ID.
4. Create a **Distribution** certificate and download the `.p12` (you'll
   set a password on export — that's `APPLE_CERTIFICATE_PASSWORD` below).
5. Create an **App Store** provisioning profile for that bundle ID and
   download the `.mobileprovision` file.
6. Create an **App Store Connect API key** (Users and Access → Integrations
   → App Store Connect API) with the **App Manager** role — this lets CI
   upload builds without storing an Apple ID password or handling 2FA.
   Download the `.p8` key file; note the Key ID and Issuer ID shown next to
   it (the `.p8` can only be downloaded once).

### 2. Add repo secrets

GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New
repository secret**. Add:

| Secret | Value |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | `base64 -i DistributionCert.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | the password you set exporting the `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | `base64 -i InnerFlare_AppStore.mobileprovision` |
| `APPLE_PROVISIONING_PROFILE_NAME` | the profile's **name** (not its UUID/filename) exactly as shown in the Developer portal — the export step maps `org.healthflare.app.innerflare` to this name |
| `APPLE_TEAM_ID` | your 10-character Apple Developer Team ID (Xcode → Signing & Capabilities → Team, or developer.appleid.apple.com under Membership — same value that goes in `ios/Flutter/Local.xcconfig` for local builds) |
| `APP_STORE_CONNECT_KEY_ID` | the Key ID shown next to the API key |
| `APP_STORE_CONNECT_ISSUER_ID` | the Issuer ID shown on the same page |
| `APP_STORE_CONNECT_API_KEY_BASE64` | `base64 -i AuthKey_XXXXXXXXXX.p8` |

The workflow decodes the certificate and profile into a temporary keychain
and `~/Library/MobileDevice/Provisioning Profiles/`, writes an
`ExportOptions.plist` from `APPLE_TEAM_ID`/`APPLE_PROVISIONING_PROFILE_NAME`
(there's no static `ExportOptions.plist` committed to the repo — CI
generates it per run so the real Team ID never has to live in source),
builds and signs the archive, exports an `.ipa`, uploads it to App Store
Connect via `xcrun altool` using the API key (no Apple ID/2FA involved),
then deletes the temporary keychain.

### 3. Cut a release

Same tag as Android:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the `release-ipa` job in `ios-release.yml`, which builds,
signs, and uploads the build to App Store Connect. It'll show up in App
Store Connect under TestFlight processing within a few minutes; from there
it's either distributed as a TestFlight build or submitted for App Store
review, both manual steps in App Store Connect's UI (Apple doesn't offer
an unauthenticated API for submitting for review).

### Local signed builds

To build and test a signed archive locally instead of waiting on CI, open
`ios/Runner.xcworkspace` in Xcode, select a signing team under Runner →
Signing & Capabilities, and use Product → Archive.

## App Store checklist before v1 goes live

The pipeline above gets a build into App Store Connect; these are the
non-CI things Apple will ask for and aren't set up yet:

- [ ] Apple Developer Program enrollment
- [ ] App Store Connect app record, using bundle ID `org.healthflare.app.innerflare`
- [ ] App listing: name, subtitle, promotional text, description, keywords,
      support URL, marketing URL (optional), icon (already in
      `ios/Runner/Assets.xcassets/AppIcon.appiconset`), screenshots (already
      captured in `screenshots/app_store/iphone_17_pro/` and
      `screenshots/app_store/ipad_pro_13/` — confirm these cover every
      device-size bucket App Store Connect currently requires; Apple's
      required screenshot sizes change occasionally)
- [ ] Privacy policy URL — same one used for Play
- [ ] App Privacy ("nutrition label") questionnaire in App Store Connect —
      expect "Data Not Collected" for every category given the fully
      offline design, but each category still needs an explicit answer
- [x] Export compliance: the app uses encryption (SQLCipher, see
      "Encrypted, biometric-gated storage" in `CLAUDE.md`). `Info.plist`
      now declares `ITSAppUsesNonExemptEncryption = false`, so App Store
      Connect won't ask this on every upload. `false` is correct here
      because on-device storage encryption with no custom cryptography
      beyond what SQLCipher/the OS provide typically qualifies for the
      standard exemption — re-confirm against Apple's current export
      compliance guidance before the first real submission, since the
      exact exemption categories do shift.
- [ ] Age rating questionnaire
- [ ] At least one TestFlight internal build, tested on a real device
- [ ] Not-a-medical-device / no-diagnostic-claims language visible
      somewhere in the listing or in-app (already a stated design
      principle in `CLAUDE.md` — just needs to survive into the App Store
      copy too, since Apple scrutinizes health-app claims during review)
- [ ] First submission for review (subsequent versions can often use
      automatic release after approval; decide that per-release)
