module Neo4j
  module Cypher
    class Where
      include Clause

      def initialize(clause_list, where_statement = nil)
        super(clause_list, :where)
        @where_statement = where_statement
      end

      def to_cypher
        @where_statement.to_s
      end
    end
  end
end
