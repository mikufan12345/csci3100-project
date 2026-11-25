# CSCI 3100 Refined Project Specification

Tabletop Game Playtesting Platform. This document replaces `3100_proposal.pdf` as the build specification. Where the PDF is ambiguous or internally inconsistent, this document is the rule the software, the tests, and the README follow.

| | |
|---|---|
| Members | Tsang Chi Kiu, Wong Mo Tien |
| Student IDs | Recorded on the Blackboard proposal PDF. Omitted here so the public repository follows the course rule that student IDs stay out of the repo. |
| Topic | Option F, open topic. A small multi-tenant SaaS product. |
| Repository | https://github.com/mikufan12345/csci3100-project |
| Runtime | Ruby 3.3.8, Rails 7.1.5 (Gemfile `~> 7.1.5`, `>= 7.1.5.2`), PostgreSQL 16 |
| Tests | RSpec for unit and request behavior, Cucumber for acceptance |
| Coverage | SimpleCov on `app/`, gate at 80% line coverage, reported from GitHub Actions |
| Deployment | Render web service plus a managed PostgreSQL database |
| Final deadline | 11 December 2026, 23:59 HKT |

Option F is met by studio tenancy and three roles. The product does not take payments, does not gamble, does not collect real personal data, and does not connect to CUHK systems. Demo data is synthetic. The deployed site is labeled as a course demonstration.

## 1. Problem, users, and organizations

Indie tabletop designers lose playtest notes in spreadsheets: feedback is tied to the wrong rulebook, short sessions are treated as evidence, and a new draft does not say which old reports are stale.

The users are studio designers, invited playtesters, and rules editors. Each **Studio** is one tenant, for example Neon Dice Co. and Dragon's Lair Designs. A studio owns its users, games, rule modules, rulebook versions, sessions, feedback, and escalations. A user belongs to exactly one studio.

Isolation is an acceptance rule, not only a schema comment. A signed-in user who requests another studio's record by id, including through a direct URL or a crafted POST, gets **404**. The response does not say whether the record exists. A signed-in user who requests an in-studio action their role forbids gets **403**. Guests are redirected to sign-in for every page except the public landing page, which lists no games.

## 2. Roles and membership

`users.role` is an integer.

| Value | Role | May do |
|---|---|---|
| 0 | Playtester | Read the studio's games and the single public rulebook. Log a session against that public version. Submit feedback. Read their own feedback. |
| 1 | Rules arbiter | Everything a playtester may do, plus list and filter all feedback in the studio, and change `status` on feedback whose rulebook version is still public. |
| 2 | Studio admin | Create and rename games, manage modules and draft versions, publish a version, appoint arbiters, and read the escalation report. |

Membership:

- Registration asks for email, password, and a studio name.
- A name that matches no studio, compared case-insensitively, creates the studio and makes this user its studio admin.
- A name that matches an existing studio joins that studio as a playtester. The registrant cannot choose admin or arbiter.
- A studio admin may change another member of the same studio from playtester to arbiter, or from arbiter to playtester. The admin cannot change their own role, cannot create a second studio admin, and cannot edit a user outside the studio (404).
- Role checks in controllers go through `authorize_role!` on `StudioIsolationEnforcer`. That concern is included from `ApplicationController`. Views may hide links. The server still enforces the rule on the direct request.

Playtesters do not see other playtesters' comments. Arbiters and admins see every feedback row in their own studio. Nobody sees another studio's rows.

## 3. User stories

Each story has a Cucumber feature file. Each feature includes the happy path, the permission failure, and the cross-studio failure. Scenarios are written and run red before the production code for that story.

### Story 1. The admin publishes one current rulebook

The studio admin wants playtesters to test a single current rulebook, and wants the previous public rulebook kept as history.

Acceptance criteria:

