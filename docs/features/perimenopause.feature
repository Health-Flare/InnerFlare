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
#    nudges rather than attempting to interpret them. See "Reproductive
#    context: HRT, IUD, and pregnancy" (extended per point 7 below to cover
#    IUDs and pregnancy on the same principle).
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
#
# 6. Every dismissible nudge (not just the two in this file) now follows a
#    single pattern: state the concrete reason inline, offer deferral to
#    either a suggested date or a user-picked one instead of a fixed
#    cooldown, and always name where the same setting lives in Settings.
#    See "Nudge transparency and deferral" — this generalizes what was
#    previously just a vague "cooldown period" concept.
#
# 7. HRT was too narrow a home for "don't read this bleeding pattern the
#    normal way" — a hormonal IUD produces the identical false-perimenopause
#    signal, and pregnancy needs the same prediction suppression for an
#    unrelated reason. All three now live together as "reproductive
#    context", deliberately NOT gated behind perimenopause opt-in or age —
#    see "Reproductive context: HRT, IUD, and pregnancy". A copper IUD is
#    explicitly excluded from this suppression since it doesn't affect
#    hormones or ovulation.
#
# 8. Two gaps surfaced by walking the spec against docs/personas.md rather
#    than just re-reading it: (a) the variability nudge had no way to catch
#    a user whose irregularity has an unrelated cause (an IUD, HRT,
#    pregnancy) she hasn't told the app about yet — it would have read a
#    29-year-old's IUD side effect as a perimenopause signal. The nudge now
#    offers "something else explain this?" alongside the perimenopause
#    option, linking straight to reproductive context settings, rather than
#    assuming perimenopause is the only possible cause. (b) The neutral,
#    no-assumed-emotion copy standard was specified for *ending* a recorded
#    pregnancy but not for recording a new one — asymmetric, and wrong in
#    the same direction (assuming congratulations are always welcome).
#    Fixed to apply symmetrically. See "The variability nudge offers
#    another explanation before assuming perimenopause" and "Recording a
#    new pregnancy is copy-neutral, the same as ending one".

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

  Scenario: The variability nudge offers another explanation before assuming perimenopause
    Given the sustained cycle variability nudge is triggered
    And the user has not recorded any reproductive context (hormonal
      medication, an IUD, or pregnancy)
    When the user opens the nudge
    Then alongside the option to enable perimenopause symptom tracking, the
      nudge asks whether something else explains the pattern — hormonal
      medication, an IUD, or pregnancy — and links directly to reproductive
      context settings
    And choosing one of those reasons there suppresses the variability
      nudge going forward, the same as recording it from Settings would
    And the nudge never assumes perimenopause is the only possible
      explanation for cycle variability

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

  # --- Nudge transparency and deferral ------------------------------------
  #
  # This pattern isn't specific to perimenopause — any dismissible
  # suggestion the app shows (this feature's age/variability nudges today,
  # whatever else in the future) follows the same three rules: say why
  # you're being asked, let the user pick when to be asked again instead of
  # a fixed cooldown, and always say where the same choice lives in
  # Settings for later.
  #
  # Data model: a new per-device `nudge_state` table, one row per nudge id
  # ('perimenopause_age', 'perimenopause_variability', and future ones),
  # columns `deferred_until` (nullable date) and `permanently_dismissed`
  # (boolean). Deliberately NOT part of export/import — like dashboard
  # card positions, this is transient per-device UI state, not data about
  # the user's body.

  Scenario: Every nudge states its own trigger in plain language
    Given any dismissible nudge shown by this feature (age-based or
      variability-based)
    When the user views the nudge
    Then it states the specific reason it's showing now (the birth year
      threshold, or the observed cycle pattern) in one plain sentence
    And it never uses a generic reason like "you might be interested in this"

  Scenario: A nudge can be deferred to a suggested future point
    Given the user is viewing a dismissible nudge
    When the user chooses "remind me later"
    Then a sensible default follow-up point is offered (e.g. in 3 months)
    And choosing it dismisses the nudge until that point without disabling
      it permanently

  Scenario: A nudge can be deferred to a date the user picks
    Given the user is viewing a dismissible nudge
    When the user chooses to pick a specific date instead of the suggested default
    Then a date picker is shown
    And the nudge does not reappear before that date
    And a picked date must be in the future; the app rejects a past or
      today's date with a plain explanation rather than silently accepting it

  Scenario: A deferred nudge reappears at the chosen time, not sooner
    Given the user deferred a nudge to a specific date
    When the app is opened before that date
    Then the nudge is not shown
    When the app is opened on or after that date
    Then the nudge may be shown again, still fully dismissible and
      deferrable itself

  Scenario: Every nudge says exactly where to find the same choice manually
    Given the user is viewing any dismissible nudge from this feature
    Then the nudge states plainly that the same setting can be turned on or
      off anytime from Settings, naming the specific settings section
    And this statement appears whether the user accepts, dismisses, or
      defers the nudge

  Scenario: "Don't ask again" is distinct from a single dismissal
    Given the user is viewing a dismissible nudge
    When the user chooses "don't ask again" rather than "remind me later"
    Then the nudge is permanently silenced for that trigger
    And this choice is separate from and stronger than letting a deferred
      date simply pass
    And the user can still find and enable the feature manually from
      Settings at any time afterward

  Scenario: The variability nudge follows the identical explain/defer/educate pattern
    Given the sustained cycle variability nudge is shown
    Then it follows every rule above the same way the age-based nudge does —
      its own plain-language reason, the same deferral choices, and the
      same pointer to Settings
    And no separate nudge mechanism exists for variability versus age

  Scenario: Deferring or declining a nudge changes nothing else about the app
    Given the user defers, dismisses, or permanently silences a nudge
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
      symptoms, or note) in at least 9 of the last 12 months
    And no period start has been logged in that same 12-month span
    When the user views insights or the dashboard
    Then the app shows an observation that it's been 12 months since the
      last logged period
    And the app asks whether the user wants to mark menopause as reached
    And life stage remains "perimenopause" until the user confirms

  Scenario: A logging gap is never mistaken for a menopause milestone
    Given no period start has been logged in the last 12 months
    And the user has logged on fewer than 9 of those 12 months
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

  # --- Reproductive context: HRT, IUD, and pregnancy ----------------------
  #
  # These three settings live together because they share one job: telling
  # cycle-math and the perimenopause nudges "don't read this pattern the
  # way you normally would." They are NOT gated behind perimenopause
  # tracking or any age/variability trigger — a 27-year-old with a hormonal
  # IUD or a first pregnancy needs the exact same prediction suppression a
  # 46-year-old does, for unrelated reasons. This section's scope has grown
  # beyond "perimenopause" specifically; docs/features/insights.feature's
  # prediction scenarios should be read as implicitly qualified by whatever
  # is set here.
  #
  # Hormonal and copper IUDs are NOT interchangeable here: a hormonal IUD
  # commonly thins or stops the lining and suppresses ovulation for some
  # users, producing exactly the light/absent/irregular bleeding pattern
  # this feature's variability nudge is built to notice — so it must be
  # excluded the same way HRT is. A copper IUD is non-hormonal and doesn't
  # suppress ovulation; a copper IUD user's natural cycle is what's being
  # tracked, so nothing about prediction logic should change for it.
  #
  # Data model: a new singleton `reproductive_context_settings` table,
  # independent of `life_stage_settings` and not gated by it — columns
  # `hormonal_medication` (boolean), `iud_type` (nullable: 'hormonal' |
  # 'copper'), `pregnant` (boolean), `pregnancy_start_date` (nullable,
  # optional user entry), `pregnancy_estimated_end_date` (nullable,
  # optional user entry, never computed by the app). Unlike nudge_state,
  # this IS part of export/import — it's data about the user's body, same
  # bar as life stage or symptom logs.

  Scenario: Recording hormonal medication use (HRT or otherwise) suppresses regularity-based predictions
    Given any user, regardless of life stage
    When the user indicates in Settings that they're using HRT or another
      hormonal medication that affects bleeding patterns
    Then next-period and fertile-window predictions are hidden
    And insights explains that predictions aren't attempted while this is
      set, because medication-influenced bleeding patterns aren't modeled
    And the perimenopause age and variability nudges do not trigger while
      this flag is set

  Scenario: A hormonal IUD is recorded distinctly from a copper IUD
    Given the user opens the reproductive context settings
    When the user records having an IUD
    Then the user is asked whether it's hormonal or copper
    And this distinction is stored, not collapsed into a single "has an
      IUD" flag

  Scenario: A hormonal IUD suppresses predictions and nudges the same way HRT does
    Given the user has recorded a hormonal IUD
    When the user views insights or the dashboard
    Then next-period and fertile-window predictions are hidden
    And the perimenopause age and variability nudges do not trigger
    And the stated reason references the IUD specifically, not a generic
      "medication" explanation

  Scenario: A copper IUD does not change prediction or nudge behavior
    Given the user has recorded a copper IUD
    When the user views insights or the dashboard
    Then predictions and nudges behave exactly as they would with no IUD recorded
    And the app does not imply a copper IUD affects hormones or cycle regularity

  Scenario: Recording pregnancy suppresses period and fertile-window predictions
    Given any user, regardless of life stage
    When the user indicates in Settings or during logging that they're pregnant
    Then next-period and fertile-window predictions are hidden
    And insights explains that predictions are off because a period isn't
      expected during pregnancy, distinct from the medication-suppression wording

  Scenario: Recording a new pregnancy is copy-neutral, the same as ending one
    Given the user is recording a pregnancy for the first time
    When the confirmation screen is shown
    Then no congratulations, celebratory language, or assumption about
      whether this is welcome news is shown
    And the screen states plainly what changes (predictions and nudges are
      suppressed) without commenting on the pregnancy itself
    And this matches the same neutral standard "Ending a recorded
      pregnancy" already holds, applied symmetrically on the way in

  Scenario: Recording pregnancy also suppresses the perimenopause nudges
    Given the user has recorded a pregnancy
    When the user views the dashboard
    Then the age-based and variability-based perimenopause nudges do not trigger
    And an absence of periods during a recorded pregnancy is never read as
      a perimenopause signal

  Scenario: Entering a pregnancy start date or estimated end date is optional
    Given the user is recording a pregnancy
    When the user declines to enter a start date or estimated end date
    Then the pregnancy is still recorded and predictions are still suppressed
    And no date is inferred or estimated by the app on the user's behalf

  Scenario: Ending a recorded pregnancy is a deliberate, low-friction action
    Given the user has a recorded pregnancy
    When the user ends the pregnancy record from Settings
    Then the app asks only whether normal cycle tracking should resume, not
      why or how the pregnancy ended
    And no judgment, congratulation, or condolence copy is assumed — the
      screen stays neutral and lets the user's own next actions (logging a
      period, or not) speak for themselves

  Scenario: Pregnancy takes precedence over IUD or HRT status when both are recorded
    Given the user has a recorded pregnancy alongside a recorded IUD, a
      hormonal medication flag, or both (rare, but not impossible — device
      failure happens, and some medication use continues into early
      pregnancy under clinical guidance)
    When the user views insights
    Then the pregnancy-suppression explanation is shown, not the IUD or
      medication one
    And the IUD and medication records themselves are left untouched, only
      the displayed reason changes

  Scenario: Reproductive context suppression takes precedence over variability-based low-confidence labeling
    Given the user's life stage is "perimenopause" and cycle variability
      meets the low-confidence threshold described above
    And a reproductive context flag (hormonal medication, hormonal IUD, or
      pregnancy) is also set
    When the user views insights
    Then predictions are hidden per the reproductive context reason
    And no low-confidence prediction is shown instead — the two explanations
      never compete for the same space on screen

  Scenario: Turning off any reproductive context flag restores normal prediction and nudge behavior
    Given a hormonal medication flag, hormonal IUD, or pregnancy record was
      set and is now cleared
    When the user views insights or the dashboard
    Then predictions resume using the same cycle-math logic as any other
      user at that life stage
    And the perimenopause age and variability nudges resume evaluating
      their normal trigger conditions

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
    Given the user has set a life stage, birth year, or reproductive
      context field (hormonal medication, IUD type, or pregnancy)
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
    Given the user has a life stage, optional birth year, and reproductive
      context settings (hormonal medication flag, IUD type, and/or
      pregnancy record) set
    When the user exports and then re-imports that backup
    Then life stage, birth year (if entered), and every reproductive
      context field are restored exactly
    And symptom logs using the expanded tag set are restored exactly

  Scenario: Nudge deferral state is device-local and deliberately not exported
    Given the user has deferred or permanently silenced a nudge on this device
    When the user exports a backup and imports it on a different device
    Then the imported device shows nudges according to its own trigger
      conditions, not the exporting device's deferral state
    And this matches how dashboard card layout is also per-device, never synced
