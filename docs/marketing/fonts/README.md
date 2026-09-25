# Marketing fonts

Bundled locally for composed marketing images and video captions (no network
fetch, per project rules). Not declared in `pubspec.yaml`, so they are not
shipped in the app.

Copied from the Inner Flare page of the project website
(`healthflare_website/assets/fonts/`), which uses the same pairing:

| File | Role |
|------|------|
| `Fraunces-SemiBold.ttf` | headline (the site sets headlines at 700 but only bundles Medium and SemiBold, so it renders SemiBold) |
| `Fraunces-Medium.ttf` | headline, lighter option |
| `DMSans-Regular.ttf` | subhead and captions |
| `DMSans-Medium.ttf` | captions, emphasis |

Fraunces and DM Sans are published under the SIL Open Font License 1.1.
The licence text is not in the website repo, so it is not copied here; add
each family's `OFL.txt` from its upstream release next to these files if
the fonts are ever redistributed outside this repo.