- The admin creates a **draft** for a game in their studio. The draft has a system-assigned `version_number` (`max + 1` for that game), a non-empty summary, and one or more rule modules that belong to that game.
- The admin publishes that draft. In one database transaction the service locks the game's versions, runs Business Rule 2 for modules this publish deprecates or replaces, archives the previous public version if one exists, and sets this draft to `public`.
- A game has at most one `public` version. A second publish is impossible: the transaction archives the previous one, and a partial unique index on `(game_project_id)` where `status = public` rejects a race.
- Creating or keeping a draft does not archive anything.
- A playtester or arbiter who POSTs publish, including by a direct URL, receives 403.
- An admin of another studio who requests this game or this version receives 404.
- After a version leaves `draft`, its summary and its set of modules are immutable.

### Story 2. The playtester logs a session and submits feedback

The playtester wants the studio to keep their notes attached to the rulebook they actually played.

Acceptance criteria:

- The playtester opens a game in their studio and reads the summary and the module list of the single public version. Draft and archived text are not offered as the current rules.
- The playtester logs a session on that public version: integer `playtime_minutes` and integer `scenarios_completed`.
- The playtester submits feedback on that session: one module that is included in that version, a severity, and comments.
- The feedback row stores the session, and the session stores the rulebook version, so the note stays tied to that version.
- A session on a draft or archived version is rejected.
- A module from another game, or a module not included in that version, is rejected.
- Business Rule 1 runs on this submit. A rejected submit stores no feedback row and does not change comments that were typed into the form.
- After a successful submit, the comments shown anywhere in the app are the submitted text. No role has a form or a parameter that changes them.
- A user cannot log a session against another studio's public version (404 on the foreign version, and the model rejects a mismatched studio).

### Story 3. The arbiter triages current feedback

The rules arbiter wants to mark which reports are real bugs and which describe the rules as written, and wants to filter that list.

Acceptance criteria:

- The arbiter opens a list of the studio's feedback. The list supports filter parameters `status`, `severity`, `priority`, and `game_project_id`. The default filter is `status=unreviewed`. An empty filter result is a normal page.
- On feedback whose version is `public`, the arbiter may set `status` to `valid_bug` or `working_as_intended`.
- The same request cannot change `comments`, `severity`, `rule_module_id`, `playtest_session_id`, or `priority`. If those keys are posted, they are ignored. The stored comments stay byte-for-byte the same.
- A playtester who opens the triage list, or POSTs a status change, receives 403.
- Business Rule 4 applies: when the version is `archived`, a status change by the arbiter or the admin is rejected, and the row is unchanged.
- A direct request for another studio's feedback id returns 404.

The admin's "reports" screen is the studio escalation list from Business Rule 3: module, severity, priority, and the number of distinct playtesters. It is filterable by game. It is not a separate analytics product.

## 4. Business rules

Each rule has its own Cucumber feature. The feature's failure scenarios are written first and must fail before the service exists. RSpec covers the same boundaries on the model or service.

### BR1. Mandatory session validation

Feedback is persisted only when that session has `playtime_minutes >= 30` and `scenarios_completed >= 2`. Otherwise validation fails, the response explains both thresholds, and no feedback row is written.

A session may be saved below the threshold. The threshold gates feedback, not the act of writing down how long the table ran. After a feedback row exists, that session's playtime and scenario count are frozen, so the gate cannot be edited after the fact.

### BR2. Re-evaluation on deprecation or replacement

The PDF called this "automatic invalidation." Nothing is deleted and nothing is marked invalid. The system **re-stamps** eligible feedback as `re_evaluation`.

A publish deprecates a module by flipping `deprecated` from false to true, replaces a module by setting `replaced_by_id`, or does both. For each module changed in that way, every **eligible** feedback row that references that module and whose session's version has `version_number` lower than the version being published is updated to `status = re_evaluation`.

Eligible means status is `unreviewed` or `valid_bug`. The service does not change `working_as_intended` or an existing `re_evaluation`. It does not change comments, severity, module, session, or priority.

