require 'rubygems'
require "bundler/setup"

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
    add_group 'Source', 'lib'
  end
end

require 'rspec'
require 'its'
require 'logger'
require 'neo4j-cypher'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  c.include(CustomNeo4jMatchers)
end
