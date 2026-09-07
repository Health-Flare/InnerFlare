Feature: Onboarding
  As a first-time user
  I want a fast, honest introduction to the app
  So that I understand what it does with my data before I start logging

  Background:
    Given the app is launched for the first time on this device

  Scenario: Privacy statement is shown before any data is collected
    When onboarding begins
    Then the user sees a clear, specific privacy statement
    And the statement says data never leaves the device unless the user explicitly exports it
    And the statement avoids vague language like "we value your privacy"

  Scenario: Not-a-medical-device disclaimer is shown plainly
    When onboarding begins
    Then the user sees a plain statement that this is a tracking tool, not a diagnostic or medical device
    And predictions are described as estimates based on transparent statistics, not a diagnosis

  Scenario: No account or sign-in is ever requested
    When the user progresses through onboarding
    Then the user is never asked for an email, password, or account of any kind
    And the user is never asked to grant network permissions

  Scenario: Default settings are established without requiring input
    When the user completes onboarding without changing any defaults
    Then a default luteal phase length assumption is set
    And a default cycle history window (N cycles) is set
    And a default dashboard card layout is set
    And the user is taken to the dashboard

  Scenario: User can optionally enter historical cycle data during onboarding
    Given the user is on the "cycle history" onboarding step
    When the user chooses to skip entering historical data
    Then onboarding completes successfully
    And insights later reflect "not enough data yet" until at least one cycle is logged

  Scenario: User can enter last period start date during onboarding
    Given the user is on the "cycle history" onboarding step
    When the user enters a last period start date
    Then that date is saved as a cycle_day_logs entry with is_period_start true
    And onboarding completes successfully

  Scenario: Onboarding only runs once
    Given the user has already completed onboarding on this device
    When the app is launched again
    Then onboarding is not shown
    And the user is taken directly to the dashboard
