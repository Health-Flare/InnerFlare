Feature: Dashboard customization
  As a user
  I want full control over what the dashboard shows and how
  So that the app reflects only what I personally care about tracking

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Default dashboard layout is not permanently fixed
    Given the dashboard is showing its default set of cards
    When the user opens dashboard customization
    Then every default card can be hidden
    And no card is marked as mandatory or unremovable

  Scenario: Hiding a card removes it from the dashboard
    Given the "insights" card is visible on the dashboard
    When the user hides the "insights" card in customization
    Then the "insights" card no longer appears on the dashboard
    And the preference is saved so it persists after restarting the app

  Scenario: Reordering cards changes their display order
    Given the dashboard shows cards in the order [log, calendar, insights]
    When the user drags the "insights" card above "calendar"
    Then the dashboard displays cards in the order [log, insights, calendar]
    And the new order is saved to settings

  Scenario: Re-showing a previously hidden card
    Given the "insights" card was previously hidden
    When the user re-enables the "insights" card in customization
    Then the card reappears on the dashboard
    And it is inserted at the end of the current card order by default

  Scenario: Card preferences are stored per-device in settings, not synced
    Given the user has customized the card layout
    When the app is reopened
    Then the same customized layout is shown
    And no network request was made to retrieve or persist the layout

  Scenario: Hiding every card still leaves the log entry point reachable
    Given the user hides every optional dashboard card
    When the user views the dashboard
    Then the persistent "log today" entry point is still present
    And the user is not blocked from logging a day
