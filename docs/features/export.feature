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
# 2. Generic CSV import from other cycle-tracking apps was drafted for v1
#    and then dropped after spec review checked the premise it rested on:
#    that a user's old app hands them a usable CSV. It mostly doesn't. Flo
#    offers CSV as one export option, but only via a manual "contact
#    support" request that emails a download link later — not an in-app
#    download sitting in Files the moment someone switches phones. Clue
#    offers JSON only, in a password-protected ZIP, with no CSV option at
#    all. Shipping a column-mapping wizard framed around "import from your
#    old app" would have implied a level of compatibility with named
#    competitors this app hadn't actually verified, for either of the two
#    most obvious sources. Rather than build that and caveat it after the
#    fact, the whole "Importing from other cycle-tracking apps" section
#    (column mapping, the `import_field_mappings` table, symptom-value
#    resolution) is cut from v1. InnerFlare's own export/import format
#    remains the only supported round-trip. Revisit only once a real
#    third-party source is confirmed to produce something this app can
#    honestly claim to read.
#
# 3. "All cycle_day_logs and settings" in the first scenario below means
#    portable data, not every row in the database. dashboard_card_preferences,
#    quick_stat_preferences, and security_settings (the idle-lock timeout)
#    are each documented elsewhere as per-device state — see "Card
#    preferences are stored per-device in settings, not synced"
#    (dashboard.feature), "Quick stat preferences are stored per-device, not
#    synced" (quick_stats.feature), and app_lock.feature's idle-lock timeout
#    scenario — and perimenopause.feature's "Nudge deferral state is
#    device-local and deliberately not exported" scenario confirms the same
#    is true of dashboard layout by direct analogy. None of the three round-
#    trip through export/import; a device keeps its own layout, quick-stat
#    choices, and lock timeout regardless of what's imported onto it. The
#    `symptoms` catalog is the one settings table that *does* travel with
#    the data, since `cycle_day_logs.symptoms` entries are meaningless
#    without the labels (and custom entries) they reference — see "The
#    symptom catalog travels with the data" below.
#
# 4. Platform health stores (Apple Health on iOS, Health Connect on
#    Android) are a materially bigger lift than file-based CSV import ever
#    was — native permission grants, platform-specific APIs, and (Health
#    Connect especially) a live on-device read rather than a picked file.
#    Unlike generic CSV import, they weren't cut: reading structured
#    records an app itself wrote via a documented platform API is a
#    verifiable claim, not a guess about a competitor's export format. See
#    "Importing from the platform health store" for what's specified now
#    versus deferred to its own later phase.

Feature: Backup export and import
  As a user
  I want to move my data between my own devices deliberately and offline
  So that I have full control over my data with no cloud or account involved

  Background:
    Given the user has completed onboarding

  Scenario: Export produces a single portable file
    Given the user has logged data across multiple cycles
    When the user chooses "export" in settings
    Then a single file is produced containing all cycle_day_logs and the
      symptom catalog
    And the file includes the current schema_version
    And the OS share sheet is presented so the user can save or send the file

  Scenario: The symptom catalog travels with the data, per-device settings do not
    Given the user has renamed a built-in symptom and added a custom one
    And the user has also customized their dashboard layout, quick stats,
      and idle-lock timeout
    When the user exports and imports that backup onto another device
    Then the renamed and custom symptoms are restored on the other device
    And the other device's dashboard layout, quick stats, and idle-lock
      timeout are left exactly as they were on that device, untouched by
      the import

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

  # --- Importing from the platform health store ----------------------------
  #
  # This is the only external (non-InnerFlare-format) import path in v1 —
  # generic CSV import from other cycle-tracking apps was drafted and then
  # dropped; see design decision 2 above for why. Platform health stores
  # are a materially bigger lift — native permission grants,
  # platform-specific APIs, and (Health Connect especially) a live
  # on-device read rather than a picked file, closer in weight to this
  # app's existing biometric-gate/Keychain integration work than to parsing
  # a file. Apple Health (iOS) and Health Connect (Android) both store
  # menstrual flow and symptom records other apps have written via each
  # platform's HealthKit/Health Connect API, entirely on-device. Scoped as
  # its own later phase; the scenarios below describe what a future
  # implementation should guarantee, not something expected alongside this
  # file's other v1 scenarios.

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

  Scenario: Platform health import previews records and resolves unmapped values before writing anything
    Given records have been read from the platform health store
    When the user reviews them before import
    Then a sample of the records as they will be imported is shown before
      anything is written to the database
    And any symptom value with no matching InnerFlare tag is listed
      individually for the user to map, keep as note text, or ignore —
      never guessed or silently dropped
    And the user is asked to choose replace or merge, the same choice
      offered for an InnerFlare-format import, before the import runs
