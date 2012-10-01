module Neo4j
  module Cypher
    class With
      include Clause

      attr_reader :arg_list

      def initialize(clause_list, where_or_match, *args, &cypher_dsl)
        super(clause_list, :with, EvalContext)

        clause_list.push

        @args = create_clause_args_for(args)
        @arg_list = @args.map { |a| a.return_value }.join(',')
        arg_exec = @args.map(&:eval_context)

        RootClause::EvalContext.new(self).instance_exec(*arg_exec, &cypher_dsl)
        @body = "#{where_or_match.to_s.upcase} #{clause_list.to_cypher}"
        clause_list.pop
      end

      def to_cypher
        @body ? "#{@arg_list} #{@body}" : @arg_list
      end

      class EvalContext
        include Context
        include Alias
        include Sortable
        include Aggregate
        include Comparable
        include Returnable
      end

    end


  end
end
