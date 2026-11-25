Feature: Archived feedback is read-only
  Once a session's rulebook version is archived, no user can change that
  feedback or that session's playtime and scenario count.

  Background:
    Given the studio "Neon Dice Co." exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And an arbiter "dave@example.com" in the studio "Neon Dice Co."
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Gloomhaven Remix" has a public version 1 with summary "Rules that will be archived." including "Combat"
    And "carol@example.com" has a session of 50 minutes and 4 scenarios on version 1 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Keep this sentence." on "Combat" of "Gloomhaven Remix" with severity high
    And version 1 of "Gloomhaven Remix" is now archived

  Scenario: An arbiter cannot change the verdict
    When "dave@example.com" marks the feedback "Keep this sentence." as valid_bug
    Then the response is a 403
    And the feedback "Keep this sentence." has status unreviewed
    And the comments on "Keep this sentence." are "Keep this sentence."

  Scenario: An admin cannot change the verdict
    When "alice@example.com" marks the feedback "Keep this sentence." as working_as_intended
    Then the response is a 403
    And the feedback "Keep this sentence." has status unreviewed

  Scenario: An admin cannot change the archived session's playtime
    When "alice@example.com" changes the session of "carol@example.com" on "Gloomhaven Remix" to 5 minutes
    Then the session on version 1 of "Gloomhaven Remix" still has 50 minutes and 4 scenarios

  Scenario: Posted comments on archived feedback do not stick
    When "dave@example.com" posts comments "Tampered sentence." and status valid_bug for the feedback "Keep this sentence."
    Then the comments on "Keep this sentence." are "Keep this sentence."
    And the feedback "Keep this sentence." has status unreviewed
    And the feedback "Keep this sentence." has severity high
    And the feedback "Keep this sentence." has priority normal
