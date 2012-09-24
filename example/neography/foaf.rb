require 'rubygems'
require "bundler/setup"
require 'neography'
require 'neo4j-cypher'
require 'neo4j-cypher/neography' #adds a Neography::Rest#execute_cypher method

@neo = Neography::Rest.new

def create_person(name)
  Neography::Node.create("name" => name)
end

johnathan = create_person('Johnathan')
mark      = create_person('Mark')
phil      = create_person('Phil')
mary      = create_person('Mary')
luke      = create_person('Luke')

johnathan.both(:friends) << mark
mark.both(:friends) << mary
mark.both(:friends) << phil
phil.both(:friends) << mary
phil.both(:friends) << luke


def suggestions_for(n)
  # Same as START me = node({node_id}) MATCH (me)-[:friends]->(friend)-[:friends]->(foaf) RETURN foaf.name
  @neo.execute_cypher(n) { |me| me > ':friends' > node > ':friends' > node(:foaf)[:name].ret }['data']

  # or
  # @neo.execute_cypher(n) { |me| me > ':friends' > node > ':friends' > node(:foaf); ret(node(:foaf)[:name])}['data']

  # or
  # @neo.execute_cypher(n) { |me| me > rel(:friends) > node > rel(:friends) > node(:foaf); ret(node(:foaf)[:name])}['data']

  # or
  # @neo.execute_cypher(n) { |me| me.outgoing(':friends').outgoing(':friends')[:name]}['data']
end

puts "Johnathan should become friends with #{suggestions_for(johnathan).join(', ')}"

