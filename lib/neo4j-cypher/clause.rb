module Neo4j
  module Cypher

    # Responsible for order of the clauses
    # Does expect a #clause method when included
    module Clause

      ORDER = [:start, :match, :create, :where, :with, :foreach, :set, :delete, :remove, :return, :order_by, :skip, :limit]
      NAME = {:start => 'START', :create => 'CREATE', :match => 'MATCH', :where => "WHERE", :with => 'WITH',
              :return => 'RETURN', :order_by => 'ORDER BY', :skip => 'SKIP', :limit => 'LIMIT', :set => 'SET',
              :remove => 'REMOVE', :delete => 'DELETE', :foreach => 'FOREACH'}

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
        clause_type == :where ? ' and ' : ','
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

      def var_name
        @var_name ||= @clause_list.create_variable(self)
      end

      def var_name=(new_name)
        @var_name = new_name.to_sym if new_name
      end

      def referenced?
        !!@referenced
      end

      def referenced!
        @referenced = true
      end

      def as_alias(new_name)
        @alias = new_name
        self.var_name = new_name
      end

      def alias_name
        @alias
      end

      def as_alias?
        !!@alias && var_name != return_value
      end

      def to_prop_string(props)
        key_values = props.keys.map do |key|
          raw = key.to_s[0, 1] == '_'
          escaped_string = props[key].gsub(/['"]/) { |s| "\\#{s}" } if props[key].is_a?(String) && !raw
          val = props[key].is_a?(String) && !raw ? "'#{escaped_string}'" : props[key]
          "#{raw ? key.to_s[1..-1] : key} : #{val}"
        end
        "{#{key_values.join(', ')}}"
      end

      def create_clause_args_for(args)
        args.map do |arg|
          case arg
            when Neo4j::Cypher::ReturnItem::EvalContext, Neo4j::Cypher::Property::EvalContext
              Argument.new_arg_from_clause(arg.clause)
            when String, Symbol
              Argument.new_arg_from_string(arg, clause_list)
            else
              arg.clause
          end
        end
      end
    end

  end
end
