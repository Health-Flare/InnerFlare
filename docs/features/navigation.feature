Feature: Navigation
  As a user
  I want consistent, predictable navigation across the app
  So that I can move between logging, calendar, insights, and settings without friction

  Background:
    Given the user has completed onboarding

  Scenario: Primary navigation reaches every top-level feature
    Given the user is on the dashboard
    Then the user can navigate to calendar, insights, export, and settings
    Without more than one navigation action from the dashboard

  Scenario: The "log today" entry point is reachable from anywhere
    Given the user is on any top-level screen
    Then a persistent entry point to log today is visible or one tap away

  Scenario: Back navigation returns to the previous screen, not the dashboard
    Given the user navigated from the dashboard into calendar, then into a specific day's log
    When the user presses back
    Then the user returns to calendar
    And a second back press returns to the dashboard

  Scenario: Deep navigation to a specific date preserves calendar context
    Given the user opens a specific day's log from calendar
    When the user saves or cancels that day's log
    Then the user returns to calendar scrolled to the same month

  Scenario: Settings is reachable without leaving the current task
    Given the user is mid-logging on the log screen
    When the user needs to change a setting
    Then settings is reachable from top-level navigation
    And returning from settings does not discard the in-progress log
