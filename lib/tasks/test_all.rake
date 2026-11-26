# frozen_string_literal

namespace :test do
  desc "Run the RSpec examples and the Cucumber scenarios. Both must pass, and the combined line coverage of app/ is reported (project target: >= 80%)."
  task :all do
    rspec_ok = system("bundle exec rspec")
    cucumber_ok = system("bundle exec cucumber")
    if rspec_ok && cucumber_ok
      # Report the combined line coverage: SimpleCov merges the RSpec and
      # Cucumber result sets in coverage/.resultset.json (the last suite's
      # exit report already covers both). The target is >= 80% of app/.
      require "json"
      resultset = Rails.root.join("coverage", ".resultset.json")
      if File.exist?(resultset)
        # Union across the RSpec and Cucumber result sets: a line is counted
        # once per file, and it is covered when any suite hit it.
        lines = Hash.new { |h, k| h[k] = Hash.new(false) } # path => line index => covered?
        JSON.parse(File.read(resultset)).each_value do |result|
          result["coverage"].each do |path, file|
            file["lines"].each_with_index do |hits, index|
              next if hits.nil?

              lines[path][index] = hits.positive?
            end
          end
        end
        total = lines.values.sum { |by_line| by_line.size }
        covered = lines.values.sum { |by_line| by_line.values.count(true) }
        percent = total.zero? ? 100.0 : (covered.to_f / total * 100)
        puts "Combined line coverage of app/: #{covered} / #{total} (#{format('%.2f', percent)}%)"
        warn "WARNING: below the 80% project target" if percent < 80
      end
    else
      abort("test:all failed")
    end
  end
end