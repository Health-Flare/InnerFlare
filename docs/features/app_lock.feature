Feature: Idle app lock
  As a user of a menstrual cycle tracking app
  I want the app to re-lock itself if I've left it backgrounded for a while
  So that my data isn't readily viewable if I set my phone down and walk away

  Background:
    Given the user has unlocked the app once this session
    And the idle-lock timeout is set to its default of 15 minutes

  Scenario: A brief interruption does not re-lock the app
    Given the app is backgrounded
    When the user returns to the app less than 15 minutes later
    Then the app is not locked
    And the user's data is shown as before

  Scenario: Fifteen minutes backgrounded re-locks the app
    Given the app is backgrounded
    When the user returns to the app 15 minutes or more later
    Then a lock screen covers whatever screen was open, hiding its content
    And the user must re-authenticate with biometrics or device passcode to continue

  Scenario: Cancelling re-authentication leaves the app locked
    Given the app re-locked after being backgrounded
    When the user cancels the biometric/passcode prompt
    Then the lock screen is still shown
    And no data is accessible

  Scenario: Successful re-authentication dismisses the lock screen
    Given the app re-locked after being backgrounded
    When the user successfully authenticates
    Then the lock screen is dismissed
    And the screen the user was on before backgrounding is shown again

  Scenario: The idle-lock timeout is configurable in Settings
    Given the user is on the Settings screen
    Then they can choose an idle-lock timeout of Immediately, 1 minute,
      5 minutes, 15 minutes, 30 minutes, 1 hour, or Never
    And the choice persists per-device across app restarts, same as
      dashboard card layout — never synced

  Scenario: A shorter configured timeout re-locks sooner
    Given the user has set the idle-lock timeout to 1 minute
    When the app is backgrounded and the user returns 1 minute or more later
    Then a lock screen covers whatever screen was open

  Scenario: "Never" disables idle-lock entirely
    Given the user has set the idle-lock timeout to Never
    When the app is backgrounded for any length of time and the user returns
    Then the app is not locked
