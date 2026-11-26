ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
# SimpleCov measures the application code (app/). The summary prints when
# the test process exits; the project target is >= 80% line coverage.
require "simplecov"
# Measure the application code only: everything outside app/ is test
# scaffolding. The project target is >= 80% line coverage of app/.
SimpleCov.start do
  add_filter "/config/"
  add_filter "/test/"
  add_filter "/spec/"
  add_filter "/lib/"
  add_filter "/features/"
  add_filter "/vendor/"
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
