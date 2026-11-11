Feature: Studio isolation
  A user can only ever see or touch records belonging to their own studio,
  and can only perform the actions their role permits. Records outside the
  user's studio are indistinguishable from nonexistent ones (404, never a
  403 that leaks their existence).

  Background:
    # alice = admin of Studio A, bob = admin of Studio B, carol = playtester in Studio A
    Given the studio "Neon Dice Co." exists
    And the studio "Dragon's Lair Designs" exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And an admin "bob@example.com" in the studio "Dragon's Lair Designs"

  Scenario: An admin only sees their own studio's games
    Given the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the studio "Dragon's Lair Designs" has a game "Lorebreakers"
    When alice signs in and visits the games page
    Then she sees "Gloomhaven Remix"
    And she does not see "Lorebreakers"

  Scenario: A foreign studio's game is indistinguishable from nonexistent
    Given the studio "Dragon's Lair Designs" has a game "Lorebreakers"
    When alice signs in and visits that game's page
    Then the response is a 404

  Scenario: A playtester cannot create games
    Given a playtester "carol@example.com" in the studio "Neon Dice Co."
    When carol signs in and tries to create a game
    Then the response is a 403

  Scenario: A studio admin can create a game in their own studio
    When alice signs in and creates the game "Kaiju Dice"
    Then the studio "Neon Dice Co." lists a game "Kaiju Dice"