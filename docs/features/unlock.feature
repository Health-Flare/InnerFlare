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
    And an enabled "Unlock" button is shown; nothing is requested of the user automatically

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
    And no prompt is triggered automatically afterwards; the user decides when to try again, with another tap

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

  # Key binding (part of #90). The key that decrypts the data is held by the
  # phone's own secure storage and released only after the phone has checked
  # it's the user: face, fingerprint, or the phone's passcode/PIN. Before
  # this, the app asked the phone "is this the user?" and then read the key
  # itself, so anything that could skip that question could read the key.
  # iPhone: Keychain item with user presence. Android 11 and later: Keystore
  # key that needs a strong biometric or the screen lock for every use.
  # Android 9 and 10 can't offer the screen lock as a fallback for this kind
  # of key, so they keep the old key and the old prompt.

  Scenario: The phone itself releases the key only after it has checked it's the user
    Given the phone has a screen lock
    When the user taps "Unlock"
    Then the phone shows its own face, fingerprint, or passcode prompt
    And the key is only released to Inner Flare once that prompt succeeds
    And the user sees one prompt, not two in a row

  Scenario: Cancelling the phone's prompt keeps the data locked
    Given the phone has a screen lock
    When the user taps "Unlock" and cancels the phone's prompt
    Then the dedicated unlock screen stays up with the retry explanation
    And no prompt is shown again until the user taps "Unlock" again

  Scenario: Updating the app carries the existing key over without losing data
    Given the user has data from a version of Inner Flare before key binding
    And the phone has a screen lock
    When the user taps "Unlock" for the first time after updating
    Then the existing key is copied into the protected slot and checked
    And the old copy is removed only after the protected copy has been read back and matches
    And all of the user's history opens as before

  Scenario: If the carry-over fails, the old key keeps working and it tries again next time
    Given the user has data from a version of Inner Flare before key binding
    When copying the key into the protected slot fails, or the copy doesn't match, or the app is closed part way through
    Then the old key is kept and the user's data still opens
    And the carry-over is tried again the next time the user unlocks

  Scenario: Adding a new fingerprint or face doesn't lock the user out
    Given the key is held by the phone's screen lock
    When the user adds or removes a fingerprint or face in the phone's settings
    Then their data still opens with face, fingerprint, or passcode as before

  Scenario: A phone with no screen lock says plainly that anyone can open the app
    Given the phone has no passcode, PIN, pattern, or biometrics set up
    Then the unlock screen says "This phone has no screen lock, so anyone holding it can open Inner Flare."
    And the unlock screen does not claim the data is unlocked with Face ID, Touch ID, or a passcode
    And the dashboard and Settings show the same warning for as long as there is no screen lock

  Scenario: Setting a screen lock later protects the key from the next unlock
    Given the phone had no screen lock, so the key was stored without one
    When the user sets a screen lock and next taps "Unlock"
    Then the key is carried over into the protected slot the same safe way as after an update
    And the warning is no longer shown

  # Android deletes keys like this for good when the screen lock is turned
  # off (Keystore: "irreversibly invalidated once the secure lock screen is
  # disabled"). That's the price of tying the key to the screen lock, so
  # Settings warns about it ahead of time.
  Scenario: Settings warns that turning the screen lock off can delete the key
    Given the key is held by the phone's screen lock
    When the user opens Settings
    Then Settings says "Your data's key is tied to this phone's screen lock. Turning the screen lock off can delete that key, so export a backup first."

  Scenario: Turning the screen lock off after the key is protected explains what happened
    Given the key is held by the phone's screen lock
    When the user turns the phone's screen lock off and taps "Unlock"
    Then the unlock screen says "Inner Flare's key was tied to this phone's screen lock, and the screen lock is now off. Turn it back on in your phone's settings and tap Unlock. If your data still doesn't open, the phone removed the key when the screen lock was turned off, and only a backup you exported earlier can bring it back."
    And no new, empty key is made in its place

  Scenario: If the app can't tell whether the phone has a screen lock, it stays locked
    Given checking the phone's screen lock settings fails with an error
    When the user taps "Unlock"
    Then the data stays locked and the retry explanation is shown
    And the user can tap "Unlock" again to retry
    And a phone that genuinely has no screen lock still gets in, with the warning above

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
