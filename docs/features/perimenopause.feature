# Design decisions and open challenges (read before touching scenarios below)
#
# 1. Age is asked nowhere in onboarding. Front-loading a "your age" question
#    onto every new user — most of whom are years from needing it — pads
#    onboarding for the common case to serve a minority. Age is only ever
#    asked contextually, inside the nudge itself (see "Introducing the
#    feature"), or if the user proactively opens Settings and turns this on
#    unprompted. Only birth year is stored, never a full date of birth —
#    month/day adds nothing to an age estimate and is unnecessary PII for an
#    app whose whole design stance is minimal data collection.
#
# 2. Detecting "menopause reached" from data alone is unreliable: 12 months
#    without a logged period start looks identical whether periods actually
#    stopped or the user just stopped logging (the same trap
#    insights.feature already guards against for ordinary gaps, at much
#    larger scale here). This spec resolves it by never auto-setting life
#    stage from data — the app only ever surfaces the observation and asks.
#    See "Life stage is an explicit, user-owned setting".
#
# 3. HRT/hormonal medication can produce breakthrough bleeding or suppress
#    periods entirely, in patterns this app has no way to model correctly.
#    Rather than guess, v1 explicitly scopes this out: HRT use is recorded
#    as a flag that suppresses cycle-regularity predictions and irregularity
#    nudges rather than attempting to interpret them. See "HRT and hormonal
#    medication context".
#
# 4. The variability threshold/window that reasonably suggests perimenopause
#    (as opposed to one or two normal irregular cycles, already handled in
#    insights.feature) is a clinical judgment call, not something derivable
#    from first principles. This spec uses a longer trailing window than
#    ordinary irregularity detection and treats it as a soft, dismissible
#    nudge rather than a claim — precision here matters less than never
#    presenting it as diagnostic.
#
# 5. Expanded symptom tags (vasomotor, sleep, cognitive) are gated behind
#    opt-in, not merged into the default symptom list. A user who never
#    engages with this feature should never see "hot flash" or "night
#    sweat" cluttering the daily log screen — this is the concrete UX
#    answer to "fade in and out as relevant": the log screen itself changes
#    shape, not just a dashboard card.

