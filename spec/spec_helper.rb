require 'rubygems'
require "bundler/setup"

unless ENV['TRAVIS']
  require 'simplecov'
  SimpleCov.start
end

require 'rspec'
require 'its'
require 'logger'
require 'neo4j-cypher'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  c.include(CustomNeo4jMatchers)
end
