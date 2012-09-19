module Neo4j
  module Cypher

    class RelVar
      include Clause
      include ToPropString
      include Referenceable

      def initialize(clause_list, expr, props = nil)
        super(clause_list, :rel_var, EvalContext)

        case expr
          when String
            @match_value = expr.empty? ? '?' : expr.to_s
            guess = expr.is_a?(String) && /([[:alpha:]_]*)/.match(expr)[1]
            self.var_name = guess.to_sym if guess && !guess.empty?
          when Symbol
            @match_value = ":`#{expr}`"
          else
            raise "Illegal arg for rel #{expr.class}"
        end

        @match_value = "#@match_value #{to_prop_string(props)}" if props
      end

      def rel_type
        @match_value.include?(':') ? @match_value.split(':').last : @match_value.sub('?', '')
      end

      def self.join(clause_list, rel_types)
        rel_string = rel_types.map { |r| _rel_to_string(clause_list, r) }.join('|')

        if rel_string.empty?
          RelVar.new(clause_list, "")
        else
          RelVar.new(clause_list, ":#{rel_string}")
        end
      end

      def self._rel_to_string(clause_list, rel_or_symbol)
        case rel_or_symbol
          when String, Symbol
            RelVar.new(clause_list, rel_or_symbol).rel_type
          when Neo4j::Core::Cypher::RelVar::EvalContext
            rel_or_symbol.clause.rel_type
          else
            raise "Unknown type of relationship, got #{rel_or_symbol.class}"
        end
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
