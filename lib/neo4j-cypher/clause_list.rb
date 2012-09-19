module Neo4j
  module Cypher

    class ClauseList
      attr_accessor :variables
      include Enumerable

      def empty?
        !first
      end

      def include?(clause_type)
        @clause_list.find { |c| c.clause_type == clause_type }
      end

      def each
        @clause_list.each { |c| yield c }
      end

      def initialize(variables = [])
        @variables = variables
        @clause_list = []
      end

      def create_sub_list
        ClauseList.new(self.variables)
      end

      def insert(clause)
        if Clause::ORDER.include?(clause.clause_type)
          @clause_list << clause
          @clause_list.sort!
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

      def debug
        puts "ClauseList id: #{object_id}, vars: #{variables.size}"
        @clause_list.each_with_index { |c, i| puts "  #{i} #{c.clause_type.inspect}, #{c.class} id: #{c.object_id}" }
      end

      def find_all(*clause_types)
        if !clause_types.empty?
          clause_types.inject([]) { |memo, ct| memo += find_all { |c| c.clause_type == ct }; memo }
        else
          super
        end
      end

      def remove_all(*clause_types)
        if !clause_types.empty?
          clause_types.each { |ct| @clause_list.delete_if { |c| c.clause_type == ct } }
        else
          @clause_list.clear
        end
      end

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
        group_by_clause.map { |list| "#{list.first.prefix} #{join_group(list)}" }.join(' ')
      end

    end
  end

end
