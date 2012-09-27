module Neo4j
  module Cypher
    class Foreach
      include Clause

      def initialize(clause_list, input_context, &block)
        super(clause_list, :foreach, input_context)
        # Input can either be a property array or a node/relationship collection
        input = input_context.clause
        clause_list.delete(input)
        @cypher = ""

        var = NodeVar.as_var(clause_list, 'x')

        if input.is_a?(Neo4j::Cypher::Property)
          @cypher << "(x in #{input.expr}"
          filter_input = Property.new(var)
          filter_input.expr = 'x'
          input.expr = :x
        else
          filter_input = var
          input.referenced!
          @cypher << "(x in #{input.return_value}"
        end
        clause_list.push

        x = RootClause::EvalContext.new(self).instance_exec(filter_input.eval_context, &block)
        filter_expr = clause_list.to_cypher

        @cypher << " : #{filter_expr})"
        clause_list.pop
      end

      def to_cypher
        @cypher
      end
    end
  end

end