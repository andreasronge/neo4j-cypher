module Neo4j
  module Cypher
    module Context
      # @return [Neo4j::Cypher:Clause]
      attr_accessor :clause

      # @param [Neo4j::Cypher:Clause] clause the clause for this eval context
      def initialize(clause)
        @clause = clause

      end

      # @return [Array<Neo4j::Cypher:Clause>] the sorted clause list
      def clause_list
        @clause.clause_list
      end

      # Used for eval context for a clause which does not allow any more method chaining.
      class Empty
        include Context
      end

      module Alias
        # Typically used in a WITH statement for a count.as(:stuff) or node(42).as(:foo)
        def as(name)
          clause.as_alias(name)
          self
        end
      end

      module MathFunctions
        def abs(value=nil)
          _add_math_func(:abs, value)
        end

        def sqrt(value=nil)
          _add_math_func(:sqrt, value)
        end

        def round(value=nil)
          _add_math_func(:round, value)
        end

        def sign(value=nil)
          _add_math_func(:sign, value)
        end

        # @private
        def _add_math_func(name, value)
          value ||= clause.to_cypher
          clause_list.delete(clause)
          ReturnItem.new(clause_list, "#{name}(#{value})").eval_context
        end
      end

      module MathOperator
        def -(other)
          Operator.new(clause_list, clause, other, '-').eval_context
        end

        def +(other)
          Operator.new(clause_list, clause, other, '+').eval_context
        end
      end

      module Comparable
        def <(other)
          Operator.new(clause_list, clause, other, '<').eval_context
        end

        def <=(other)
          Operator.new(clause_list, clause, other, '<=').eval_context
        end

        def =~(other)
          Operator.new(clause_list, clause, other, '=~').eval_context
        end

        def >(other)
          Operator.new(clause_list, clause, other, '>').eval_context
        end

        def >=(other)
          Operator.new(clause_list, clause, other, '>=').eval_context
        end

        ## Only in 1.9
        if RUBY_VERSION > "1.9.0"
          eval %{
            def !=(other)
              Operator.new(clause_list, clause, other, "<>").eval_context
            end  }
        end

        def ==(other)
          Operator.new(clause_list, clause, other, "=").eval_context
        end
      end

      module PredicateMethods
        def all?(&block)
          Predicate.new(clause_list, 'all', self, &block).eval_context
        end

        def any?(&block)
          Predicate.new(clause_list, 'any', self, &block).eval_context
        end

        def none?(&block)
          Predicate.new(clause_list, 'none', self, &block).eval_context
        end

        def single?(&block)
          Predicate.new(clause_list, 'single', self, &block).eval_context
        end
      end

      module Returnable
        # Specifies a return statement.
        # Notice that this is not needed, since the last value of the DSL block will be converted into one or more
        # return statements.
        # @param [Symbol, #var_name] returns a list of variables we want to return
        # @return [ReturnItem]
        def ret(*returns, &block)
          options = returns.last.is_a?(Hash) ? returns.pop : {}
          returns = [self] if returns.empty? # return self unless not specified what to return
          returns = [RootClause::EvalContext.new(self).instance_exec(self, &block)].flatten if block
          r = Return.new(clause_list, returns, options, &block).eval_context
          (self.is_a?(RootClause::EvalContext)) ? r : self
        end

        # To return a single property, or the value of a function from a collection of nodes or relationships, you can use EXTRACT.
        # It will go through a collection, run an expression on every element, and return the results in an collection with these values.
        # It works like the map method in functional languages such as Lisp and Scala.
        # Will generate:
        #   EXTRACT( identifier in collection : expression )
        def extract(&block)
          Collection.new(clause_list, 'extract', self, &block).eval_context
        end

        # Returns all the elements in a collection that comply to a predicate.
        # Will generate
        #  FILTER(identifier in collection : predicate)
        def filter(&block)
          Collection.new(clause_list, 'filter', self, &block).eval_context
        end

        def foreach(&block)
          Foreach.new(clause_list, self, &block).eval_context
        end

      end

      module Sortable
        def _return_item
          @return_item ||= ReturnItem.new(clause_list, self).eval_context
        end

        def asc(*props)
          _return_item.asc(*props)
          self
        end

        def desc(*props)
          _return_item.desc(*props)
          self
        end

        def skip(val)
          _return_item.skip(val)
          self
        end

        def limit(val)
          _return_item.limit(val)
          self
        end
      end

      module ReturnOrder
        def _sort_args(props)
          return [self] if props.empty?
          props.map { |p| p.is_a?(Symbol) ? Property.new(clause, p).eval_context : p }
        end

        # Specifies an <tt>ORDER BY</tt> cypher query
        # @param [Property] props the properties which should be sorted
        # @return self
        def asc(*props)
          @order_by ||= OrderBy.new(clause_list, self)
          clause_list.delete(props.first)
          @order_by.asc(_sort_args(props))
          self
        end

        # Specifies an <tt>ORDER BY</tt> cypher query
        # @param [Property] props the properties which should be sorted
        # @return self
        def desc(*props)
          @order_by ||= OrderBy.new(clause_list, self)
          clause_list.delete(props.first)
          @order_by.desc(_sort_args(props))
          self
        end

        # Creates a <tt>SKIP</tt> cypher clause
        # @param [Fixnum] val the number of entries to skip
        # @return self
        def skip(val)
          Skip.new(clause_list, val, self)
          self
        end

        # Creates a <tt>LIMIT</tt> cypher clause
        # @param [Fixnum] val the number of entries to limit
        # @return self
        def limit(val)
          Limit.new(clause_list, val, self)
          self
        end

      end

      module Aggregate
        def distinct
          ReturnItem.new(clause_list, "distinct(#{clause.return_value})").eval_context
        end

        def count
          ReturnItem.new(clause_list, "count(#{clause.return_value})").eval_context
        end

        def sum
          ReturnItem.new(clause_list, "sum(#{clause.return_value})").eval_context
        end

        def avg
          ReturnItem.new(clause_list, "avg(#{clause.return_value})").eval_context
        end

        def min
          ReturnItem.new(clause_list, "min(#{clause.return_value})").eval_context
        end

        def max
          ReturnItem.new(clause_list, "max(#{clause.return_value})").eval_context
        end

        def collect
          ReturnItem.new(clause_list, "collect(#{clause.return_value})").eval_context
        end


        def last
          ReturnItem.new(clause_list, "last(#{clause.return_value})").eval_context
        end

        def tail
          ReturnItem.new(clause_list, "tail(#{clause.return_value})").eval_context
        end

        def head
          ReturnItem.new(clause_list, "head(#{clause.return_value})").eval_context
        end

      end

      module Variable
        def where(&block)
          Where.new(clause_list, self, &block)
          self
        end

        def where_not(&block)
          Where.new(clause_list, self, &block).neg!
          self
        end

        def [](prop_name)
          Property.new(clause, prop_name).eval_context
        end

        # generates a <tt>ID</tt> cypher fragment.
        def neo_id
          Property.new(clause, 'ID').to_function!
        end

        # generates a <tt>has</tt> cypher fragment.
        def property?(p)
          p = Property.new(clause, p)
          Operator.new(clause_list, p, nil, "has").unary!
        end

        def []=(p, value)
          left = Property.new(clause, p).eval_context
          Operator.new(clause_list, left, value, "=", :set)
          self
        end

        def set_label(*labels)
          Label.new(clause_list, clause, labels, :set)
          self
        end

        def del_label(*labels)
          Label.new(clause_list, clause, labels, :remove)
          self
        end

        def del
          Delete.new(clause_list, clause)
          self
        end

        # Can be used instead of [_classname] == klass
        def is_a?(klass)
          return super if klass.class != Class || !klass.respond_to?(:_load_wrapper)
          self[:_classname] == klass.to_s
        end
      end

      module Matchable

        ## Only in 1.9
        if RUBY_VERSION > "1.9.0"
          eval %{
            def !=(other)
              Operator.new(clause_list, clause, other, "<>").eval_context
            end  }
        end

        def ==(other)
          Operator.new(clause_list, clause, other, "=").eval_context
        end


        def match(&cypher_dsl)
          RootClause::EvalContext.new(self).instance_exec(self, &cypher_dsl)
          self
        end

        def with(*args, &cypher_dsl)
          With.new(clause_list, :where, self, *args, &cypher_dsl)
          self
        end

        def with_match(*args, &cypher_dsl)
          With.new(clause_list, :match, self, *args, &cypher_dsl)
          self
        end

        def create_path(*args, &cypher_dsl)
          CreatePath.new(clause_list, self, *args, &cypher_dsl)
          self
        end

        def create_unique_path(*args, &cypher_dsl)
          CreatePath.new(clause_list, self, *args, &cypher_dsl).unique!
          self
        end


        # This operator means related to, without regard to type or direction.
        # @param [Symbol, #var_name] other either a node (Symbol, #var_name)
        # @return [MatchRelLeft, MatchNode]
        def <=>(other)
          MatchStart.new_match_node(clause, other, :both).eval_context
        end

        # This operator means outgoing related to
        # @param [Symbol, #var_name, String] other the relationship
        # @return [MatchRelLeft, MatchNode]
        def >(other)
          MatchStart.new(clause).new_match_rel(other).eval_context
        end

        # This operator means any direction related to
        # @param (see #>)
        # @return [MatchRelLeft, MatchNode]
        def -(other)
          MatchStart.new(clause).new_match_rel(other).eval_context
        end

        # This operator means incoming related to
        # @param (see #>)
        # @return [MatchRelLeft, MatchNode]
        def <(other)
          MatchStart.new(clause).new_match_rel(other).eval_context
        end

        # Outgoing relationship to other node
        # @param [Symbol, #var_name] other either a node (Symbol, #var_name)
        # @return [MatchRelLeft, MatchNode]
        def >>(other)
          MatchStart.new_match_node(clause, other, :outgoing).eval_context
        end

        # Incoming relationship to other node
        # @param [Symbol, #var_name] other either a node (Symbol, #var_name)
        # @return [MatchRelLeft, MatchNode]
        def <<(other)
          MatchStart.new_match_node(clause, other, :incoming).eval_context
        end

        def outgoing(*rel_types)
          node = _get_or_create_node(rel_types)
          MatchStart.new(clause).new_match_rels(rel_types).eval_context > node
          node.eval_context
        end

        def _get_or_create_node(rel_types)
          rel_types.last.kind_of?(Matchable) ? rel_types.pop.clause : NodeVar.new(clause.clause_list)
        end

        def outgoing?(*rel_types)
          node = _get_or_create_node(rel_types)
          MatchStart.new(clause).new_match_rels?(rel_types).eval_context > node
          node.eval_context
        end

        def incoming(*rel_types)
          node = _get_or_create_node(rel_types)
          MatchStart.new(clause).new_match_rels(rel_types).eval_context < node
          node.eval_context
        end

        def incoming?(*rel_types)
          node = _get_or_create_node(rel_types)
          MatchStart.new(clause).new_match_rels?(rel_types).eval_context < node
          node.eval_context
        end

        def both(*rel_types)
          node = _get_or_create_node(rel_types)
          MatchStart.new(clause).new_match_rels(rel_types).eval_context - node
          node.eval_context
        end

        def both?(*rel_types)
          node = _get_or_create_node(rel_types)
          MatchStart.new(clause).new_match_rels?(rel_types).eval_context - node
          node.eval_context
        end
      end


    end
  end
end
