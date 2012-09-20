require 'spec_helper'

describe "Neo4j::Cypher" do

  describe 'MATCH' do

    describe "<=>" do

      describe "node(3) <=> :x" do
        it { Proc.new { node(3) <=> :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)--(x) RETURN v2") }
      end

      describe "node(3) <=> node" do
        it { Proc.new { node(3) <=> node }.should be_cypher("START v1=node(3) MATCH v3 = (v1)--(v2) RETURN v3") }
      end

      describe "(node(3) <=> :x).ret(:x)" do
        it { Proc.new { (node(3) <=> :x).ret(:x) }.should be_cypher("START v1=node(3) MATCH (v1)--(x) RETURN x") }
      end

      describe "x = node; n = node(3); match n <=> x; ret x" do
        it { Proc.new { x = node; n = node(3); match n <=> x; ret x }.should be_cypher("START v1=node(3) MATCH (v1)--(v2) RETURN v2") }
      end

      describe "x = node; n = node(3); match n <=> x; ret x[:name]" do
        it { Proc.new { x = node; n = node(3); match n <=> x; ret x[:name] }.should be_cypher("START v2=node(3) MATCH (v2)--(v1) RETURN v1.name") }
      end

      describe "node(3) <=> node(:x); :x" do
        it { Proc.new { node(3) <=> node(:x); :x }.should be_cypher("START v1=node(3) MATCH (v1)--(x) RETURN x") }
      end

      describe "node(3) <=> 'foo'; :foo" do
        it { Proc.new { node(3) <=> 'foo'; :foo }.should be_cypher("START v1=node(3) MATCH (v1)--(foo) RETURN foo") }
      end

    end

    describe "both" do
      describe "node(3).both" do
        it { Proc.new { node(3).both(rel) }.should be_cypher("START v1=node(3) MATCH (v1)-[?]-(v2) RETURN v2") }
      end

      describe "node(1).both('r:friends')" do
        it { Proc.new { node(1).both('r:friends') }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[r:friends]-(v2) RETURN v2]) }
      end

      describe "node(3).both(node)[:name]" do
        it { Proc.new { node(3).both(node)[:name] }.should be_cypher("START v2=node(3) MATCH (v2)-[?]-(v1) RETURN v1.name") }
      end

      describe "node(3).both(rel)" do
        it { Proc.new { node(3).both(rel) }.should be_cypher("START v1=node(3) MATCH (v1)-[?]-(v2) RETURN v2") }
      end

      describe "node(1).both(:friends)" do
        it { Proc.new { node(1).both(:friends) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[:`friends`]-(v2) RETURN v2]) }
      end

      describe "node(1).both(:friends, :knows)" do
        it { Proc.new { node(1).both(:friends, :knows) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[:`friends`|`knows`]-(v2) RETURN v2]) }
      end

      describe "node(1).both(rel(:friends), rel(:knows))" do
        it { Proc.new { node(1).both(rel(:friends), rel(:knows)) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[:`friends`|`knows`]-(v2) RETURN v2]) }
      end


      describe "node(3).both(rel(:foo)" do
        it { Proc.new { node(3).both(rel(:foo)) }.should be_cypher("START v1=node(3) MATCH (v1)-[:`foo`]-(v2) RETURN v2") }
      end

      describe "node(1).both(node(:other_person))" do
        it { Proc.new { node(1).both(node(:other_person)) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?]-(other_person) RETURN other_person]) }
      end

      describe "node(1).both(node(:other_person)).both(node(:foo))" do
        it { Proc.new { node(1).both(node(:other_person)).both(node(:foo)) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?]-(other_person),(other_person)-[?]-(foo) RETURN foo]) }
      end

      describe "node(1).both(:friends, :work)" do
        it { Proc.new { node(1).both(:friends, :work) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[:`friends`|`work`]-(v2) RETURN v2]) }
      end

      describe "node(1).both(:friends, :work, node(42)).both" do
        it { Proc.new { node(1).both(:friends, :work, node(42)).both }.should be_cypher(%Q[START v1=node(1),v2=node(42) MATCH (v1)-[:`friends`|`work`]-(v2),(v2)-[?]-(v3) RETURN v3]) }
      end
    end

    describe 'both?' do

      describe "node(1).both?" do
        it { Proc.new { node(1).both? }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?]-(v2) RETURN v2]) }
      end

      describe "node(1).both?(:friends)" do
        it { Proc.new { node(1).both?(:friends) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?:`friends`]-(v2) RETURN v2]) }
      end

      describe "node(1).both?(rel(:kalle))" do
        it { Proc.new { node(1).both?(rel(:kalle)) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?:`kalle`]-(v2) RETURN v2]) }
      end

    end

    describe "-" do

      describe "node(3) - rel - node(4)" do
        it { Proc.new { node(3) - rel - node(4) }.should be_cypher("START v1=node(3),v2=node(4) MATCH v3 = (v1)-[?]-(v2) RETURN v3") }
      end

      describe "node(3) - :foo - node(4)" do
        it { Proc.new { node(3) - :foo - node(4) }.should be_cypher("START v1=node(3),v2=node(4) MATCH v3 = (v1)-[:`foo`]-(v2) RETURN v3") }
      end

      describe "node(3) - ':knows|friends' - :foo; :foo" do
        it { Proc.new { node(3) - ':knows|friends' - :foo; :foo }.should be_cypher("START v1=node(3) MATCH (v1)-[:knows|friends]-(foo) RETURN foo") }
      end

      describe "(node(3) << node(:c)) - ':friends' - :d; :d" do
        it { Proc.new { (node(3) << node(:c)) - ':friends' - :d; :d }.should be_cypher(%{START v1=node(3) MATCH (v1)<--(c)-[:friends]-(d) RETURN d}) }
      end

      describe "node(3) - ':knows' - :c; :c" do
        it { Proc.new { node(3) - ':knows' - :c; :c }.should be_cypher(%{START v1=node(3) MATCH (v1)-[:knows]-(c) RETURN c}) }
      end

      describe %{a = node(3); a - ':knows' - :c - ":friends" - :d; :c} do
        it { Proc.new { a = node(3); a - ':knows' - :c - ":friends" - :d; :c }.should be_cypher(%{START v1=node(3) MATCH (v1)-[:knows]-(c)-[:friends]-(d) RETURN c}) }
      end

    end

    describe "<<" do

      describe "node(3) << node(4)" do
        it { Proc.new { node(3) << node(4)}.should be_cypher(%{START v1=node(3),v2=node(4) MATCH v3 = (v1)<--(v2) RETURN v3}) }
      end

      describe "node(3) << node(:c) << :d; :c" do
        it { Proc.new { node(3) << node(:c) << :d; :c }.should be_cypher(%{START v1=node(3) MATCH (v1)<--(c)<--(d) RETURN c}) }
      end

    end

    describe 'incoming' do

    end

    describe 'incoming?' do

      describe "node(1).incoming?(:friends)" do
        it { Proc.new { node(1).incoming?(:friends) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)<-[?:`friends`]-(v2) RETURN v2]) }
      end

    end

    describe ">>" do

      describe %{node(3) >> :b} do
        it { Proc.new { node(3) >> :b }.should be_cypher(%{START v1=node(3) MATCH v2 = (v1)-->(b) RETURN v2}) }
      end

      describe "node(3) >> node(4)" do
        it { Proc.new { node(3) >> node(4)}.should be_cypher(%{START v1=node(3),v2=node(4) MATCH v3 = (v1)-->(v2) RETURN v3}) }
      end

      describe "node(3) >> node(:c) >> :d; :c" do
        it { Proc.new { node(3) >> node(:c) >> :d; :c }.should be_cypher(%{START v1=node(3) MATCH (v1)-->(c)-->(d) RETURN c}) }
      end

      describe "node(1) <=> node(:other_person) >> node; :other_person" do
        it do
          Proc.new do
            (node(1) <=> node(:other_person)) >> node
            :other_person
          end.should be_cypher(%Q[START v1=node(1) MATCH (v1)--(other_person)-->(v2) RETURN other_person])
        end

      end

      describe "node(1) >> node(:other_person) <=> node; :other_person" do
        it do
          Proc.new do
            node(1) >> node(:other_person) <=> node
            :other_person
          end.should be_cypher(%Q[START v1=node(1) MATCH (v1)-->(other_person)--(v2) RETURN other_person])
        end

      end

    end

    describe 'outgoing' do

      describe %{node(2).outgoing.as(:q)} do
        it { Proc.new { node(2).outgoing.as(:q) }.should be_cypher(%{START v1=node(2) MATCH (v1)-[?]->(q) RETURN q}) }
      end

      describe "node(1).outgoing(:friends, :work, node(42)).incoming" do
        it { Proc.new { node(1).outgoing(:friends, :work, node(42)).incoming }.should be_cypher(%Q[START v1=node(1),v2=node(42) MATCH (v1)-[:`friends`|`work`]->(v2),(v2)<-[?]-(v3) RETURN v3]) }
      end
    end

    describe 'outgoing?' do

      describe "node(1).outgoing?(:friends)" do
        it { Proc.new { node(1).outgoing?(:friends) }.should be_cypher(%Q[START v1=node(1) MATCH (v1)-[?:`friends`]->(v2) RETURN v2]) }
      end
    end

    describe '>' do
      describe "node(3) > :r > :x" do
        it { Proc.new { node(3) > :r > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[:`r`]->(x) RETURN v2") }
      end

      describe "(node(5) > :r > :middle) >> node(7)" do
        it { Proc.new {(node(5) > :r > :middle) >> node(7)}.should be_cypher("START v1=node(5),v2=node(7) MATCH v3 = (v1)-[:`r`]->(middle)-->(v2) RETURN v3") }
      end

      describe "node(3) > :r > node" do
        it { Proc.new { node(3) > :r > node }.should be_cypher("START v1=node(3) MATCH v3 = (v1)-[:`r`]->(v2) RETURN v3") }
      end

      describe "node(3) > :r > node(4)" do
        it { Proc.new { node(3) > :r > node(4) }.should be_cypher("START v1=node(3),v2=node(4) MATCH v3 = (v1)-[:`r`]->(v2) RETURN v3") }
      end

      describe "node(3) << node(:c) > ':friends' > :d; :d" do
        it { Proc.new { node(3) << node(:c) > ':friends' > :d; :d }.should be_cypher(%{START v1=node(3) MATCH (v1)<--(c)-[:friends]->(d) RETURN d}) }
      end

      describe "node(3) > 'r:friends' > :x; :r" do
        it { Proc.new { node(3) > 'r:friends' > :x; :r }.should be_cypher("START v1=node(3) MATCH (v1)-[r:friends]->(x) RETURN r") }
      end

      describe "node(3) > ':r' > 'bla'; :x" do
        it { Proc.new { node(3) > ':r' > 'bla'; :x }.should be_cypher("START v1=node(3) MATCH (v1)-[:r]->(bla) RETURN x") }
      end

      describe "node(3) > :r > node; node" do
        it { Proc.new { node(3) > :r > node; :r }.should be_cypher("START v1=node(3) MATCH (v1)-[:`r`]->(v2) RETURN r") }
      end

      describe "a=node(3); a > ':knows' > node(:b) > ':knows' > :c; :c" do
        it { Proc.new { a=node(3); a > ':knows' > node(:b) > ':knows' > :c; :c }.should be_cypher(%{START v1=node(3) MATCH (v1)-[:knows]->(b)-[:knows]->(c) RETURN c}) }
      end

    end


    describe '<' do

      describe "node(3) < :r < :x" do
        it { Proc.new { node(3) < :r < :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)<-[:`r`]-(x) RETURN v2") }
      end

      describe "node(3) > :r > node" do
        it { Proc.new { node(3) < :r < node }.should be_cypher("START v1=node(3) MATCH v3 = (v1)<-[:`r`]-(v2) RETURN v3") }
      end

      describe "node(3) > :r > node(4)" do
        it { Proc.new { node(3) < :r < node(4) }.should be_cypher("START v1=node(3),v2=node(4) MATCH v3 = (v1)<-[:`r`]-(v2) RETURN v3") }
      end

      describe "node(3) << node(:c) < ':friends' < :d; :d" do
        it { Proc.new { node(3) << node(:c) < ':friends' < :d; :d }.should be_cypher(%{START v1=node(3) MATCH (v1)<--(c)<-[:friends]-(d) RETURN d}) }
      end

      describe "a=node(3); a < ':knows' < :c; :c" do
        it { Proc.new { a=node(3); a < ':knows' < :c; :c }.should be_cypher(%{START v1=node(3) MATCH (v1)<-[:knows]-(c) RETURN c}) }
      end

      describe "a=node(3); a < ':knows' < node(:c) < :friends < :d" do
        it { Proc.new { a=node(3); a < ':knows' < node(:c) < :friends < :d }.should be_cypher(%{START v1=node(3) MATCH v2 = (v1)<-[:knows]-(c)<-[:`friends`]-(d) RETURN v2}) }
      end

      describe "a=node(3); a < ':knows' < node(:c) > :friends > :d" do
        it { Proc.new { a=node(3); a < ':knows' < node(:c) > :friends > :d }.should be_cypher(%{START v1=node(3) MATCH v2 = (v1)<-[:knows]-(c)-[:`friends`]->(d) RETURN v2}) }
      end

    end


    describe 'shortestPath' do
      describe %{ a, x=node(1), node(2); p = shortest_path { a > '?*' > x }; p } do
        it { Proc.new { a, x=node(1), node(2); p = shortest_path { a > '?*' > x }; p }.should be_cypher(%{START v1=node(1),v2=node(2) MATCH v3 = shortestPath((v1)-[?*]->(v2)) RETURN v3}) }
      end

      describe %{(node(1) > '?*' > node(2)).shortest_path} do
        it { Proc.new { (node(1) > '?*' > node(2)).shortest_path }.should be_cypher(%{START v1=node(1),v2=node(2) MATCH v3 = shortestPath((v1)-[?*]->(v2)) RETURN v3}) }
      end

      describe %{shortest_path{node(1) > '?*' > node(2)}} do
        it { Proc.new { shortest_path { node(1) > '?*' > node(2) } }.should be_cypher(%{START v1=node(1),v2=node(2) MATCH v3 = shortestPath((v1)-[?*]->(v2)) RETURN v3}) }
      end

      describe %{shortest_path { node(1) > '?*' > :x > ':friend' > node(2)}} do
        it { Proc.new { shortest_path { node(1) > '?*' > :x > ':friend' > node(2) } }.should be_cypher(%{START v1=node(1),v2=node(2) MATCH v3 = shortestPath((v1)-[?*]->(x)-[:friend]->(v2)) RETURN v3}) }
      end
    end

    describe %{a=node(3); a > ':knows' > :b > ':knows' > :c; a -':blocks' - :d -':knows' -:c; [a, :b, :c, :d] } do
      it { Proc.new { a=node(3); a > ':knows' > :b > ':knows' > :c; a -':blocks' - :d -':knows' -:c; [a, :b, :c, :d] }.should be_cypher(%{START v1=node(3) MATCH (v1)-[:knows]->(b)-[:knows]->(c),(v1)-[:blocks]-(d)-[:knows]-(c) RETURN v1,b,c,d}) }
    end

  end

  describe 'allShortestPaths' do
    describe %{ a, x=node(1), node(2); p = shortest_paths { a > '?*' > x }; p } do
      it { Proc.new { a, x=node(1), node(2); p = shortest_paths { a > '?*' > x }; p }.should be_cypher(%{START v1=node(1),v2=node(2) MATCH v3 = allShortestPaths((v1)-[?*]->(v2)) RETURN v3}) }
    end
  end

  end
