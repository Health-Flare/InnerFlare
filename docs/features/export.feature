# Design decisions and open challenges (read before touching scenarios below)
#
# 1. Export stays a personal-use portability format, never a sharing format.
#    BRIEF.md §5 lists a "printable/PDF summary for a doctor visit" as a
#    deferred v2 candidate; this spec supersedes that framing from
#    "deferred" to "not a goal of this feature" — this app doesn't produce
#    anything meant to be read by, or handed to, anyone but the user
#    operating their own device. PDF and CSV export are both out: PDF is a
#    presentation format for other readers, and a CSV export would
#    flatten/lose the structure round-tripping needs (symptom sets,
#    schema_version, optional fields) for no benefit an export aimed only
#    at the user's own other device actually needs. See "Export stays
#    personal-use, not a sharing format".
#
# 2. Import is a different problem from export and gets an asymmetric
#    answer: CSV import (from wherever a user's old app or their own
#    spreadsheet produced one) is genuinely valuable on the way IN, because
#    it's the lowest common denominator most other cycle-tracking apps and
#    manual trackers actually produce, and it's how a user leaves another
#    app for good. Supporting CSV import while refusing CSV export isn't a
#    contradiction — export serves round-tripping InnerFlare's own full
#    data model; import serves whatever incomplete, lossy format a user
#    shows up with. See "Importing from other cycle-tracking apps".
#
# 3. Platform health stores (Apple Health on iOS, Health Connect on
#    Android) are a materially bigger lift than file-based CSV import —
#    native permission grants, platform-specific APIs, and (Health Connect
#    especially) a live on-device read rather than a picked file. Scoped as
#    its own later phase rather than bundled into a v1 CSV importer; see
#    "Importing from the platform health store" for what's specified now
#    versus deferred.
#
# 4. A third-party file's data quality is unknown and its column/tag names
#    never match InnerFlare's model by construction. The rule throughout:
#    never guess a mapping silently and never silently drop what doesn't
#    map — always show the user what wasn't understood and let them decide,
#    the same "no fabrication" principle cycle_math.dart already applies to
#    gaps in logged data.

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

  # --- Export stays personal-use, not a sharing format --------------------

  Scenario: No PDF or CSV export option exists
    Given the user opens the export screen
    Then the only output is the app's own portable file format
    And no PDF, CSV, or other externally-readable report format is offered
    And nothing in the export flow is framed around sharing with a third
      party (a doctor, a partner, a printout) — it moves data to the
      user's own other device, nothing else

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

  # --- Importing from other cycle-tracking apps ----------------------------
  #
  # This is new scope beyond BRIEF.md's v1 MVP (which only covers
  # InnerFlare's own export round-tripping). A user switching in from
  # another app is the whole point: they shouldn't have to re-enter years
  # of history by hand, and a CSV is the one format most other trackers (or
  # a manually kept spreadsheet) can actually produce.
  #
  # Data model: a new per-device `import_field_mappings` table — columns
  # `source_label` (user-entered, e.g. "Clue export"), `source_field`,
  # `mapped_to` (an InnerFlare field or symptom, or explicitly "ignore"),
  # `last_used_at`. Purely a convenience cache for re-imports from the same
  # source; never required, never exported/synced (per-device UI state,
  # same bar as nudge_state in docs/features/perimenopause.feature), and
  # safe to lose. Also needs an `ImportSource` domain concept
  # (innerFlareBackup | genericCsv | appleHealth | healthConnect) to
  # select the right parser and drive the mapping screen's copy.

  Scenario: A CSV file can be chosen as an alternative to InnerFlare's own export format
    Given the user chooses "import" in settings
    When the user selects a .csv file instead of an InnerFlare export file
    Then the app recognizes it as a CSV import rather than rejecting it outright
    And the user is taken to a column-mapping screen instead of the
      replace/merge prompt used for InnerFlare's own format

  Scenario: CSV columns are mapped by the user, never guessed silently
    Given the app has read the CSV file's header row
    When the mapping screen is shown
    Then each source column is listed next to a chooser for which
      InnerFlare field it corresponds to (date, period flow, symptom, note,
      or "ignore this column")
    And no column is auto-assigned to a field without the user confirming it

  Scenario: Only a recognizable date column is required to proceed
    Given the user is mapping CSV columns
    When no column has been mapped to "date"
    Then the import cannot proceed
    And every other mapping (flow, symptoms, note) remains optional

  Scenario: Unrecognized symptom values are never silently dropped or guessed
    Given a mapped symptom column contains a value with no matching
      InnerFlare symptom tag (e.g. a source app's own custom tag name)
    When the mapping screen reaches that column
    Then each distinct unrecognized value is listed individually
    And the user chooses, per value, to map it to an existing symptom tag,
      keep it as text appended to that day's note, or ignore it
    And no value is imported into a symptom tag it wasn't explicitly mapped to

  Scenario: A preview is shown before anything is written to the database
    Given the user has finished mapping columns
    When the user reaches the review step
    Then a sample of the rows as they will be imported is shown, using the
      chosen mappings
    And the user can go back and change a mapping before confirming
    And nothing is written to the database until the user explicitly confirms

  Scenario: A CSV import still goes through the same replace/merge choice as any other import
    Given the user has confirmed a CSV import's column mappings
    When the import is about to run
    Then the user is asked to choose replace or merge, the same choice
      offered for an InnerFlare-format import
    And the chosen strategy is applied before any data is written

  Scenario: Malformed rows are reported, not silently skipped
    Given a CSV file has rows that don't parse under the chosen mappings
      (e.g. an unparseable date)
    When the import runs
    Then those rows are listed to the user as not imported, with the reason
    And every row that did parse is still imported normally
    And the app never guesses a value to make a malformed row fit

  Scenario: Column mappings can be reused on a later import from the same source
    Given the user previously imported a CSV and named the mapping (e.g.
      "Clue export")
    When the user imports another CSV and selects that saved mapping
    Then the same column-to-field assignments are pre-filled
    And the user can still adjust them before confirming, same as a fresh import

  Scenario: CSV import never makes a network request
    Given the user is anywhere in the CSV import flow, including column
      mapping and symptom-value resolution
    Then no request is made to look up a known app's template or column
      names from anywhere but the app's own bundled data
    And this matches the app's existing offline-only posture for every
      other feature

  Scenario: The app offers, but never forces, removing the source file after a successful import
    Given a CSV import has completed successfully
    When the confirmation screen is shown
    Then the user is offered the option to delete the original file the
      app read from
    And declining leaves the file exactly where the user's file picker
      found it — the app never deletes it without the user choosing to

  # --- Importing from the platform health store ----------------------------
  #
  # Scoped lighter than CSV import above on purpose — this is a later phase,
  # not something this spec expects to ship alongside generic CSV import.
  # Apple Health (iOS) and Health Connect (Android) both store menstrual
  # flow and symptom records other apps have written via each platform's
  # HealthKit/Health Connect API, entirely on-device. Reading them needs a
  # native runtime permission grant and platform-specific integration code,
  # not a file picker — closer in weight to this app's existing
  # biometric-gate/Keychain integration work than to parsing a CSV.

  Scenario: Platform health import requests only the record types it needs
    Given the user chooses to import from Apple Health or Health Connect
    When the platform's permission prompt is shown
    Then only menstrual flow and symptom record types are requested
    And no broader health data access (heart rate, steps, or anything
      unrelated to cycle tracking) is requested

  Scenario: Platform health import is user-initiated only, never automatic
    Given the app has previously been granted platform health permissions
    When the app is opened normally, without the user choosing "import"
    Then no read of the platform health store occurs
    And this matches "Export never happens automatically" above — a granted
      permission is not standing consent for the app to read on its own schedule

  Scenario: Platform health import reuses the same preview-before-write and replace/merge rules
    Given records have been read from the platform health store
    When the user reviews them before import
    Then the same preview, unmapped-value resolution, and replace/merge
      choices apply as they do for a CSV import
    And no platform-specific exception to those rules exists
