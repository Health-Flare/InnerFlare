Feature: Cycle insights and predictions
  As a user
  I want transparent, on-device statistics about my cycle
  So that I can see predictions and understand exactly what they're based on

  Background:
    Given the user has completed onboarding

  Scenario: No prediction is shown with no cycle history
    Given the user has never logged a period start
    When the user views insights
    Then the app shows "not enough data yet" instead of a prediction
    And no fabricated estimate is shown

  Scenario: First-ever cycle has no prior-cycle average to draw on
    Given the user has logged exactly one period start and no prior cycle
    When the user views insights
    Then average cycle length is not shown
    And the app explains that a second cycle is needed to estimate cycle length

  Scenario: Average cycle length is computed from the last N cycles
    Given the user has logged period start dates for at least 2 complete cycles
    When the user views insights
    Then the average cycle length is the mean of the last N complete cycle lengths
    And N matches the cycle history window set in settings

  Scenario: Cycle length variability is shown alongside the average
    Given the user has logged period start dates for at least 3 complete cycles
    When the user views insights
    Then a variability measure (e.g. standard deviation or min-max range) is shown next to the average
    And the app does not present the average alone as if cycles were perfectly regular

  Scenario: Predicted next period uses average cycle length from the last logged start
    Given the user's average cycle length is 28 days
    And the user's last logged period start was 14 days ago
    When the user views insights
    Then the predicted next period start is 14 days from today
    And the prediction is labeled as an estimate

  Scenario: Predicted fertile window uses the standard luteal phase length assumption
    Given the user's predicted next period start is known
    And the luteal phase length assumption is set in settings
    When the user views insights
    Then the predicted fertile window is computed by subtracting the luteal phase length from the predicted next period start
    And the fertile window is labeled as an estimate

  Scenario: Irregular cycles still produce an average, clearly caveated
    Given the user's last 3 cycle lengths vary by more than 7 days from each other
    When the user views insights
    Then an average and variability are still shown
    And the app indicates the cycles are irregular rather than presenting false precision

  Scenario: Gaps in logging do not silently corrupt cycle length calculation
    Given the user logged a period start, then logged nothing for 10 days, then logged a new period start
    When the user views insights
    Then the gap is treated as a single cycle length equal to the days between the two period starts
    And no days are fabricated to fill the gap

  Scenario Outline: Cycle math handles date and timezone edge cases
    Given a period start on "<start_date>" and the next period start on "<next_start_date>"
    When cycle length is computed
    Then the result is <expected_days> days
    And the result is unaffected by daylight saving time transitions

    Examples:
      | start_date | next_start_date | expected_days |
      | 2026-03-01 | 2026-03-29       | 28             |
      | 2026-03-08 | 2026-04-05       | 28             |
      | 2026-11-01 | 2026-11-29       | 28             |

  Scenario: Insights recompute live, nothing is stored redundantly
    Given the user edits a past period start date
    When the user returns to insights
    Then the average, variability, and predictions reflect the edited date immediately
    And no separate cached "insights" row needed to be manually updated
