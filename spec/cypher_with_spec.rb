require 'spec_helper'

describe "Neo4j::Cypher" do

  describe 'WITH' do

    describe 'where' do

      describe '' do
        it do
          Proc.new do

          end
        end
      end
      describe "(node(1) <=> node(:other_person).with(count){|_, foaf| foaf > 1}) >> node: other_person" do
        it do
          Proc.new do
            (node(1) <=> node(:other_person).with(count) { |_, foaf| foaf > 1 }) >> node
            :other_person
          end.should be_cypher(%Q[START v2=node(1) MATCH (v2)--(other_person)-->(v3) WITH other_person,count(*) as v1 WHERE v1 > 1 RETURN other_person])
        end
      end

      describe "node(1).both.as(:other_person).with(count.as(:c)){|_, foaf| foaf > 1}.outgoing(:KNOWS).ret(:c, :other_person)" do
        it do
          Proc.new do
            node(1).both.as(:other_person).with(count.as(:c)) { |_, foaf| foaf > 1 }.outgoing(:KNOWS).ret(:c, :other_person)
          end.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?]-(other_person),(other_person)-[:`KNOWS`]->(v2) WITH other_person,count(*) as c WHERE c > 1 RETURN c,other_person])
        end
      end

      describe "node(1) <=> node(:other_person) >> node}; with(:other_person, count){|_, foaf| foaf > 1} :other_person " do
        it do
          Proc.new do
            (node(1) <=> node(:other_person)) >> node
            with(:other_person, count.as(:foo)) { |_, foaf| foaf > 1 }
            :foo
          end.should be_cypher(%Q[START v1=node(1) MATCH (v1)--(other_person)-->(v2) WITH other_person,count(*) as foo WHERE foo > 1 RETURN foo])
        end
      end


      describe "node(1).outgoing(':KNOWS').with{|c| c[:name] == 'Morpheus'}" do
        it do
          Proc.new do
            node(1).outgoing(':KNOWS').with { |c| c[:name] == 'Morpheus' }.ret
          end.should be_cypher('START v2=node(1) MATCH (v2)-[:KNOWS]->(v1) WITH v1 WHERE v1.name = "Morpheus" RETURN v1')
        end
      end


      describe "node(1).outgoing(':KNOWS').as(:other).with(node(:other)[:name].as(:c)){|_, c| c == 'Morpheus'}" do
        it do
          Proc.new do
            node(1).outgoing(':KNOWS').as(:other).with(node(:other)[:name].as(:c)) { |_, c| c == 'Morpheus' }.ret(:other)
          end.should be_cypher('START v1=node(1) MATCH (v1)-[:KNOWS]->(other) WITH other,other.name as c WHERE c = "Morpheus" RETURN other')
        end
      end

      describe "node(1).outgoing(':KNOWS').as(:other); with(node(:other)[:name].as(:c)){|c| c == 'Morpheus'}" do
        it do
          Proc.new do
            node(1).outgoing(':KNOWS').as(:other)
            with(node(:other)[:name].as(:c)) { |c| c == 'Morpheus' }
            :c
          end.should be_cypher('START v1=node(1) MATCH (v1)-[:KNOWS]->(other) WITH other.name as c WHERE c = "Morpheus" RETURN c')
        end
      end

      describe "node(1).outgoing(':KNOWS').as(:other); with(node(:other)[:name].as(:c)){|c| c == 'Morpheus'}" do
        it do
          Proc.new do
            node(1).outgoing(':KNOWS').as(:other)
            with(node(:other)[:name].as(:c)) { |c| c == 'Morpheus' }; :c
          end.should be_cypher('START v1=node(1) MATCH (v1)-[:KNOWS]->(other) WITH other.name as c WHERE c = "Morpheus" RETURN c')
        end
      end

      describe "node(2).outgoing(':KNOWS').as(:knows).with(node(3)) { |knows, other| knows.outgoing(':WORKS', other)}.ret(:knows)" do
        it do
          Proc.new do
            node(2).outgoing(':KNOWS').as(:knows).with(node(3)) { |knows, other| knows.outgoing(':WORKS', other) }.ret(:knows)
          end.should be_cypher("START v2=node(2),v1=node(3) MATCH (v2)-[:KNOWS]->(knows) WITH knows,v1 WHERE (knows)-[:WORKS]->(v1) RETURN knows")
        end
      end
    end

    describe 'match' do

      describe "node(2) > ':KNOWS' > node(:knows).with_match{|n| n - ':LOVES' - node(3).ret}" do
        it do
          Proc.new do
            node(2) > ':KNOWS' > node(:knows).with_match { |n| n - ':LOVES' - node(3).ret }
          end.should be_cypher("START v2=node(2),v1=node(3) MATCH (v2)-[:KNOWS]->(knows) WITH knows MATCH (knows)-[:LOVES]-(v1) RETURN v1")
        end
      end


      describe "node(2) > ':KNOWS' > node(:knows); with_match(node(:knows)) { |n| n - ':LOVES' - node(3).ret }" do
        it do
          Proc.new do
            node(2) > ':KNOWS' > node(:knows); with_match(node(:knows)) { |n| n - ':LOVES' - node(3).ret }
          end.should be_cypher("START v2=node(2),v1=node(3) MATCH (v2)-[:KNOWS]->(knows) WITH knows MATCH (knows)-[:LOVES]-(v1) RETURN v1")
        end
    end

      describe "COMPLEX" do
        it do
          Proc.new do

            n = node(42).as(:n)
            r = rel('r')
            m = node(:m)
            rel_types = r.rel_type.collect
            end_nodes = m.collect

            n.with_match(rel_types.as(:out_types), end_nodes.as(:outgoing)) { |n, _, _| n < r < m } > r > m

            ret do
              [n,
               :outgoing,
               :out_types,
               end_nodes.as(:incoming),
               rel_types.as(:in_types)
              ]
            end


          end.should be_cypher("START n=node(42) MATCH (n)-[r]->(m) WITH n,collect(type(r)) as out_types,collect(m) as outgoing MATCH (n)<-[r]-(m) RETURN n,outgoing,out_types,collect(m) as incoming,collect(type(r)) as in_types")
        end
      end
    end
  end
end
