module Neo4j
  module Cypher

    class RelVar
      include Clause

      def initialize(clause_list, expr, props = nil)
        super(clause_list, :rel_var, EvalContext)

        self.var_name = guess_var_name_from_string(expr.first) if expr.first.is_a?(String)

        if props
          @match_value = "#{match_value_from_args(expr)} #{to_prop_string(props)}"
        else
          @match_value = match_value_from_args(expr)
        end
      end

      def match_value_from_args(expr)
        if expr.first.is_a?(String)
          expr.first
        elsif expr.first.is_a?(Symbol)
          ":#{expr.map { |e| match_value_from_symbol(e) }.join('|')}"
        elsif expr.empty?
          '?'
        else
          # try to join several RelVars to one rel var
          ":#{expr.map { |e| e.clause.rel_type }.join('|')}"
        end
      end

      def guess_var_name_from_string(expr)
        guess = /([[:alpha:]_]*)/.match(expr)[1]
        guess && !guess.empty? && guess
      end

      def match_value_from_symbol(expr)
        "`#{expr}`"
      end

      def rel_type
        @match_value.include?(':') ? @match_value.split(':').last : @match_value.sub('?', '')
      end

      def referenced!
        eval_context.as(var_name) unless referenced?
        super
      end

      def return_value
        var_name
      end

      def optionally!
        if @match_value.include?('?')
          # We are done
        elsif @match_value.include?(':')
          @match_value.sub!(/:/, "?:")
        else
          @match_value += '?'
        end
        self
      end

      class EvalContext
        include Context
        include Variable
        include Returnable
        include Aggregate
        include Alias
        include Sortable


        def rel_type
          Property.new(clause, 'type').to_function!
        end


        def where(&block)
          x = block.call(self)
          clause_list.delete(x)
          Operator.new(clause_list, x.clause, nil, "").unary!
          self
        end

        def where_not(&block)
          x = block.call(self)
          clause_list.delete(x)
          Operator.new(clause_list, x.clause, nil, "not").unary!
          self
        end

        # generates a <tt>is null</tt> cypher fragment.
        def null
          clause.referenced!
          Operator.new(clause_list, self, nil, '', :where, " is null").unary!
        end


        def [](p)
          # TODO
          clause.referenced!
          property = super
          property.clause.match_value = clause.expr
          property
        end

        def as(name) # TODO DRY
          super
          super.tap do
            if clause.match_value == '?'
              clause.match_value = "#{clause.var_name}?"
            elsif clause.match_value.include?(':') || clause.match_value.include?('?')
              clause.match_value = clause.match_value.sub(/[^:\?]*/, clause.var_name.to_s)
            else
              clause.match_value = clause.var_name.to_s
            end
          end
        end
      end
    end

  end
end
