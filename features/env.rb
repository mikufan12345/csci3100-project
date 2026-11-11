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

include FactoryBot::Syntax::Methods

# Sign-in helper for steps: `login_as(user, scope: :user)` in step definitions.
# (Devise 5 dropped the old IntegrationHelpers API, so we drive Warden directly.)
require "warden/test/helpers"
include Warden::Test::Helpers
Before { Warden.test_mode! }
After { Warden.test_reset! }

# Clean the database before and after every scenario (DatabaseCleaner drives
# the actual truncation; cucumber-rails v4 only provides the hook plumbing).
require "database_cleaner-active_record"
DatabaseCleaner.strategy = :truncation
Before { DatabaseCleaner.clean }
After { DatabaseCleaner.clean }