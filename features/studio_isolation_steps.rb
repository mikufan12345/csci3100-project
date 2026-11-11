# Step definitions for features/studio_isolation.feature

Given("the studio {string} exists") do |name|
  Studio.find_or_create_by!(name: name)
end

Given("an admin {string} in the studio {string}") do |email, name|
  FactoryBot.create(:studio_admin, email: email, studio: Studio.find_by!(name: name))
end

Given("a playtester {string} in the studio {string}") do |email, name|
  FactoryBot.create(:user, email: email, studio: Studio.find_by!(name: name))
end

Given("the studio {string} has a game {string}") do |name, title|
  FactoryBot.create(:game_project, title: title, studio: Studio.find_by!(name: name))
end

When("alice signs in and visits the games page") do
  login_as(user_named("alice@example.com"), scope: :user)
  visit root_path
end

When("alice signs in and visits that game's page") do
  login_as(user_named("alice@example.com"), scope: :user)
  game = GameProject.find_by!(title: "Lorebreakers")
  visit game_project_path(game)
end

When("carol signs in and tries to create a game") do
  login_as(user_named("carol@example.com"), scope: :user)
  visit new_game_project_path
end

When("alice signs in and creates the game {string}") do |title|
  login_as(user_named("alice@example.com"), scope: :user)
  visit new_game_project_path
  fill_in "Title", with: title
  click_on "Create game"
end

Then("she sees {string}") do |text|
  assert page.has_text?(text), "expected to see #{text.inspect}"
end

Then("she does not see {string}") do |text|
  assert !page.has_text?(text), "should not see #{text.inspect}"
end

Then("the response is a {int}") do |status|
  assert_equal status, page.status_code
end

Then("the studio {string} lists a game {string}") do |name, title|
  assert Studio.find_by!(name: name).game_projects.pluck(:title).include?(title)
end

def user_named(email)
  User.find_by!(email: email)
end