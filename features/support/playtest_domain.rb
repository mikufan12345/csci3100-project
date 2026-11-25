# frozen_string_literal: true

# Vocabulary and record lookup shared by the step definitions.
# Paths are strings on purpose: the routes are part of the contract the
# scenarios specify, and they are not all drawn yet.
module PlaytestDomain
  VERSION_STATUS = { "draft" => 0, "public" => 1, "archived" => 2 }.freeze
  FEEDBACK_STATUS = {
    "unreviewed" => 0,
    "valid_bug" => 1,
    "working_as_intended" => 2,
    "re_evaluation" => 3
  }.freeze
  SEVERITY = { "low" => 0, "medium" => 1, "high" => 2 }.freeze
  PRIORITY = { "normal" => 0, "escalated" => 1 }.freeze
  ROLES = { "playtester" => 0, "arbiter" => 1, "studio_admin" => 2 }.freeze

  def sign_in_as(email)
    login_as(User.find_by!(email: email), scope: :user)
  end

  def game_named(title)
    GameProject.find_by!(title: title)
  end

  def module_named(game_title, module_title)
    game_named(game_title).rule_modules.find_by!(title: module_title)
  end

  def version_named(game_title, number)
    game_named(game_title).rulebook_versions.find_by!(version_number: number)
  end

  def feedback_named(comments)
    Feedback.find_by!(comments: comments)
  end

  def assert_role(email, role_name, studio_name)
    user = User.find_by!(email: email)
    assert_equal ROLES.fetch(role_name), user.role
    assert_equal studio_name, user.studio.name
  end

  # Warden's login applies to the next request only, so sign in immediately
  # before the request that should be authenticated.
  def submit_as(email, method, path, params = {})
    sign_in_as(email)
    page.driver.submit(method, path, params)
  end
end

World(PlaytestDomain)
