Feature: Priority escalation
  Three distinct playtesters submitting the same module and the same severity
  create one escalation and raise priority on feedback that is not archived.
  The same playtester does not count three times. Archived rows count toward
  the three and are not updated.

  Background:
    Given the studio "Neon Dice Co." exists
    And a playtester "carol@example.com" in the studio "Neon Dice Co."
    And a playtester "frank@example.com" in the studio "Neon Dice Co."
    And a playtester "grace@example.com" in the studio "Neon Dice Co."
    And a playtester "helen@example.com" in the studio "Neon Dice Co."
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And the studio "Neon Dice Co." has a game "Gloomhaven Remix"
    And the studio "Neon Dice Co." has a game "Quiet Dice"
    And the game "Gloomhaven Remix" has a module "Combat"
    And the game "Quiet Dice" has a module "Bidding"
    And the game "Gloomhaven Remix" has a public version 2 with summary "Current public rules." including "Combat"
    And the game "Quiet Dice" has a public version 1 with summary "Bidding rules." including "Bidding"

  Scenario: Two playtesters do not escalate
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank on combat." on "Combat" of "Gloomhaven Remix" with severity high
    Then no escalation exists
    And the feedback "Carol on combat." has priority normal
    And the feedback "Frank on combat." has priority normal

  Scenario: Three sessions from one playtester do not escalate
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol first." on "Combat" of "Gloomhaven Remix" with severity high
    And "carol@example.com" has a session of 41 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol second." on "Combat" of "Gloomhaven Remix" with severity high
    And "carol@example.com" has a session of 42 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol third." on "Combat" of "Gloomhaven Remix" with severity high
    Then no escalation exists

  Scenario: The third distinct playtester creates one escalation
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "grace@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "grace@example.com" left unreviewed feedback "Grace on combat." on "Combat" of "Gloomhaven Remix" with severity high
    Then one escalation exists for "Combat" at severity high
    And the feedback "Carol on combat." has priority escalated
    And the feedback "Frank on combat." has priority escalated
    And the feedback "Grace on combat." has priority escalated
    And 1 escalations exist

  Scenario: A fourth playtester joins the same escalation
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "grace@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "grace@example.com" left unreviewed feedback "Grace on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "helen@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "helen@example.com" left unreviewed feedback "Helen on combat." on "Combat" of "Gloomhaven Remix" with severity high
    Then 1 escalations exist
    And one escalation exists for "Combat" at severity high
    And the feedback "Helen on combat." has priority escalated

  Scenario: A different severity does not match
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol high." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank high." on "Combat" of "Gloomhaven Remix" with severity high
    And "grace@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "grace@example.com" left unreviewed feedback "Grace low." on "Combat" of "Gloomhaven Remix" with severity low
    Then no escalation exists
    And the feedback "Grace low." has priority normal

  Scenario: Archived feedback counts and is not updated
    Given the game "Gloomhaven Remix" has a archived version 1 with summary "Retired rules." including "Combat"
    And "helen@example.com" has historical feedback "Helen on the old book." on version 1 of "Gloomhaven Remix" module "Combat" with severity high
    And "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank on combat." on "Combat" of "Gloomhaven Remix" with severity high
    Then one escalation exists for "Combat" at severity high
    And the feedback "Carol on combat." has priority escalated
    And the feedback "Frank on combat." has priority escalated
    And the feedback "Helen on the old book." has priority normal
    And the feedback "Helen on the old book." is not linked to an escalation
    And the comments on "Helen on the old book." are "Helen on the old book."

  Scenario: A posted priority does not escalate a single report
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    When "carol@example.com" posts feedback "Please escalate me." on module "Combat" of "Gloomhaven Remix" for their latest session
    Then the feedback "Please escalate me." has priority normal
    And no escalation exists

  Scenario: The admin report lists the escalation and filters by game
    Given "carol@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "carol@example.com" left unreviewed feedback "Carol on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "frank@example.com" left unreviewed feedback "Frank on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "grace@example.com" has a session of 40 minutes and 2 scenarios on version 2 of "Gloomhaven Remix"
    And "grace@example.com" left unreviewed feedback "Grace on combat." on "Combat" of "Gloomhaven Remix" with severity high
    And "carol@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Quiet Dice"
    And "frank@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Quiet Dice"
    And "grace@example.com" has a session of 40 minutes and 2 scenarios on version 1 of "Quiet Dice"
    And "carol@example.com" left unreviewed feedback "Carol on bidding." on "Bidding" of "Quiet Dice" with severity low
    And "frank@example.com" left unreviewed feedback "Frank on bidding." on "Bidding" of "Quiet Dice" with severity low
    And "grace@example.com" left unreviewed feedback "Grace on bidding." on "Bidding" of "Quiet Dice" with severity low
    When "alice@example.com" filters the escalation report to the game "Gloomhaven Remix"
    Then she sees "Combat"
    And she sees "high"
    And she does not see "Bidding"
