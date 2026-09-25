import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/privacy/privacy_policy_url.dart';

void main() {
  test('points at the published privacy policy', () {
    expect(privacyPolicyUrl, 'https://healthflare.org/inner-flare/privacy');
  });
}
