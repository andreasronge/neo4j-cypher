module Neo4j
  module Cypher

    class ClauseList
      attr_accessor :variables, :clause_list
      include Enumerable

      def initialize(variables = [])
        @variables = variables
        @lists_of_clause_list = [[]]
        @curr_clause_list = @lists_of_clause_list.first
        @insert_order = 0
      end

      def empty?
        !first
      end

      def include?(clause_type)
        !!find(clause_type)
      end

      def find(clause_type)
        @curr_clause_list.find { |c| c.clause_type == clause_type }
      end

      def each
        @curr_clause_list.each { |c| yield c }
      end

      def push
        @lists_of_clause_list << []
        @curr_clause_list = @lists_of_clause_list.last
        self
      end

      def pop
        @lists_of_clause_list.pop
        @curr_clause_list = @lists_of_clause_list.last
        @curr_clause_list.sort!
        self
      end

      def return_clause
        @curr_clause_list.find{|r| r.respond_to?(:return_items)}
      end

      def depth
        @lists_of_clause_list.count
      end

      def insert(clause)
        ctype = clause.clause_type

        if Clause::ORDER.include?(ctype)
          # which list should we add the cluase to, the root or the sub list ?
          # ALl the start and return clauses should move to the clause_list
          c = (depth > 1 && (ctype == :start || ctype == :return)) ? @lists_of_clause_list.first : @curr_clause_list
          c << clause
          @insert_order += 1
          clause.insert_order = @insert_order
          c.sort!
        end
        self
      end

      def last
        @curr_clause_list.last
      end

      def delete(clause_or_context)
        c = clause_or_context.respond_to?(:clause) ? clause_or_context.clause : clause_or_context
        @curr_clause_list.delete(c)
      end

      #def debug
      #  @curr_clause_list.each_with_index { |c, i| puts "  #{i} #{c.clause_type.inspect}, #{c.to_cypher} - #{c.class} id: #{c.object_id} order #{c.insert_order}" }
      #end

      def create_variable(var)
        raise "Already included #{var}" if @variables.include?(var)
        @variables << var
        "v#{@variables.size}".to_sym
      end

      def group_by_clause
        prev_clause = nil
        inject([]) do |memo, clause|
          memo << [] if clause.clause_type != prev_clause
          prev_clause = clause.clause_type
          memo.last << clause
          memo
        end
      end

      def join_group(list)
        list.map { |c| c.to_cypher }.join(list.first.separator)
      end

      def to_cypher
        # Sub lists, like in with clause should not have a clause prefix like WHERE or MATCH
        group_by_clause.map { |list| "#{prefix(list)}#{join_group(list)}" }.join(' ')
      end

      def prefix(list)
        (depth > 1) && !prefix_for_depth_2.include?(list.first.clause_type) ? '' : "#{list.first.prefix} "
      end

      def prefix_for_depth_2
        if include?(:match) && include?(:where)
          [:set, :delete, :create, :remove, :where]
        else
          [:set, :delete, :create, :remove]
        end

      end
    end
  end

end
