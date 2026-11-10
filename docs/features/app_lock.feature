Feature: Idle app lock
  As a user of a menstrual cycle tracking app
  I want the app to re-lock itself if I've left it backgrounded for a while
  So that my data isn't readily viewable if I set my phone down and walk away

  # Default decided 2026-10-05 (issues #90, #91): 1 minute, down from 15.
  # A cycle tracker is often on a shared or borrowed phone, and 15 minutes
  # left the app open to whoever picked the phone up next. A timeout the
  # user picked themselves is kept.
  #
  # Before this change, accepting the first-run statement saved the old
  # default of 15 minutes, so a saved "15 minutes" can't be told apart
  # from a real choice. It is treated as "never chosen" and moves to the
  # new default; anyone who wants 15 minutes back can pick it again.

  Background:
    Given the user has unlocked the app once this session
    And the idle-lock timeout is set to its default of 1 minute

  Scenario: A brief interruption does not re-lock the app
    Given the app is backgrounded
    When the user returns to the app less than 1 minute later
    Then the app is not locked
    And the user's data is shown as before

  Scenario: One minute backgrounded re-locks the app
    Given the app is backgrounded
    When the user returns to the app 1 minute or more later
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

  Scenario: The lock screen hides the app from screen readers and the keyboard
    Given the user was typing in a note when the app re-locked
    When the lock screen is shown
    Then a screen reader can't read anything from the screen underneath
    And the note field no longer has the keyboard focus
    And a hardware keyboard can't move focus back into the screen underneath
    And animations on the screen underneath pause until the app is unlocked

  Scenario: The idle-lock timeout is configurable in Settings
    Given the user is on the Settings screen
    Then the Auto-lock entry shows the current idle-lock timeout
    When they open the Auto-lock entry
    Then a page with the idle-lock timeout options is shown
    And they can choose an idle-lock timeout of Immediately, 1 minute,
      5 minutes, 15 minutes, 30 minutes, 1 hour, or Never
    And, back on Settings, the entry shows the new choice
    And the choice persists per-device across app restarts, same as
      dashboard card layout, never synced

  Scenario: Someone who never chose a timeout gets the new default after updating
    Given the user installed an earlier version and never changed Auto-lock
    When they update the app
    Then the idle-lock timeout is 1 minute

  Scenario: A timeout the user chose is kept after updating
    Given the user chose an idle-lock timeout of 5 minutes, 30 minutes,
      1 hour, Immediately, 1 minute or Never in an earlier version
    When they update the app
    Then the idle-lock timeout is the one they chose

  Scenario: A saved 15 minutes from an earlier version moves to the new default
    Given an earlier version had saved an idle-lock timeout of 15 minutes
    When the user updates the app
    Then the idle-lock timeout is 1 minute
    And if they choose 15 minutes again, it stays 15 minutes from then on

  Scenario: A shorter configured timeout re-locks sooner
    Given the user has set the idle-lock timeout to 5 minutes
    When the app is backgrounded and the user returns 5 minutes or more later
    Then a lock screen covers whatever screen was open

  Scenario: "Immediately" locks as soon as the app leaves the screen
    Given the user has set the idle-lock timeout to Immediately
    When the app is sent to the background
    Then the app locks straight away, before the user comes back
    And on return the lock screen is the first thing shown

  Scenario: The unlock prompt itself does not re-lock the app
    Given the user has set the idle-lock timeout to Immediately
    And the app is locked
    When the user taps Unlock and the Face ID sheet or the passcode screen appears
    Then the app does not count that as being sent to the background
    And a successful unlock leaves the app unlocked

  Scenario: "Never" disables idle-lock entirely
    Given the user has set the idle-lock timeout to Never
    When the app is backgrounded for any length of time and the user returns
    Then the app is not locked

  Scenario: Choosing "Never" shows a warning
    Given the user is on the Auto-lock page
    When they choose Never
    Then they see "Anyone who picks up your unlocked phone can open Inner Flare."
    When they choose any other timeout
    Then the warning is gone

  # The two scenarios below live in the native iOS and Android code, which
  # no Flutter test can reach. They are checked by hand on a device.

  Scenario: The app switcher never shows the user's data
    Given the user has Inner Flare open on any screen
    When they open the app switcher
    Then the Inner Flare preview is a plain cover with no data on it

  Scenario: Android blocks screenshots and screen recording of the app
    Given the user is on Android
    When they or another app take a screenshot, record or cast the screen
    Then Inner Flare's screen does not show up in it
