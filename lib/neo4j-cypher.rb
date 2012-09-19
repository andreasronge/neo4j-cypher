require 'neo4j-cypher/version'

require 'neo4j-cypher/context'
require 'neo4j-cypher/mixins'
require 'neo4j-cypher/clause'
require 'neo4j-cypher/clause_list'
require 'neo4j-cypher/argument'
require 'neo4j-cypher/root'
require 'neo4j-cypher/start'
require 'neo4j-cypher/create'
require 'neo4j-cypher/match'
require 'neo4j-cypher/return'
require 'neo4j-cypher/node_var'
require 'neo4j-cypher/rel_var'
require 'neo4j-cypher/property'
require 'neo4j-cypher/predicate'
require 'neo4j-cypher/with'
require 'neo4j-cypher/operator'
require 'neo4j-cypher/where'

module Neo4j
  module Cypher

    # Creates a Cypher DSL query.
    # To create a new cypher query you must initialize it either an String or a Block.
    #
    # @example <tt>START n0=node(3) MATCH (n0)--(x) RETURN x</tt> same as
    #   Cypher.query { start n = node(3); match n <=> :x; ret :x }.to_s
    #
    # @example <tt>START n0=node(3) MATCH (n0)-[:`r`]->(x) RETURN r</tt> same as
    #   Cypher.query { node(3) > :r > :x; :r }
    #
    # @example <tt>START n0=node(3) MATCH (n0)-->(x) RETURN x</tt> same as
    #   Cypher.query { node(3) >> :x; :x }
    #
    # @param args the argument for the dsl_block
    # @yield the block which will be evaluated in the context of this object in order to create an Cypher Query string
    # @yieldreturn [Return, Object] If the return is not an instance of Return it will be converted it to a Return object (if possible).
    # @return [Cypher::Result]
    def self.query(*args, &dsl_block)
      Result.new(*args, &dsl_block)
    end


    class Result

      def initialize(*args, &dsl_block)
        @root = Neo4j::Cypher::RootClause.new
        eval_context = @root.eval_context
        to_dsl_args = args.map do |a|
          case
            when a.is_a?(Array) && a.first.respond_to?(:_java_node)
              eval_context.node(*a)
            when a.is_a?(Array) && a.first.respond_to?(:_java_rel)
              eval_context.rel(*a)
            when a.respond_to?(:_java_node)
              eval_context.node(a)
            when a.respond_to?(:_java_rel)
              eval_context.rel(a)
            else
              raise "Illegal argument #{a.class}"
          end

        end
        @root.execute(to_dsl_args, &dsl_block)
        @result = @root.return_value
      end

      def return_names
        @root.return_names
      end

      # Converts the DSL query to a cypher String which can be executed by cypher query engine.
      def to_s
        @result
      end

    end

  end
end
