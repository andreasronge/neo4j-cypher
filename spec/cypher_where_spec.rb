require 'spec_helper'

describe "Neo4j::Cypher" do

  describe 'WHERE' do

    describe 'where' do

      describe %{n=node(3,1).as(:n); where(%q[n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias"')]} do
        it { Proc.new { n=node(3, 1).as(:n); where(%q[(n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias")]); ret n }.should be_cypher(%q[START n=node(3,1) WHERE (n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias") RETURN n]) }
      end

      describe %{n=node(3,1); where n[:age] < 30; ret n} do
        it { Proc.new { n=node(3, 1); where n[:age] < 30; ret n }.should be_cypher(%q[START v1=node(3,1) WHERE v1.age < 30 RETURN v1]) }
      end

      describe %{node(3, 1).as(:n); where "n.age < 30"; :n} do
        it { Proc.new { node(3, 1).as(:n); where "n.age < 30"; :n }.should be_cypher(%q[START n=node(3,1) WHERE n.age < 30 RETURN n]) }
      end

      describe %{n=node(3, 1); where (n[:name] == 'foo').not; ret n} do
        it { Proc.new { n=node(3, 1); where (n[:name] == 'foo').not; ret n }.should be_cypher(%q[START v1=node(3,1) WHERE not(v1.name = "foo") RETURN v1]) }
      end

      describe %{r=rel(3,1); where r[:since] < 2; r} do
        it { Proc.new { r=rel(3, 1); where r[:since] < 2; r }.should be_cypher(%q[START v1=relationship(3,1) WHERE v1.since < 2 RETURN v1]) }
      end

    end

    describe "where on #rel" do

      describe "node(1).outgoing(rel(:friends).where{|r| r[:since] == 1994})" do
        it do
          Proc.new { node(1).outgoing(rel(:friends).where{|r| r[:since] == 1994}) }.should \
            be_cypher("START v2=node(1) MATCH (v2)-[v1:`friends`]->(v3) WHERE (v1.since = 1994) RETURN v3")
        end
      end


      describe "node(1) > rel(:friends).where{|r| r[:since] == 1994} > node" do
        it do
          Proc.new { node(1) > rel(:friends).where{|r| r[:since] == 1994} > node }.should \
            be_cypher("START v2=node(1) MATCH v4 = (v2)-[v1:`friends`]->(v3) WHERE (v1.since = 1994) RETURN v4")
        end
      end

      describe "node(1) > rel(:friends).where_not{|r| r[:since] == 1994} > node" do
        it do
          Proc.new { node(1) > rel(:friends).where_not{|r| r[:since] == 1994} > node }.should \
            be_cypher("START v2=node(1) MATCH v4 = (v2)-[v1:`friends`]->(v3) WHERE not(v1.since = 1994) RETURN v4")
        end
      end

      describe "node(1) > (rel(:knows)[:since] == 1994) > :other; :other" do
        it do
          Proc.new do
            node(1) > (rel(:knows)[:since] == 1994) > :other; :other
          end.should be_cypher("START v2=node(1) MATCH (v2)-[v1:`knows`]->(other) WHERE v1.since = 1994 RETURN other")
        end
      end

      describe "node(1) > (rel(:knows)[:since] > 1994) > (node(:other)[:name] == 'foo'); :other" do
        it do
          Proc.new do
            node(1) > (rel(:knows)[:since] > 1994) > (node(:other)[:name] == 'foo'); :other
          end.should be_cypher(%Q[START v2=node(1) MATCH (v2)-[v1:`knows`]->(other) WHERE v1.since > 1994 and other.name = "foo" RETURN other])
        end
      end

    end

    describe 'where on #outgoing' do

      describe %{node(3,4)[:name].where{|n| n == "hej"}.as(:myname)} do
        it { Proc.new { node(3, 4)[:name].where { |n| n == "hej" }.as(:myname) }.should be_cypher(%q[START v1=node(3,4) WHERE (v1.name = "hej") RETURN v1.name as myname]) }
      end

      if RUBY_VERSION > "1.9.0"
        describe %{node(2).outgoing(:friends).where{|c| (c[:name] != 'kalle')}} do
          it { Proc.new { node(2).outgoing(:friends).where { |c| (c[:name] != 'kalle') } }.should \
        be_cypher(%{START v2=node(2) MATCH (v2)-[:`friends`]->(v1) WHERE (v1.name <> "kalle") RETURN v1}) }
        end
      end

      describe "a=node(5);b=node(7);x=node; a > ':friends' > x; (x > ':friends' > node > ':work' > b).not; x" do
        it do
          Proc.new do
            a=node(5); b=node(7); x=node; a > ':friends' > x; (x > ':friends' > node > ':work' > b).not; x
          end.should be_cypher("START v1=node(5),v2=node(7) MATCH (v1)-[:friends]->(v3) WHERE not((v3)-[:friends]->(v4)-[:work]->(v2)) RETURN v3")
        end
      end

      describe "a=node(5); b=node(7); x=node; match{a > ':friends' > x}; match_not{a >> b >> x}; x" do
        it do
          Proc.new do
            a=node(5); b=node(7); x=node; match{a > ':friends' > x}; match_not{a >> b >> x}; x
          end.should be_cypher("START v1=node(5),v2=node(7) MATCH (v1)-[:friends]->(v3) WHERE not((v1)-->(v2)-->(v3)) RETURN v3")
        end
      end

      describe "node(1) << node(:person).where{|p| p >> node(7).as(:interest)}; :person" do
        it do
          Proc.new do
            node(1) << node(:person).where { |p| p >> node(7).as(:interest) }; :person
          end.should be_cypher("START v1=node(1),interest=node(7) MATCH (v1)<--(person) WHERE ((person)-->(interest)) RETURN person")
        end
      end

      describe "node(1) << node(:person).where_not{|p| p >> node(7).as(:interest)}; :person" do
        it do
          Proc.new do
            node(1) << node(:person).where_not { |p| p >> node(7).as(:interest) }; :person
          end.should be_cypher("START v1=node(1),interest=node(7) MATCH (v1)<--(person) WHERE not((person)-->(interest)) RETURN person")
        end
      end

    end

    describe 'where on path' do
      describe "(node(1) << :person).where{|path| path.nodes.all? { |x| x[:age] > 30 }}.ret(:person)" do
        it do
          Proc.new do
            (node(1) << :person).where{|path| path.nodes.all? { |x| x[:age] > 30 }}.ret(:person)
          end.should be_cypher("START v2=node(1) MATCH v1 = (v2)<--(person) WHERE (all(x in nodes(v1) WHERE x.age > 30)) RETURN person")
        end
      end


      describe "(node(1)>>node).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}" do
        it {Proc.new{ (node(1)>>node).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}}.should \
          be_cypher('START v2=node(1) MATCH v1 = (v2)-->(v3) WHERE (single(x in nodes(v1) WHERE x.name = "Morpheus")) RETURN v1')}
      end

      describe "(node(1)>>node).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}.where{|path| path.nodes.all? { |x| x[:age] > 30 }}" do
        it {Proc.new{ (node(1)>>node).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}.where{|path| path.nodes.all? { |x| x[:age] > 30 }}}.should \
          be_cypher('START v2=node(1) MATCH v1 = (v2)-->(v3) WHERE (single(x in nodes(v1) WHERE x.name = "Morpheus")) and (all(x in nodes(v1) WHERE x.age > 30)) RETURN v1')}
      end


      describe "(node(1)>>node).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}.where{|path| path.nodes.all? { |x| x[:age] > 30 }}" do
        it {pending "TODO "; Proc.new{ (node(1)>>node).where{|p| p.nodes.single?{|n| (n[:name] == 'Morpheus') &  p.nodes.all? { |x| x[:age] > 30 }}} }.should \
          be_cypher('START v1=node(1) MATCH v3 = (v1)-->(v2) WHERE (single(x in nodes(v3) WHERE (x.name = "Morpheus") and all(x in nodes(v3) WHERE x.age > 30))) RETURN v3')}
      end

      describe "(node(1)>>node.where{|n| n[:age] == 42}).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}" do
        it {Proc.new{ (node(1)>>node.where{|n| n[:age] == 42}).where{|p| p.nodes.single?{|n| n[:name] == 'Morpheus'}}}.should \
          be_cypher('START v3=node(1) MATCH v2 = (v3)-->(v1) WHERE (v1.age = 42) and (single(x in nodes(v2) WHERE x.name = "Morpheus")) RETURN v2')}
      end

    end

  end


    describe 'operators (>, <, ==, !=)' do
      describe 'node(4,5,6)[:age] == 32' do
        it { Proc.new { node(4, 5, 6)[:age] == 32 }.should be_cypher('START v1=node(4,5,6) WHERE v1.age = 32 RETURN v1') }
      end

      describe 'n=node(3,1); n[:belt?] == "white";n' do
        it { Proc.new { n=node(3, 1); n[:belt?] == "white"; n }.should be_cypher('START v1=node(3,1) WHERE v1.belt? = "white" RETURN v1') }
      end

      describe 'node(4,5,6)[:age] > 32' do
        it { Proc.new { node(4, 5, 6)[:age] > 32 }.should be_cypher('START v1=node(4,5,6) WHERE v1.age > 32 RETURN v1') }
      end

      describe 'node(4,5,6)[:age] < 32' do
        it { Proc.new { node(4, 5, 6)[:age] < 32 }.should be_cypher('START v1=node(4,5,6) WHERE v1.age < 32 RETURN v1') }
      end

      if RUBY_VERSION > "1.9.0"
        describe 'node(4,5,6)[:age] != 32' do
          it { Proc.new { node(4, 5, 6)[:age] != 32 }.should be_cypher('START v1=node(4,5,6) WHERE v1.age <> 32 RETURN v1') }
        end
      end


      describe %{n=node(3,4); n[:desc] == "hej"; n} do
        it { Proc.new { n=node(3, 4); n[:desc] == "hej"; n }.should be_cypher(%q[START v1=node(3,4) WHERE v1.desc = "hej" RETURN v1]) }
      end


      describe %{r=rel('r?'); n=node(2); n > r > :x; r[:since] < 2; r} do
        it { Proc.new { r=rel('r?'); n=node(2); n > r > :x; r[:since] < 2; r }.should be_cypher(%q[START v1=node(2) MATCH (v1)-[r?]->(x) WHERE r.since < 2 RETURN r]) }
      end

      describe %{r=rel('r:friends|like'); n=node(2); n > r > :x; r[:since] < 2; r} do
        it { Proc.new { r=rel('r:friends|like'); n=node(2); n > r > :x; r[:since] < 2; r }.should be_cypher(%q[START v1=node(2) MATCH (v1)-[r:friends|like]->(x) WHERE r.since < 2 RETURN r]) }
      end
    end

    describe 'and, or (&, |)' do
      describe "n=node(4,5,6); (n[:age] > 32) & (n[:name] == 'kalle')" do
        it { Proc.new { n=node(4, 5, 6); (n[:age] > 32) & (n[:name] == 'kalle') }.should be_cypher('START v1=node(4,5,6) WHERE (v1.age > 32) and (v1.name = "kalle") RETURN v1') }
      end

      describe "n=node(4,5,6); (n[:age] > 32) | (n[:name] == 'kalle')" do
        it { Proc.new { n=node(4, 5, 6); (n[:age] > 32) | (n[:name] == 'kalle') }.should be_cypher('START v1=node(4,5,6) WHERE (v1.age > 32) or (v1.name = "kalle") RETURN v1') }
      end

      describe %{n=node(3, 1); (n[:age] < 30) & ((n[:name] == 'foo') | (n[:size] > n[:age]))); ret n} do
        it { Proc.new { n=node(3, 1); (n[:age] < 30) & ((n[:name] == 'foo') | (n[:size] > n[:age])); ret n }.should be_cypher(%q[START v1=node(3,1) WHERE (v1.age < 30) and ((v1.name = "foo") or (v1.size > v1.age)) RETURN v1]) }
      end

    end

    describe "=~" do
      describe %q[node(4, 5, 6)[:age] =~ /.\d+/] do
        it { Proc.new { node(4, 5, 6)[:age] =~ /.\d+/ }.should be_cypher(%q[START v1=node(4,5,6) WHERE v1.age =~ '.\d+' RETURN v1]) }
      end

      describe %q[node(4, 5, 6)[:age] == /.\d+/] do
        it { Proc.new { node(4, 5, 6)[:age] == /.\d+/ }.should be_cypher(%q[START v1=node(4,5,6) WHERE v1.age =~ '.\d+' RETURN v1]) }
      end

      describe %q[node(4, 5, 6)[:age] =~ "."] do
        it { Proc.new { node(4, 5, 6)[:age] =~ "." }.should be_cypher(%q[START v1=node(4,5,6) WHERE v1.age =~ '.' RETURN v1]) }
      end

      describe %{node(3,4) <=> :x; node(:x)[:desc] =~ /hej/; :x} do
        it { Proc.new { node(3, 4) <=> :x; node(:x)[:desc] =~ /hej/; :x }.should be_cypher(%q[START v1=node(3,4) MATCH (v1)--(x) WHERE x.desc =~ 'hej' RETURN x]) }
      end

      describe %{n=node(3); n > (r=rel('r')) > node; r.rel_type =~ /K.*/; r} do
        it { Proc.new { n=node(3); n > (r=rel('r')) > node; r.rel_type =~ /K.*/; r }.should be_cypher(%{START v1=node(3) MATCH (v1)-[r]->(v2) WHERE type(r) =~ 'K.*' RETURN r}) }
      end
    end


    describe "property?" do
      describe %{node(1,2).property?(:belt)} do
        it { Proc.new { node(1,2).property?(:belt) }.should be_cypher(%{START v1=node(1,2) WHERE has(v1.belt) RETURN v1}) }
      end

      describe %{n=node(3, 1); n.property?(:belt); n} do
        it { Proc.new { n=node(3, 1); n.property?(:belt); n }.should be_cypher(%{START v1=node(3,1) WHERE has(v1.belt) RETURN v1}) }
      end
    end

    describe "null" do

      describe "node(1,2,3).outgoing(rel?.null)" do
        it { Proc.new {node(1,2,3).outgoing(rel?.null) }.should be_cypher("START v2=node(1,2,3) MATCH (v2)-[v1?]->(v3) WHERE (v1 is null) RETURN v3")}
      end


      describe "node(1,2,3).outgoing(rel?(:foo).null)" do
        it { Proc.new {node(1,2,3).outgoing(rel?(:foo).null) }.should be_cypher("START v2=node(1,2,3) MATCH (v2)-[v1?:`foo`]->(v3) WHERE (v1 is null) RETURN v3")}
      end

      describe "node(1,2,3) > rel.null > node(4,5,6).as(:b); :b" do
        it { Proc.new {node(1,2,3) > rel?.null > node(4,5,6).as(:b); :b }.should be_cypher("START v2=node(1,2,3),b=node(4,5,6) MATCH (v2)-[v1?]->(b) WHERE (v1 is null) RETURN b")}
      end

      describe "node(1,2,3) > rel?.null > node > rel(:foo).null > node(4,5,6).as(:b); :b" do
        it { Proc.new {node(1,2,3) > rel?.null > node > rel(:foo).null > node(4,5,6).as(:b); :b }.should be_cypher("START v3=node(1,2,3),b=node(4,5,6) MATCH (v3)-[v1?]->(v4)-[v2:`foo`]->(b) WHERE (v1 is null) and (v2 is null) RETURN b")}
      end

      describe %{a=node(1).as(:a);b=node(3,2); r=rel('r?'); a < r < b; r.null ; b} do
        it { Proc.new { a=node(1).as(:a); b=node(3, 2); r=rel('r?'); a < r < b; r.null; b }.should be_cypher(%{START a=node(1),v1=node(3,2) MATCH (a)<-[r?]-(v1) WHERE (r is null) RETURN v1}) }
      end
    end


    describe "in" do

      describe 'node(3, 1, 2)[:name].in?(["Peter", "Tobias"])' do
        it { Proc.new { node(3, 1, 2)[:name].in?(["Peter", "Tobias"]) }.should be_cypher(%{START v1=node(3,1,2) WHERE (v1.name IN ["Peter","Tobias"]) RETURN v1}) }
      end

      describe 'node(1).outgoing(:foo).as(:x)[:name].in?(["Peter", "Tobias"])' do
        it { Proc.new { node(1).outgoing(:foo).as(:x)[:name].in?(["Peter", "Tobias"]) }.should be_cypher(%{START v1=node(1) MATCH (v1)-[:`foo`]->(x) WHERE (x.name IN ["Peter","Tobias"]) RETURN x}) }
      end

      describe %{names = ["Peter", "Tobias"]; a=node(3,1,2).as(:a); a[:name].in?(names); ret a} do
        it { Proc.new { names = ["Peter", "Tobias"]; a=node(3, 1, 2).as(:a); a[:name].in?(names); ret a }.should be_cypher(%{START a=node(3,1,2) WHERE (a.name IN ["Peter","Tobias"]) RETURN a}) }
      end

    end

    describe 'all?, any?, none?, single?' do

      describe "        a = node(3); b=node(1); match p = a > '*1..3' > b; where p.nodes.all? { |x| x[:age] > 30 }; ret p" do
        it { Proc.new { a = node(3); b=node(1); match p = a > '*1..3' > b; where p.nodes.all? { |x| x[:age] > 30 }; ret p }.should \
      be_cypher(%{START v2=node(3),v3=node(1) MATCH v1 = (v2)-[*1..3]->(v3) WHERE all(x in nodes(v1) WHERE x.age > 30) RETURN v1}) }
      end

      describe "  a = node(2); a[:array].any? { |x| x == 'one' }; a" do
        it { Proc.new { a = node(2); a[:array].any? { |x| x == 'one' }; a }.should be_cypher(%{START v1=node(2) WHERE any(x in v1.array WHERE x = "one") RETURN v1}) }
      end

      describe "        p=node(3)>'*1..3'>:b; p.nodes.none? { |x| x[:age] == 25 };p" do
        it { Proc.new { p=node(3)>'*1..3'>:b; p.nodes.none? { |x| x[:age] == 25 }; p }.should be_cypher(%{START v2=node(3) MATCH v1 = (v2)-[*1..3]->(b) WHERE none(x in nodes(v1) WHERE x.age = 25) RETURN v1}) }
      end

      describe %{       p = node(3)>>:b; p.nodes.single? { |x| x[:eyes] == 'blue' }; p } do
        it { Proc.new { p = node(3)>>:b; p.nodes.single? { |x| x[:eyes] == 'blue' }; p }.should \
      be_cypher(%{START v2=node(3) MATCH v1 = (v2)-->(b) WHERE single(x in nodes(v1) WHERE x.eyes = "blue") RETURN v1}) }
      end

      describe %{       p = node(3)>>:b; p.rels.single? { |x| x[:eyes] == 'blue' }; p } do
        it { Proc.new { p = node(3)>>:b; p.rels.single? { |x| x[:eyes] == 'blue' }; p }.should \
      be_cypher(%{START v2=node(3) MATCH v1 = (v2)-->(b) WHERE single(x in relationships(v1) WHERE x.eyes = "blue") RETURN v1}) }
      end


    describe 'neo_id' do
      describe %{ a = node(3, 4, 5); a - (r=rel("r")) - :b; r.neo_id < 20; r} do
        it { Proc.new { a = node(3, 4, 5); a - (r=rel("r")) - :b; r.neo_id < 20; r }.should be_cypher(%{START v1=node(3,4,5) MATCH (v1)-[r]-(b) WHERE ID(r) < 20 RETURN r}) }
      end

    end

    describe 'abs' do

      describe %{       a=node(3); (a[:x] - a[:y]).abs==3; a } do
        it { Proc.new { a=node(3); (a[:x] - a[:y]).abs==3; a }.should be_cypher(%{START v1=node(3) WHERE abs(v1.x - v1.y) = 3 RETURN v1}) }
      end

      describe %{       a=node(3); a[:x].abs==3; a; a } do
        it { Proc.new { a=node(3); a[:x].abs==3; a }.should be_cypher(%{START v1=node(3) WHERE abs(v1.x) = 3 RETURN v1}) }
      end

    end



  end
end
