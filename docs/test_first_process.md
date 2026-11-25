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

Business Rule 1 is the iteration the README will cite. Its red side is `803628e` (`features/session_validation.feature` and the playtime examples in `spec/models/feedback_spec.rb`). Its green side is `33179ca`. The tenancy work in `c8dcdf9` landed tests and code together, so it is not this example. The run record is `docs/work_log.md`.

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

PostgreSQL has to be running. `config/database.yml` sets `host: localhost` in the `default` block. On this machine the server is the portable PostgreSQL 16.11 tree under `%LOCALAPPDATA%\pgsql`, started with `postgres.exe -D %LOCALAPPDATA%\pgsql\data`. There is no Windows service. The checked results are in `docs/work_log.md`.

```text
bin/rspec
bundle exec cucumber
bundle exec cucumber -p dryrun
bundle exec rake test:all
```

`dryrun` only checks that every step has a definition. It does not tell you the rules pass. `rake test:all` runs RSpec and then Cucumber, and it fails if either fails.

GitHub Actions runs the same two commands on every push. Cucumber is no longer marked `continue-on-error`. A red scenario fails the workflow. That is the red baseline. Do not put `continue-on-error` back to make the badge green.

Before PostgreSQL was available, the Cucumber dry run matched every step. On 2026-11-25 the lists below were checked against PostgreSQL. Business Rule 1, Story 1, and Story 2 are in the pass list. Later slices in the fail list are still red. Quote `docs/work_log.md` for the commands and the counts. `bundle exec rake test:all` was not run as one command. RSpec and Cucumber were run separately.

## What should already pass

These lock behavior that is already in the app. If one of them fails, fix the test harness or a regression. Do not delete it.

- `spec/models/user_spec.rb`: founding a studio, joining one, blank studio name, known roles, and a posted admin role that still saves as playtester. `requires a role` stays in the fail list.
- `spec/models/playtest_session_spec.rb`: a session of 10 minutes and 0 scenarios can be stored. A draft version, an archived version, and another studio's version are rejected. After feedback exists, playtime and scenario count stay frozen.
- `spec/models/feedback_spec.rb`: 30 minutes and 2 scenarios saves. Under 30 minutes is rejected with `Playtime must be at least 30 minutes.` Under 2 scenarios is rejected with `At least 2 scenarios must be completed.` Comments are required. An explicit nil severity is rejected. A module that is not in the version is rejected. A later save cannot replace the comments. An archived status change and a posted priority stay in the fail list.
- `spec/models/game_project_spec.rb`: a whitespace title is rejected, and a game belongs to its studio.
- `spec/models/rulebook_version_spec.rb`: a draft can sit beside one public version. A second public version is invalid. A public version needs a summary. A summary change after the version leaves draft does not persist.
- `spec/services/publish_rulebook_version_spec.rb`: publishing archives the previous public version. The two examples that expect feedback to stay unchanged pass because this slice does not write feedback. The two stamp examples stay red.
- `spec/requests/game_projects_spec.rb`: another studio's game is 404, a playtester who posts a game is 403, and a blank title returns 422 and creates no game.
- `spec/requests/permissions_spec.rb`: an admin who edits a member of another studio gets 404. A playtester or an arbiter who publishes gets 403. Another studio's version is 404.
- `features/studio_isolation.feature`: the four original scenarios, and the blank title scenario. Title search stays red.
- `features/membership.feature`: signup with a studio name, founding a studio, joining as a playtester, and appointing an arbiter inside the studio.
- `features/session_validation.feature`: the five Business Rule 1 scenarios.
- `features/publish_rulebook.feature`: all eight scenarios. An admin saves a draft, publishing archives the previous public version, an incomplete draft stays a draft at 422, a playtester or an arbiter who publishes gets 403, another studio's version is 404, and a summary edit on a public version does not stick.
- `features/log_session_and_feedback.feature`: all nine scenarios. The public summary is the one a playtester sees. A qualified session stores feedback. A short session stores none. A draft or archived session is 422. A module outside the version, or from another game, is 422. Another studio's version is 404. Posted comments do not replace the stored sentence.
- `features/archived_feedback_readonly.feature`: "Posted comments on archived feedback do not stick" passes because this slice does not write a verdict, a severity, or a priority. The other three scenarios stay red. That pass is not Business Rule 4.

