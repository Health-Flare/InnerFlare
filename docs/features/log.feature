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

  # The user decides (issue #103). The rule above is only the default for
  # a day the user hasn't marked. "Period day" on the log screen overrides
  # it for that one day, whatever flow is logged, and never changes the
  # flow, symptoms or note.
  Scenario: The Period day switch shows what the app worked out
    Given the user logged "medium" flow on March 1
    When the user opens March 1
    Then "Period day" is on
    And it says "Worked out from your flow. Change it if you know better."

  Scenario: Spotting the user marks as a period day starts a period
    Given the user logged spotting on March 1 and "medium" flow on March 2
    When the user turns "Period day" on for March 1
    Then March 1 is the period start
    And March 1 still shows spotting on the calendar

  Scenario: A day with no flow can be marked as a period day
    Given nothing is logged on the 2 days before March 1
    When the user opens March 1 and turns "Period day" on without choosing a flow
    Then March 1 is the period start

  Scenario: Bleeding the user marks as not a period is left out of cycles
    Given the user logged "heavy" flow on March 10 and 11
    When the user turns "Period day" off for March 10 and 11
    Then no period starts on March 10
    And cycle lengths, predictions and "days since last period" ignore March 10 and 11
    And the heavy flow is kept and still shows on the calendar, marked "not counted as a period"

  Scenario: Marking the first day as not a period moves the start
    Given the user logged "medium" flow on March 1, 2 and 3
    When the user turns "Period day" off for March 1
    Then March 2 is the period start

  Scenario: Switching back to what the app would work out clears the choice
    Given the user turned "Period day" on for a day with no flow
    When the user turns it off again
    Then no choice is stored for that day

  Scenario: Going back to working it out from flow
    Given the user turned "Period day" on for a spotting day
    When the user taps "Work it out from flow"
    Then no choice is stored for that day
    And the spotting day counts the same way as any other spotting day

  Scenario: Spotting the user marks as not a period is left out of the period
    Given the user logged "medium" flow on March 1 and 2 and spotting on March 3
    When the user turns "Period day" off for March 3
    Then the period ends on March 2

  Scenario: A changed flow that matches the user's choice clears it
    Given the user turned "Period day" on for a day with no flow
    When the user logs "light" flow on that day
    Then no choice is stored for that day
    And it is still a period day

  Scenario: The user's choice is kept in backups
    Given the user marked March 1 as a period day and March 10 as not a period day
    When the user exports a backup and imports it on another device
    Then both choices are restored

  Scenario: Merging a backup keeps the choice already on this device
    Given March 1 is marked as not a period day on this device
    And the imported backup marks March 1 as a period day
    When the user merges the backup
    Then March 1 is still marked as not a period day
