# Cucumber environment hook. cucumber-rails loads the Rails app after this
# file runs, so SimpleCov starts here: it tracks the application files as
# they load, which the support files could not do.

ENV["RAILS_ENV"] ||= "test"
require "simplecov"

# Measure the application code only: everything outside app/ is test
# scaffolding. The project target is >= 80% line coverage of app/.
SimpleCov.start do
  project_name "Cucumber"
  add_filter "/config/"
  add_filter "/test/"
  add_filter "/spec/"
  add_filter "/lib/"
  add_filter "/features/"
  add_filter "/vendor/"
end