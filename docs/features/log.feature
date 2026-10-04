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

  # Period starts are worked out from the whole log every time they are
  # read, never stored at save time, so editing or back-logging a day
  # always updates its neighbours too. Rule (issue #101): cycle day 1 is
  # the first day of light, medium or heavy flow. Spotting can continue a
  # period but never starts one. One day without flow inside a period
  # does not split it; two or more days without flow do.
  Scenario: Marking a day as the start of a period
    Given no flow is logged on the 2 days before
    When the user logs a day with "light", "medium" or "heavy" flow
    Then that day is the period start

  Scenario: The order days are saved in does not change the cycles
    Given the same period days are logged in any order
    Then the app finds the same period starts every time

  Scenario: Back-logging the day before a period moves its start
    Given the user logged "medium" flow on March 2
    When the user back-logs "light" flow on March 1
    Then March 1 is the period start
    And March 2 is not a period start

  Scenario: Clearing flow on the first day moves the start to the next day
    Given the user logged flow on March 1 and March 2
    When the user changes March 1 to no flow
    Then March 2 is the period start

  Scenario: Clearing every day of a period removes it
    Given the user logged flow on March 1 and March 2 only
    When the user changes both days to no flow
    Then there is no period start in March

  Scenario: Spotting alone does not start a period
    Given the user logs only spotting on a day between periods
    Then no new period starts
    And the spotting still shows on the calendar

  Scenario: Spotting before a period is part of it, but day 1 is the first day of real flow
    Given the user logged spotting on March 1 and "medium" flow on March 2
    Then March 2 is the period start

  Scenario: One unlogged day inside a period does not split it
    Given the user logged flow on March 1 and 2, nothing on March 3, and flow on March 4
    Then March 1 is the only period start

  Scenario: Two days without flow end a period
    Given the user logged flow on March 1, nothing on March 2 and 3, and flow on March 4
    Then March 1 and March 4 are both period starts
