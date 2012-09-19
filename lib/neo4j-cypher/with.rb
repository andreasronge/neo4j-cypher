module Neo4j
  module Cypher
    class With
      include Clause

      attr_reader :arg_list

      def initialize(clause_list, where_or_match, *args, &cypher_dsl)
        super(clause_list, :with, EvalContext)

        @args = create_clause_args_for(args)
        @arg_list = @args.map { |a| a.return_value }.join(',')
        @where_or_match = where_or_match
        arg_exec = @args.map(&:eval_context)

        old_match_clauses = clause_list.find_all(:match, :create, :where)
        clause_list.remove_all(:match, :create, :where)
        RootClause::EvalContext.new(self).instance_exec(*arg_exec, &cypher_dsl)
        # Create Path means that we convert all the match clauses to create clauses
        new_match_clauses = clause_list.find_all(:match, :where)
        clause_list.remove_all(:match, :create, :where)

        # The create node is done a bit different if it's in a create path clause
        old_match_clauses.each { |c| clause_list.insert(c) }

        @body = clause_list.join_group(new_match_clauses) unless new_match_clauses.empty?
      end


      def create_clause_args_for(args)
        args.map do |arg|
          case arg
            when Neo4j::Core::Cypher::ReturnItem::EvalContext, Neo4j::Core::Cypher::Property::EvalContext
              Argument.new_arg_from_clause(arg.clause)
            when String, Symbol
              Argument.new_arg_from_string(clause_list, arg)
            when Neo4j::Core::Cypher::NodeVar::EvalContext, Neo4j::Core::Cypher::Start::EvalContext
              arg.clause
            else
              raise "not supported #{arg.class}"
          end
        end
      end

      def create_arg_list(args)
        args.map do |a|
          if a.is_a?(String) || a.is_a?(Symbol)
            a.to_sym
          else
            a.clause.var_name
          end
        end
      end

      def to_cypher
        @body ? "#{@arg_list} #{@where_or_match.to_s.upcase} #{@body}" : @arg_list
      end

      class EvalContext
        include Context
        include Alias
        include ReturnOrder
        include Aggregate
        include Comparable
        include Returnable
      end

    end


  end
end
