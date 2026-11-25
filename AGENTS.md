# Project: CSCI3100 — Tabletop Game Playtesting Platform

Rails 7.1 + PostgreSQL, multi-tenant. Team: Tsang Chi Kiu, Wong Mo Tien.

The build specification is `docs/refined_proposal.md`. This file is the short form of the rules that must not drift from it.

## Hard rules (do not deviate)

### Multi-tenancy
- Every studio-owned record is reachable ONLY through its Studio: Studio → GameProject → RuleModule / RulebookVersion → PlaytestSession → Feedback, and Escalation through its RuleModule.
- Controllers must scope ALL queries to `current_user.studio` (or, for admin reports, the same studio). Never query global `GameProject.all`, `Feedback.all`, or an unscoped `find`.
- A user from Studio A must be unable to read, create, or modify ANY record of Studio B. A direct URL or crafted POST for a foreign id returns 404. Enforce this in `StudioIsolationEnforcer`, included from `ApplicationController`. Do not scatter `where(studio:)` by hand.

### Roles (users.role: integer, 0=playtester, 1=arbiter, 2=studio_admin)
- Studio Admin: create games, manage modules and draft versions, publish, appoint arbiters, view the escalation report.
- Playtester: read the studio's single PUBLIC rulebook, log sessions, submit feedback, read their own feedback.
- Rules Arbiter: a playtester's rights, plus list/filter studio feedback and change `status` on feedback whose version is still public.
- The first registrant of a studio name is its admin. A later registrant of that name joins as playtester and cannot self-assign a higher role. An admin may switch another same-studio member between playtester and arbiter, and cannot change their own role.
- Role checks go through one `authorize_role!` helper, not per-controller if-statements. A forbidden in-studio action returns 403.

### Business rules — implement exactly, each needs its own Cucumber feature
- BR1 Mandatory session validation: reject feedback unless the session has `playtime_minutes >= 30` AND `scenarios_completed >= 2`. Saving the session itself is allowed below that gate. After feedback exists, playtime and scenario count are frozen.
- BR2 Re-evaluation on publish: when an admin publishes a version that deprecates a RuleModule (`deprecated` flipped false → true) or sets `replaced_by_id`, every eligible feedback row on that module in OLDER versions (`version_number` lower than the version being published) gets status `re_evaluation`. Eligible statuses are `unreviewed` and `valid_bug`. `working_as_intended` and an existing `re_evaluation` stay as they are. Comments are not touched. This write happens inside the publish transaction BEFORE the previous public version is archived.
- BR3 Priority escalation: 3 PlaytestSessions from distinct users, feedback on the same RuleModule with the same severity, create one Escalation for that module and severity and set priority to escalated (1). A further distinct user joins that escalation. Archived feedback counts toward the three users and is not updated.
- BR4 Historical integrity: feedback belonging to a PlaytestSession whose RulebookVersion is `archived` is read-only for ALL users (including admins and arbiters). The only exception is the BR2 stamp inside the publish transaction, at the step above, before archive commits.
- Playtester feedback text (`comments`) is immutable after submission. No user of any role can edit it. Arbiters may change `status` only, and only while the version is public, and only to `valid_bug` or `working_as_intended`. Tests must not rewrite comments after create.

### Statuses
- Rulebook version: 0=draft, 1=public, 2=archived. At most ONE public version per GameProject.
- Feedback: 0=unreviewed, 1=valid_bug, 2=working_as_intended (terminal), 3=re_evaluation (system only, terminal).
- Severity: 0=low, 1=medium, 2=high. Priority: 0=normal, 1=escalated.
- Publishing is one transaction: lock the game's versions, apply deprecation/replacement, run BR2, archive the previous public version, set the draft public.

## Conventions
- Ruby idiomatic, no `eval`, no `system()`. ActiveRecord for data access.
- Services (publish, BR2, BR3) live in `app/services/` as plain classes with a `call` method.
- Testing is test-first. For each story and each business rule: add a failing Cucumber feature and failing RSpec examples, commit them, then implement, then commit the green code. One feature file per user story and per business rule.
- The README's TDD/BDD example is BR1. The red commit is `803628e`. The green commit is `33179ca` (local until it is pushed). The README does not cite them yet.
- Work record: after every slice, append an entry to the bottom of `docs/work_log.md` before the task is finished. Read the latest entries before changing the same area. The entry names the date, what was asked, the files changed, why, the commands that were run and the result they printed, the commit SHA and whether it was pushed, and what was left failing or undone. Record a check only when it was run. If a check was skipped, say so. Do not invent a pass, a SHA, or an Actions URL.
- Target >=80% SimpleCov line coverage of `app/`. `bin/rspec` and `bundle exec cucumber` must both pass. CI must fail when either fails. Do not set `continue-on-error` on Cucumber.
- Nothing merges red.

## Commands
- `bin/rails db:prepare` then `bin/dev` (or `bin/rails s`)
- `bin/rails db:seed` for the two demo studios
- `bin/rspec` / `bundle exec cucumber`
- `bundle exec rake test:all` (rspec + cucumber + coverage)
