Feature: First-run disclaimer
  As a first-time user
  I want a plain privacy and not-a-medical-device statement before I use the app
  So that I know what happens to my data and what the app does not claim

  # Smallest gate ahead of the full onboarding flow in onboarding.feature
  # (last period date, default settings wizard). Those steps stay deferred.
  # The acknowledgement is a per-device flag in security_settings and is
  # not part of an export.

  Background:
    Given the encrypted database has been unlocked

  Scenario: Disclaimer is shown before the dashboard on first launch
    Given the user has not acknowledged the disclaimer on this device
    When the app finishes unlocking
    Then the user sees a statement that this is not a medical or diagnostic device
    And predictions are described as estimates, not a diagnosis
    And the user sees that logged data stays on the device unless they explicitly export it
    And a privacy policy link is shown
    And that link opens in the browser only when the user taps it
    And the user is not asked for an email, password, or account

  Scenario: Acknowledging the disclaimer dismisses it on later launches
    Given the disclaimer is showing
    When the user taps Continue
    Then the acknowledgement is stored on this device
    And the user is taken to the dashboard
    And a later launch does not show the disclaimer

  Scenario: Returning users can re-read the disclaimer from Settings
    Given the user has already acknowledged the disclaimer
    When the user opens Settings and chooses Privacy and disclaimer
    Then the same statement and privacy policy link are shown
