Feature: Log a session and submit feedback
  A playtester reads the single public rulebook, logs a session on it, and
  submits feedback tied to that session and version.

  Background:
    Given the studio "Neon Dice Co." exists
    And the studio "Dragon's Lair Designs" exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And an admin "bob@example.com" in the studio "Dragon's Lair Designs"
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And a playtester "erin@example.com" in the studio "Dragon's Lair Designs"
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Gloomhaven Remix" has a module "Magic"
    And the studio "Dragon's Lair Designs" has a game "Lorebreakers"
    And the game "Lorebreakers" has a module "Heist"
    And the game "Gloomhaven Remix" has a public version 2 with summary "Current public rules." including "Combat"
    And the game "Gloomhaven Remix" has a draft version 3 with summary "Unreleased draft rules." including "Magic"
    And the game "Gloomhaven Remix" has a archived version 1 with summary "Retired rules." including "Combat"
    And the game "Lorebreakers" has a public version 1 with summary "Dragon public rules." including "Heist"

  Scenario: A playtester reads only the public rulebook
    When "carol@example.com" opens the game "Gloomhaven Remix"
    Then she sees "Current public rules."
    And she sees "Combat"
    And she does not see "Unreleased draft rules."
    And she does not see "Retired rules."

  Scenario: A qualified session stores feedback on that version
    When "carol@example.com" logs 40 minutes and 3 scenarios on "Gloomhaven Remix" and submits "The combat round runs too long." on "Combat" with severity high
    Then the feedback "The combat round runs too long." belongs to "carol@example.com" and version 2 of "Gloomhaven Remix"
    And the feedback "The combat round runs too long." has status unreviewed
    And the feedback "The combat round runs too long." has severity high

  Scenario: A short session stores no feedback
    When "carol@example.com" logs 10 minutes and 3 scenarios on "Gloomhaven Remix" and submits "Too short to count." on "Combat" with severity high
    Then no feedback was stored
    And she sees "Playtime must be at least 30 minutes."

  Scenario: A session on a draft version is rejected
    When "carol@example.com" posts a session of 40 minutes and 2 scenarios on version 3 of "Gloomhaven Remix"
    Then the response is a 422
    And "carol@example.com" has no sessions

  Scenario: A session on an archived version is rejected
    When "carol@example.com" posts a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    Then the response is a 422
    And "carol@example.com" has no sessions

  Scenario: Feedback on a module outside the version is rejected
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    When "carol@example.com" posts feedback "Magic was not in this book." on module "Magic" of "Gloomhaven Remix" for their latest session
    Then the response is a 422
    And no feedback was stored

  Scenario: Feedback on another game's module is rejected
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    When "carol@example.com" posts feedback "Wrong game." on module "Heist" of "Lorebreakers" for their latest session
    Then the response is a 422
    And no feedback was stored

  Scenario: Another studio's public version is invisible
    When "carol@example.com" opens version 1 of "Lorebreakers"
    Then the response is a 404

  Scenario: Submitted comments cannot be replaced
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Keep this sentence." on "Combat" of "Gloomhaven Remix" with severity high
    When "alice@example.com" posts comments "Tampered sentence." and status valid_bug for the feedback "Keep this sentence."
    Then the comments on "Keep this sentence." are "Keep this sentence."
