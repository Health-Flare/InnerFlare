Feature: Dashboard ownership and personalization
  As a user tracking my own health data
  I want the dashboard to clearly be mine and to reshape it to how I think
  So that I trust the data, understand it belongs to me, and can read it
  the way that makes sense to me

  Background:
    Given I am logged in as "Jordan"
    And I have at least one tracked cycle with logged entries

  Scenario: Dashboard is clearly labeled as belonging to me
    When I open the dashboard
    Then I see a heading that identifies it as my own space, such as
      "Jordan's Dashboard" or "My Dashboard"
    And I do not see any data, defaults, or examples attributed to another
      person or a generic sample account

  Scenario: First-time user is told the dashboard is theirs to shape
    Given I have just created my account and logged my first entry
    When I open the dashboard for the first time
    Then I see an introductory message explaining that this dashboard is
      mine and that every widget can be rearranged, resized, hidden, or
      swapped for a different visualization
    And I am not shown this introductory message again on later visits
      unless I ask to see it again from settings

  Scenario: Reordering dashboard widgets
    Given my dashboard shows the calendar, a gauge, and a trend chart
    When I drag the trend chart above the calendar
    Then the trend chart is displayed above the calendar
    And the new order persists the next time I log in on this or another
      device

  Scenario: Hiding and re-showing a widget
    Given my dashboard includes an "average cycle length" widget
    When I hide the "average cycle length" widget
    Then it no longer appears on my dashboard
    And I can find it in an "add widget" list and re-add it at any time
    And re-adding it restores its previous settings if I hid it within
      the last 30 days

  Scenario: Choosing a different chart type for the same data
    Given I am viewing "previous cycle lengths" as a bar chart
    When I switch its display type to a line chart
    Then the same underlying cycle-length data is rendered as a line chart
    And my choice is remembered for this widget going forward

  Scenario: Choosing which metric a gauge highlights
    Given I have a gauge widget currently showing "days since last cycle
      started"
    When I change its setting to "estimated days until next cycle"
    Then the gauge redraws to show the estimated-days-until value
    And the widget's title updates to match what it is now showing

  Scenario: Personalization preferences sync across devices
    Given I reordered and re-themed my dashboard on my phone
    When I log in on my laptop
    Then my laptop dashboard shows the same widget order, visibility, and
      chart-type choices I set on my phone

  Scenario: Resetting the dashboard to its default layout
    Given I have heavily customized my dashboard's layout and widget
      choices
    When I choose "Reset dashboard to default" from settings
    Then I am asked to confirm the reset before anything changes
    And after confirming, my dashboard returns to the default widget set
      and order
    And my underlying tracked data is unaffected by the reset

  Scenario: Data ownership is reinforced in empty states
    Given I have not logged any entries yet
    When I open the dashboard
    Then every widget shows an empty state explaining what it will show
      once I log data, phrased in terms of "your" data (for example, "Log
      your first entry to see your cycle trends")
    And no widget shows another user's or a placeholder demo account's
      data as if it were mine

  Scenario: Exporting my data reinforces that it is mine to take with me
    Given I have several months of tracked entries
    When I choose "Export my data" from the dashboard settings
    Then I can download my entries in a portable format (for example CSV
      or JSON)
    And the export includes only my own data
