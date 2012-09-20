require 'rake'
#require 'rcov/rcovtask'
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
#FileList = Rake::FileList

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

#Rcov::RcovTask.new do |t|
#  t.libs << "spec"
#  t.test_files = Rake::FileList['spec/**/*_spec.rb']
#  t.verbose = true
#end


task :default => 'spec'