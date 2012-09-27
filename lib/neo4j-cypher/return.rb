module Neo4j
  module Cypher


    # Can be used to skip result from a return clause
    class Skip
      include Clause

      def initialize(clause_list, value, context)
        super(clause_list, :skip, context)
        @value = value
      end

      def to_cypher
        @value
      end
    end

    # Can be used to limit result from a return clause
    class Limit
      include Clause

      def initialize(clause_list, value, context)
        super(clause_list, :limit, context)
        @value = value
      end

      def to_cypher
        @value
      end
    end

    class OrderBy
      include Clause

      def initialize(clause_list, context)
        super(clause_list, :order_by, context)
        @orders = []
      end

      def asc(props)
        @orders << [:asc, props.map(&:clause)]
      end

      def desc(props)
        @orders << [:desc, props.map(&:clause)]
      end

      def to_cypher
        @orders.map do |pair|
          if pair[0] == :asc
            pair[1].map{|p| p.alias_name || p.return_value}.join(', ')
          else
            pair[1].map{|p| p.alias_name || p.return_value}.join(', ') + " DESC"
          end
        end.join(', ')
      end
    end

    # Used for returning several values, e.g. RETURN x,y,z
    class Return
      include Clause

      attr_reader :return_items

      def initialize(clause_list, return_items, opts = {})
        super(clause_list, :return, EvalContext)
        @return_items = return_items.map { |ri| ri.is_a?(ReturnItem::EvalContext) ? ri.clause : ReturnItem.new(clause_list, ri) }
        opts.each_pair { |k, v| self.eval_context.send(k, v) }
      end

      def to_cypher
        @return_items.map(&:return_value_with_alias).join(',')
      end


      class EvalContext
        include Context
        include ReturnOrder
      end

    end

    # The return statement in the cypher query
    class ReturnItem
      include Clause
      attr_accessor :order_by

      def initialize(clause_list, name_or_ref)
        super(clause_list, :return_item, EvalContext)
        if name_or_ref.respond_to?(:clause)
          @delegated_clause = name_or_ref.clause
          @delegated_clause.referenced!
          as_alias(@delegated_clause.alias_name) if @delegated_clause.as_alias?
        else
          @return_value = name_or_ref.to_s
        end
      end

      def var_name
        @var_name || (@delegated_clause && @delegated_clause.var_name) || @return_value.to_sym
      end

      def return_value_with_alias
        as_alias? ? "#{return_value} as #{alias_name}" : return_value
      end

      def return_value
        @delegated_clause ? @delegated_clause.return_value : @return_value
      end

      class EvalContext
        include Context
        include Alias
        include ReturnOrder
        include Aggregate
        include Comparable
      end


    end
  end

end
