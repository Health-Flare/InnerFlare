import 'dart:math';

/// Quotes shown on the loading screen (see docs/features/loading.feature).
/// Reinforces the app's offline, private philosophy on every launch.
const List<String> loadingQuotes = [
  'No cloud. No accounts. Just you.',
  'Your body keeps better records than you think.',
  'Tracking you, not tracked by anyone.',
];

/// Picks one of [quotes] at random using [random]. [random] is injected
/// (rather than created here) so the choice stays deterministic in tests.
String pickLoadingQuote(List<String> quotes, Random random) {
  return quotes[random.nextInt(quotes.length)];
}
