Feature: Triage feedback
  A rules arbiter filters the studio's feedback and sets a verdict on
  feedback whose rulebook is still public. The playtester's comments never
  change. Another studio's feedback is a 404.

  Background:
    Given the studio "Neon Dice Co." exists
    And the studio "Dragon's Lair Designs" exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And an admin "bob@example.com" in the studio "Dragon's Lair Designs"
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And a playtester "frank@example.com" in the studio "Neon Dice Co."
    And an arbiter "dave@example.com" in the studio "Neon Dice Co."
    And a playtester "erin@example.com" in the studio "Dragon's Lair Designs"
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Gloomhaven Remix" has a public version 1 with summary "Current public rules." including "Combat"
    And the studio "Neon Dice Co." has a game "Quiet Dice"
    And the game "Quiet Dice" has a module "Bidding"
    And the game "Quiet Dice" has a public version 1 with summary "Bidding rules." including "Bidding"
    And the studio "Dragon's Lair Designs" has a game "Lorebreakers"
    And the game "Lorebreakers" has a module "Heist"
    And the game "Lorebreakers" has a public version 1 with summary "Dragon public rules." including "Heist"
    And "carol@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "The combat round runs too long." on "Combat" of "Gloomhaven Remix" with severity high
    And "carol@example.com" left valid_bug feedback "The timing window is wrong." on "Combat" of "Gloomhaven Remix" with severity high
    And "erin@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Lorebreakers"
    And "erin@example.com" left unreviewed feedback "The heist timer is fine." on "Heist" of "Lorebreakers" with severity low

  Scenario: The default list is the studio's unreviewed feedback
    When "dave@example.com" opens the feedback list
    Then she sees "The combat round runs too long."
    And she does not see "The heist timer is fine."

  Scenario: An arbiter filters by status and severity
    When "dave@example.com" filters feedback with status unreviewed and severity low
    Then the response is a 200
    And she sees "No feedback"
    And she does not see "The combat round runs too long."

  Scenario: An arbiter marks public feedback as a valid bug
    When "dave@example.com" marks the feedback "The combat round runs too long." as valid_bug
    Then the feedback "The combat round runs too long." has status valid_bug
    And the comments on "The combat round runs too long." are "The combat round runs too long."

  Scenario: An arbiter marks public feedback as working as intended
    When "dave@example.com" marks the feedback "The combat round runs too long." as working_as_intended
    Then the feedback "The combat round runs too long." has status working_as_intended

  Scenario: A status update ignores posted comments, severity, and priority
    When "dave@example.com" posts comments "Tampered sentence." and status valid_bug for the feedback "The combat round runs too long."
    Then the comments on "The combat round runs too long." are "The combat round runs too long."
    And the feedback "The combat round runs too long." has severity high
    And the feedback "The combat round runs too long." has priority normal
    And the feedback "The combat round runs too long." has status valid_bug

  Scenario: A playtester cannot open the triage list
    When "carol@example.com" opens the feedback list
    Then the response is a 403

  Scenario: A playtester cannot change status
    When "carol@example.com" marks the feedback "The combat round runs too long." as valid_bug
    Then the response is a 403
    And the feedback "The combat round runs too long." has status unreviewed

  Scenario: Archived feedback rejects a verdict
    Given version 1 of "Gloomhaven Remix" is now archived
    When "dave@example.com" marks the feedback "The combat round runs too long." as valid_bug
    Then the response is a 403
    And the feedback "The combat round runs too long." has status unreviewed
    And the comments on "The combat round runs too long." are "The combat round runs too long."

  Scenario: Another studio's feedback is a 404
    When "dave@example.com" opens feedback "The heist timer is fine." directly
    Then the response is a 404

  Scenario: The default list hides reviewed rows
    When "dave@example.com" opens the feedback list
    Then she sees "The combat round runs too long."
    And she does not see "The timing window is wrong."

  Scenario: An arbiter can list every status explicitly
    When "dave@example.com" filters feedback with status all
    Then she sees "The timing window is wrong."
    And she sees "The combat round runs too long."

  Scenario: An arbiter filters by priority and by game
    Given "frank@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "dave@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    And "dave@example.com" left unreviewed feedback "Dave on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "carol@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Quiet Dice"
    And "carol@example.com" left unreviewed feedback "Carol on bidding." on "Bidding" of "Quiet Dice" with severity low
    When "dave@example.com" filters feedback with priority escalated
    Then she sees "Frank on combat."
    And she sees "The combat round runs too long."
    And she does not see "Carol on bidding."
    When "dave@example.com" filters feedback to the game "Gloomhaven Remix"
    Then she sees "The combat round runs too long."
    And she does not see "Carol on bidding."

  Scenario: A playtester reads only their own feedback
    Given "frank@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank at the table." on "Combat" of "Gloomhaven Remix" with severity low
    When "carol@example.com" opens feedback "Frank at the table." directly
    Then the response is a 404
    When "carol@example.com" opens feedback "The combat round runs too long." directly
    Then the response is a 200
    And she sees "The combat round runs too long."

  Scenario: Feedback against another studio's session is a 404
    When "carol@example.com" tries to give feedback on "erin@example.com"'s latest session
    Then the response is a 404
