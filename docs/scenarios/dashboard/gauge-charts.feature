Feature: Gauge charts for days-since and days-until metrics
  As a user who wants an at-a-glance read on timing
  I want gauge charts for "days since" and "estimated days until" metrics
  So that I can quickly understand where I am in my current cycle

  Background:
    Given I am logged in as "Jordan"
    And I have logged at least one previous cycle

  Scenario: Gauge shows days since last cycle started
    Given my last logged cycle started 10 days ago
    When I view the "days since last cycle" gauge
    Then the gauge displays "10 days"
    And the gauge's fill reflects 10 days relative to my typical cycle
      length

  Scenario: Gauge shows estimated days until next cycle
    Given my average cycle length is 28 days
    And my last cycle started 24 days ago
    When I view the "estimated days until next cycle" gauge
    Then the gauge displays an estimate of approximately 4 days
    And the gauge is labeled as an estimate, not a guarantee

  Scenario: Gauge updates automatically as days pass
    Given the "days since last cycle" gauge currently reads "10 days"
    When a new day begins without a new cycle being logged
    Then the gauge updates to read "11 days" without requiring a manual
      refresh from me

  Scenario: Gauge reflects a newly logged cycle immediately
    Given the "days since last cycle" gauge currently reads "27 days"
    When I log today as the start of a new cycle
    Then the gauge immediately updates to read "0 days"

  Scenario: Low-confidence estimate is communicated honestly
    Given I have fewer than 3 logged cycles, or my cycle lengths vary by
      more than 7 days
    When I view the "estimated days until next cycle" gauge
    Then the gauge shows a wider estimated range instead of a single
      number, or indicates that there is not yet enough data for a
      confident estimate
    And I am not shown a falsely precise single-day estimate

  Scenario: Gauge uses color zones to communicate status
    Given my average cycle length is 28 days
    When my current cycle reaches day 28 or beyond without a new cycle
      logged
    Then the "days since" gauge's color shifts to indicate the cycle has
      run longer than my average

  Scenario: Choosing which gauge is featured on the dashboard
    Given both "days since" and "estimated days until" gauges are
      available
    When I set "estimated days until next cycle" as my featured gauge
    Then that gauge appears in the primary, most prominent position on my
      dashboard

  Scenario: Gauge tooltip explains how the estimate was calculated
    When I tap or hover on the "estimated days until next cycle" gauge
    Then I see an explanation of how the estimate is derived, for example
      "based on the average of your last 6 cycles"
