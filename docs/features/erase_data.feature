Feature: Erase all data
  So that I can remove everything Inner Flare holds about me quickly,
  for example when someone else may look at or take my phone,
  I can erase all of my data from Settings and the app starts over as if
  it had just been installed.

  # Decided with the product owner (issue #94):
  # - Settings only, once the app is unlocked. Not on the lock screen.
  # - Guarded by the device unlock (Face ID, fingerprint or passcode), then
  #   one confirm dialog. No typed confirmation word, no duress PIN.

  Background:
    Given the user has unlocked the app
    And they have logged some days, symptoms and notes

  Scenario: Erase all data is in its own section at the end of Settings
    When the user opens Settings
    Then they see an "Erase all data" section, set apart from the other settings
    And it is not shown on the lock screen or the unlock screen

  Scenario: The device unlock is asked for first
    Given the user is on Settings
    When they tap "Erase all data"
    Then they are asked for Face ID, fingerprint or their device passcode
    And their prompt does not lock the app again behind them

  Scenario: Cancelling the device unlock does nothing
    Given the user tapped "Erase all data"
    When they cancel or fail the Face ID, fingerprint or passcode prompt
    Then no confirm dialog is shown
    And all of their data is still there

  Scenario: The confirm dialog says what will be lost
    Given the user tapped "Erase all data" and passed the device unlock
    Then they see "Erase all data?"
    And it says every logged day, symptom, note and setting on this phone will be deleted
    And it says this can't be undone
    And it says backups they've already exported aren't affected
    And they can choose "Cancel", "Export a backup first" or "Erase"

  Scenario: Cancel leaves everything as it was
    Given the confirm dialog is showing
    When the user taps "Cancel"
    Then the dialog closes
    And all of their data is still there

  Scenario: Export a backup first
    Given the confirm dialog is showing
    When the user taps "Export a backup first"
    Then the Export data screen opens
    And nothing has been erased

  Scenario: Erase starts the app over as if newly installed
    Given the confirm dialog is showing
    When the user taps "Erase"
    Then the key that unlocks their data is deleted from the phone's secure storage
    And the data file and its working files are deleted
    And any backup files the app left behind while exporting are deleted
    And other apps' files are left alone
    And the app shows the same unlock and welcome screens as a fresh install
    And when they unlock again, nothing they logged before is there

  Scenario: Once the key is gone, a later failure still finishes the erase
    Given the key that unlocks their data has been deleted
    When deleting the data file or the leftover export files fails
    Then the app still starts over as if newly installed
    And the data left behind can't be read, because its key is gone

  Scenario: If the key can't be deleted, nothing is erased
    Given the user tapped "Erase"
    When the key that unlocks their data can't be deleted
    Then nothing else is deleted
    And they see "Couldn't erase. Your data is still here."
    And they stay on Settings with their data as it was
