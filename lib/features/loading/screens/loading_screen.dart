import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/features/loading/loading_quotes.dart';

/// Splash screen shown while local data is read on launch, with a random
/// quote reinforcing the app's offline, private philosophy.
/// See docs/features/loading.feature.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    this.random,
    this.readyFuture,
    this.minDisplayDuration = const Duration(milliseconds: 1400),
    this.nextScreenBuilder = _defaultNextScreen,
  });

  /// Injected so quote selection is deterministic in tests.
  final Random? random;

  /// Resolves once local data has finished loading. Defaults to an
  /// already-completed future — there is no local data to await yet.
  final Future<void>? readyFuture;

  /// Floor on how long the quote stays on screen, so it's readable even
  /// when local data loads instantly. Loading waits for whichever of this
  /// or [readyFuture] takes longer.
  final Duration minDisplayDuration;

  /// Builds the screen to show once loading completes: onboarding or the
  /// dashboard, per docs/features/loading.feature.
  final WidgetBuilder nextScreenBuilder;

  static Widget _defaultNextScreen(BuildContext context) =>
      const DashboardScreen();

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = pickLoadingQuote(loadingQuotes, widget.random ?? Random());
    final ready = widget.readyFuture ?? Future.value();
    final gated = widget.minDisplayDuration > Duration.zero
        ? Future.wait([ready, Future.delayed(widget.minDisplayDuration)])
        : ready;
    gated.then((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: widget.nextScreenBuilder));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Deep, desaturated teal — complementary to the logo's warm
            // orange/cream so the mark reads clearly, while staying calm
            // and private rather than clinical.
            colors: [Color(0xFF17272C), Color(0xFF0B1416)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/Inner Flare Logo.png',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _quote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFEFE3D3),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
