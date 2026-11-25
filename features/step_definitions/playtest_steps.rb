# frozen_string_literal: true

# Steps for the stories and business rules in docs/refined_proposal.md.
# Givens build records directly. Whens drive the browser or a direct request.
# A missing column, route, or rule fails the scenario. Do not soften a step
# to hide that.

Given("the game {string} has a module {string}") do |game_title, module_title|
  FactoryBot.create(:rule_module, title: module_title, game_project: game_named(game_title))
end

Given("the game {string} has a {word} version {int} with summary {string} including {string}") do |game_title, status_name, number, summary, module_list|
  game = game_named(game_title)
  version = game.rulebook_versions.create!(
    version_number: number,
    status: PlaytestDomain::VERSION_STATUS.fetch(status_name),
    summary: summary
  )
  module_list.split(",").each do |name|
    rule_module = game.rule_modules.find_by!(title: name.strip)
    RulebookInclusion.create!(rulebook_version: version, rule_module: rule_module)
  end
end

Given("the game {string} has an incomplete draft version {int}") do |game_title, number|
  game_named(game_title).rulebook_versions.create!(version_number: number, status: 0, summary: "")
end

Given("version {int} of {string} is now archived") do |number, game_title|
  # Fixture only. Production code archives inside PublishRulebookVersion.
  version_named(game_title, number).update_columns(status: PlaytestDomain::VERSION_STATUS.fetch("archived"))
end

Given("{string} has a session of {int} minutes and {int} scenarios on version {int} of {string}") do |email, minutes, scenarios, number, game_title|
  PlaytestSession.create!(
    user: User.find_by!(email: email),
    rulebook_version: version_named(game_title, number),
    playtime_minutes: minutes,
    scenarios_completed: scenarios
  )
end

Given("{string} left {word} feedback {string} on {string} of {string} with severity {word}") do |email, status_name, comments, module_title, game_title, severity_name|
  session = User.find_by!(email: email).playtest_sessions.order(:id).last
  Feedback.create!(
    playtest_session: session,
    rule_module: module_named(game_title, module_title),
    status: PlaytestDomain::FEEDBACK_STATUS.fetch(status_name),
    severity: PlaytestDomain::SEVERITY.fetch(severity_name),
    priority: 0,
    comments: comments
  )
end

When("a visitor opens the sign up page") do
  visit "/users/sign_up"
end

When("a visitor registers {string} with studio {string}") do |email, studio_name|
  visit "/users/sign_up"
  fill_in "Email", with: email
  fill_in "Password", with: "password123"
  fill_in "Password confirmation", with: "password123"
  fill_in "Studio name", with: studio_name
  click_on "Sign up"
end

When("a visitor posts a registration for {string} as role {int} in studio {string}") do |email, role, studio_name|
  page.driver.post("/users", {
    user: {
      email: email,
      password: "password123",
      password_confirmation: "password123",
      studio_name: studio_name,
      role: role
    }
  })
end

When("{string} sets the role of {string} to {word}") do |actor_email, member_email, role_name|
  member = User.find_by!(email: member_email)
  submit_as(actor_email, :patch, "/studio_members/#{member.id}", { user: { role: role_name } })
end

When("{string} searches games for {string}") do |email, query|
  sign_in_as(email)
  visit "/?q=#{CGI.escape(query)}"
end

When("{string} saves a draft of {string} with summary {string} including {string}") do |email, game_title, summary, module_list|
  sign_in_as(email)
  visit "/game_projects/#{game_named(game_title).id}"
  fill_in "Summary", with: summary
  module_list.split(",").each { |name| check name.strip }
  click_on "Save draft"
end

When("{string} publishes version {int} of {string}") do |email, number, game_title|
  version = version_named(game_title, number)
  submit_as(email, :post, "/rulebook_versions/#{version.id}/publish", {})
end

When("{string} publishes version {int} of {string} deprecating {string}") do |email, number, game_title, module_title|
  version = version_named(game_title, number)
  rule_module = module_named(game_title, module_title)
  submit_as(email, :post, "/rulebook_versions/#{version.id}/publish", { deprecate_ids: [rule_module.id] })
end

When("{string} publishes version {int} of {string} replacing {string} with {string}") do |email, number, game_title, old_title, new_title|
  version = version_named(game_title, number)
  old_module = module_named(game_title, old_title)
  new_module = module_named(game_title, new_title)
  submit_as(
    email,
    :post,
    "/rulebook_versions/#{version.id}/publish",
    { replacements: { old_module.id.to_s => new_module.id } }
  )
end