This write is part of the publish transaction, and it runs **before** the previous public version is archived:

1. Lock the game's rulebook versions.
2. Apply the deprecation and replacement edits requested by this publish.
3. Stamp eligible older feedback as `re_evaluation`.
4. Archive the current public version, if there is one.
5. Set the draft being published to `public`.
6. Commit, or roll back the whole sequence.

`re_evaluation` on an older version is a historical stamp, not a second triage queue. Story 3 continues on feedback whose version is still public. Fresh sessions against the new public version are how the studio re-judges the rules.

### BR3. Priority escalation

Severity is required on every feedback row and is one of `low` (0), `medium` (1), or `high` (2). Two rows match when they share `rule_module_id` and `severity`.

After a feedback row is saved, count distinct `user_id` values among all saved feedback for that module and severity. Sessions from the same user count once.

When the distinct-user count reaches 3:

- Create one `Escalation` for that module and severity if it does not already exist. Uniqueness is `(rule_module_id, severity)`.
- Set the escalation's `priority` to `escalated` (1). Normal priority is 0.
- On matching feedback whose rulebook version is **not** archived, set `priority` to `escalated` and set `escalation_id`.
- Do not update matching feedback whose version is archived. Those rows still count toward the three users. Business Rule 4 forbids writing them.
- A fourth distinct user joins the same escalation. Priority stays 1. A second escalation is not created.
- Users cannot post a priority. Only this service raises it, and only from 0 to 1.

### BR4. Historical integrity

Once a session's rulebook version is `archived`, every user, including studio admins and arbiters, is refused any change to that session's feedback and to that session's playtime and scenario count. The refusal leaves the row as it was.

The publish service in BR2 is the only writer allowed to set `re_evaluation` on those rows, and only inside the transaction, at the step numbered 3 above, before the archive is committed. After commit, the stamp is frozen too.

Comments are immutable for every role on every version, archived or not, from the moment of submission. Arbiters may change `status`, and only on a public version, and only to `valid_bug` or `working_as_intended`.

### Status values

| Value | Name | Meaning |
|---|---|---|
| 0 | `unreviewed` | Initial status. Eligible for BR2. |
| 1 | `valid_bug` | Arbiter verdict. Eligible for BR2. |
| 2 | `working_as_intended` | Arbiter verdict. Terminal. BR2 does not change it. |
| 3 | `re_evaluation` | Set only by the publish service. Terminal. BR2 does not change it again. |

Rulebook version status: `draft` 0, `public` 1, `archived` 2.

## 5. Database

PostgreSQL. Every studio-owned row is reached through its studio. Controllers load from `current_user.studio` and its associations. They do not call `GameProject.all`, `Feedback.all`, or an unscoped `find`.

```text
Studio
  name                  string, required, unique case-insensitively

User
  studio_id             required
  email                 required, unique
  encrypted_password
  role                  required, in {0, 1, 2}

GameProject
  studio_id             required
  title                 required

RuleModule
  game_project_id       required
  title                 required
  deprecated            boolean, default false, null false
  replaced_by_id        optional self reference, same game, not self

RulebookVersion
  game_project_id       required
  version_number        integer, required, unique per game
  status                required, in {0, 1, 2}
  summary               text, required before publish
  partial unique index  (game_project_id) WHERE status = 1

RulebookInclusion
  rulebook_version_id   required
  rule_module_id        required
  unique (rulebook_version_id, rule_module_id)
  module.game_project_id = version.game_project_id

PlaytestSession
  user_id               required
  rulebook_version_id   required
  playtime_minutes      integer, required, >= 0
  scenarios_completed   integer, required, >= 0
  user.studio_id = version.game_project.studio_id
  version.status must be public at create time

Feedback
  playtest_session_id   required
  rule_module_id        required, and that module is included in the session's version
  status                required, default 0
  severity              required, in {0, 1, 2}
  priority              required, default 0, in {0, 1}
  comments              text, required, immutable after create
  escalation_id         optional

Escalation
  rule_module_id        required
  severity              required
  priority              required, default 1
  unique (rule_module_id, severity)
```

