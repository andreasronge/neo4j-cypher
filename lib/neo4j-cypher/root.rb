module Neo4j
  module Cypher
    class RootClause
      include Clause

      def initialize
        super(ClauseList.new, :root, EvalContext)
      end

      def execute(args, &cypher_dsl)
        result = eval_context.instance_exec(*args, &cypher_dsl)

        if ![Array, Symbol].include?(result.class)
          return if clause_list.include?(:return)
          return if clause_list.include?(:with)
          return if clause_list.include?(:delete)
          return if clause_list.include?(:set)
          return if clause_list.include?(:remove)
        end
        create_returns(result)
      end

      def create_returns(last_result)
        if last_result.is_a?(Array)
          eval_context.ret(*last_result)
        elsif last_result.nil?
          eval_context.ret(clause_list.last.eval_context) unless clause_list.empty?
        else
          eval_context.ret(last_result)
        end
      end

      def return_value
        clause_list.to_cypher
      end

      def return_names
        ret = clause_list.return_clause
        ret ? ret.return_items.map { |ri| (ri.alias_name || ri.return_value).to_sym } : []
      end

      class EvalContext
        include Context
        include MathFunctions
        include Returnable

        # Does nothing, just for making the DSL easier to read (maybe).
        # @return self
        def match(*, &match_dsl)
          instance_eval(&match_dsl) if match_dsl
        end

        def match_not(&match_dsl)
          instance_eval(&match_dsl).not
        end

        # Does nothing, just for making the DSL easier to read (maybe)
        # @return self
        def start(*)
          self
        end

        def where(w=nil, &block)
          Where.new(clause_list, self, w, &block)
          self
        end

        def where_not(w=nil, &block)
          Where.new(clause_list, self, w, &block).neg!
          self
        end

        # Specifies a start node by performing a lucene query.
        # @param [Class, String] index_class a class responsible for an index or the string value of the index
        # @param [String] q the lucene query
        # @param [Symbol] index_type the type of index
        # @return [LuceneQuery]
        def query(index_class, q, index_type = :exact)
          LuceneQuery.query_node_by_class(clause_list, index_class, q, index_type).eval_context
        end

        # Specifies a start relationship by performing a lucene query.
        # @param [Class, String] index_class a class responsible for an index or the string value of the index
        # @param [String] q the lucene query
        # @param [Symbol] index_type the type of index
        # @return [LuceneQuery]
        def query_rel(index_class, q, index_type = :exact)
          LuceneQuery.query_rel_by_class(clause_list, index_class, q, index_type).eval_context
        end


        # Specifies a start node by performing a lucene query.
        # @param [Class, String] index_class a class responsible for an index or the string value of the index
        # @param [String, Symbol] key the key we ask for
        # @param [String, Symbol] value the value of the key we ask for
        # @return [LuceneQuery]
        def lookup(index_class, key, value)
          LuceneQuery.lookup_node_by_class(clause_list, index_class, key, value).eval_context
        end


        # Specifies a start relationship by performing a lucene query.
        # @param [Class, String] index_class a class responsible for an index or the string value of the index
        # @param [String, Symbol] key the key we ask for
        # @param [String, Symbol] value the value of the key we ask for
        # @return [LuceneQuery]
        def lookup_rel(index_class, key, value)
          LuceneQuery.lookup_rel_by_class(clause_list, index_class, key, value).eval_context
        end


        # Creates a node variable.
        # It will create different variables depending on the type of the first element in the nodes argument.
        # * Fixnum - it will be be used as neo_id  for start node(s) (StartNode)
        # * Symbol - it will create an unbound node variable with the same name as the symbol (NodeVar#as)
        # * empty array - it will create an unbound node variable (NodeVar)
        #
        # @param [Fixnum,Symbol,String] nodes the id of the nodes we want to start from
        # @return [StartNode, NodeVar]
        def node(*nodes)
          if nodes.first.is_a?(Symbol)
            NodeVar.new(clause_list).eval_context.as(nodes.first)
          elsif !nodes.empty?
            StartNode.new(clause_list, nodes).eval_context
          else
            NodeVar.new(clause_list).eval_context
          end
        end

        # Similar to #node
        # @return [StartRel, RelVar]
        def rel(*rels)
          if rels.first.is_a?(Fixnum) || rels.first.respond_to?(:neo_id)
            StartRel.new(clause_list, rels).eval_context
          else
            props = rels.pop if rels.last.is_a?(Hash)
            RelVar.new(clause_list, rels, props).eval_context
          end
        end

        def rel?(*rels)
          rel(*rels).clause.optionally!.eval_context
        end


        def shortest_path(&block)
          match = instance_eval(&block)
          match.shortest_path
        end

        def shortest_paths(&block)
          match = instance_eval(&block)
          match.shortest_paths
        end

        # @param [Symbol,nil] variable the entity we want to count or wildcard (*)
        # @return [ReturnItem] a counter return clause
        def count(variable='*')
          operand = variable.respond_to?(:clause) ? variable.clause.var_name : variable
          ReturnItem.new(clause_list, "count(#{operand})").eval_context
        end

        def coalesce(*args)
          s = args.map { |x| x.clause.return_value }.join(", ")
          ReturnItem.new(clause_list, "coalesce(#{s})").eval_context
        end

        def nodes(*args)
          _entities(args, 'nodes')
        end

        def rels(*args)
          _entities(args, 'relationships')
        end

        def _entities(arg_list, entity_type)
          s = arg_list.map { |x| x.clause.referenced!; x.clause.var_name }.join(", ")
          ReturnItem.new(clause_list, "#{entity_type}(#{s})").eval_context
        end

        def create_path(*args, &block)
          CreatePath.new(clause_list, *args, &block).eval_context
        end

        def create_unique_path(*args, &block)
          CreatePath.new(clause_list, *args, &block).unique!.eval_context
        end

        def with(*args, &block)
          With.new(clause_list, :where, *args, &block).eval_context
        end

        def with_match(*args, &block)
          With.new(clause_list, :match, *args, &block).eval_context
        end

        def distinct(node_or_name)
          operand = node_or_name.respond_to?(:clause) ? node_or_name.clause.var_name : node_or_name
          ReturnItem.new(clause_list, "distinct(#{operand})").eval_context
        end

      end
    end

  end
end
