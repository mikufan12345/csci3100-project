Feature: Studio membership
  Registration founds a studio or joins one as a playtester.
  A studio admin appoints arbiters. Nobody promotes themselves, and nobody
  edits a member of another studio.

  Background:
    Given the studio "Neon Dice Co." exists
    And the studio "Dragon's Lair Designs" exists
    And an admin "alice@example.com" in the studio "Neon Dice Co."
    And an admin "bob@example.com" in the studio "Dragon's Lair Designs"
    And a playtester "carol@example.com" in the studio "Neon Dice Co."

  Scenario: Registration shows a studio name and rejects a blank one
    When a visitor opens the sign up page
    Then she sees "Studio name"
    When a visitor registers "nameless@example.com" with studio ""
    Then no user "nameless@example.com" exists

  Scenario: The first registration for a new studio name founds it as admin
    When a visitor registers "founder@example.com" with studio "Fresh Tabletop Co."
    Then "founder@example.com" is a studio_admin in "Fresh Tabletop Co."

  Scenario: Joining an existing studio by a direct registration post stays a playtester
    When a visitor posts a registration for "late@example.com" as role 2 in studio "Neon Dice Co."
    Then "late@example.com" is a playtester in "Neon Dice Co."

  Scenario: A studio admin appoints a playtester as arbiter
    When "alice@example.com" sets the role of "carol@example.com" to arbiter
    Then "carol@example.com" is an arbiter in "Neon Dice Co."

  Scenario: A studio admin cannot change their own role
    When "alice@example.com" sets the role of "alice@example.com" to playtester
    Then "alice@example.com" is still a studio_admin

  Scenario: A studio admin cannot create a second studio admin
    When "alice@example.com" sets the role of "carol@example.com" to studio_admin
    Then "carol@example.com" is still a playtester

  Scenario: A playtester cannot appoint roles
    When "carol@example.com" sets the role of "alice@example.com" to playtester
    Then the response is a 403
    And "alice@example.com" is still a studio_admin

  Scenario: An admin cannot edit a member of another studio
    When "alice@example.com" sets the role of "bob@example.com" to playtester
    Then the response is a 404
    And "bob@example.com" is still a studio_admin