## What should fail until the code exists

A failure is the point. `summary`, `severity`, `priority`, `RulebookInclusion`, and `PublishRulebookVersion` now exist. `Escalation` still does not. Publish archives the previous public version and does not apply the Business Rule 2 stamp. `PATCH /feedbacks/:id` rejects a new comment and does not apply a verdict. Where a column exists and the rule does not, the example must fail on the expectation, not on `unknown attribute`. Do not rescue those errors. Do not drop `severity:` from an example to make it load.

Expected red groups:

- `User roles requires a role`.
- A status change on an archived version still saves (`Feedback refuses a status change once the version is archived`, got 1, expected 0). A posted priority of 1 stays 1. `Escalation` is still uninitialized.
- `PublishRulebookVersion` stamping eligible older feedback to status 3 when a module is deprecated or replaced. `features/reevaluate_on_publish.feature` still sees status 0. The two publish examples that expect feedback to be left alone are green only because nothing writes feedback.
- Escalation after the third distinct playtester, and the admin report. `GET /escalations` has no route.
- Triage. `GET /feedbacks` has no route. A playtester list is 404 where the example expects 403. A verdict post leaves status 0 where the example expects 1. The permissions example that posts a new sentence still fails on status, which stays 0.
- Archived verdicts and archived playtime. An arbiter or admin mark returns 200 where the scenario expects 403. An admin changing another user's playtime raises `ActiveRecord::RecordNotFound`.
- Title search on the games page (`features/studio_isolation.feature`).

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

## Business Rule 1 is green

This is the shape every later slice follows, and it is the pair the README must describe.

1. The red run failed on the missing gate. The red commit is `803628e`.
2. The validation uses the two exact sentences. A session below the gate still saves. After a feedback row exists, playtime and scenario count do not change.
3. `features/session_validation.feature` then passed. The green commit is `33179ca`. It was not pushed, so there is no Actions URL yet.
4. The README still has to name Story 2, BR1, both SHAs, the two commands, and the Actions URL of the green commit after it is pushed.

`bundle exec rake test:all` was not run for this slice. The counts and the commands are in `docs/work_log.md`.

## Story 1 is green

Work-plan slice 2. The red scenarios were already in `803628e`.

1. An admin saves a draft with a summary and the checked modules. The next version number is used. Saving a draft leaves the current public version public.
2. `PublishRulebookVersion.new(version:, deprecate_module_ids:, replacements:).call` locks that game's versions, archives the previous public version, and sets the draft public. A blank summary stays a draft and rolls the archive back. The deprecation and replacement arguments are accepted and not applied.
3. A game title of whitespace is rejected. The broken "Save game" form is gone. The admin game page lists each draft and posts "Publish version N".
4. `features/publish_rulebook.feature` passed: 8 scenarios. The green commit is `6e0bfc1`. It was not pushed, so there is no Actions URL yet.
5. The two Business Rule 2 stamp examples still fail: status stays 0 where the example expects 3. That stamp is a later slice.

## Story 2 is green

Work-plan slice 3, except the Business Rule 1 gate, which was already green in `33179ca`. The red scenarios were already in `803628e`.

1. A session is valid only when its rulebook version is public and belongs to the player's studio. A shorter session can still be saved. The feedback gate is unchanged.
2. Feedback requires comments and a severity of 0, 1, or 2. An omitted severity defaults to low so the older play-gate examples still build a row. An explicit nil severity is invalid. The module has to be included in that version.
3. On update, a change to comments adds an error and the save does not persist. `PATCH /feedbacks/:id` assigns a posted comment so the model can reject it. It does not assign status, severity, or priority.
4. `features/log_session_and_feedback.feature` passed: 9 scenarios, inside the full Cucumber run. The green commit is `b213a97`. It was not pushed, so there is no Actions URL yet.
5. One archived-feedback scenario passes because no verdict is written. The archive freeze itself is still red.
