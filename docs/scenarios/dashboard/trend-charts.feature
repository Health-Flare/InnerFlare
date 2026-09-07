Feature: Line and bar trend charts
  As a user tracking patterns over time
  I want line and bar charts of my cycle lengths, averages, and related
  data points
  So that I can spot trends and changes in my own history

  Background:
    Given I am logged in as "Jordan"
    And I have logged at least 6 previous cycles with varying lengths

  Scenario: Bar chart of previous cycle lengths
    When I view the "previous cycle lengths" widget as a bar chart
    Then each bar represents one past cycle, ordered chronologically
    And each bar's height corresponds to that cycle's length in days
    And the most recent cycle is clearly distinguishable as the latest

  Scenario: Line chart of cycle length trend over time
    When I switch the "previous cycle lengths" widget to a line chart
    Then the same cycles are plotted as points connected by a line in
      chronological order
    And I can see whether my cycle length is trending shorter, longer, or
      staying stable

  Scenario: Average cycle length is shown as a reference
    Given my average cycle length over the visible range is 29 days
    When I view either the bar or line chart of previous cycle lengths
    Then a reference line or annotation marks the 29-day average
    And I can see at a glance which cycles ran longer or shorter than
      average

  Scenario: Filtering the trend chart by time range
    Given I have more than 12 months of logged cycles
    When I set the chart's time range to "last 6 months"
    Then only cycles that started within the last 6 months are plotted
    And the average reference line recalculates for that filtered range

  Scenario: Chart values are available on hover or tap
    Given I am viewing the "previous cycle lengths" bar chart
    When I hover over or tap a single bar
    Then I see the exact cycle length in days and the start date of that
      cycle

  Scenario: Additional relevant data points beyond cycle length
    Given I have logged symptom severity and flow/flare intensity
      alongside my cycle dates
    When I browse the dashboard's chart options
    Then I can add charts for other tracked data points, such as symptom
      frequency by day of cycle, flare/flow intensity over time, or
      average time between symptom onset and cycle start
    And each of these charts follows the same customization rules as
      other widgets (choice of line or bar, time-range filtering, hover
      detail)

  Scenario: Accessible data table alternative to a chart
    Given I am viewing any line or bar chart on my dashboard
    When I select "view as table"
    Then the same data is presented as a sortable table
    And I can switch back to the chart view at any time

  Scenario: Charts communicate insufficient data honestly
    Given I have logged only 1 previous cycle
    When I view the "previous cycle lengths" chart
    Then it shows the single data point I have
    And it also shows a message that more cycles are needed before
      meaningful trends or averages can be shown, rather than presenting
      a misleading average from one data point
