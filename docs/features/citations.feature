Feature: Sources for estimates
  As a user
  I want to see how each estimate is calculated and where its assumptions come from
  So that I can judge how much to trust it

  # App Review Guideline 1.4.1: health information needs citations the user
  # can find easily. Sources live in lib/core/citations/medical_sources.dart.

  Scenario: Sources are one tap from every prediction
    Given the user can see a predicted period or fertile window on Insights
    When they tap "How is this calculated?"
    Then they see "How estimates work"

  Scenario: Sources are reachable from Insights with no data
    Given the user has never logged a period start
    When they tap the info button on Insights
    Then they see "How estimates work"

  Scenario: Sources are reachable from the calendar legend
    When the user taps the info button next to the calendar legend
    Then they see "How estimates work"

  Scenario: Sources are reachable from Settings
    When the user opens Settings
    Then "How estimates work" is listed under About

  Scenario: Every assumption shows its source
    When the user views "How estimates work"
    Then each estimate explains how it is calculated
    And each estimate lists at least one published source as a full citation
    And the page says these are estimates, not medical advice or a diagnosis

  Scenario: A source opens in the browser
    When the user taps a citation
    Then the original publication opens in the system browser
    And Inner Flare itself makes no network request

  Scenario: A link that cannot open fails quietly
    Given the system browser cannot open the link
    When the user taps a citation
    Then the app shows "Could not open that link."

  Scenario: The fertile window states its assumption
    Given the user can see a predicted fertile window on Insights
    Then its caveat says it assumes ovulation about 14 days before the next period
    And that this varies from about 7 to 19 days
    And that it is not contraception
