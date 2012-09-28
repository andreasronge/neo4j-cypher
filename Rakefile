require 'rake'
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

#Dir.glob('lib/tasks/*.rake').each { | rake_file | import rake_file }  unless ENV['TRAVIS'] == 'true'

desc "Run all specs"
RSpec::Core::RakeTask.new("spec") do |t|
  t.rspec_opts = ["-c"]
end

namespace :spec do
  desc "Create rspec coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].execute
  end
end

task :default => 'spec'