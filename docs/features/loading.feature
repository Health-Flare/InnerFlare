Feature: Loading screen quotes
  As a user opening the app
  I want a short, honest quote on the loading screen
  So that the app's offline, private philosophy is reinforced every time I
  open it, not just during onboarding

  Background:
    Given the user opens the app

  Scenario Outline: A configured quote can appear on the loading screen
    Given the loading screen is shown while local data is being read
    When loading completes
    Then the loading screen displayed one of the app's configured quotes,
      for example "<quote>"

    Examples:
      | quote                                           |
      | No cloud. No accounts. Just you.                 |
      | Your body keeps better records than you think.   |
      | Tracking you, not tracked by anyone.              |

  Scenario: A quote is chosen at random on each launch
    Given the app has more than one configured loading quote
    When the user closes and reopens the app several times
    Then the quote shown is not the same one every time
    And the choice is made on-device, with no network request involved

  Scenario: Loading screen is dismissed once the app is ready
    Given a quote is being displayed on the loading screen
    When the app finishes loading its local data
    Then the loading screen and its quote are dismissed
    And the user is taken to onboarding or the dashboard as appropriate
