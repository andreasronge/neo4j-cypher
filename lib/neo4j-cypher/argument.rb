module Neo4j
  module Cypher

    class Argument
      include Clause

      def initialize(clause_list, expr, var_name)
        super(clause_list, :argument, EvalContext)
        var_name ||= self.var_name
        @expr = var_name
        as_alias(var_name)
        @return_value = (expr != var_name.to_s) ? "#{expr} as #{var_name}" : expr
      end

      def return_value
        @return_value
      end

      def self.new_arg_from_clause(clause)
        Argument.new(clause.clause_list, clause.return_value, clause.as_alias? && clause.alias_name)
      end

      def self.new_arg_from_string(string, clause_list)
        Argument.new(clause_list, string.to_s, string)
      end

      class EvalContext
        include Context
        include Comparable
        include MathOperator
        include MathFunctions
        include PredicateMethods
        include Aggregate
      end

    end
  end
end
