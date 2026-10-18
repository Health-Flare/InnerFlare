Feature: Large screen calendar and day log layout
  As someone logging on a roomy window
  I want to keep the calendar beside the day I am working on
  So that I can review history without losing my place

  # UNVERIFIED (TODO): This entire proposal, including notes, needs user review.
  # No production implementation or native device validation is included.
  # Recommended direction: calendar with selected-day detail when both fit.
  # Use available content width, text scale, safe areas and keyboard insets.
  # Do not use a device name or orientation as the layout rule.
  # Main already autosaves each log change. This proposal does not replace that
  # contract with Save/Cancel. Explicit Save/Cancel in the HTML is demo-only.
  # Pending input means text selection/composition and writes not yet completed,
  # including failed writes. A layout change must not cause a new write.

  @unverified
  Scenario: A roomy calendar keeps the selected day beside the month
    Given the calendar and day editor can both fit at the user's text size
    When the user selects a date in the calendar
    Then the calendar remains visible beside that day's log
    And the selected date is identified by text and a visible selection state
    And the editor uses the same fields and persistence contract as the compact editor
    And no new health estimate is introduced by the wider layout

  @unverified
  Scenario: A narrow window retains the compact logging path
    Given there is not enough usable width for both panes
    When the user selects a date
    Then that day's log opens as the primary compact view
    And returning to the calendar restores the visible month and selected date
    And the next back action returns to the screen that opened the calendar

  @unverified
  Scenario: Resizing changes presentation without saving or discarding input
    Given the user is editing a selected day's log
    And a note contains input not yet successfully persisted
    When the available width crosses the pane layout boundary in either direction
    Then the selected date and visible month remain unchanged
    And the note, flow, symptoms and period day override remain unchanged
    And text selection and logical focus stay with the same field where available
    And the layout transition neither submits an extra write nor discards input
    And any write already in progress keeps its original date and ordering

  @unverified
  Scenario: A failed write stays attached to its original day
    Given a write for a selected day's log has failed
    When the user resizes the window or selects another date
    Then the failed input remains associated with its original date
    And the user can return to that date and retry
    And the failure is not presented as a saved log
    And input is never copied into the other day's log

  @unverified
  Scenario: Existing dashboard choices are not rewritten by wider layouts
    Given the user has hidden and reordered cards and changed their spans
    When the user opens the app in a wider or narrower window
    Then card identities, visibility, order and saved spans remain unchanged
    And the existing two-column dashboard grid is reused within a bounded region
    And Log today remains reachable even when every configurable card is hidden
    And resize feedback, preset suggestions and nudges remain separate work

  @unverified
  Scenario: Large text uses a readable layout rather than smaller text
    Given text is scaled to 200 percent
    When the calendar and editor no longer fit beside each other
    Then the layout uses one primary pane without horizontal page scrolling
    And dates, field labels, errors and actions remain readable without clipping
    And a labelled date list is available if the month grid cannot fit usable targets
    And touch targets remain at least 48 logical pixels
    And the keyboard does not prevent reaching the active field or Done action

  @unverified
  Scenario: Keyboard and assistive technology can operate both panes
    Given the user is navigating without touch
    When the user chooses a date and edits its log
    Then selection and focus are visible and not communicated by color alone
    And date navigation and all edit actions are available using the keyboard
    And assistive technology announces the selected date and save failure if present
    And focus order follows calendar then selected-day detail without trapping focus
    And returning from the compact editor restores focus to the selected date

  @unverified
  Scenario: Existing navigation and protection remain authoritative
    Given the calendar was opened from the dashboard
    When the window becomes wide
    Then the existing dashboard, calendar, insights and settings destinations remain available through their existing paths
    And no new permanent navigation rail or bottom bar is required
    And the current app lock continues to cover the task when its policy requires it
    And a layout transition does not bypass authentication
