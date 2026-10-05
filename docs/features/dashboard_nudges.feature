Feature: Dashboard nudges
  As a user
  I want the app to gently point out useful changes to my dashboard
  without ever nagging me about them
  So that I discover value I might otherwise miss, while staying fully
  in control of what my dashboard looks like

  This is a general-purpose mechanism, not tied to any one card or
  screen — it exists in its own file so it can be reused wherever a
  "gently suggest, never nag" moment is needed, independent of whichever
  feature branch happens to be adding the next kind of nudge. The
  concrete nudges that use it today live in:
  - docs/features/dashboard_visualizations.feature ("a gauge/trend card
    becomes available", "the dashboard nudges toward cleanup")
  - docs/features/dashboard_presets.feature ("a bundle is suggested")

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Every nudge offers exactly two ways to act on it
    Given any nudge is currently shown
    When the user is presented with it
    Then it offers exactly two actions: "Dismiss" and "Snooze"
    And neither action requires more than one tap
    And ignoring the nudge entirely (doing neither) leaves it showing,
      rather than silently expiring on its own

  Scenario: Dismissing a nudge permanently retires it
    Given a nudge is shown
    When the user dismisses it permanently
    Then that specific nudge never appears again
    And no other, unrelated nudge is affected by the dismissal

  Scenario: Snoozing a cleanup nudge re-surfaces it the next time a card is added
    Given the dashboard-cleanup nudge (see dashboard_visualizations.feature,
      "the dashboard nudges toward cleanup") is shown
    When the user snoozes it
    Then the nudge disappears immediately
    And it does not reappear until the user next adds a card
    And if the card count still meets the cleanup threshold at that point,
      the nudge is shown again — otherwise it stays quiet

  Scenario: Snoozing a suggestion nudge re-surfaces after roughly two cycles
    Given a card-suggestion or bundle-suggestion nudge is shown
    And the user has an average cycle length of their own
    When the user snoozes it
    Then the nudge disappears immediately
    And it does not reappear for approximately twice their own average
      cycle length — never a fixed number of days that ignores how long
      their cycles actually run

  Scenario: Snoozing a suggestion nudge before any cycle history exists
    Given the user has no average cycle length yet
    And a card-suggestion or bundle-suggestion nudge is shown
    When the user snoozes it
    Then the snooze duration falls back to twice the standard clinical
      estimate for an average cycle — the same kind of fallback already
      used elsewhere (see docs/features/insights.feature) before there's
      enough personal history to do better

  Scenario: A nudge can be acted on without leaving the dashboard
    Given any nudge is shown
    When the user wants to act on what it suggests
    Then doing so is reachable directly from the dashboard
    Though acting on it may open Customize or the add-card catalog as
      the next step, the same way it would if the user had found that
      path on their own

  Scenario: Nudge choices are stored per-device, never synced
    Given the user has dismissed or snoozed one or more nudges
    When the app is reopened on the same device
    Then every dismissal and snooze choice from before is exactly as left
    And no network request is made to retrieve or persist any of it

  Scenario: Nudge choices don't travel with a backup, same as other
    per-device dashboard settings
    Given the user has dismissed or snoozed one or more nudges
    And the user restores a backup onto a new device
    When the restore completes
    Then every nudge starts fresh on that device, exactly as a first
      install would
    And this matches "The symptom catalog travels with the data,
      per-device settings do not" in docs/features/export.feature —
      dashboard card and quick stat preferences already work this way

  # ---------------------------------------------------------------------------
  # Showing nudges (#44)
  # ---------------------------------------------------------------------------

  Scenario: Only one nudge shows at a time
    Given more than one nudge currently applies
    When the user opens the dashboard
    Then exactly one nudge is shown, in this order of priority:
      | nudge                 |
      | cleanup               |
      | suggest a gauge card  |
      | suggest a trend card  |
    And once that one is acted on, dismissed or snoozed, the next one that
      still applies takes its place

  Scenario: A nudge sits below "Log today", never above it
    Given a nudge is shown
    Then it appears below the "Log today" card and above the card grid
    And logging today is never pushed off the first screen by a nudge

  Scenario: Every nudge has the same three buttons
    Given a nudge is shown
    Then it has one button that does what it suggests, such as "Add gauge",
      "Review" or "Remove extra"
    And a "Not now" button that snoozes it
    And a "Don't suggest this again" button that dismisses it permanently

  # Duplicates and "lots of cards" are one cleanup nudge with two
  # wordings, so dismissing it once quiets both.
  Scenario: Duplicate cards trigger the cleanup nudge on their own
    Given the user has two "Days since last period" gauge cards
    And fewer than 7 cards showing
    When the user opens the dashboard
    Then the cleanup nudge shows, naming the duplicate cards

  Scenario: Removing duplicate cards straight from the nudge
    Given the user has two "Days since last period" gauge cards
    And the cleanup nudge names them
    When the user taps "Remove extra"
    Then one of the two is removed and the other stays where it was
    And nothing else on the dashboard changes

  Scenario: A snoozed cleanup nudge comes back after the next card is added
    Given the user snoozed the cleanup nudge
    When the user adds a card
    And the dashboard still has 7 or more cards showing
    Then the cleanup nudge shows again
    And it stays snoozed across app restarts until a card is added

  # ---------------------------------------------------------------------------
  # Testing nudges by hand (debug builds only)
  # ---------------------------------------------------------------------------

  Scenario: Debug builds can reset and inspect nudges
    Given a debug build, not a screenshot build
    When the developer opens Settings
    Then a "Nudges" section lists every nudge with its current state:
      never acted on, snoozed until a date, snoozed until a card is added,
      or dismissed
    And "Reset all nudges" forgets every choice, as on a fresh install
    And "End snoozes now" makes every snoozed nudge eligible again
    And release and TestFlight builds never show this section

