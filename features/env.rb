# Runs the features against the test environment/database, same as CI.
ENV["RAILS_ENV"] ||= "test"
ENV["RAILS_ROOT"] ||= File.expand_path("..", __dir__)
require_relative "../config/environment"
require "cucumber/rails"

Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 2

require "factory_bot"
FactoryBot.definition_file_paths = [Rails.root.join("test", "factories")]
FactoryBot.reload

require "minitest"
module CucumberAssertions
  include Minitest::Assertions
  attr_accessor :assertions
end

# Step bodies run on the Cucumber World, so helpers have to be mixed in there.
# Devise 5 dropped IntegrationHelpers; login_as comes from Warden's test mode.
require "warden/test/helpers"
World(CucumberAssertions)
World(FactoryBot::Syntax::Methods)
World(Warden::Test::Helpers)

Before do
  self.assertions = 0
  Warden.test_mode!
end
After { Warden.test_reset! }

# Clean the database before and after every scenario (DatabaseCleaner drives
# the actual truncation; cucumber-rails v4 only provides the hook plumbing).
require "database_cleaner-active_record"
DatabaseCleaner.strategy = :truncation
Before { DatabaseCleaner.clean }
After { DatabaseCleaner.clean }