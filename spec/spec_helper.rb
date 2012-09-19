require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'its'
require 'logger'

require 'neo4j-cypher'
#require 'pry'


Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  c.include(CustomNeo4jMatchers)

end
