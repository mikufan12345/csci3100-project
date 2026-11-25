Feature: Publish a rulebook
  A studio admin keeps one current public rulebook. Publishing a draft
  archives the previous public version. The draft's summary and modules
  freeze once it leaves draft.

  Background:
    Given the studio "Neon Dice Co." exists
    And the studio "Dragon's Lair Designs" exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And an admin "bob@example.com" in the studio "Dragon's Lair Designs"
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And an arbiter "dave@example.com" in the studio "Neon Dice Co."
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Gloomhaven Remix" has a module "Magic"

  Scenario: An admin saves a draft with the next version number
    When "alice@example.com" saves a draft of "Gloomhaven Remix" with summary "Players win by emptying the deck." including "Combat, Magic"
    Then the latest version of "Gloomhaven Remix" is draft number 1
    And the game "Gloomhaven Remix" has 0 public versions

  Scenario: Saving a draft does not archive the current public version
    Given the game "Gloomhaven Remix" has a public version 1 with summary "The first public rules." including "Combat"
    When "alice@example.com" saves a draft of "Gloomhaven Remix" with summary "A second draft." including "Combat, Magic"
    Then version 1 of "Gloomhaven Remix" is public
    And the latest version of "Gloomhaven Remix" is draft number 2
    And the game "Gloomhaven Remix" has 1 public versions

  Scenario: Publishing a draft archives the previous public version
    Given the game "Gloomhaven Remix" has a public version 1 with summary "The first public rules." including "Combat"
    And the game "Gloomhaven Remix" has a draft version 2 with summary "The revised rules." including "Combat, Magic"
    When "alice@example.com" publishes version 2 of "Gloomhaven Remix"
    Then version 1 of "Gloomhaven Remix" is archived
    And version 2 of "Gloomhaven Remix" is public
    And the game "Gloomhaven Remix" has 1 public versions

  Scenario: A draft with no summary cannot be published
    Given the game "Gloomhaven Remix" has an incomplete draft version 1
    When "alice@example.com" publishes version 1 of "Gloomhaven Remix"
    Then the response is a 422
    And version 1 of "Gloomhaven Remix" is draft

  Scenario: A playtester cannot publish by a direct request
    Given the game "Gloomhaven Remix" has a public version 1 with summary "The first public rules." including "Combat"
    And the game "Gloomhaven Remix" has a draft version 2 with summary "The revised rules." including "Magic"
    When "carol@example.com" publishes version 2 of "Gloomhaven Remix"
    Then the response is a 403
    And version 1 of "Gloomhaven Remix" is public
    And version 2 of "Gloomhaven Remix" is draft

  Scenario: An arbiter cannot publish by a direct request
    Given the game "Gloomhaven Remix" has a draft version 1 with summary "The revised rules." including "Combat"
    When "dave@example.com" publishes version 1 of "Gloomhaven Remix"
    Then the response is a 403
    And version 1 of "Gloomhaven Remix" is draft

  Scenario: Another studio's admin cannot open this version
    Given the game "Gloomhaven Remix" has a public version 1 with summary "The first public rules." including "Combat"
    When "bob@example.com" opens version 1 of "Gloomhaven Remix"
    Then the response is a 404

  Scenario: A published summary is immutable
    Given the game "Gloomhaven Remix" has a public version 1 with summary "The first public rules." including "Combat"
    When "alice@example.com" posts summary "Secretly rewritten." for version 1 of "Gloomhaven Remix"
    Then version 1 of "Gloomhaven Remix" still has summary "The first public rules."
