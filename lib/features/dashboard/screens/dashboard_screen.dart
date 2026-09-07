import 'package:flutter/material.dart';

/// Placeholder dashboard shell. Card layout, customization, and the real
/// "log today" flow land with docs/features/dashboard.feature and
/// docs/features/log.feature.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InnerFlare')),
      body: const Center(child: Text('Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(Icons.add),
        label: const Text('Log today'),
      ),
    );
  }
}
