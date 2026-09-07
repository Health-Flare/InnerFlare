Feature: Backup export and import
  As a user
  I want to move my data between my own devices deliberately and offline
  So that I have full control over my data with no cloud or account involved

  Background:
    Given the user has completed onboarding

  Scenario: Export produces a single portable file
    Given the user has logged data across multiple cycles
    When the user chooses "export" in settings
    Then a single file is produced containing all cycle_day_logs and settings
    And the file includes the current schema_version
    And the OS share sheet is presented so the user can save or send the file

  Scenario: Export never happens automatically
    Given the user has logged data
    When the user has not explicitly requested an export
    Then no export file is ever written or transmitted
    And there is no background or scheduled export of any kind

  Scenario: Import replaces or merges into the local database
    Given the user selects a previously exported file to import
    When the file's schema_version is validated as compatible
    Then the user is asked to choose replace or merge
    And the chosen strategy is applied before any data is written

  Scenario: Import rejects a file with an incompatible or unreadable schema
    Given the user selects a file that is not a valid export
    When the app attempts to validate the file
    Then the import is rejected with a clear error
    And no partial data is written to the local database

  Scenario: Import from an older schema version is still supported
    Given the user selects a file exported from an older app version with schema_version 1
    And the current app is on schema_version 2
    When the file is imported
    Then the older data is migrated to the current schema during import
    And no data from the older export is silently dropped

  Scenario: Optional passphrase encrypts the export file at rest
    Given the user enables "encrypt export" and sets a passphrase
    When the user exports their data
    Then the resulting file is encrypted and unreadable without the passphrase
    And the plaintext data is not written to disk at any point during export

  Scenario: Importing an encrypted file requires the correct passphrase
    Given the user selects a passphrase-encrypted export file to import
    When the user enters an incorrect passphrase
    Then the import fails with a clear "incorrect passphrase" error
    And no data is written to the local database

  Scenario: Plaintext export is the default with encryption opt-in
    Given the user has not enabled "encrypt export"
    When the user exports their data
    Then the file is written as plaintext
    And the user is not blocked from exporting by an unset passphrase
