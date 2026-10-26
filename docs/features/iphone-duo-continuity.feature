Feature: iPhone Duo continuity during daily logging
  As someone moving between an outer and an inner display
  I want to keep working on the same day
  So that opening or closing the device does not interrupt my log

  # UNVERIFIED (TODO): This entire proposal, including notes, needs user review.
  # Depends on the shared large-screen-layout feature, not a second Duo layout.
  # Product case: folding mid-log must retain date, input and navigation context.
  # Apple describes inner and outer displays. Logical viewport sizes, fold events,
  # hinge geometry and native lifecycle behavior are not assumed here.
  # HTML sizes are illustrative CSS widths, not iPhone Duo specifications.
  # Native SDK, simulator and hardware verification are required before support claims.
  # Existing autosave remains authoritative; a width change is not a save trigger.

  @unverified
  Scenario: Opening during a log exposes context without resetting the task
    Given the user opened a selected day's log from a compact calendar
    And the editor has pending note input, a flow choice, symptoms and a period day override
    When the available content area becomes wide enough for both panes
    Then the same day's editor remains active beside the same calendar month
    And the pending values and text selection remain attached to that day
    And no extra save is triggered by the layout transition
    And the navigation history is not reset to the dashboard

  @unverified
  Scenario: Closing during a log keeps the editor primary
    Given the calendar and a selected day's editor are visible side by side
    When the available area becomes compact while the user is editing
    Then that day's editor remains the primary view
    And the pending note is not discarded or copied to a different day
    And back navigation returns to the same calendar month and selected date
    And opening the device again restores the same two-pane task when it fits

  @unverified
  Scenario: Repeated size changes do not duplicate writes
    Given a log update is already being saved for a selected date
    When the available width changes repeatedly before the update completes
    Then only the original requested update is persisted
    And no duplicate log is created
    And a save failure keeps the pending input and retry action on the same day

  @unverified
  Scenario: Navigation and dashboard customization survive the transition
    Given the user is in calendar after opening it from a customized dashboard
    When the usable content area changes between compact and wide
    Then the calendar context and back navigation remain intact
    And no card is unhidden, reordered or resized in stored preferences
    And the same layout rules also apply to tablet multitasking and resized windows

  @unverified
  Scenario: Text size and keyboard determine whether two panes fit
    Given the user has 200 percent text or an onscreen keyboard open
    When the available area is evaluated after a display transition
    Then the app uses the shared readable-layout rules rather than the device model
    And the active input and Done action remain reachable by scrolling
    And focus is restored to the same logical field where available
    And no custom hinge control or unsupported posture API is required

  @unverified
  Scenario: A lifecycle interruption keeps privacy policy intact
    Given the user is editing when a display transition also backgrounds the app
    When the app resumes and the configured lock policy requires authentication
    Then the task stays behind the app lock until authentication succeeds
    And the layout code does not disable or shorten the lock policy
    And the in-memory task resumes with its selected date and pending input after unlock
    And process termination recovery is not claimed by this continuity feature
