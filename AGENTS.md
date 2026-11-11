# Project: CSCI3100 — Tabletop Game Playtesting Platform

Rails 7.1 + PostgreSQL, multi-tenant. Teams: Tsang Chi Kiu, Wong Mo Tien.

## Hard rules (do not deviate)

### Multi-tenancy
- Every studio-owned record is reachable ONLY through its Studio: Studio → GameProject → RuleModule / RulebookVersion → PlaytestSession → Feedback.
- Controllers must scope ALL queries to `current_user.studio` (or, for admin reports, the same studio). Never query global `GameProject.all` etc.
- A user from Studio A must be unable to read, create, or modify ANY record of Studio B. Enforce in the controller layer via a shared `TenantScopedController` concern; do not scatter `where(studio:)` by hand.

### Roles (users.role: integer, 0=playtester, 1=arbiter, 2=studio_admin)
- Studio Admin: create games, manage rulebook versions, view reports.
- Playtester: read PUBLIC rulebook versions, log playtest sessions, submit feedback.
- Rules Arbiter: review/triage feedback (change status only).
- Role checks go through one `authorize_role!` helper, not per-controller if-statements.

### Business rules — implement exactly, each needs its own Cucumber feature
- BR1 Mandatory session validation: reject feedback unless the session has `playtime_minutes >= 30` AND `scenarios_completed >= 2`.
- BR2 Automatic invalidation: when an admin publishes a new version that deprecates a RuleModule (rule_module.deprecated flipped / module replaced), every ACTIVE feedback (status not terminal) referencing that module in OLDER versions gets status `re_evaluation`.
- BR3 Priority escalation: 3 independent PlaytestSessions (distinct users) with feedback on the same RuleModule with matching severity → create an aggregation (Escalation) and bump priority.
- BR4 Historical integrity: feedback belonging to a PlaytestSession whose RulebookVersion is `archived` is read-only for ALL users (including admins and arbiters).
- Playtester feedback text (`comments`) is immutable after submission — no user (any role) can edit it. Arbiters may only change `status`.

### Rulebook versions
- statuses: 0=draft, 1=public, 2=archived.
- At most ONE public version per GameProject. Publishing a new version in a single transaction: lock the game's versions, archive the previous public, set the new one public.

## Conventions
- Ruby idiomatic, no `eval`, no `system()`. ActiveRecord for data access.
- Services (non-controller logic for BR2/BR3/version publishing) live in `app/services/` as plain classes with a `call` method.
- Testing: RSpec (spec/) for units, Cucumber (features/) for acceptance — one feature file per user story and per business rule. Target >80% coverage (simplecov).
- Nothing merges red: `bin/rspec` and `bundle exec cucumber` must both pass.
- Never alter playtester feedback text in tests or code.

## Commands
- `bin/rails db:prepare` then `bin/dev` (or `bin/rails s`)
- `bin/rspec` / `bundle exec cucumber`
- `bundle exec rake test:all` (rspec + cucumber + coverage)