# InnerFlare

See `CLAUDE.md` for architecture and conventions, `BRIEF.md` for the product
brief, and `docs/deployment/android-release.md` for the Android build/release
pipeline.

## Setup

```bash
flutter pub get
./scripts/setup_git_hooks.sh   # one-time: installs pre-commit/pre-push checks
```

## CI/CD

- **CI** (`.github/workflows/ci.yml`): format check, `flutter analyze`,
  offline-URL scan, and `flutter test` on every push to `main` and every PR.
- **Android build & release** (`.github/workflows/android-release.yml`):
  builds a debug APK you can sideload on every push to `main` or on demand;
  pushing a `v*.*.*` tag builds a signed release bundle and attaches it to a
  GitHub Release. See `docs/deployment/android-release.md`.
