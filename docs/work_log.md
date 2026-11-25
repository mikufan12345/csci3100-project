# Work log

Append-only record of what was done, why, and how it was checked. A course report or a later explanation should quote this file rather than reconstruct the history from memory.

Add the next entry at the bottom. An entry states only checks that were actually run. If a check was skipped, the entry says so.

## 2026-11-11 — Scaffold and tenancy

Commits already on `main` before the test-first work:

| SHA | What it contains |
|---|---|
| `5f0e9ff` | Rails 7.1, PostgreSQL, Devise, schema, CI, Render config |
| `a45f18f` | Ruby pin relaxed so CI can use any 3.3.x |
| `dc835b6` | RSpec binstub |
| `c8dcdf9` | Studio isolation in controllers, plus the user spec and the first Cucumber feature, in the same commit |
| `602842a` | Comment and style cleanup of that tenancy slice |

`c8dcdf9` is real history. It is not the graded TDD example, because the tests and the implementation landed together.

At that point the database had the studio, user, game, module, version, session, and feedback tables. Game list and create worked. Signup assigned a studio inside the user model. Stories 1–3 and business rules 1–4 were not implemented. The game page posted a title update to a route that did not exist. The signup screen could not send `studio_name`. `db/seeds.rb` was empty. The README was the Rails placeholder. Cucumber in CI was marked `continue-on-error`. There was no `.gitignore`, and `config/master.key` was tracked.

## 2026-11-25 — Specification, red baseline, and gitignore

Compared `project_csci3100_spec.pdf` and `3100_proposal.pdf` with the repository. No application code was changed in that comparison. The proposal was then rewritten so the rules, the schema, and the test-first cycle agree with the course spec.

Files from that pass:

- `docs/refined_proposal.md` is the build specification. Student IDs are not in it.
- `AGENTS.md` matches that specification.
- `docs/test_first_process.md` describes the red-then-green cycle.
- Cucumber features, step definitions, RSpec examples, factories, `cucumber.yml`, and `lib/tasks/test_all.rake`.
- `.github/workflows/ci.yml` no longer has `continue-on-error` on Cucumber.

The Cucumber dry run (`bundle exec cucumber -p dryrun`) matched 61 scenarios and 909 steps, with no undefined steps. The suite itself was not executed then: nothing was accepting connections on `localhost:5432`.

`.gitignore` was added. Already tracked junk was removed from the index only, with `git rm --cached`, so the working copies stayed on disk:

- `config/master.key`
- `.bundle/`
- `.clm/`
- `log/cucumber.log`, `log/development.log`, `log/test.log`
- `tmp/cache/`

`log/.keep`, `tmp/.keep`, `tmp/pids/.keep`, `tmp/storage/.keep`, and `storage/.keep` stay tracked. `config/credentials.yml.enc` stays tracked. `3100_proposal.pdf` is ignored because it contains student IDs. `project_csci3100_spec.pdf` is ignored so the course handout is not published by accident.

Those two commits were made and pushed to `origin` (`git@github.com:mikufan12345/csci3100-project.git`):

| SHA | Message |
|---|---|
| `fd05dea` | Stop tracking the Rails master key, logs, and generated caches. |
| `803628e` | Add the failing Cucumber features and RSpec examples for the test-first baseline. |

`803628e` is the red SHA for Business Rule 1.

The GitHub repository is public. `config/master.key` is still in the history of the commits before `fd05dea`. Removing it from the latest tree does not delete it from those older commits. Treat that key as public. Rotate it before a real deployment. History was not rewritten, and nothing was force-pushed.

`bin/*` shows as modified on this Windows machine because `core.autocrlf` is true. Those diffs are line endings. They were left out of the commits.

## 2026-11-25 — Business Rule 1, green commit

Requested work: start PostgreSQL, confirm the Business Rule 1 tests fail, then implement only that rule.

### Database

No PostgreSQL Windows service was installed. Docker Desktop was installed, and its daemon was not running. Ubuntu in WSL had no `psql`, and `sudo` there asks for a password, so nothing was installed with administrator rights.

PostgreSQL 16.11 Windows binaries were downloaded to `%LOCALAPPDATA%\pgsql` and initialized there:

- binaries: `%LOCALAPPDATA%\pgsql\pgsql\bin`
- data: `%LOCALAPPDATA%\pgsql\data`
- auth on localhost: `trust`
- login role: `Moses` (same name as the Windows user, including the capital M)
- databases: `csci3100_project_development`, `csci3100_project_test`

The server was started in this session with:

```text
postgres.exe -D %LOCALAPPDATA%\pgsql\data
```

A later shell does not keep that process. Start it again with the same command. `config/database.yml` sets `host: localhost` in the `default` block, because Windows has no Unix sockets. CI sets `DATABASE_URL`, which overrides that host.

`bin/rails` on this machine is a Bundler binstub. After a successful `db:prepare` or `db:migrate` it also prints the generic Rails help. The migration output above that help is the real result. `db:prepare` loaded the schema. Two migrations then ran:

- `20261125173000` adds `rulebook_versions.summary`, `feedbacks.severity`, and `rulebook_inclusions`
- `20261125174500` adds `feedbacks.priority`, default 0, null false

`priority` is a column only. A lone report can still be saved with priority 1. Escalation is not implemented. The column exists because the freeze scenario's Given assigns `priority`.

### Red run, before the validation

`bundle exec rspec spec/models/feedback_spec.rb spec/models/playtest_session_spec.rb` — 14 examples, 12 failures. The 30-minute example, the 2-scenario example, and the freeze example failed on the expectation. Saving a 10-minute session, and saving feedback at 30 minutes and 2 scenarios, already passed.

`bundle exec cucumber features/session_validation.feature` — 5 scenarios, all failed. The background stopped on `undefined method rulebook_versions` for `GameProject`.

### What was implemented

- `Feedback` rejects a session under 30 minutes or under 2 scenarios, with the sentences `Playtime must be at least 30 minutes.` and `At least 2 scenarios must be completed.` A new feedback row with no status is stored as `unreviewed` (0).
- `PlaytestSession` still saves below that gate. On update, once a feedback row exists, a change to playtime or scenario count does not persist.
- Game page, for the signed-in user's public version: summary, included module titles, "Log session", then "Rule module", "Severity", "Comments", and "Submit feedback".
- Routes used by those scenarios: `POST /rulebook_versions/:id/playtest_sessions`, `PATCH /playtest_sessions/:id`, `POST /playtest_sessions/:id/feedbacks`.
- Queries go through the signed-in user's studio. A playtester logs and edits their own session.

Not in this commit: publish, triage, escalation, comment immutability, archived read-only, draft-only sessions, required severity, required comments, seeds, Render, and the README.

`config/environments/test.rb` keeps the Sprockets cache in memory. The file cache raised `Permission denied` on rename under `tmp/cache/assets` on Windows, which aborted the first Cucumber scenario before the form was submitted.

### Green run

`bundle exec cucumber features/session_validation.feature` — 5 scenarios, 41 steps, all passed.

`bundle exec rspec spec/models/feedback_spec.rb spec/models/playtest_session_spec.rb` — the three Business Rule 1 examples pass (30 minutes and 2 scenarios, under 30 minutes, under 2 scenarios) and the freeze example passes. Nine examples in those two files still fail. They belong to later slices: comments required, severity required, module included in the version, immutable comments, archived status, lone-report priority, and sessions on a draft, an archived version, or another studio.

`features/studio_isolation.feature` and `features/log_session_and_feedback.feature` were run together: 15 scenarios, 7 passed, 8 failed. The four original tenancy scenarios still pass. These also pass, because they use the same gate and the public rulebook on the game page:

- a playtester reads only the public summary
- a qualified session stores feedback
- a short session stores no feedback and shows the playtime sentence

These stay red, which is what this commit intended:

- blank game title
- title search
- a session on a draft or archived version (response was 200, the scenario requires 422)
- feedback on a module outside the version, or on another game (response was 200, the scenario requires 422)
- opening another studio's version (`GET /rulebook_versions/:id` has no route)
- replacing submitted comments (`PATCH /feedbacks/:id` has no route)

`bundle exec rake test:all` was not run. A browser was not opened. Cucumber's rack_test driver submitted the forms.

### Commit

`33179ca` — `Reject feedback below 30 minutes or 2 scenarios.`

16 files. Not pushed. `main` is one commit ahead of `origin/main`. The README does not cite the two SHAs yet. The Actions URL for the green commit does not exist until this commit is pushed.

Graded pair, once the README is written:

- story and rule: Story 2's submit path, gated by Business Rule 1
- red SHA: `803628e`
- green SHA: `33179ca`
- commands: `bundle exec rspec spec/models/feedback_spec.rb` and `bundle exec cucumber features/session_validation.feature`

## 2026-11-25 — Work log and the record rule

Requested work: write down the steps already taken, so a report or an explanation can quote them, and require later runs to keep that record.