Feature: Perimenopause and menopause tracking
  As a user whose cycle patterns may be changing with age
  I want the app to gently introduce relevant tracking when it's likely to
    matter, without assuming anything about my body
  So that I'm not stuck using a strictly reproductive-years period tracker
    forever, and I'm never told what stage I'm in

  Background:
    Given the user has completed onboarding

  # --- Introducing the feature -----------------------------------------

  Scenario: The feature is entirely opt-in and invisible until relevant
    Given a newly onboarded user with no birth year on file
    And no cycle data suggesting irregularity
    When the user views the dashboard
    Then no perimenopause-related card, nudge, or prompt is shown
    And nothing about perimenopause tracking is enabled

  Scenario: A birth year suggesting relevant age triggers a dismissible nudge
    Given the user has entered a birth year making them 40 or older
    When the user views the dashboard
    Then a dismissible nudge invites the user to enable perimenopause
      symptom tracking
    And the nudge explains this is an offer based on age, not an assessment
      of the user's body

  Scenario: Sustained cycle variability triggers the same nudge regardless of age
    Given the user's cycle lengths over the last 6 logged cycles vary by
      more than 10 days from each other
    And this pattern holds across at least 4 of those cycles, not just one
      outlier pair
    When the user views the dashboard
    Then the same dismissible nudge is shown
    And the nudge cites the variability pattern as its reason, not age

  Scenario: The nudge itself is where age is first asked, and it's optional
    Given the nudge is shown for either age or variability reasons
    When the user opens the nudge
    Then the user may enter a birth year if one isn't already on file
    And entering a birth year is optional even at this point
    And declining to enter it does not block enabling symptom tracking

  Scenario: Any user can turn this on proactively, unprompted
    Given a user of any age with no variability trigger
    When the user opens Settings and enables perimenopause symptom tracking directly
    Then tracking is enabled immediately
    And no birth year or justification is required

  Scenario: Dismissing the nudge doesn't mean never
    Given the user dismisses the perimenopause tracking nudge
    When the triggering condition (age or variability) still holds after a
      cooldown period
    Then the nudge may be shown again, no more than once per cooldown period
    And the user can permanently silence it from Settings, separate from a
      single dismissal

  Scenario: Declining the nudge changes nothing about the app
    Given the user dismisses or declines the nudge
    When the user continues using the app
    Then logging, calendar, and insights behave exactly as before
    And no data about age or life stage is retained from a declined nudge's
      birth year entry, if the user chose not to save it

  # --- Life stage is an explicit, user-owned setting ---------------------

  Scenario: Life stage defaults to unset and is only ever changed by the user
    Given a user who has not interacted with perimenopause tracking
    Then their life stage setting is unset
    And no cycle-math or insights behavior differs from a user for whom the
      feature doesn't exist

  Scenario: Enabling tracking sets life stage to "perimenopause", not "menopause"
    Given the user enables perimenopause symptom tracking from the nudge or Settings
    When tracking is enabled
    Then the life stage setting is set to "perimenopause"
    And this only changes which symptom tags and cards are shown, not any
      cycle-math prediction logic yet

  Scenario: 12 months without a logged period is surfaced as a question, never set automatically
    Given the user's life stage is "perimenopause"
    And the user has logged at least one cycle day (of any kind — flow,
      symptoms, or note) in each of the last 12 months
    And no period start has been logged in that same 12-month span
    When the user views insights or the dashboard
    Then the app shows an observation that it's been 12 months since the
      last logged period
    And the app asks whether the user wants to mark menopause as reached
    And life stage remains "perimenopause" until the user confirms

  Scenario: A logging gap is never mistaken for a menopause milestone
    Given no period start has been logged in the last 12 months
    But the user also has no other cycle day logs of any kind across at
      least 3 of those months
    When the user views insights or the dashboard
    Then the app does not suggest that menopause may have been reached
    And any period-related "not enough data" or "no recent logs" messaging
      takes precedence over a menopause observation

  Scenario: Confirming menopause is a deliberate, explained action
    Given the app has surfaced the 12-month observation
    When the user confirms menopause has been reached
    Then life stage is set to "menopause"
    And the confirmation screen states this reflects the user's own
      confirmation, not a diagnosis or clinical assessment
    And the user can revert this from Settings at any time (e.g. a period
      resumes, which happens and is not an error state)

  Scenario: Life stage can always be set or changed manually from Settings
    Given the user is in Settings
    When the user opens the life stage setting
    Then the user can set it to "not tracking", "perimenopause", or
      "menopause" directly
    And no confirmation dialog claims special knowledge about why the user
      is making the change

  # --- Symptom vocabulary is gated, not merged in ------------------------

  Scenario: Default symptom list is unchanged for users not tracking this
    Given the user's life stage setting is unset or "not tracking"
    When the user opens the daily log screen
    Then only the existing default symptom tags are shown
    And no vasomotor, sleep, or cognitive symptom tags appear

  Scenario: Expanded symptom tags appear once perimenopause tracking is enabled
    Given the user's life stage is "perimenopause" or "menopause"
    When the user opens the daily log screen
    Then additional symptom tags are available: hot flash, night sweat,
      sleep disruption, brain fog, and joint aches
    And these appear alongside the existing default tags, not replacing them

  Scenario: Turning tracking off hides the tags but keeps the logged data
    Given the user has logged days with a hot flash tag
    When the user sets life stage back to "not tracking" in Settings
    Then the hot flash tag no longer appears as a selectable option in the
      daily log screen
    And previously logged days still show and store their hot flash tag
    And no logged data is deleted

  # --- Cycle-math and insights adaptation --------------------------------

  Scenario: Sustained irregularity lowers prediction confidence instead of hiding it outright
    Given the user's life stage is "perimenopause"
    And cycle lengths over the last 6 cycles vary by more than 10 days
      across at least 4 of them
    When the user views insights
    Then a predicted next period date is still shown if an average exists
    And it is labeled as low-confidence, explicitly because of the detected
      variability, distinct from the existing general "estimate" label
    And a plain-language note explains predictions are less reliable during
      this kind of pattern

  Scenario: Once menopause is confirmed, period and fertile-window predictions stop
    Given the user's life stage is "menopause"
    When the user views insights
    Then no predicted next period date is shown
    And no predicted fertile window is shown
    And the insights screen explains predictions are turned off because
      periods aren't expected at this life stage, not because of missing data

  Scenario: Symptom-only logging works with no period tracking active
    Given the user's life stage is "menopause"
    When the user logs a day with symptoms and no period flow
    Then the log is saved normally
    And the calendar and symptom history continue to reflect it
    And nothing in the UI implies period logging is still expected

  Scenario: A period logged after menopause was confirmed is not an error
    Given the user's life stage is "menopause"
    When the user logs a new period start
    Then the log is saved without warning or blocking dialogs
    And the app surfaces (not forces) the option to revert life stage to
      "perimenopause", consistent with "Confirming menopause is a
      deliberate, explained action"

  # --- HRT and hormonal medication context --------------------------------

  Scenario: Recording HRT/hormonal medication use suppresses regularity-based predictions
    Given the user's life stage is "perimenopause" or "menopause"
    When the user indicates in Settings that they're using HRT or hormonal
      medication that affects bleeding patterns
    Then next-period and fertile-window predictions are hidden
    And insights explains that predictions aren't attempted while this is
      set, because medication-influenced bleeding patterns aren't modeled
    And the irregularity nudge described above does not trigger while this
      flag is set

  Scenario: Turning off the HRT flag restores normal prediction behavior
    Given the HRT/hormonal medication flag was set and is now cleared
    When the user views insights
    Then predictions resume using the same cycle-math logic as any other
      user at that life stage

  # --- Not a diagnosis, always --------------------------------------------

  Scenario: Every perimenopause/menopause surface avoids diagnostic language
    Given any screen that mentions life stage, symptoms, or the 12-month
      observation
    Then the wording describes patterns and user-confirmed settings only
    And no screen states or implies a medical diagnosis, a clinical stage,
      or a prediction of when menopause will occur
    And this is consistent with the app's existing not-a-medical-device
      disclaimer (docs/features/onboarding.feature)

  # --- Dashboard and data lifecycle ---------------------------------------

  Scenario: The life stage card follows the same customization rules as any other card
    Given the user has enabled perimenopause tracking
    When the user opens dashboard customization
    Then a life stage card can be shown, hidden, or reordered like any
      other card (docs/features/dashboard.feature)
    And it is not marked mandatory or unremovable

  Scenario: Life stage settings are per-device, never synced
    Given the user has set a life stage, birth year, or HRT flag
    When the app is reopened
    Then the same settings are shown
    And no network request was made to retrieve or persist them

  Scenario: Export/import carries life stage data forward without breaking older backups
    Given a backup exported from a version of the app before this feature existed
    When that backup is imported on a version that includes perimenopause tracking
    Then the import succeeds
    And life stage defaults to unset for the imported data
    And no error is raised for the absence of life-stage fields in the
      older backup

  Scenario: A backup that does include life stage data round-trips correctly
    Given the user has a life stage, optional birth year, and HRT flag set
    When the user exports and then re-imports that backup
    Then life stage, birth year (if entered), and the HRT flag are restored exactly
    And symptom logs using the expanded tag set are restored exactly