Associations that the current models still lack are part of this schema: a game has many modules and versions; a version has many inclusions and sessions; a session has many feedbacks; a module has many feedbacks; an escalation has many feedbacks. `deprecated` is a boolean. The integer column in the current migration has to be replaced, not overloaded with 0 and 1.

`PublishRulebookVersion`, the BR2 stamp, and the BR3 escalation check are plain service objects in `app/services/` with a `call` method. Controllers authorize, pass already-scoped records in, and render the result.

## 6. Validation, search, and invalid actions

Rejected input is a validation error on the form, or 403 or 404 as defined above. The database constraints back the same rules.

- Studio name, game title, module title, version summary, and feedback comments are required.
- Role, version status, feedback status, severity, and priority accept only the values in this document.
- Playtime and scenarios are non-negative integers. Feedback additionally requires the BR1 floor.
- A game cannot have two public versions.
- A session cannot point at a version from another studio, or at a version that is not public.
- Feedback cannot point at a module outside the session's version.
- Comment updates do not persist.
- Status updates do not persist when the version is archived, when the caller is a playtester, or when the caller is outside the studio.

Search and filter, both scoped to the studio:

- The game list accepts `q` and shows titles that contain that string. A title that exists only in another studio is absent.
- The arbiter feedback list accepts `status`, `severity`, `priority`, and `game_project_id`.
- The admin escalation list accepts `game_project_id`.

## 7. How development is test-driven

The course requires TDD and BDD, and the deployment grade asks for one project-level example that connects a story, its tests, and the implementation. This project uses the following cycle for **every** story and **every** business rule. The cycle is the process, not a final test pass.

1. Write the Cucumber feature, including the failure and the 403 or 404 scenario. Run `bundle exec cucumber`. Confirm the new scenarios fail because the behavior is absent.
2. Write the RSpec examples for that rule's boundaries, including the rejected values. Run `bin/rspec`. Confirm those examples fail.
3. Commit the failing tests on their own, with a message that names the story or rule.
4. Write the smallest implementation that turns those examples green. Do not edit the assertion text to match a weaker behavior.
5. Refactor under the green suite.
6. Commit the implementation, with a message that names the same story or rule.

`features/` holds one feature file per user story and one per business rule:

- `features/publish_rulebook.feature` (Story 1)
- `features/log_session_and_feedback.feature` (Story 2)
- `features/triage_feedback.feature` (Story 3)
- `features/session_validation.feature` (BR1)
- `features/reevaluate_on_publish.feature` (BR2)
- `features/priority_escalation.feature` (BR3)
- `features/archived_feedback_readonly.feature` (BR4)
- `features/studio_isolation.feature` (tenancy and direct-URL access; already started)

RSpec holds the corresponding model and service examples, plus request specs for 403 and 404. Fixtures and factories must not rewrite `comments` after a feedback row is created. A factory builds the text once, at create time. Session factories used by BR1 examples must be able to set playtime and scenarios above and below the gate. The scaffold values of 1 minute and 1 scenario are only the below-gate case.

### The graded TDD example

Business Rule 1 is the iteration recorded in the README. It is small, it has an objective pass and fail, and it has not been implemented yet, so the history can show the red commit before the green commit. The README names:

