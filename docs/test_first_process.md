# Test-first process

This file is the working record of how TDD and BDD are done on this project. The rules being tested are in `docs/refined_proposal.md`. The scenarios and examples below were written before the screens, services, and columns they describe. That order is the requirement. A green suite produced by editing a scenario is not.

## The two layers

BDD is the outside of a rule. Each Cucumber feature is one user story or one business rule, written as what a person does and what must be true afterward. The step definitions drive the browser or a direct HTTP request. They do not call model methods to perform the action under test.

TDD is the inside of the same rule. RSpec examples state the boundary in Ruby: 29 minutes is rejected, 30 minutes and 2 scenarios are accepted, a second public version is invalid, comments survive a later save. Those examples go red before the validation or service exists.

Both layers stay. Cucumber proves the path a player or arbiter uses. RSpec proves the edge values that path can hide.

## Cycle for every remaining slice

1. Confirm the scenario or example fails for the missing behavior. `bundle exec cucumber features/<file>.feature` or `bin/rspec spec/<file>_spec.rb`.
2. Commit that red file by itself if it is not already in the red baseline. Message: `test: <story or rule>`.
3. Write the smallest implementation that makes that file pass. Do not change the scenario text, the expected sentence, or the status code to fit whatever the code currently does.
4. Run the whole suite. Earlier green scenarios must stay green.
5. Commit the implementation. Message: `feat: <same story or rule>`.

Business Rule 1 is the iteration the README will cite. Its red side is `features/session_validation.feature` and the playtime examples in `spec/models/feedback_spec.rb`. Its green side will be the validation, in a later commit. The tenancy work in `c8dcdf9` landed tests and code together, so it is not this example.

## What was added

61 Cucumber scenarios, all matched to a step definition (`bundle exec cucumber -p dryrun` reports 61 scenarios, 0 undefined). 47 RSpec examples.

| File | Layer | Covers |
|---|---|---|
| `features/studio_isolation.feature` | BDD | Tenancy, blank title, title search |
| `features/membership.feature` | BDD | Signup, joining, appointing an arbiter |
| `features/publish_rulebook.feature` | BDD | Story 1 |
| `features/log_session_and_feedback.feature` | BDD | Story 2 |
| `features/triage_feedback.feature` | BDD | Story 3 |
| `features/session_validation.feature` | BDD | BR1, the graded example |
| `features/reevaluate_on_publish.feature` | BDD | BR2 |
| `features/priority_escalation.feature` | BDD | BR3 and the admin report |
| `features/archived_feedback_readonly.feature` | BDD | BR4 |
| `spec/models/user_spec.rb` | TDD | Signup and roles |
| `spec/models/game_project_spec.rb` | TDD | Title required |
| `spec/models/rulebook_version_spec.rb` | TDD | One public version, frozen summary |
| `spec/models/playtest_session_spec.rb` | TDD | Public version only, frozen playtime |
| `spec/models/feedback_spec.rb` | TDD | BR1, immutable comments, archived status |
| `spec/services/publish_rulebook_version_spec.rb` | TDD | Story 1 and BR2 |
| `spec/services/escalate_feedback_spec.rb` | TDD | BR3 |
| `spec/requests/game_projects_spec.rb` | TDD | 404, 403, blank title |
| `spec/requests/permissions_spec.rb` | TDD | Direct publish, triage, and role URLs |

Step definitions live in `features/step_definitions/playtest_steps.rb` and `features/studio_isolation_steps.rb`. Shared words and paths live in `features/support/playtest_domain.rb`. Record builders for RSpec live in `spec/support/playtest_fixtures.rb`.

Givens create records directly so a scenario fails on the rule it names. Whens use the screen or a direct request. A historical row that must already be archived is planted with `save!(validate: false)` in one Given only (`has historical feedback`). Every other create goes through validation, so the rules can fail those creates.

## Commands

PostgreSQL has to be running. `config/database.yml` on this Windows machine needs `host: localhost` under `development` and `test`.

```text
bin/rspec
bundle exec cucumber
bundle exec cucumber -p dryrun
bundle exec rake test:all
```

`dryrun` only checks that every step has a definition. It does not tell you the rules pass. `rake test:all` runs RSpec and then Cucumber, and it fails if either fails.

GitHub Actions runs the same two commands on every push. Cucumber is no longer marked `continue-on-error`. A red scenario fails the workflow. That is the red baseline. Do not put `continue-on-error` back to make the badge green.

The author could not execute the suite here: nothing was accepting connections on `localhost:5432`. Syntax of the new Ruby files was checked, and the Cucumber dry run matched every step. The pass/fail split below is from reading the current models against the examples, not from a green run. Re-run both commands once Postgres is up and treat that output as the record.

## What should already pass

These lock behavior that is already in the app. If one of them fails, fix the test harness or a regression. Do not delete it.

