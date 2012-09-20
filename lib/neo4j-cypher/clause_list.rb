module Neo4j
  module Cypher

    class ClauseList
      attr_accessor :variables
      include Enumerable

      def initialize(variables = [])
        @variables = variables
        @clause_list = []
        @insert_order = 0
      end

      def empty?
        !first
      end

      def include?(clause_type)
        @clause_list.find { |c| c.clause_type == clause_type }
      end

      def each
        @clause_list.each { |c| yield c }
      end

      def push
        raise "Only support stack of depth 2" if @old_clause_list
        @old_clause_list = @clause_list
        @clause_list = []
        self
      end

      def pop
        @clause_list = @old_clause_list
        @clause_list.sort!
        @old_clause_list = nil
        self
      end

      def insert(clause)
        ctype = clause.clause_type

        if Clause::ORDER.include?(ctype)
          # which list should we add the cluase to, the root or the sub list ?
          # ALl the start and return clauses should move to the clause_list
          c = (@old_clause_list && (ctype == :start || ctype == :return)) ? @old_clause_list : @clause_list
          c << clause
          @insert_order += 1
          clause.insert_order = @insert_order
          c.sort!
        end
        self
      end

      def last
        @clause_list.last
      end

      def delete(clause_or_context)
        c = clause_or_context.respond_to?(:clause) ? clause_or_context.clause : clause_or_context
        @clause_list.delete(c)
      end

      #def debug
      #  puts "ClauseList id: #{object_id}, vars: #{variables.size}"
      #  @clause_list.each_with_index { |c, i| puts "  #{i} #{c.clause_type.inspect}, #{c.class} id: #{c.object_id} order #{c.insert_order}" }
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
        @old_clause_list && ![:set, :delete, :create].include?(list.first.clause_type) ? '' : "#{list.first.prefix} "
      end

    end
  end

end
