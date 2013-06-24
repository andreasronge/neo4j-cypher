module Neo4j
  module Cypher
    # Wraps the Cypher query result.
    # Loads the node and relationships wrapper if possible and use symbol as column keys.
    # This is typically used in the native neo4j bindings since result does is not a Ruby enumerable with symbols as keys.
    # @notice The result is a once forward read only Enumerable, work if you need to read the result twice - use #to_a
    #
    # @example
    #   result = Neo4j.query(@a, @b){|a,b| node(a,b).as(:n)}
    #   r = @query_result.to_a # can only loop once
    #   r.size.should == 2
    #   r.first.should include(:n)
    #   r[0][:n].neo_id.should == @a.neo_id
    #   r[1][:n].neo_id.should == @b.neo_id
    class ResultWrapper
      class ResultsAlreadyConsumedException < Exception; end;

      include Enumerable

      # @return the original result from the Neo4j Cypher Engine, once forward read only !
      attr_reader :source

      def initialize(source)
        @source = source
        @unread = true
      end

      # @return [Array<Symbol>] the columns in the query result
      def columns
        @source.columns.map { |x| x.to_sym }
      end

      # for the Enumerable contract
      def each
        raise ResultsAlreadyConsumedException unless @unread

        if block_given?
          @unread = false
          @source.each { |row| yield symbolize_row_keys(row) }
        else
          Enumerator.new(self)
        end
      end

      private

      # Maps each row so that we can use symbols for column names.
      def symbolize_row_keys(row)
        out = {} # move to a real hash!
        row.each do |key, value|
          out[key.to_sym] = value.respond_to?(:wrapper) ? value.wrapper : value
        end
        out
      end

    end
  end
end
