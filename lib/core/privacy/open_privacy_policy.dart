import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/privacy/privacy_policy_url.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [privacyPolicyUrl] in the system browser.
///
/// A user tap hands the address to the OS. There is no in-app web view
/// and no internet permission. [LaunchMode.externalApplication] keeps
/// the request out of the app process.
Future<void> openPrivacyPolicy() async {
  final opened = await launchUrl(
    Uri.parse(privacyPolicyUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!opened) {
    throw StateError('The system browser did not open the privacy policy.');
  }
}

/// Overridable in tests so a tap does not need a platform browser.
final privacyPolicyOpenerProvider = Provider<Future<void> Function()>(
  (ref) => openPrivacyPolicy,
);
