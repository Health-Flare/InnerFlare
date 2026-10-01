import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a cited source in the system browser.
///
/// Same pattern as the privacy policy: a user tap hands the address to the
/// OS. No in-app web view, no internet permission.
Future<void> openSourceLink(Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw StateError('The system browser did not open $uri.');
  }
}

/// Overridable in tests so a tap does not need a platform browser.
final sourceLinkOpenerProvider = Provider<Future<void> Function(Uri)>(
  (ref) => openSourceLink,
);
