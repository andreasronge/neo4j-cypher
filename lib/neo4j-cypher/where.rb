module Neo4j
  module Cypher
    class Where
      include Clause

      def initialize(clause_list, context, where_statement = nil, &block)
        super(clause_list, :where)

        if where_statement
          @where_statement = where_statement
        else
          clause_list.push
          RootClause::EvalContext.new(context).instance_exec(context, &block)
          @where_statement = clause_list.to_cypher
          clause_list.pop
        end

      end

      def neg!
        @where_statement = "not(#{@where_statement})"
      end

      def to_cypher
        @where_statement
      end
    end
  end
end
