Feature: Re-evaluation on publish
  Publishing a version that deprecates or replaces a module stamps eligible
  feedback on older versions as re_evaluation. Terminal verdicts and the
  playtester's comments stay as they were. Nothing is deleted.

  Background:
    Given the studio "Neon Dice Co." exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And a playtester "frank@example.com" in the studio "Neon Dice Co."
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Gloomhaven Remix" has a module "Magic"
    And the game "Gloomhaven Remix" has a public version 1 with summary "Old public rules." including "Combat, Magic"
    And the game "Gloomhaven Remix" has a draft version 2 with summary "New public rules." including "Magic"
    And "carol@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Combat takes too many dice." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Gloomhaven Remix"
    And "frank@example.com" left valid_bug feedback "The timing window is wrong." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" left working_as_intended feedback "This rule works at the table." on "Magic" of "Gloomhaven Remix" with severity low

  Scenario: Deprecating a module stamps eligible older feedback and leaves the rest
    When "alice@example.com" publishes version 2 of "Gloomhaven Remix" deprecating "Combat"
    Then the feedback "Combat takes too many dice." has status re_evaluation
    And the feedback "The timing window is wrong." has status re_evaluation
    And the feedback "This rule works at the table." has status working_as_intended
    And the comments on "Combat takes too many dice." are "Combat takes too many dice."
    And the comments on "The timing window is wrong." are "The timing window is wrong."
    And the feedback "Combat takes too many dice." has severity high
    And the feedback "Combat takes too many dice." has priority normal
    And 3 feedback rows exist
    And version 1 of "Gloomhaven Remix" is archived
    And version 2 of "Gloomhaven Remix" is public
    And the game "Gloomhaven Remix" has 1 public versions

  Scenario: Replacing a module stamps that module's eligible feedback
    When "alice@example.com" publishes version 2 of "Gloomhaven Remix" replacing "Combat" with "Magic"
    Then the feedback "Combat takes too many dice." has status re_evaluation
    And the feedback "The timing window is wrong." has status re_evaluation
    And the feedback "This rule works at the table." has status working_as_intended
    And the comments on "This rule works at the table." are "This rule works at the table."

  Scenario: Publishing without a deprecation or replacement does not stamp feedback
    When "alice@example.com" publishes version 2 of "Gloomhaven Remix"
    Then the feedback "Combat takes too many dice." has status unreviewed
    And the feedback "The timing window is wrong." has status valid_bug
    And version 2 of "Gloomhaven Remix" is public

  Scenario: An existing re_evaluation stamp is left alone
    Given "carol@example.com" left re_evaluation feedback "Already stamped." on "Combat" of "Gloomhaven Remix" with severity medium
    When "alice@example.com" publishes version 2 of "Gloomhaven Remix" deprecating "Combat"
    Then the feedback "Already stamped." has status re_evaluation
    And the comments on "Already stamped." are "Already stamped."
