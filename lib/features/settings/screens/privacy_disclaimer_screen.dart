import 'package:flutter/material.dart';
import 'package:inner_flare/features/first_run/widgets/disclaimer_body.dart';

/// Settings → About copy of the first-run disclaimer, so someone who
/// already continued can read it again. No second acknowledgement.
class PrivacyDisclaimerScreen extends StatelessWidget {
  const PrivacyDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and disclaimer')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: DisclaimerBody(),
        ),
      ),
    );
  }
}
