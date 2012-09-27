module Neo4j
  module Cypher
    class Foreach < AbstractFilter

      def initialize(clause_list, input_context, &block)
        super(clause_list, :foreach, input_context)
        # Input can either be a property array or a node/relationship collection
        input = input_context.clause
        clause_list.delete(input)
        filter_initialize(input_context, '', " : ", &block)
      end

    end
  end

end