Feature: Daily logging
  As a user tracking my cycle
  I want to log a day in one screen with no required fields
  So that logging is ridiculously easy and I actually keep doing it

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Logging today with zero input confirms the day
    When the user taps the persistent "log today" entry point
    And the user confirms without selecting anything
    Then a cycle_day_logs entry is saved for today
    And the entry has no period flow, no symptoms, and no note
    And no field was required to save the entry

  Scenario: Logging period flow is a single tap
    When the user taps the "log today" entry point
    And the user taps the "medium" flow chip
    Then the entry's period_flow is set to "medium"
    And no additional screen or confirmation step was required

  Scenario: Logging symptoms uses single-tap toggle chips
    When the user taps the "log today" entry point
    And the user taps the "cramps" symptom chip
    And the user taps the "fatigue" symptom chip
    Then both symptoms are included in the entry's symptom set
    And tapping a selected chip again removes it from the set

  Scenario: Adding a free-text note is optional
    When the user taps the "log today" entry point
    And the user types a note
    And the user confirms
    Then the note is saved with the entry
    And the note field was never required to save

  Scenario: Back-logging a missed day is exactly as fast as logging today
    Given the user missed logging yesterday
    When the user opens the calendar and selects yesterday's date
    Then the same single-screen logging UI is shown as for today
    And saving requires no more steps than logging today would

  Scenario: Editing an existing day's log
    Given the user already logged today with "light" flow
    When the user reopens today's log entry
    And the user changes the flow to "heavy"
    Then the existing entry is updated, not duplicated
    And there is still only one cycle_day_logs row for today's date

  Scenario: Marking a day as the start of a period
    When the user logs a day with any non-null period flow
    Then the app determines whether this day is the period start
    Based on whether the prior day also had period flow logged
