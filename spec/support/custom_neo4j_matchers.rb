module CustomNeo4jMatchers
  class BeCypher

    def initialize(expected, alternative = nil)
      @expected = expected
      @alternative = alternative
    end

    def matches?(actual)
      @actual = Neo4j::Cypher.query(&actual).to_s
      @actual == @expected || (@alternative && (@alternative == @expected))
    end

    def expected
      %Q[#@expected\n]
    end

    def actual
      %Q[#@actual\n]
    end

    def failure_message_for_should
      %Q[expected #{@actual} to be "#{@expected}"]
    end

    def failure_message_for_should_not
      %Q[expected #{@actual} not to be "#{@expected}"]
    end

    def description
      "be equal \"#{@expected}\""
    end

    def diffable?
      true
    end
  end

  def be_cypher(expected, alternative=nil)
    BeCypher.new(expected, alternative)
  end
end