- `spec/models/user_spec.rb`: founding a studio, joining one, blank studio name, known roles, and a posted admin role that still saves as playtester.
- `spec/models/playtest_session_spec.rb`: a session of 10 minutes and 0 scenarios can be stored.
- `spec/models/feedback_spec.rb`: a feedback row with comments and a session saves. This does not yet prove the 30-minute gate.
- `spec/models/rulebook_version_spec.rb`: a draft can sit beside one public version.
- `spec/requests/game_projects_spec.rb`: another studio's game is 404, and a playtester who posts a game is 403.
- `features/studio_isolation.feature`: the four original scenarios (own games, foreign 404, playtester 403, admin create).

## What should fail until the code exists

A failure is the point. The first error is often `unknown attribute` or `uninitialized constant`, because `summary`, `severity`, `priority`, `RulebookInclusion`, `Escalation`, and `PublishRulebookVersion` are not in the app yet. After the migration and the empty class exist, the same example must fail on the expectation (the status did not change, the row was stored, the response was 404 instead of 403). Only then does the real rule get written.

Do not rescue those errors in the specs. Do not drop `severity:` from an example to make it load.

Expected red groups:

- BR1 messages `Playtime must be at least 30 minutes.` and `At least 2 scenarios must be completed.`
- Blank game title, required role, second public version, frozen summary, frozen playtime, frozen comments.
- Sessions on a draft, an archived version, or another studio's version.
- `PublishRulebookVersion.new(version:, deprecate_module_ids:, replacements:).call`
- Escalation after the third distinct playtester, and not before.
- Direct requests: playtester or arbiter publish is 403, triage list for a playtester is 403, another studio's version or feedback is 404, appointing across studios is 404.

## Contract the steps already assume

Implement against these names. Changing a label or a path means changing a scenario, which is not allowed while making a slice pass.

| Action | Request | Fields and labels |
|---|---|---|
| Sign up | `GET /users/sign_up`, `POST /users` | Email, Password, Password confirmation, Studio name. Button "Sign up". |
| Appoint a role | `PATCH /studio_members/:id` | `user[role]` is `playtester` or `arbiter`. |
| Search games | `GET /?q=` | The games page shows only matching titles from the signed-in studio. |
| Save a draft | Game page | Labels "Summary" and a checkbox per module title. Button "Save draft". |
| Publish | `POST /rulebook_versions/:id/publish` | `deprecate_ids[]`. `replacements[<old id>]` = new module id. |
| Edit a version | `PATCH /rulebook_versions/:id` | `rulebook_version[summary]`. Refused once the version is not draft. |
| Read a version | `GET /rulebook_versions/:id` | 404 outside the studio. |
| Log a session | Game page, and `POST /rulebook_versions/:id/playtest_sessions` | "Playtime minutes", "Scenarios completed", button "Log session". |
| Submit feedback | Game page after logging, and `POST /playtest_sessions/:id/feedbacks` | "Rule module", "Severity" (`low`, `medium`, `high`), "Comments", button "Submit feedback". |
| Triage | `GET /feedbacks`, `PATCH /feedbacks/:id` | Query `status`, `severity`, `priority`, `game_project_id`. Empty filter shows the text `No feedback`. Status values posted as words: `valid_bug`, `working_as_intended`. |
| Report | `GET /escalations?game_project_id=` | Shows module title and severity for that game only. |
| Change playtime | `PATCH /playtest_sessions/:id` | `playtest_session[playtime_minutes]`. |

Validation failures from those posts are HTTP 422. The wrong role on an in-studio action is 403 with the existing plain body `forbidden`. Another studio's id is 404 with the existing plain body `not found`.

Status numbers, unchanged from the proposal: feedback `unreviewed` 0, `valid_bug` 1, `working_as_intended` 2, `re_evaluation` 3. Versions `draft` 0, `public` 1, `archived` 2. Severity `low` 0, `medium` 1, `high` 2. Priority `normal` 0, `escalated` 1.

`PublishRulebookVersion` is the only object the publish specs construct. Escalation is observed by saving feedback, not by calling a service from the spec, so the callback and the controller can share one implementation.

## How to turn BR1 green

This is the shape of every later slice, and it is the one the README must describe with two commit SHAs.

1. Run `bin/rspec spec/models/feedback_spec.rb` and `bundle exec cucumber features/session_validation.feature`. Confirm they fail.
2. Commit if this red baseline is not committed yet.
3. Add the feedback validation and the two exact sentences. A session below the gate still saves. After a feedback row exists, playtime and scenario count do not change.
4. Re-run those two files, then `bundle exec rake test:all`.
5. Commit the validation. In the README, name Story 2, BR1, the red SHA, the green SHA, the two commands, and the Actions URL of the green commit.

Leave the other features red. Do not implement publish, triage, and escalation in that same commit.