When("{string} posts summary {string} for version {int} of {string}") do |email, summary, number, game_title|
  version = version_named(game_title, number)
  submit_as(email, :patch, "/rulebook_versions/#{version.id}", { rulebook_version: { summary: summary } })
end

When("{string} opens version {int} of {string}") do |email, number, game_title|
  sign_in_as(email)
  visit "/rulebook_versions/#{version_named(game_title, number).id}"
end

When("{string} opens the game {string}") do |email, game_title|
  sign_in_as(email)
  visit "/game_projects/#{game_named(game_title).id}"
end

When("{string} posts a session of {int} minutes and {int} scenarios on version {int} of {string}") do |email, minutes, scenarios, number, game_title|
  version = version_named(game_title, number)
  submit_as(email, :post, "/rulebook_versions/#{version.id}/playtest_sessions", {
    playtest_session: { playtime_minutes: minutes, scenarios_completed: scenarios }
  })
end

When("{string} logs {int} minutes and {int} scenarios on {string} and submits {string} on {string} with severity {word}") do |email, minutes, scenarios, game_title, comments, module_title, severity_name|
  sign_in_as(email)
  visit "/game_projects/#{game_named(game_title).id}"
  fill_in "Playtime minutes", with: minutes
  fill_in "Scenarios completed", with: scenarios
  click_on "Log session"
  select module_title, from: "Rule module"
  select severity_name, from: "Severity"
  fill_in "Comments", with: comments
  click_on "Submit feedback"
end

When("{string} posts feedback {string} on module {string} of {string} for their latest session") do |email, comments, module_title, game_title|
  session = User.find_by!(email: email).playtest_sessions.order(:id).last
  rule_module = module_named(game_title, module_title)
  submit_as(email, :post, "/playtest_sessions/#{session.id}/feedbacks", {
    feedback: { rule_module_id: rule_module.id, severity: "high", comments: comments, priority: "escalated" }
  })
end

When("{string} changes their latest session on {string} to {int} minutes") do |email, game_title, minutes|
  session = User.find_by!(email: email).playtest_sessions.joins(rulebook_version: :game_project)
    .where(game_projects: { title: game_title }).order(:id).last
  submit_as(email, :patch, "/playtest_sessions/#{session.id}", {
    playtest_session: { playtime_minutes: minutes }
  })
end

When("{string} changes the session of {string} on {string} to {int} minutes") do |actor_email, owner_email, game_title, minutes|
  session = User.find_by!(email: owner_email).playtest_sessions.joins(rulebook_version: :game_project)
    .where(game_projects: { title: game_title }).order(:id).last
  submit_as(actor_email, :patch, "/playtest_sessions/#{session.id}", {
    playtest_session: { playtime_minutes: minutes }
  })
end

# Plants a row that already belongs to history. Skips validation so the
# "public version only" rule can exist without making this fixture impossible.
Given("{string} has historical feedback {string} on version {int} of {string} module {string} with severity {word}") do |email, comments, number, game_title, module_title, severity_name|
  session = PlaytestSession.new(
    user: User.find_by!(email: email),
    rulebook_version: version_named(game_title, number),
    playtime_minutes: 40,
    scenarios_completed: 2
  )
  session.save!(validate: false)
  feedback = Feedback.new(
    playtest_session: session,
    rule_module: module_named(game_title, module_title),
    status: PlaytestDomain::FEEDBACK_STATUS.fetch("unreviewed"),
    severity: PlaytestDomain::SEVERITY.fetch(severity_name),
    priority: PlaytestDomain::PRIORITY.fetch("normal"),
    comments: comments
  )
  feedback.save!(validate: false)
end

When("{string} opens the feedback list") do |email|
  sign_in_as(email)
  visit "/feedbacks"
end

When("{string} filters feedback with status {word} and severity {word}") do |email, status_name, severity_name|
  sign_in_as(email)
  visit "/feedbacks?status=#{status_name}&severity=#{severity_name}"
end

When("{string} marks the feedback {string} as {word}") do |email, comments, status_name|
  feedback = feedback_named(comments)
  submit_as(email, :patch, "/feedbacks/#{feedback.id}", { feedback: { status: status_name } })
end

When("{string} posts comments {string} and status {word} for the feedback {string}") do |email, new_comments, status_name, original_comments|
  feedback = feedback_named(original_comments)
  submit_as(email, :patch, "/feedbacks/#{feedback.id}", {
    feedback: { comments: new_comments, status: status_name, severity: "low", priority: "escalated" }
  })
end

When("{string} opens feedback {string} directly") do |email, comments|
  sign_in_as(email)
  visit "/feedbacks/#{feedback_named(comments).id}"
end

When("{string} opens the escalation report") do |email|
  sign_in_as(email)
  visit "/escalations"
