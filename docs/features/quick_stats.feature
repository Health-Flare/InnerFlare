Feature: Dashboard quick stats
  As a user
  I want two at-a-glance numbers about where I am in my cycle
  So that I don't have to open Insights just to see the basics

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Quick stats sit between the "log today" area and the data cards
    Given the dashboard is showing its default layout
    Then two quick stat data points appear below the "log today" hero card
      and the "Log a previous day" link
    And they appear above the "Your data, at a glance" heading

  Scenario: Default first quick stat is days since last period, measured from its end
    Given the user has logged a period that started and later stopped
    When the user views the dashboard
    Then the first quick stat shows the count of days since the last logged
      day of period flow
    And the label makes clear it is measured from the end of the last period

  Scenario: Default second quick stat is estimated days to next period
    Given the user's average cycle length is 28 days
    And the user's last logged period start was 10 days ago
    When the user views the dashboard
    Then the second quick stat shows 18 as the estimated days to the next period
    And the label makes clear this is an estimate

  Scenario: Days-since-last-period can be reconfigured to count from the start instead
    Given the first quick stat is "days since last period"
    When the user opens quick stat customization
    And changes its reference point from "end of last period" to "start of last period"
    Then the first quick stat recalculates using the last logged period start date
    And the choice is saved so it persists after restarting the app

  Scenario: A period still being logged counts as ongoing, not yet ended
    Given the user logged period flow for today and every day since the last period start
    When the user views a quick stat configured to measure from the end of the last period
    Then the days-since count is 0
    And it keeps resetting to 0 as each additional day of flow is logged, until
      a day passes with no flow logged

  Scenario: Quick stats are individually customizable, not just show or hide
    Given the user is viewing quick stat customization
    Then each of the two slots can be set to any of the available stat types
      independently
    And the two slots are not required to show two different stat types

  Scenario: No period ever logged shows an honest empty state, not a fabricated number
    Given the user has never logged a period start
    When the user views the dashboard
    Then both quick stats show "not enough data yet" instead of a number
    And no fabricated day count is shown

  Scenario: Estimated days to next period needs at least one complete cycle
    Given the user has logged exactly one period start and no prior cycle
    When the user views the dashboard
    Then "estimated days to next period" shows "not enough data yet"
    And "days since last period" still shows a real value, since it doesn't
      depend on an average

  Scenario: An overdue period is shown honestly, not as a negative day count
    Given the user's average cycle length is 28 days
    And the user's last logged period start was 31 days ago
    And no new period has been logged since
    When the user views the dashboard
    Then "estimated days to next period" indicates the period is overdue
    And it does not silently display "-3" with no explanation

  Scenario: Quick stats recompute live from the same data as Insights
    Given the user edits a past period start date
    When the user returns to the dashboard
    Then both quick stats reflect the edited date immediately
    And the calculation reuses the same cycle-math functions as
      docs/features/insights.feature, not a separate implementation

  Scenario: Quick stat preferences are stored per-device, not synced
    Given the user has customized which stat types are shown and their
      reference points
    When the app is reopened
    Then the same customized quick stats are shown
    And no network request was made to retrieve or persist the preference
