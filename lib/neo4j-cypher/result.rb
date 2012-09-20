module Neo4j
  module Cypher

    # Generates a Cypher string from a Ruby DSL
    # The result returned by #to_s and the last Cypher return columns can be found #return_names.
    # The cypher query will only be generated once - in the constructor.
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