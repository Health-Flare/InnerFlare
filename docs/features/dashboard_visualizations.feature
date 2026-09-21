Feature: Dashboard visualization cards
  As a user
  I want gauge and trend-chart cards for my own cycle data
  So that I can read it at a glance, in whichever visual form makes sense
  to me, without any of it leaving my device

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: A gauge card can show days since the last period started
    Given the user's last logged period start was 10 days ago
    When the user adds a gauge card set to "days since last period"
    Then the gauge displays "10 days"
    And the gauge fills relative to the user's own average cycle length,
      not a fixed or generic scale

  Scenario: A gauge card can show estimated days until the next period
    Given the user's average cycle length is 28 days
    And the user's last logged period start was 24 days ago
    When the user adds a gauge card set to "estimated days until next
      period"
    Then the gauge displays an estimate of approximately 4 days
    And the estimate is labeled as an estimate, consistent with
      docs/features/insights.feature

  Scenario: Switching a gauge card between its two supported modes
    Given a gauge card is currently set to "days since last period"
    When the user switches the card to "estimated days until next period"
    Then the gauge redraws using the estimated-days-until value
    And the card's title updates to match what it now shows
    And the choice is saved per-device, the same way other dashboard
      preferences are saved

  Scenario: Gauge shows a range instead of false precision when data is thin
    Given the user has fewer than 2 complete cycles logged, or the last 3
      cycle lengths vary by more than 7 days
    When the user views a gauge card set to "estimated days until next
      period"
    Then the gauge shows a range or a "not enough data yet" state instead
      of a single fabricated number
    And this matches the honesty rules already defined in
      docs/features/insights.feature

  Scenario: A trend card displays previous cycle lengths as a bar chart
    Given the user has logged at least 2 complete cycles
    When the user adds a trend card set to "previous cycle lengths"
    Then each bar represents one complete cycle length in chronological
      order
    And the most recent cycle is visually distinguishable as the latest

  Scenario: A trend card can be switched from bar to line
    Given a trend card is showing "previous cycle lengths" as a bar chart
    When the user switches the card's chart type to line
    Then the same cycle lengths are plotted as connected points in the
      same chronological order
    And the choice of chart type is saved per-device for that card

  Scenario: Average cycle length appears as a reference on the trend chart
    Given the user's average cycle length over the visible history is 29
      days, as computed in docs/features/insights.feature
    When the user views the "previous cycle lengths" trend card, in
      either bar or line form
    Then a reference line or annotation marks the 29-day average
    And cycles above or below that average are distinguishable at a
      glance

  Scenario: Trend chart never fabricates a trend from insufficient history
    Given the user has fewer than 2 complete cycles logged
    When the user views the "previous cycle lengths" trend card
    Then the chart shows only the data points that exist
    And it states that more cycles are needed before an average or trend
      line can be shown, rather than drawing one from too little data

  Scenario: Additional data points can be added as their own cards
    Given the user has logged symptoms and period flow alongside period
      starts
    When the user browses the "add card" list
    Then cards for other tracked data points are available, such as
      symptom frequency by day of cycle, flow intensity over time, and
      cycle length variability
    And each of these cards supports the same chart-type switching as the
      "previous cycle lengths" card where more than one presentation
      makes sense

  Scenario: Chart-type and gauge-mode preferences are per-device, not synced
    Given the user has chosen a line chart for "previous cycle lengths"
      and set a gauge card to "estimated days until next period"
    When the app is reopened
    Then both choices are restored exactly as set
    And no network request was made to retrieve or persist either choice

  Scenario: Gauge and trend cards start hidden until the app suggests them
    Given the user has never added a gauge or trend card
    And the user has logged enough cycle history that at least one gauge
      or trend card would show real data, not an immediate "not enough
      data yet" state
    When the user opens the dashboard
    Then a nudge (docs/features/dashboard_nudges.feature) suggests
      adding that specific card
    And the card itself stays off the dashboard until the user acts on
      the suggestion or adds it manually through "Add a card"

    # The exact data threshold for "enough to suggest" is still open:
    # candidates include reusing the same bar the gauge/trend cards
    # already use for their own thin-history warning, or a lower one
    # (e.g. a single logged period is enough to suggest a gauge, even
    # before it can show a precise number). Flagging rather than
    # guessing until this is settled.

  Scenario: The dashboard nudges toward cleanup once there are 6 or more cards
    Given the user has 6 or more cards on the dashboard, whether default
      or added
    When the user opens the dashboard
    Then a cleanup nudge appears (docs/features/dashboard_nudges.feature)
    And it suggests reviewing the dashboard in general terms

  Scenario: A cleanup nudge calls out duplicate cards by name
    Given two or more of the user's cards are the same kind, configured
      with the same mode or metric
    When the cleanup nudge (docs/features/dashboard_nudges.feature)
      appears
    Then it names the duplicate cards specifically, rather than speaking
      generally about the whole dashboard
    And it offers removing the extras directly, without a general
      dashboard review

  Scenario: A trend card becomes tappable once it has real history to summarize
    Given a "previous cycle lengths" or "cycle length variability" trend
      card has at least 2 complete cycles logged
    When the user taps the card
    Then it opens a cycle-by-cycle detail table

  Scenario: A trend card without enough history isn't tappable
    Given a trend card has fewer than 2 complete cycles logged
    When the user views the card
    Then it shows the same "not enough cycles logged yet" message as
      before
    And tapping it does nothing: there's nothing yet to summarize

  Scenario: The cycle detail table lists every complete cycle and the gap since the one before it
    Given the user has logged at least 2 complete cycles
    When the user opens the cycle detail table from either the "previous
      cycle lengths" or the "cycle length variability" trend card
    Then each row shows one complete cycle: the date it started, its
      length in days, and how many days it differs from the cycle
      immediately before it
    And rows are ordered most-recent-first, since this table exists to
      be reviewed quickly (e.g. ahead of or during a conversation with
      a healthcare provider), unlike the trend chart itself, which stays
      chronological (oldest-first) to read naturally left to right

  Scenario: Both trend cards open the exact same cycle detail table
    Given the user has added both the "previous cycle lengths" and
      "cycle length variability" trend cards
    When the user taps either one
    Then both open the identical cycle detail table
    And the table's content never depends on which card was tapped

  Scenario: The cycle detail table makes no diagnostic claim
    Given the user opens the cycle detail table
    Then it presents only what was logged, with no interpretation,
      diagnosis, or recommendation attached
    And this matches the app's existing "not a medical device, no
      diagnostic claims" stance stated in onboarding

  Scenario: A gauge card opens Insights once it has real data behind it
    Given a gauge card is not showing a thin-history approximation
    When the user taps the card
    Then it opens Insights (docs/features/insights.feature), the
      existing screen for real cycle history and predictions

    # Unlike the trend cards' cycle detail table, no dedicated gauge
    # detail screen has been designed yet: routing to the existing
    # Insights screen is a reasonable default for now, not a settled
    # product decision. Revisit if a more specific destination turns
    # out to be worth building.
