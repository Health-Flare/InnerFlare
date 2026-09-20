Feature: Dashboard presets
  As a user
  I want a sensible starting dashboard, and suggestions for bundles of
  cards that fit how I actually use the app
  So that I don't have to build my dashboard from nothing, while still
  ending up with exactly what's useful to me

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: A fresh install starts with the same default for everyone
    Given a brand new install with no logged data
    When the user finishes onboarding
    Then the dashboard shows exactly today's default cards — Calendar
      and Insights — and nothing more
    And this default is identical for every user; it is not personalized
      based on anything entered during onboarding

    # This default stays as-is "until we have some other semblance of
    # feedback" — a deliberate choice to hold the line here rather than
    # pre-add a gauge or trend card to the default, at least for now.

  Scenario: The app suggests a bundle once the user's data fits a
    recognized pattern
    Given the user's logged data matches a recognized usage pattern
    When the user opens the dashboard
    Then a nudge suggests adding a bundle of related cards together,
      rather than one card at a time
    And the nudge follows the same dismiss/snooze contract as any other
      nudge (docs/features/dashboard_nudges.feature)

    # Which patterns map to which bundles is a genuinely open product
    # question — not yet defined beyond the general idea. Needs its own
    # decision before this scenario can be implemented; flagging rather
    # than inventing specific bundles here.

  Scenario: Accepting a suggested bundle adds every card in it at once
    Given a bundle-suggestion nudge is shown
    When the user accepts it
    Then every card in that bundle is added to the dashboard in a single
      action, not one at a time
    And each added card is individually visible, reorderable, and
      removable afterward — exactly like a card added one at a time
      through "Add a card"

  Scenario: Declining a bundle suggestion doesn't prevent adding its
    cards individually later
    Given the user has dismissed or snoozed a bundle-suggestion nudge
    When the user later opens "Add a card" on their own
    Then every card that would have been in the bundle is still
      available to add individually
    And nothing about the dismissed bundle blocks or hides them