end

When("{string} filters the escalation report to the game {string}") do |email, game_title|
  sign_in_as(email)
  visit "/escalations?game_project_id=#{game_named(game_title).id}"
end

Then("the studio {string} does not list a game {string}") do |studio_name, title|
  titles = Studio.find_by!(name: studio_name).game_projects.pluck(:title)
  assert !titles.include?(title), "studio listed #{title.inspect}"
end

Then("no user {string} exists") do |email|
  assert_nil User.find_by(email: email)
end

Then("{string} is a {word} in {string}") do |email, role_name, studio_name|
  assert_role(email, role_name, studio_name)
end

Then("{string} is an {word} in {string}") do |email, role_name, studio_name|
  assert_role(email, role_name, studio_name)
end

Then("{string} is still a {word}") do |email, role_name|
  assert_equal PlaytestDomain::ROLES.fetch(role_name), User.find_by!(email: email).reload.role
end

Then("the latest version of {string} is draft number {int}") do |game_title, number|
  version = game_named(game_title).rulebook_versions.order(:version_number).last
  assert_equal number, version.version_number
  assert_equal PlaytestDomain::VERSION_STATUS.fetch("draft"), version.status
end

Then("version {int} of {string} is {word}") do |number, game_title, status_name|
  version = version_named(game_title, number).reload
  assert_equal PlaytestDomain::VERSION_STATUS.fetch(status_name), version.status
end

Then("the game {string} has {int} public versions") do |game_title, count|
  actual = game_named(game_title).rulebook_versions.where(status: PlaytestDomain::VERSION_STATUS.fetch("public")).count
  assert_equal count, actual
end

Then("version {int} of {string} still has summary {string}") do |number, game_title, summary|
  assert_equal summary, version_named(game_title, number).reload.summary
end

Then("the saved session for {string} on version {int} of {string} is {int} minutes and {int} scenarios") do |email, number, game_title, minutes, scenarios|
  session = User.find_by!(email: email).playtest_sessions.order(:id).last
  assert_equal minutes, session.playtime_minutes
  assert_equal scenarios, session.scenarios_completed
  assert_equal number, session.rulebook_version.version_number
  assert_equal game_title, session.rulebook_version.game_project.title
end

Then("{string} has no sessions") do |email|
  assert_equal 0, User.find_by!(email: email).playtest_sessions.count
end

Then("the session on version {int} of {string} still has {int} minutes and {int} scenarios") do |number, game_title, minutes, scenarios|
  session = version_named(game_title, number).playtest_sessions.order(:id).last.reload
  assert_equal minutes, session.playtime_minutes
  assert_equal scenarios, session.scenarios_completed
end

Then("no feedback was stored") do
  assert_equal 0, Feedback.count
end

Then("{int} feedback rows exist") do |count|
  assert_equal count, Feedback.count
end

Then("the feedback {string} belongs to {string} and version {int} of {string}") do |comments, email, number, game_title|
  feedback = feedback_named(comments)
  assert_equal email, feedback.playtest_session.user.email
  assert_equal number, feedback.playtest_session.rulebook_version.version_number
  assert_equal game_title, feedback.playtest_session.rulebook_version.game_project.title
end

Then("the feedback {string} has status {word}") do |comments, status_name|
  feedback = feedback_named(comments).reload
  assert_equal PlaytestDomain::FEEDBACK_STATUS.fetch(status_name), feedback.status
end

Then("the feedback {string} has severity {word}") do |comments, severity_name|
  feedback = feedback_named(comments).reload
  assert_equal PlaytestDomain::SEVERITY.fetch(severity_name), feedback.severity
end

Then("the feedback {string} has priority {word}") do |comments, priority_name|
  feedback = feedback_named(comments).reload
  assert_equal PlaytestDomain::PRIORITY.fetch(priority_name), feedback.priority
end

Then("the feedback {string} is not linked to an escalation") do |comments|
  assert_nil feedback_named(comments).reload.escalation_id
end

Then("the comments on {string} are {string}") do |stored_comments, expected|
  assert_equal expected, feedback_named(stored_comments).reload.comments
end

Then("one escalation exists for {string} at severity {word}") do |module_title, severity_name|
  rule_module = RuleModule.find_by!(title: module_title)
  matches = Escalation.where(rule_module: rule_module, severity: PlaytestDomain::SEVERITY.fetch(severity_name))
  assert_equal 1, matches.count
  assert_equal PlaytestDomain::PRIORITY.fetch("escalated"), matches.first.priority
end

Then("no escalation exists") do
  assert_equal 0, Escalation.count
end

Then("{int} escalations exist") do |count|
  assert_equal count, Escalation.count
end
