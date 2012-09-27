module Neo4j
  module Cypher

    class Collection
      include Clause

      def initialize(clause_list, method_name, input_context, &block)
        super(clause_list, :return_item)
        # Input can either be a property array or a node/relationship collection
        input = input_context.clause
        clause_list.delete(input)
        @cypher = method_name

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
        filter_expr = x.clause.to_cypher

        @cypher << " : #{filter_expr})"
        # WHERE all(x in nodes(v1) WHERE x.age > 30)
        clause_list.pop
      end

      def return_value
        @cypher
      end

    end
  end
end
