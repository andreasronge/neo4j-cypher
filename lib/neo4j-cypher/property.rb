module Neo4j
  module Cypher

    # A property is returned from a Variable by using the [] operator.
    #
    # It has a number of useful method like
    # <tt>count</tt>, <tt>sum</tt>, <tt>avg</tt>, <tt>min</tt>, <tt>max</tt>, <tt>collect</tt>, <tt>head</tt>, <tt>last</tt>, <tt>tail</tt>,
    #
    # @example
    #  n=node(2, 3, 4); n[:name].collect
    #  # same as START n0=node(2,3,4) RETURN collect(n0.property)
    class Property
      include Referenceable
      include Clause

      def initialize(var, prop_name = nil)
        super(var.clause_list, :property, EvalContext)
        @var = var
        self.var_name = var.var_name
        @prop_name = prop_name
        @expr = prop_name ? "#{var.var_name}.#{prop_name}" : var.var_name.to_s
      end


      # @private
      def to_function!(prop_name = nil)
        @expr = "#{prop_name || @prop_name}(#{var_name})"
        eval_context
      end

      def return_value
        to_cypher
      end


      def match_value
        @var.match_value
      end

      def unary_operator(op, clause_type = :where, post_fix = nil)
        # TODO DELETE THIS ?
        Operator.new(clause_list, self, nil, op, clause_type, post_fix).unary!
      end


      def to_cypher
        @expr
      end

      class EvalContext
        include Context
        include Alias
        include Comparable
        include MathOperator
        include MathFunctions
        include PredicateMethods
        include Aggregate
        include Sortable # TODO REMOVE THIS LINE

        def asc
          ReturnItem.new(clause_list, self).eval_context.asc
        end

        def desc
          ReturnItem.new(clause_list, self).eval_context.desc
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

        # required by the Predicate Methods Module
        # @see PredicateMethods
        # @private
        def iterable
          clause.return_value
        end

        def input
          clause
        end

        # @private
        def in?(values)
          clause.unary_operator("", :where, " IN [#{values.map { |x| %Q["#{x}"] }.join(',')}]")
        end

        def length
          clause.to_function!('length')
          self
        end
      end

    end

  end
end
