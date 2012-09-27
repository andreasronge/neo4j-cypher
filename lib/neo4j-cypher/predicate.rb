module Neo4j
  module Cypher
    class Predicate < AbstractFilter

      def initialize(clause_list, method_name, input_context, &block)
        super(clause_list, :where, input_context)
        # Input can either be a property array or a node/relationship collection
        filter_initialize(input_context, method_name, " WHERE ", &block)
      end
    end

  end
end
