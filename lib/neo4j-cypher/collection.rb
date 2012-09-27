module Neo4j
  module Cypher

    class Collection < AbstractFilter

      def initialize(clause_list, method_name, input_context, &block)
        super(clause_list, :return_item)
        clause_list.delete(input_context)
        filter_initialize(input_context, method_name, " : ", &block)
      end

    end
  end
end
