module Neo4j
  module Cypher
    class AbstractFilter
      include Clause

      def filter_initialize(input_context, method_name, selector_token, &block)
        input = input_context.clause
        fe = filter_expr(input, selector_token, &block)
        @cypher = "#{method_name}#{fe}"
      end

      def return_value
        @cypher
      end

      def to_cypher
        @cypher
      end

      def filter_arg(input)
        var = NodeVar.as_var(clause_list, 'x')

        if input.is_a?(Neo4j::Cypher::Property)
          filter_input = Property.new(var)
          filter_input.expr = 'x'
          filter_input.eval_context
        else
          input.referenced!
          var.eval_context
        end
      end

      def filter_value(input)
        input.is_a?(Neo4j::Cypher::Property) ? input.expr : input.return_value
      end

      def filter_exec(arg, &block)
        clause_list.push
        ret = RootClause::EvalContext.new(self).instance_exec(arg, &block)
        filter = clause_list.empty? ? ret.clause.to_cypher : clause_list.to_cypher
        clause_list.pop
        filter
      end

      def filter_expr(input, selector_token, &block)
        expr = "(x in #{filter_value(input)}"
        arg = filter_arg(input)
        filter = filter_exec(arg, &block)
        expr << "#{selector_token}#{filter})"
        # WHERE all(x in nodes(v1) WHERE x.age > 30)
        expr
      end

    end
  end

end