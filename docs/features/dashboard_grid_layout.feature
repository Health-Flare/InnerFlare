Feature: Dashboard grid layout
  As a user
  I want quick stats, Calendar, Insights, and any data visualization I've
  added to live in one shared space, sized to what each one needs
  So that nothing on my dashboard reads as more or less important than
  anything else: it's one dashboard, not a hierarchy of sections

  This supersedes the older "Quick stats" / "Your data, at a glance" split
  described piecemeal in docs/features/dashboard.feature and
  docs/features/quick_stats.feature. See those files for what's
  unchanged (show/hide, reorder, per-device storage, individual stat/card
  configuration); this file is specifically about where everything sits
  and how much room it takes up.

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Quick stats, Calendar, and Insights share one grid, not two
    separate sections
    Given the dashboard is showing its default layout
    Then there is a single grid area below the "log today" hero card and
      the "Log a previous day" link
    And there is no separate "Your data, at a glance" heading or section
      distinct from the quick stats

  Scenario: The default layout is a 2x2 grid
    Given a fresh install with no logged data
    When the user finishes onboarding
    Then the grid shows exactly four cells: the two default quick stats,
      a Calendar cell, and an Insights cell
    And this arrangement is identical for every user, matching "A fresh
      install starts with the same default for everyone" in
      docs/features/dashboard_presets.feature

  Scenario: Calendar and Insights occupy one grid cell each by default,
    same as a quick stat
    Given the default 2x2 grid
    Then the Calendar and Insights cells are the same size as each quick
      stat cell
    And none of the four is visually larger, more prominent, or otherwise
      privileged over the others

  Scenario: A newly added gauge or trend card defaults to a wider cell
    Given the user adds a gauge or trend card from the catalog
      (docs/features/dashboard_visualizations.feature)
    When the card is added
    Then it's placed in the same grid as everything else, not a separate
      area
    And it defaults to one row tall by two columns wide, since a gauge or
      chart needs more room than a single quick stat to read clearly

  Scenario: Every card in the grid is a peer
    Given the grid contains a mix of default and added cards
    Then no card's type (quick stat, Calendar, Insights, gauge, trend)
      determines its importance or position
    And the user's own arrangement is the only thing that determines what
      stands out

  Scenario: Reordering works across the whole grid, not within separate areas
    Given the grid contains quick stats, Calendar, Insights, and one or
      more added cards
    When the user reorders cards in Customize
    Then any card can be moved anywhere in the grid, regardless of its
      type
    And this replaces the old behavior where quick stats and dashboard
      cards were reordered as two separate lists

  Scenario: The privacy reassurance card stays pinned below the grid
    Given the user has any number of cards in the grid
    When the user views the dashboard
    Then the privacy reassurance message still appears at the very
      bottom, below the grid, exactly as before this change
    And it is never itself a grid cell the user can move or resize

  Scenario: Calendar and Insights remain fixed, not removable, only
    resizable and reorderable once resizing exists
    Given Calendar and Insights are default cells in the grid
    Then the user can hide, show, and reorder them like any other cell
    But neither can be removed outright or replaced with a different card
      type, matching the existing rule in docs/features/dashboard.feature

  # Forward-looking, not yet implemented: the user will eventually be
  # able to resize any cell in the grid (e.g. make an added trend card
  # two rows tall by two columns wide instead of its one-by-two default),
  # not just accept the default size for its type. Noted here so the
  # default-sizing rules above are understood as starting points, not a
  # fixed layout. Candidate implementation: flutter_staggered_grid_view
  # for variable-size cells plus a hand-built Draggable/DragTarget layer
  # for reordering, since no single actively-maintained package does
  # both (evaluated in product discussion, not yet spiked in code).
  # Tracked as its own initiative, separate from the visualization/
  # nudge/preset work already underway.
  Scenario: Cell size will eventually be user-adjustable
    Given a card is showing at its default size
    When resizing ships in a future release
    Then the user will be able to make that card's cell bigger or smaller
      within the grid
    And every other cell will reflow to accommodate the new size, the
      same way reordering already causes the rest of the grid to shift
