module Neo4j
  module Cypher

    # Responsible for order of the clauses
    # Does expect a #clause method when included
    module Clause

      ORDER = [:start, :match, :create, :where, :with, :foreach, :set, :delete, :return, :order_by, :skip, :limit]
      NAME = {:start => 'START', :create => 'CREATE', :match => 'MATCH', :where => "WHERE", :with => 'WITH',
              :return => 'RETURN', :order_by => 'ORDER BY', :skip => 'SKIP', :limit => 'LIMIT', :set => 'SET',
              :delete => 'DELETE', :foreach => 'FOREACH'}

      attr_accessor :clause_type, :clause_list, :eval_context, :expr, :insert_order

      def initialize(clause_list, clause_type, eval_context = Context::Empty)
        @clause_type = clause_type
        @clause_list = clause_list
        if eval_context.is_a?(Class)
          @eval_context = eval_context.new(self)
        else
          @eval_context = eval_context
        end
        self.insert_order = 0
        clause_list.insert(self)
      end

      def <=>(other)
        clause_position == other.clause_position ? insert_order <=> other.insert_order : clause_position <=> other.clause_position
      end

      def clause_position
        valid_clause?
        ORDER.find_index(clause_type)
      end

      def valid_clause?
        raise "Unknown clause_type '#{clause_type}' on #{self}" unless ORDER.include?(clause_type)
      end

      def separator
        ','
      end

      def match_value=(mv)
        @match_value = mv
      end

      def match_value
        @match_value || expr || var_name
      end

      # Used in return clause to generate the last part of the return cypher clause string
      def return_value
        var_name
      end

      def prefix
        NAME[clause_type]
      end

      def create_clause_args_for(args)
        args.map do |arg|
          case arg
            when Neo4j::Cypher::ReturnItem::EvalContext, Neo4j::Cypher::Property::EvalContext
              Argument.new_arg_from_clause(arg.clause)
            when String, Symbol
              Argument.new_arg_from_string(arg, clause_list)
            when Neo4j::Cypher::NodeVar::EvalContext, Neo4j::Cypher::Start::EvalContext
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

    end

  end
end
