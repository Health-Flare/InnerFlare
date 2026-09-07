Feature: Calendar and history
  As a user
  I want to see my logged days on a calendar and browse history
  So that I can review past cycles and fill in missed days

  Background:
    Given the user has completed onboarding
    And the user is on the dashboard

  Scenario: Days with period flow are visually distinguished
    Given the user has logged period flow on several consecutive days
    When the user opens the calendar
    Then those days are visually marked as period days
    And the flow intensity is distinguishable at a glance

  Scenario: Days with symptoms but no period are marked differently
    Given the user has logged symptoms with no period flow on a day
    When the user opens the calendar
    Then that day is marked as a symptom-only day
    And it is visually distinct from a period day

  Scenario: Selecting any day opens that day's log
    Given the user is viewing the calendar
    When the user taps any date, past or future
    Then the single-screen log UI opens for that date
    And future dates can still be pre-logged if the user chooses

  Scenario: Predicted period and fertile window are shown on the calendar
    Given the user has at least one complete prior cycle logged
    When the user opens the calendar and navigates to an upcoming month
    Then the predicted next period range is shown
    And the predicted fertile window is shown
    And both are visually labeled as estimates, not confirmed events

  Scenario: Navigating between months preserves scroll position and selection
    Given the user is viewing the current month
    When the user navigates to the previous month and back to the current month
    Then the calendar returns to today's date without losing context

  Scenario: Empty calendar before any logging
    Given the user has never logged a day
    When the user opens the calendar
    Then no days are marked as period, symptom, or predicted
    And the user sees guidance to log their first day
