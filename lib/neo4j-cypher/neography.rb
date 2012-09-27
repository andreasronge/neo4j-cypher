module Neography

  # Monkey patch so it works better with neo4-cypher gem and becomes more similar to neo4j-core
  class Relationship
    def _java_rel
      self
    end
  end

  class Node
    def _java_node
      self
    end
  end

  class Rest
    def execute_cypher(params, &dsl)
      q = Neo4j::Cypher.query(params, &dsl).to_s
      execute_query(q)
    end
  end
end