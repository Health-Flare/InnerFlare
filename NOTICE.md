# Third-party notices

InnerFlare is licensed under the GNU General Public License v3.0 or later
(see `LICENSE`). It's built on the Flutter/Dart SDK and a number of
third-party packages, each under its own license. This file lists what's
bundled in a release build and the license each is under.

This list is maintained by hand and may lag a `pubspec.yaml` change. The
authoritative, always-current source is the **"Open source licenses"**
entry in the app's Settings screen: Flutter collects the actual `LICENSE`
file bundled with every package (direct and transitive) at build time and
renders it there via `showLicensePage`. If this file and the in-app page
ever disagree, trust the in-app page and update this file to match.

## Flutter & Dart SDK

Copyright 2014 The Flutter Authors / the Dart project authors.
BSD 3-Clause "New" or "Revised" License.
<https://github.com/flutter/flutter/blob/master/LICENSE>

## Direct dependencies

| Package | License | Notes |
|---|---|---|
| `cupertino_icons` | BSD-3-Clause | Flutter team |
| `flutter_riverpod`, `riverpod`, `riverpod_annotation` | MIT | Rémi Rousselet |
| `go_router` | BSD-3-Clause | Flutter team (flutter/packages) |
| `path`, `path_provider` | BSD-3-Clause | Dart/Flutter teams |
| `share_plus` | BSD-3-Clause | fluttercommunity/plus_plugins |
| `file_picker` | MIT | Miguel Ruivo |
| `flutter_local_notifications` | BSD-3-Clause | MaikuB |
| `sqflite_sqlcipher` | MIT | davidmartos96 (SQLCipher-backed fork of `sqflite`) |
| `sqflite_common` | MIT | Tekartik |
| `flutter_secure_storage` | BSD-3-Clause | mogol |
| `local_auth` | BSD-3-Clause | Flutter team (flutter/packages) |

All of the above are permissive (MIT/BSD) and compatible with distributing
this GPLv3 application. Dev-only tooling (`build_runner`, `riverpod_generator`,
`flutter_lints`, `sqflite_common_ffi`, `flutter_launcher_icons`, and similar)
isn't compiled into the shipped app and isn't listed here; see
`pubspec.yaml` → `dev_dependencies` if you need it.

## SQLCipher

`sqflite_sqlcipher` links against **SQLCipher** (the encrypted SQLite
extension actually used to encrypt the on-device database — see
"Encrypted, biometric-gated storage" in `CLAUDE.md`), which ships its own
license separate from the Dart plugin wrapping it:

> Copyright (c) 2008-2023, ZETETIC LLC
> All rights reserved.
>
> Redistribution and use in source and binary forms, with or without
> modification, are permitted provided that the following conditions are met:
>
> * Redistributions of source code must retain the above copyright notice,
>   this list of conditions and the following disclaimer.
> * Redistributions in binary form must reproduce the above copyright
>   notice, this list of conditions and the following disclaimer in the
>   documentation and/or other materials provided with the distribution.
> * Neither the name of the ZETETIC LLC nor the names of its contributors
>   may be used to endorse or promote products derived from this software
>   without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY ZETETIC LLC ''AS IS'' AND ANY EXPRESS OR
> IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
> OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
> IN NO EVENT SHALL ZETETIC LLC BE LIABLE FOR ANY DIRECT, INDIRECT,
> INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
> NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
> DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
> THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
> (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
> THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

> **Maintenance note:** this text was reproduced from memory of the
> published SQLCipher BSD license (a short, widely-quoted, long-stable
> license) because this environment's network policy blocked a live fetch
> from zetetic.net/sqlcipher/license/ to diff against at the time this file
> was written. Before a public release, verify it word-for-word against
> <https://www.zetetic.net/sqlcipher/license/> and correct anything that
> doesn't match exactly — this is a legal document, verbatim accuracy
> matters more than usual here.

## Regenerating this file

To double-check or extend this list against the actual lockfile:

```bash
flutter pub deps --style=compact
```

then cross-reference each package's license on <https://pub.dev> (each
package page links its `LICENSE` file). For a definitive, non-hand-maintained
list of everything actually bundled in a build, use the in-app "Open source
licenses" page described above.
