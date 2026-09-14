Feature: Unlocking Inner Flare
  As a user of a menstrual cycle tracking app
  I want opening or reopening the app to be one clear, predictable moment
  So that proving it's me is quick and painless, and never feels like
  something has gone wrong

  Background:
    Given the device has biometrics or a device passcode configured

  Scenario: First open of a session shows a single dedicated unlock screen
    Given the app has just finished its loading screen for the first time this session
    Then a dedicated "Inner Flare is locked" screen is shown, full-screen
    And no dashboard cards, navigation, or partially-loaded content are visible behind it
    And no raw error text or diagnostic icon is shown before the user has had a chance to unlock

  Scenario: The unlock prompt appears automatically, with no tap required
    Given the dedicated unlock screen has just appeared, whether on first open this session or after re-locking
    Then the biometric or passcode prompt is triggered immediately, without the user tapping "Unlock" first

  Scenario: Successful authentication goes straight to fully-loaded content
    Given the automatic unlock prompt is showing
    When the user authenticates successfully
    Then the unlock screen is dismissed immediately
    And the screen underneath (the dashboard on first open, or whatever screen was covered on a re-lock) is already fully loaded
    And there is no flash of an empty or partially-loaded state in between

  Scenario: Cancelling or failing the prompt leaves one clear way to retry
    Given the automatic unlock prompt is showing
    When the user cancels it, or it fails
    Then the dedicated unlock screen stays up, with a plain-language explanation and a single "Unlock" button
    And no second prompt is triggered automatically — the user decides when to try again

  Scenario: Retrying is a single tap, never a stack of prompts
    Given the dedicated unlock screen is showing a retry state after a cancelled or failed attempt
    When the user taps "Unlock"
    Then exactly one biometric or passcode prompt is triggered
    And the button is disabled while that prompt is in progress, so a second tap can't trigger an overlapping prompt

  Scenario: First open and recurring re-lock share one visual language
    Given the app re-locks itself after the idle timeout (see docs/features/app_lock.feature)
    Then the screen shown uses the same layout, colors, and iconography as the first-open unlock screen
    And the wording only differs where the situation genuinely differs, e.g. "Inner Flare is locked" versus an explanation that the user stepped away

  Scenario: A genuine authentication error explains itself in place
    Given authentication fails for a reason other than the user cancelling
    Then a short, plain-language explanation is shown directly on the dedicated unlock screen
    And the user is not required to open Settings or notice an icon elsewhere in the app to learn that something went wrong

  Scenario: A device with no biometrics or passcode never shows an unlock screen
    Given the device has no biometrics enrolled and no passcode, PIN, or pattern set
    When the app opens for the first time this session, or would otherwise re-lock
    Then no unlock screen or prompt is shown at all
    And the user goes straight to their data, since there is nothing to gate with

  Scenario: First-ever launch reaches onboarding without a confusing detour
    Given this is the very first launch on this device, before onboarding has been completed
    When the loading screen finishes and the database still needs to be unlocked
    Then the same dedicated unlock screen is shown before onboarding begins
    And once unlocked, the user proceeds directly into onboarding with no separate or unexplained step

  Scenario: An already-unlocked session never re-prompts on its own
    Given the user has already unlocked the app once this session
    When the user navigates between screens within the app
    Then no further biometric or passcode prompt appears
    And a prompt is only shown again after the idle timeout re-locks the app
