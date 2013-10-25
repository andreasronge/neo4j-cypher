module Neo4j
  module Cypher
    class Start
      include Clause

      def initialize(clause_list, rvalue)
        super(clause_list, :start, EvalContext)
        @rvalue = rvalue
      end

      def entity_list(entity_type, entities)
        list = entities.map { |n| n.respond_to?(:neo_id) ? n.neo_id : n }.join(',')
        "#{entity_type}(#{list})"
      end

      def to_cypher
        "#{var_name}=#{@rvalue}"
      end

      class EvalContext
        include Context
        include Variable
        include Matchable
        include Returnable
        include Sortable
        include Aggregate
        include Alias
      end

    end

    # Can be created from a <tt>node</tt> dsl method.
    class StartNode < Start

      def initialize(clause_list, nodes)
        super(clause_list, entity_list('node', nodes))
      end
    end


    # Can be created from a <tt>rel</tt> dsl method.
    class StartRel < Start
      def initialize(clause_list, rels)
        super(clause_list, entity_list('relationship', rels))
      end
    end

    class LuceneQuery < Start
      def initialize(clause_list, query, type)
        super(clause_list, "#{type}:#{query}")
      end

      def self._lookup_params(index_class, key, value)
        %Q[#{_index_name_for_key(index_class, key)}(#{key}="#{value}")]
      end

      def self.lookup_node_by_class(clause_list, index_class, key, value)
        LuceneQuery.new(clause_list, _lookup_params(index_class, key, value), 'node')
      end

      def self.query_node_by_class(clause_list, index_class, query, index_type)
        LuceneQuery.new(clause_list, "#{_index_name_for_type(index_class, index_type)}('#{query}')", 'node')
      end

      def self.lookup_rel_by_class(clause_list, index_class, key, value)
        LuceneQuery.new(clause_list, _lookup_params(index_class, key, value), 'relationship')
      end

      def self.query_rel_by_class(clause_list, index_class, query, index_type)
        LuceneQuery.new(clause_list, "#{_index_name_for_type(index_class, index_type)}('#{query}')", 'relationship')
      end

      def self._index_name_for_type(index_class , index_type)
        index_class.respond_to?(:index_name_for_type) ? index_class.index_name_for_type(index_type) : index_class.to_s
      end

      def self._index_name_for_key(index_class, key)
        if index_class.respond_to?(:index_type)
          index_type = index_class.index_type(key.to_s)
          raise "No index on #{index_class} property #{key}" unless index_type
          index_class.index_name_for_type(index_type)
        else
          index_class.to_s
        end
      end
    end

  end
end
