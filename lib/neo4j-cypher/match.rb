module Neo4j
  module Cypher

    class MatchStart
      include Clause

      attr_reader :match_list
      attr_accessor :algorithm

      def initialize(from)
        super(from.clause_list, :match)
        @from = from
        @match_list = []
      end

      def new_match_node(from, to, dir)
        NodeMatchContext.new_first(self, from, to, dir)
        self
      end

      def new_match_rel(rel)
        RelLeftMatchContext.new(self, @from).set_rel(rel)
        self
      end

      def new_match_rels(rels)
        RelLeftMatchContext.new(self, @from).set_rels(rels)
        self
      end

      def new_match_rels?(rels)
        RelLeftMatchContext.new(self, @from).set_rels?(rels)
        self
      end


      def eval_context
        @match_list.last
      end


      #negate this match
      def not
        clause_list.delete(self)
        Operator.new(clause_list, self, nil, "not").unary!
      end

      def to_cypher
        match_string = @match_list.map(&:to_cypher).join
        match_string = algorithm ? "#{algorithm}(#{match_string})" : match_string
        referenced? ? "#{var_name} = #{match_string}" : match_string
      end

      def self.new_match_node(from, to, dir)
        MatchStart.new(from).new_match_node(from, to, dir)
      end

      module MatchContext


        ## Only in 1.9
        if RUBY_VERSION > "1.9.0"
          eval %{
            def !
              Operator.new(clause_list, clause, nil, "not").unary!
            self
            end  }
        end

        def initialize(match_start)
          super(match_start)
          @match_start = match_start
          @match_start.match_list << self
        end

        def convert_create_clauses(to_or_from)
          # perform a create operation in a match clause ?
          c = to_or_from.respond_to?(:clause) ? to_or_from.clause : to_or_from
          if c.respond_to?(:clause_type) && c.clause_type == :create
            clause_list.delete(c)
            c.as_create_path!
          end
        end

        def clause
          @match_start
        end

        def join_previous!
          @join_previous = true
          self
        end

        def join_previous?
          @join_previous
        end

        def to_cypher
          if join_previous?
            to_cypher_join
          else
            to_cypher_no_join
          end
        end

        # Generates a <tt>x in nodes(m3)</tt> cypher expression.
        #
        # @example
        #   p.nodes.all? { |x| x[:age] > 30 }
        def nodes
          Entities.new(clause.clause_list, "nodes", self).eval_context
        end

        # Generates a <tt>x in relationships(m3)</tt> cypher expression.
        #
        # @example
        #   p.relationships.all? { |x| x[:age] > 30 }
        def rels
          Entities.new(clause.clause_list, "relationships", self).eval_context
        end

        # returns the length of the path
        def length
          clause.referenced!
          Property.new(clause, 'length').to_function!
        end

        def not
          clause.not
        end
      end

      module JoinableMatchContext

        def next_new_node(to, dir)
          to_var = NodeVar.as_var(@match_start.clause_list, to)
          NodeMatchContext.new(@match_start, self, to_var, dir).join_previous!
        end

        def next_new_rel(rel)
          RelLeftMatchContext.new(@match_start, self).set_rel(rel).join_previous!
        end

        def <=>(other)
          next_new_node(other, :both)
        end

        def >>(other)
          next_new_node(other, :outgoing)
        end

        def <<(other)
          next_new_node(other, :incoming)
        end

        def <(rel)
          next_new_rel(rel)
        end

        def >(rel)
          next_new_rel(rel)
        end

        def -(rel)
          next_new_rel(rel)
        end

      end

      module Algorithms

        def shortest_path
          @match_start.algorithm = "shortestPath"
          @match_start.eval_context
        end

        def shortest_paths
          @match_start.algorithm = "allShortestPaths"
          @match_start.eval_context
        end
      end

      class RelLeftMatchContext
        include Context
        include MatchContext

        def initialize(match_start, from)
          super(match_start)
          @from = from
          convert_create_clauses(from)
        end

        def set_rels(rels)
          if rels.size == 1
            set_rel(rels.first)
          else
            # wrap and maybe join several relationship strings
            @rel_var = RelVar.new(clause_list, rels)
          end
          self
        end

        def set_rels?(rels)
          set_rels(rels)
          @rel_var.optionally!
          self
        end

        def set_rel(rel)
          return set_rels(rel) if rel.is_a?(Array)

          if rel.is_a?(Neo4j::Cypher::RelVar::EvalContext)
            @rel_var = rel.clause
          elsif rel.respond_to?(:clause) && rel.clause.match_value
            @rel_var = rel.clause
          else
            @rel_var = RelVar.new(clause_list, [rel])
          end
          self
        end

        def -(to)
          @match_start.match_list.delete(self) # since it is complete now
          RelRightMatchContext.new(@match_start, self, @rel_var, to, :both)
        end

        def >(to)
          @match_start.match_list.delete(self)
          RelRightMatchContext.new(@match_start, self, @rel_var, to, :outgoing)
        end

        def <(to)
          @match_start.match_list.delete(self)
          RelRightMatchContext.new(@match_start, self, @rel_var, to, :incoming)
        end

        def match_value
          @from.match_value
        end
      end

      class RelRightMatchContext
        include Context
        include Variable
        include Returnable
        include MatchContext
        include JoinableMatchContext
        include Algorithms
        include PredicateMethods
        include Alias

        FIRST_DIR_OP = {:outgoing => "-", :incoming => "<-", :both => '-'}
        SECOND_DIR_OP = {:outgoing => "->", :incoming => "-", :both => '-'}

        def initialize(match_start, from, rel_var, to, dir)
          super(match_start)
          @from = from
          convert_create_clauses(from)
          convert_create_clauses(to)
          join_previous! if @from.kind_of?(MatchContext) && @from.join_previous?
          @rel_var = rel_var
          @dir = dir
          convert_create_clauses(to)
          @to = NodeVar.as_var(match_start.clause_list, to)
        end

        def to_cypher_no_join
          "(#{@from.match_value})#{FIRST_DIR_OP[@dir]}[#{@rel_var.match_value}]#{SECOND_DIR_OP[@dir]}(#{@to.match_value})"
        end

        def to_cypher_join
          "#{FIRST_DIR_OP[@dir]}[#{@rel_var.match_value}]#{SECOND_DIR_OP[@dir]}(#{@to.match_value})"
        end

      end


      class NodeMatchContext
        include Context
        include Variable
        include Returnable
        include MatchContext
        include JoinableMatchContext
        include Alias

        DIR_OPERATORS = {:outgoing => "-->", :incoming => "<--", :both => '--'}

        def initialize(match_start, from, to, dir)
          super(match_start)
          @from = from
          @to = to
          convert_create_clauses(from)
          convert_create_clauses(to)
          @dir = dir
        end


        def self.new_first(match_start, from, to, dir)
          from_var = NodeVar.as_var(match_start.clause_list, from)
          to_var = NodeVar.as_var(match_start.clause_list, to)
          NodeMatchContext.new(match_start, from_var, to_var, dir)
        end

        def to_cypher_no_join
          x = @to.match_value
          "(#{@from.match_value})#{DIR_OPERATORS[@dir]}(#{x})"
        end

        def to_cypher_join
          "#{DIR_OPERATORS[@dir]}(#{@to.match_value})"
        end
      end

      class Entities
        include Clause
        attr_reader :input

        def initialize(clause_list, iterable, input)
          super(clause_list, :entities, EvalContext)
          @iterable = iterable
          @input = input.clause
        end

        def referenced!
          @input.referenced!
        end

        def return_value
          "#{@iterable}(#{@input.var_name})"
        end

        class EvalContext
          include Context
          include PredicateMethods
          include Returnable

          include Variable
          include Matchable
          include Aggregate
        end
      end

    end

  end
end