- the story and rule (Story 2's submit path, gated by BR1),
- the red commit SHA that adds `features/session_validation.feature` and the RSpec examples,
- the green commit SHA that adds the validation,
- the command that reproduces the run,
- the GitHub Actions URL for the green commit.

The existing tenancy work landed tests and implementation in one commit (`c8dcdf9`). That history is real, and it is not the TDD example.

### Coverage and CI

SimpleCov starts from `spec/spec_helper.rb` and from `features/env.rb`, filters out `spec/`, `features/`, `config/`, `db/`, and `vendor/`, and covers `app/`. The measured number is line coverage of `app/`. The gate is 80%. CI fails when the gate fails.

`.github/workflows/ci.yml` runs on every push and every pull request:

1. PostgreSQL 16, with `DATABASE_URL` pointing at a named test database.
2. `bin/rails db:prepare`
3. `bin/rspec`
4. `bundle exec cucumber`
5. the SimpleCov gate

Cucumber is not allowed to fail the job quietly. `continue-on-error` is removed. Both commands must be green before a branch is merged. `bundle exec rake test:all` runs the same three steps locally.

## 8. Deployment, seeds, and the final submission

Render runs the Rails web service. PostgreSQL is a Render managed database. `DATABASE_URL` comes from that database. `RAILS_MASTER_KEY` is an environment variable on the service. `config/master.key` is not in Git. `tmp/`, `log/`, and `.bundle/` are gitignored. The release command is `bin/rails db:prepare`. The health check hits a path that does not require a signed-in user.

`db/seeds.rb` is idempotent and creates two studios with the synthetic accounts below. The same accounts are printed in the README. They are course demo logins, not personal passwords.

| Email | Studio | Role | Password |
|---|---|---|---|
| neon-admin@example.com | Neon Dice Co. | studio admin | PlaytestDemo!2026 |
| neon-play@example.com | Neon Dice Co. | playtester | PlaytestDemo!2026 |
| neon-arbiter@example.com | Neon Dice Co. | arbiter | PlaytestDemo!2026 |
| dragon-admin@example.com | Dragon's Lair Designs | studio admin | PlaytestDemo!2026 |
| dragon-play@example.com | Dragon's Lair Designs | playtester | PlaytestDemo!2026 |
| dragon-arbiter@example.com | Dragon's Lair Designs | arbiter | PlaytestDemo!2026 |

Each studio seed includes one game, two modules, one public version that includes both modules, and no feedback. Feedback in the demo is created through the UI so the video shows the real rule.

The README in the repository contains: both members, Option F, the features actually implemented, known limitations, Ruby and Rails versions, setup, `db:prepare`, `db:seed`, the server command, the test commands, the coverage command, the deployed URL, the demo table above, the CI URL for the submitted SHA, the BR1 red and green SHAs, reused material (Rails application template, Devise, Cucumber, RSpec, SimpleCov), and the AI tools used. The submitted package also names the GitHub URL and the exact commit SHA. The 2–3 minute video uses that deployed commit, walks Story 1 through Story 3, and shows one rejected action: a feedback submit under 30 minutes, or a direct open of the other studio's game.

Local setup on Windows sets `host: localhost` in `config/database.yml`. CI does not depend on that host line because it sets `DATABASE_URL`.

## 9. Work plan

The plan runs from 24 November 2026 to the 11 December deadline. Each slice finishes its red commit before its green commit. Later slices do not start by rewriting earlier acceptance tests.

| Slice | Test first | Then implement |
|---|---|---|
| 0. Make the current suite enforceable | Fix the user-factory sequence and the Cucumber assertion helpers so `studio_isolation.feature` can run. Remove `continue-on-error`. | Add the Rails `.gitignore`, stop tracking `master.key`, `tmp/`, and `log/`, and point `render.yaml` at managed Postgres. |
| 1. Accounts | Scenarios for founding a studio, joining as playtester, rejecting a self-assigned admin, and appointing an arbiter. | Registration field and Devise permit list for `studio_name`. Admin role update, scoped to the studio. Sign-out link. |
| 2. Story 1 | `publish_rulebook.feature` red, including the second-public and cross-studio cases. Service specs red. | Drafts, inclusions, `PublishRulebookVersion`, partial unique index. Remove the game-page save form until a real update exists, and reject a blank title. |
| 3. Story 2 and BR1 | `session_validation.feature` and the session feature red. This pair is the README's TDD example. | Sessions on the public version only. Feedback create with the 30-minute and 2-scenario gate. Immutable comments at the model. |
| 4. Story 3 and BR4 | Triage and archived-read-only features red, including a posted comment that must survive unchanged. | Filterable arbiter index. Status-only update. Refuse writes when the version is archived. |
| 5. BR2 | `reevaluate_on_publish.feature` red, including a `working_as_intended` row that must stay put, and a comments string that must stay put. | Deprecation and replacement inside the publish transaction, in the order in section 4. |
| 6. BR3 and the report | Escalation feature red: two users do not escalate, the same user three times does not escalate, the third distinct user does, an archived row is not updated. | `Escalation` and the admin report. Game title search. |
| 7. Submission | Coverage gate red if `app/` is under 80%, then fill gaps with examples that assert behavior. | Seeds, Render, README, and the video recorded from the deployed SHA. |

## 10. Specification and rubric checklist

| Course requirement | Where this specification meets it |
|---|---|
| Option F: SaaS, multi-tenant or complex roles | Sections 1 and 2. Studios are tenants. Three roles have different writes. |
| At least three user stories | Section 3. |
| At least two business rules beyond CRUD | Section 4. Four rules, plus immutable comments and a single public version. |
| Authentication and at least two roles, enforced on direct requests | Section 2. 403 for the wrong role, 404 for the wrong studio, including POST. |
| At least two organizations, private data separated | Sections 1 and 8. Seeds create Neon Dice Co. and Dragon's Lair Designs. |
| Relational database, validation, clear invalid actions | Sections 5 and 6. |
| A useful search or filter | Section 6. Title search and feedback filters. |
| Unit tests and acceptance tests for stories, rule failures, permissions, and isolation | Sections 3, 4, and 7. |
| GitHub Actions runs those tests | Section 7. |
| At least 80% coverage, method stated | Section 7. SimpleCov line coverage of `app/`, gate in CI. |
| TDD and BDD, with one documented iteration | Section 7. Red commit then green commit. BR1 is the README example. |
| Working cloud deployment, reproducible setup, demo accounts | Section 8. |
| README contents required by Phase 2 | Section 8. |
| 2–3 minute video of the submitted version, including one invalid action | Section 8. |
| No secrets for real accounts in Git | Section 8. Demo passwords are synthetic and published on purpose. `master.key` stays out of Git. |
| Synthetic data, no payments, no gambling, labeled as a course demo | Opening section and section 8. |
| AI assistance disclosed | Section 8, in the README. |
| Rubric A, proposal | This document: one problem, a scope that fits the deadline, testable stories and rules, and a Rails plan. |
| Rubric B, functionality | Sections 3 through 6 are the workflow, the rules, the persistence, the validation, and the screens. |
| Rubric C, engineering | Sections 2, 5, and 7: one isolation concern, one role helper, services for the rules, tests that fail the build, coverage gate. |
| Rubric D, deployment and practice | Sections 7 and 8, including the red-then-green BR1 history. |
| Rubric E, README and video | Section 8. |

## 11. Decisions that correct the original PDF

- Rule modules, severity, priority, and escalations are in the schema because BR2 and BR3 refer to them and the PDF's table omitted them.
- "Invalidation" is a status stamp to `re_evaluation`. Rows and comments stay.
- BR2 runs inside the publish transaction before the old version is archived. After commit, BR4 freezes user edits, including edits to that stamp. BR3 may read archived feedback and must not update it.
- The playtime minimum is 30 minutes. The PDF said "a minimum" and left the number unset.
- The three sessions in BR3 must come from three different users.
- A playtester does not choose among public versions. A game has one. Sessions attach to that one.
- "Reads public rules" means the public version's summary and module list. "Views reports" means the escalation list. Neither is an extra product.
- The work-plan item "Blind Testing" is dropped. It named no rule in the PDF. Cucumber scenarios are written at the start of each slice, not in a cleanup week.
