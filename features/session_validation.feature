Feature: Mandatory session validation
  Feedback is stored only when the session has at least 30 minutes and at
  least 2 scenarios. The session itself may record a shorter table. After
  feedback exists, that session's numbers are frozen.

  Background:
    Given the studio "Neon Dice Co." exists
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Gloomhaven Remix" has a public version 1 with summary "Current public rules." including "Combat"

  Scenario: Thirty minutes and two scenarios stores the feedback
    When "carol@example.com" logs 30 minutes and 2 scenarios on "Gloomhaven Remix" and submits "Long enough to count." on "Combat" with severity medium
    Then the feedback "Long enough to count." belongs to "carol@example.com" and version 1 of "Gloomhaven Remix"

  Scenario: Twenty-nine minutes stores no feedback and explains the gate
    When "carol@example.com" logs 29 minutes and 2 scenarios on "Gloomhaven Remix" and submits "Too short to count." on "Combat" with severity medium
    Then no feedback was stored
    And she sees "Playtime must be at least 30 minutes."

  Scenario: One scenario stores no feedback and explains the gate
    When "carol@example.com" logs 30 minutes and 1 scenarios on "Gloomhaven Remix" and submits "Too few scenarios." on "Combat" with severity medium
    Then no feedback was stored
    And she sees "At least 2 scenarios must be completed."

  Scenario: A short session can still be saved
    When "carol@example.com" posts a session of 10 minutes and 0 scenarios on version 1 of "Gloomhaven Remix"
    Then the saved session for "carol@example.com" on version 1 of "Gloomhaven Remix" is 10 minutes and 0 scenarios
    And no feedback was stored

  Scenario: Playtime is frozen after feedback exists
    Given "carol@example.com" has a session of 45 minutes and 3 scenarios on version 1 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Long enough to count." on "Combat" of "Gloomhaven Remix" with severity medium
    When "carol@example.com" changes their latest session on "Gloomhaven Remix" to 5 minutes
    Then the session on version 1 of "Gloomhaven Remix" still has 45 minutes and 3 scenarios
    And the comments on "Long enough to count." are "Long enough to count."
