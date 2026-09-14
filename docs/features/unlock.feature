Feature: Unlocking Inner Flare
  As a user of a menstrual cycle tracking app
  I want opening or reopening the app to be one clear, predictable moment
  that I control
  So that proving it's me is quick and painless, explains itself, and
  never feels like a system dialog ambushing me

  Background:
    Given the device has biometrics or a device passcode configured

  Scenario: First open of a session shows a single dedicated unlock screen
    Given the app has just finished its loading screen for the first time this session
    Then a dedicated "Inner Flare is locked" screen is shown, full-screen
    And no dashboard cards, navigation, or partially-loaded content are visible behind it
    And no raw error text or diagnostic icon is shown before the user has had a chance to unlock

  Scenario: The unlock screen explains itself before asking for anything
    Given the dedicated unlock screen has just appeared, whether on first open this session or after re-locking
    Then it explains in plain language that the data is encrypted on-device and needs to be unlocked to view
    And an enabled "Unlock" button is shown — nothing is requested of the user automatically

  Scenario: The database is never created or opened until the user chooses to unlock
    Given the dedicated unlock screen is showing, before any tap
    Then the encrypted database has not been created, opened, or touched in any way
    And no biometric or passcode prompt is shown
    And this remains true no matter how long the screen sits untouched

  Scenario: Tapping "Unlock" is what triggers the biometric or passcode prompt
    Given the dedicated unlock screen is showing its initial, not-yet-attempted state
    When the user taps "Unlock"
    Then exactly one biometric or passcode prompt is triggered
    And the button becomes disabled and relabelled "Unlocking…" so a second tap can't fire an overlapping prompt

  Scenario: Successful authentication goes straight to fully-loaded content
    Given the user tapped "Unlock" and authenticated successfully
    Then the unlock screen is dismissed immediately
    And the screen underneath (the dashboard on first open, or whatever screen was covered on a re-lock) is already fully loaded
    And there is no flash of an empty or partially-loaded state in between

  Scenario: Cancelling or failing the prompt leaves one clear way to retry
    Given the user tapped "Unlock" and the prompt was cancelled or failed
    Then the dedicated unlock screen stays up, with a plain-language explanation and a single "Unlock" button
    And no prompt is triggered automatically afterwards — the user decides when to try again, with another tap

  Scenario: Retrying is a single tap, never a stack of prompts
    Given the dedicated unlock screen is showing a retry state after a cancelled or failed attempt
    When the user taps "Unlock" again
    Then exactly one new biometric or passcode prompt is triggered
    And the button is disabled while that prompt is in progress, so a second tap can't trigger an overlapping prompt

  Scenario: First open and recurring re-lock share one visual language
    Given the app re-locks itself after the idle timeout (see docs/features/app_lock.feature)
    Then the screen shown uses the same layout, colors, iconography, and tap-to-unlock interaction as the first-open unlock screen
    And the wording only differs where the situation genuinely differs, e.g. why the screen is showing right now

  Scenario: A genuine authentication error explains itself in place
    Given authentication fails for a reason other than the user cancelling
    Then a short, plain-language explanation is shown directly on the dedicated unlock screen
    And the user is not required to open Settings or notice an icon elsewhere in the app to learn that something went wrong

  Scenario: A device with no biometrics or passcode still requires the tap, but never a prompt
    Given the device has no biometrics enrolled and no passcode, PIN, or pattern set
    When the user taps "Unlock" on the dedicated unlock screen
    Then no biometric or passcode prompt is shown, since there is nothing to gate with
    And the user goes straight to their data

  Scenario: First-ever launch reaches onboarding without a confusing detour
    Given this is the very first launch on this device, before onboarding has been completed
    When the loading screen finishes
    Then the same dedicated unlock screen is shown, explaining why, before onboarding begins
    And once the user taps "Unlock" and authenticates, they proceed directly into onboarding with no separate or unexplained step

  Scenario: An already-unlocked session never re-prompts on its own
    Given the user has already unlocked the app once this session
    When the user navigates between screens within the app
    Then no further biometric or passcode prompt appears, and no unlock screen is shown again
    And a prompt is only shown again after the idle timeout re-locks the app, and only once the user taps "Unlock" there too
