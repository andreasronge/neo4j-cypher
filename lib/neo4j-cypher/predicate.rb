module Neo4j
  module Cypher
    class Predicate
      include Clause

      def initialize(clause_list, method_name, input_context, &block)
        super(clause_list, :where, input_context)
        # Input can either be a property array or a node/relationship collection
        input = input_context.clause

        @cypher = method_name

        var = NodeVar.as_var(clause_list, 'x')

        if input.is_a?(Neo4j::Cypher::Property)
          @cypher << "(x in #{input.expr}"
          filter_input = Property.new(var)
          filter_input.expr = 'x'
          input.expr = :x
        else
          filter_input = var
          @cypher << "(x in #{input.return_value}"
        end
        clause_list.push

        x = RootClause::EvalContext.new(self).instance_exec(filter_input.eval_context, &block)
        filter_expr = clause_list.to_cypher

        @cypher << " WHERE #{filter_expr})"
        # WHERE all(x in nodes(v1) WHERE x.age > 30)
        clause_list.pop
      end

      def to_cypher
        @cypher
      end
    end

  end
end