- Created `docs/work_log.md` with the scaffold, the red baseline, the gitignore cleanup, and the Business Rule 1 run.
- Corrected `docs/test_first_process.md` where it still said the gate was unproven and that PostgreSQL had never been reached.
- Added the work-record rule to `AGENTS.md`, and recorded the two Business Rule 1 SHAs there.

No tests were run for this documentation pass. Nothing was pushed. `33179ca` is still the unpushed green commit. The documentation commit is `3090a69`.

## 2026-11-25 — Accounts (work-plan slice 1)

Requested work: commit the work record, then do the next unfinished slice. Slice 1 is studio membership. The red scenarios were already in `803628e`. They were confirmed red before this implementation: `bundle exec cucumber features/membership.feature` reported 8 scenarios, 8 failed. The sign-up page had no "Studio name" field, a direct registration did not create the user, and `PATCH /studio_members/:id` had no route.

What was added:

- The sign-up form has Email, Studio name, Password, Password confirmation, and the button "Sign up". Devise is permitted to store `studio_name` and is not permitted to store `role`.
- A blank studio name is rejected by the existing model check. A new studio name makes that user the studio admin. A name that matches an existing studio, ignoring case, joins as playtester. A posted role of 2 on that join is ignored. The development log recorded `Unpermitted parameter: :role` and the inserted role was 0.
- `StudioMembersController#update` loads the member with `find_in_studio`, then `authorize_role!(User::STUDIO_ADMIN)`. A playtester gets 403. Another studio's id gets 404. The admin cannot change their own role and cannot grant `studio_admin`. `playtester` and `arbiter` are the only accepted values. The games page lists same-studio members and shows that form to the admin. The layout has a Sign out button for a signed-in user.
- On Windows, Sprockets' file cache rename was denying permission while rendering a page in development. `config/environments/development.rb` uses a memory cache for assets on Windows, the same workaround already used in the test environment.

Checks that were run:

- `bundle exec cucumber features/membership.feature`: 8 scenarios, 8 passed.
- `bundle exec rspec spec/models/user_spec.rb` and the cross-studio example in `spec/requests/permissions_spec.rb`: 7 examples, 1 failure. The failure is `User roles requires a role`. `allow_nil: true` is still on the role validation. That example was left red. The other six passed, including founding, joining, and ignoring a posted admin role.
- `bundle exec cucumber features/studio_isolation.feature features/session_validation.feature`: 11 scenarios, 9 passed, 2 failed. The failures are the blank game title and the title search. Business Rule 1's five scenarios passed. The four original isolation scenarios passed.
- `bundle exec rspec spec/requests/game_projects_spec.rb` lines for the foreign game and the playtester create: 2 examples, 0 failures.
- Full `bundle exec rspec`: 47 examples, 30 failures, exit 1. The new failure is not from this slice. `requires a role` is still the only user-spec failure. The other failures are blank titles, draft and archived sessions, publish, triage, and escalation.
- Full `bundle exec cucumber`: 61 scenarios, 20 passed, 41 failed, exit 1. Membership is in the 20 that passed. Publish, triage, re-evaluation, escalation, archived writes, blank titles, and title search stay red.
- `bundle exec rake test:all` was not run as one command. The two commands it wraps were run separately, and both exited 1 because later slices are still red.
- No browser tool was available. The same forms were submitted with HTTP against `bin/rails server` on `127.0.0.1:3000`. The sign-up page returned 200 and contained "Studio name". A blank studio name returned 422 and created no user. Founding "Slice One Studio" redirected to the games page, which showed Sign out, Studio members, and the founder's email. Sign out returned to the page with Sign in. A second registration for "slice one studio" that also posted `user[role]=2` stored role 0 and did not show "Save role". Signing back in as the founder and saving role `arbiter` redirected to the games page. The database then had the founder at role 2 and the joiner at role 1, both in Slice One Studio. Those two users and that studio were deleted afterward.
- The first development request before the memory-cache change returned 500: `Permission denied @ rb_file_s_rename` under `tmp/cache/assets`. After the change, the same page returned 200.

The implementation commit is `ade3ef5`. The documentation commit from the previous entry is `3090a69`. `33179ca` and these two commits are local. Nothing was pushed. There is no Actions URL.

Left undone: role is still optional when a studio is assigned directly (`requires a role` stays red). Story 1 publish, Story 3 triage, Business Rules 2, 3, and 4, title search, seeds, the README SHA write-up, and Render are not this slice. `render.yaml` still does not point at managed Postgres.
