# Dashboard Scenarios

Gherkin-style acceptance scenarios for the InnerFlare personal dashboard.
These are written ahead of implementation to define expected behavior;
they can be wired up to a BDD runner (Cucumber, Behave, etc.) later or
used directly as a manual QA checklist.

- `ownership-and-personalization.feature` — the dashboard is always
  presented as the user's own, and every view of the data can be
  reconfigured by the user.
- `calendar-display.feature` — the calendar view of cycle/flare history
  and predictions.
- `gauge-charts.feature` — "days since" / "estimated days until" gauges.
- `trend-charts.feature` — line and bar charts for cycle length history,
  averages, and other longitudinal data points.

## Shared vocabulary

- **Cycle** — one full tracked cycle, from its logged start date to the
  day before the next logged start date.
- **Entry** — a single day's logged data (symptoms, flow/flare
  intensity, notes, etc.).
- **Widget** — one self-contained card on the dashboard (a gauge, a
  chart, the calendar, a stat tile).
