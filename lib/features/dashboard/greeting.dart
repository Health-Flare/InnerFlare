/// Pure, hour-based greeting so the dashboard header can be tested
/// deterministically instead of depending on [DateTime.now] internally.
String greetingForHour(int hour) {
  if (hour < 5) return 'Still up?';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  if (hour < 21) return 'Good evening';
  return 'Winding down?';
}
