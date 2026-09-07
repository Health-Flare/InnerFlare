Feature: Calendar display widget
  As a user reviewing my history
  I want a calendar view of my logged and predicted cycle days
  So that I can see patterns over time in a familiar layout

  Background:
    Given I am logged in as "Jordan"
    And I have logged entries spanning at least 3 previous cycles

  Scenario: Calendar shows logged cycle days
    When I open the calendar widget
    Then days I logged as part of a cycle are visually marked
    And days with a logged symptom or flare entry are visually
      distinguished from days with no entry

  Scenario: Calendar shows predicted future days
    Given my cycle history is regular enough to generate a prediction
    When I view the current or next month in the calendar
    Then predicted future cycle days are shown with a visually distinct
      style from confirmed, already-logged days

  Scenario: Legend explains what the calendar's colors and markers mean
    When I open the calendar widget
    Then I can see or reveal a legend that explains each color and marker
      used (for example: logged cycle day, predicted cycle day, symptom
      logged, no entry)

  Scenario: Navigating between months
    Given I am viewing the current month in the calendar
    When I select the previous-month control
    Then the calendar shows the prior month's data
    When I select the next-month control repeatedly back to the current
      month
    Then the calendar returns to today's month with today highlighted

  Scenario: Logging an entry directly from the calendar
    Given I am viewing today's date in the calendar
    When I select today's date
    Then I am able to add or edit an entry for that day without leaving
      the dashboard

  Scenario: Switching between calendar and list view
    Given I am viewing my history as a calendar
    When I switch the widget's display mode to "list"
    Then the same date range is shown as a chronological list of entries
    And I can switch back to the calendar view at any time
    And my last-chosen view mode is remembered for next time

  Scenario: Calendar respects my locale and week-start preference
    Given I have set my week to start on Monday in my preferences
    When I open the calendar widget
    Then each week row begins on Monday
