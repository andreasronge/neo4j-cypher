module Neo4j
  module Cypher

    # Represents an unbound node variable used in match statements
    class NodeVar
      include Clause

      def initialize(clause_list, var_name = nil)
        super(clause_list, :node_var, EvalContext)
        @var_name = var_name
      end

      def self.as_var(clause_list, something)
        if something.is_a?(Symbol) || something.is_a?(String)
          NodeVar.new(clause_list, something)
        elsif something.respond_to?(:clause)
          something.clause
        else
          something
        end
      end

      def expr
        var_name
      end

      # @return [String] a cypher string for this node variable
      def to_cypher
        var_name
      end

      def return_value
        to_cypher
      end

      class EvalContext
        include Context
        include Variable
        include Matchable
        include Returnable
        include Aggregate
        include Alias
        include Sortable


        def initialize(clause)
          super
        end

        def new(props = nil, *labels)
          clause.clause_list.delete(clause)
          Create.new(clause_list, props, labels).eval_context
        end

        def [](p)
          property = Property.new(clause, p)
          property.match_value = clause.var_name
          property.eval_context
        end

      end
    end

  end
end
