# frozen_string_literal: true

namespace :test do
  desc "Run the RSpec examples and the Cucumber scenarios. Both must pass."
  task :all do
    rspec_ok = system("bundle exec rspec")
    cucumber_ok = system("bundle exec cucumber")
    abort("test:all failed") unless rspec_ok && cucumber_ok
  end
end
