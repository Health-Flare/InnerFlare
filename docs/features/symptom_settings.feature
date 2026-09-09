Feature: Symptom tracking settings
  As a user
  I want to change, add, enable, and disable which symptoms I can log
  So that the log screen only offers what actually matters to me

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Every default symptom starts enabled
    Given the app has never had its symptom settings changed
    When the user opens "Symptoms to track" in settings
    Then every default symptom is listed and enabled

  Scenario: Disabling a symptom removes it from the log screen
    Given "acne" is enabled
    When the user disables "acne" in symptom settings
    And the user opens today's log
    Then the "acne" chip is not offered

  Scenario: Disabling a symptom never touches days already logged with it
    Given a prior day was logged with the "acne" symptom
    When the user disables "acne" in symptom settings
    Then that prior day's entry still has "acne" in its symptom set
    And reopening that day's log still shows the "acne" chip, selected

  Scenario: Re-enabling a symptom brings it back to the log screen
    Given "acne" was previously disabled
    When the user re-enables "acne" in symptom settings
    And the user opens today's log
    Then the "acne" chip is offered again

  Scenario: Adding a custom symptom makes it available to log
    When the user adds a custom symptom named "Back pain" in symptom settings
    And the user opens today's log
    Then a "Back pain" chip is offered alongside the default symptoms

  Scenario: A newly added symptom is enabled by default
    When the user adds a custom symptom named "Back pain" in symptom settings
    Then "Back pain" is listed as enabled without any extra step

  Scenario: Changing a symptom's name updates it everywhere it appears
    Given the user has logged "cramps" on a prior day
    When the user renames "cramps" to "Cramping" in symptom settings
    Then the log screen offers a "Cramping" chip instead of "Cramps"
    And the prior day's entry is unchanged, now shown as "Cramping"
