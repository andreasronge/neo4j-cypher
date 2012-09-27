require 'spec_helper'

describe "Neo4j::Cypher" do

  describe 'RETURN' do


    describe 'ret{|x| ...}' do
      describe 'node(42).ret{|n| n[:name]}' do
        it { Proc.new { node(42).ret { |n| n[:name] } }.should be_cypher('START v1=node(42) RETURN v1.name') }
      end

      describe 'node(42).ret{|n| [n, n[:name]]' do
        it { Proc.new { node(42).ret { |n| [n, n[:name]] } }.should be_cypher('START v1=node(42) RETURN v1,v1.name') }
      end

      describe 'node(1,2,3).ret { |n| n[:name].as(:fname)} >> :foo' do
        it { Proc.new { node(1,2,3).ret { |n| n[:name].as(:fname)} >> :foo }.should be_cypher('START v1=node(1,2,3) MATCH (v1)-->(foo) RETURN v1.name as fname') }
      end

      describe 'node(42).ret { |n| [n, n[:name].asc] }' do
        it { Proc.new { node(42).ret { |n| [n, n[:name].asc] } }.should be_cypher('START v1=node(42) RETURN v1,v1.name ORDER BY v1.name') }
      end

    end

    describe '.ret' do
      describe 'node(42).ret' do
        it { Proc.new{ node(42).ret }.should be_cypher("START v1=node(42) RETURN v1")}
      end

      describe 'node(42).ret' do
        it { Proc.new{ node(42)[:name].ret }.should be_cypher("START v1=node(42) RETURN v1.name")}
      end

      describe 'node(1) > :friends > node[:name].ret' do
        it { Proc.new{ node(1) > :friends > node[:name].ret }.should be_cypher("START v2=node(1) MATCH (v2)-[:`friends`]->(v1) RETURN v1.name")}
      end


      describe 'node(1) > :friends > node(:friend)[:name].ret > :friends > node(:foaf).ret' do
        it { Proc.new{ node(1) > :friends > node(:friend)[:name].ret > :friends > node(:foaf).ret }.should be_cypher("START v1=node(1) MATCH (v1)-[:`friends`]->(friend)-[:`friends`]->(foaf) RETURN friend.name,foaf")}
      end

    end

    describe 'nodes' do
      describe '(node(3) >> :b >> node(2)).nodes' do
        it { Proc.new{ (node(3) >> :b >> node(2)).nodes}.should be_cypher("START v1=node(3),v2=node(2) MATCH v3 = (v1)-->(b)-->(v2) RETURN nodes(v3)")}
      end
    end

    describe 'rels' do
      describe '(node(3) >> :b >> node(2)).rels' do
        it { Proc.new{ (node(3) >> :b >> node(2)).rels}.should be_cypher("START v1=node(3),v2=node(2) MATCH v3 = (v1)-->(b)-->(v2) RETURN relationships(v3)")}
      end
    end

    describe 'extract, filter, coalesce, head, last, tail, collect' do
      describe %{       a=node(3); b=node(4); c=node(1); p=a>>b>>c; p.nodes.extract { |x| x[:age] }} do
        it { Proc.new { a=node(3); b=node(4); c=node(1); p=a>>b>>c; p.nodes.extract { |x| x[:age] } }.should \
      be_cypher(%{START v2=node(3),v3=node(4),v4=node(1) MATCH v1 = (v2)-->(v3)-->(v4) RETURN extract(x in nodes(v1) : x.age)}) }
      end

      describe %{       a=node(2); ret a[:array], a[:array].filter{|x| x.length == 3}} do
        it { Proc.new { a=node(2); ret a[:array], a[:array].filter { |x| x.length == 3 } }.should be_cypher(%{START v1=node(2) RETURN v1.array,filter(x in v1.array : length(x) = 3)}) }
        it {Proc.new{ node(3)[:array].filter.length == 3}}
      end

      describe %{       a=node(2); ret a[:array], a[:array].filter{|x| x == "hej"}} do
        it { Proc.new { a=node(2); ret a[:array], a[:array].filter { |x| x == "hej" } }.should be_cypher(%{START v1=node(2) RETURN v1.array,filter(x in v1.array : x = "hej")}) }
      end

      describe %{       a=node(3); coalesce(a[:hair_colour?], a[:eyes?]) } do
        it { Proc.new { a=node(3); coalesce(a[:hair_colour?], a[:eyes?]) }.should be_cypher(%{START v1=node(3) RETURN coalesce(v1.hair_colour?, v1.eyes?)}) }
      end

      describe %{       a=node(2); ret a[:array], a[:array].head } do
        it { Proc.new { a=node(2); ret a[:array], a[:array].head }.should be_cypher(%{START v1=node(2) RETURN v1.array,head(v1.array)}) }
      end

      describe %{       a=node(2); ret a[:array], a[:array].last } do
        it { Proc.new { a=node(2); ret a[:array], a[:array].last }.should be_cypher(%{START v1=node(2) RETURN v1.array,last(v1.array)}) }
      end

      describe %{       a=node(2); ret a[:array], a[:array].tail } do
        it { Proc.new { a=node(2); ret a[:array], a[:array].tail }.should be_cypher(%{START v1=node(2) RETURN v1.array,tail(v1.array)}) }
      end

      describe %{ n=node(2, 3, 4); n[:property].collect} do
        it { Proc.new { n=node(2, 3, 4); n[:property].collect }.should be_cypher(%{START v1=node(2,3,4) RETURN collect(v1.property)}) }
      end

    end

    describe 'abs, round, sqrt, sign' do
      describe %{       a=node(3); abs(-3)} do
        it { Proc.new { a=node(3); abs(-3) }.should be_cypher(%{START v1=node(3) RETURN abs(-3)}) }
      end

      describe %{       a=node(3); b = node(2); ret a[:age], b[:age], (a[:age] - b[:age]).abs } do
        it { Proc.new { a=node(3); b = node(2); ret a[:age], b[:age], (a[:age] - b[:age]).abs }.should be_cypher(%{START v1=node(3),v2=node(2) RETURN v1.age,v2.age,abs(v1.age - v2.age)}) }
      end

      describe %{       a=node(3); b = node(2); ret (a[:age] - b[:age]).abs.as("newname") } do
        it { Proc.new { a=node(3); b = node(2); ret (a[:age] - b[:age]).abs.as("newname") }.should be_cypher(%{START v1=node(3),v2=node(2) RETURN abs(v1.age - v2.age) as newname}) }
      end

      describe %{       a=node(3); round(3.14)} do
        it { Proc.new { a=node(3); round(3.14) }.should be_cypher(%{START v1=node(3) RETURN round(3.14)}) }
      end

      describe %{       a=node(3); sqrt(256)} do
        it { Proc.new { a=node(3); sqrt(256) }.should be_cypher(%{START v1=node(3) RETURN sqrt(256)}) }
      end

      describe %{       a=node(3); sign(256)} do
        it { Proc.new { a=node(3); sign(256) }.should be_cypher(%{START v1=node(3) RETURN sign(256)}) }
      end


    end

    describe 'neo_id' do
      describe %{ node(3, 4, 5).neo_id} do
        it { Proc.new { node(3, 4, 5).neo_id }.should be_cypher(%{START v1=node(3,4,5) RETURN ID(v1)}) }
      end

    end

    describe 'sorting' do

      describe "node(3, 1, 2).asc(:name)" do
        it { Proc.new { node(3, 1, 2).asc(:name)}.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name}) }
      end

      describe "node(3, 1, 2).desc(:age).asc(:name)" do
        it { Proc.new { node(3, 1, 2).desc(:age).asc(:name)}.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.age DESC, v1.name}) }
      end

      describe "node(3, 1, 2).asc(:name)" do
        it { Proc.new { node(3, 1, 2).asc(:name).skip(10)}.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name SKIP 10}) }
      end

      describe %{n=node(3,1,2); ret(n).asc(n[:name])} do
        it { Proc.new { n=node(3, 1, 2); ret(n).asc(n[:name]) }.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name}) }
      end

      # TODO
      # ret(n.asc(:name))
      # n.asc(:name)
      # node(3,1,2).asc(:name)
      describe %{       n=node(3,1,2); ret(n).desc(n[:name])} do
        it { Proc.new { n=node(3, 1, 2); ret(n).desc(n[:name]) }.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name DESC}) }
      end

      describe %{node(1).outgoing(:friends).asc(:name)} do
        it { Proc.new { node(1).outgoing(:friends).asc(:name) }.should be_cypher(%{START v1=node(1) MATCH (v1)-[:`friends`]->(v2) RETURN v2 ORDER BY v2.name}) }
      end

      describe %{node(1).outgoing(:friends).desc(:name)} do
        it { Proc.new { node(1).outgoing(:friends).desc(:name) }.should be_cypher(%{START v1=node(1) MATCH (v1)-[:`friends`]->(v2) RETURN v2 ORDER BY v2.name DESC}) }
      end

      describe %{node(1).outgoing(rel(:friends).ret.asc(:since))} do
        it { Proc.new { node(1).outgoing(rel(:friends).ret.asc(:since)) }.should be_cypher(%{START v2=node(1) MATCH (v2)-[v1:`friends`]->(v3) RETURN v1 ORDER BY v1.since}) }
      end

      describe %{node(1).outgoing(rel(:friends).ret.desc(:since))} do
        it { Proc.new { node(1).outgoing(rel(:friends).ret.desc(:since)) }.should be_cypher(%{START v2=node(1) MATCH (v2)-[v1:`friends`]->(v3) RETURN v1 ORDER BY v1.since DESC}) }
      end

      describe %{node(1).outgoing(rel('r:friends')).ret(rel('r').asc(:name))} do
        it { Proc.new { node(1).outgoing(rel('r:friends')).ret(rel('r').asc(:name)) }.should be_cypher(%{START v1=node(1) MATCH (v1)-[r:friends]->(v2) RETURN r ORDER BY r.name}) }
      end

      describe %{node(3, 1, 2).asc(:name)} do
        it { Proc.new { node(3, 1, 2).asc(:name) }.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name}) }
      end

      describe %{node(3, 1, 2).desc(:name)} do
        it { Proc.new { node(3, 1, 2).desc(:name) }.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name DESC}) }
      end

      describe %{node(1,2,3)[:name].asc} do
        it { Proc.new { node(1,2,3)[:name].asc }.should be_cypher(%{START v1=node(1,2,3) RETURN v1.name ORDER BY v1.name}) }
      end

      describe %{node(1,2,3)[:name].desc} do
        it { Proc.new { node(1,2,3)[:name].desc }.should be_cypher(%{START v1=node(1,2,3) RETURN v1.name ORDER BY v1.name DESC}) }
      end


      describe %{node(1,2,3)[:name].as(:myname).asc} do
        it { Proc.new { node(1,2,3)[:name].as(:myname).asc }.should be_cypher(%{START v1=node(1,2,3) RETURN v1.name as myname ORDER BY myname}) }
      end

      describe %{       n=node(3,1,2); ret(n, n[:name]).asc(n[:name], n[:age])} do
        it { Proc.new { n=node(3, 1, 2); ret(n, n[:name]).asc(n[:name], n[:age]) }.should be_cypher(%{START v1=node(3,1,2) RETURN v1,v1.name ORDER BY v1.name, v1.age}) }
      end

      describe %{       n=node(3,1,2); ret(n).desc(n[:name]} do
        it { Proc.new { n=node(3, 1, 2); ret(n).desc(n[:name]) }.should be_cypher(%{START v1=node(3,1,2) RETURN v1 ORDER BY v1.name DESC}) }
      end

      describe %{       n=node(3,1,2); p=node(5,6); ret(n).asc(p[:age]).desc(n[:name]) } do
        it { Proc.new { n=node(3, 1, 2); p=node(5, 6); ret(n).asc(p[:age]).desc(n[:name]) }.should be_cypher(%{START v1=node(3,1,2),v2=node(5,6) RETURN v1 ORDER BY v2.age, v1.name DESC}) }
      end

      describe %{       node(1,2,3).asc(:age)} do
        it { Proc.new { node(1,2,3).asc(:age) }.should be_cypher(%{START v1=node(1,2,3) RETURN v1 ORDER BY v1.age}) }
      end

      describe %{       node(1,2,3).asc(:age).desc(:name)} do
        it { Proc.new { node(1,2,3).asc(:age).desc(:name) }.should be_cypher(%{START v1=node(1,2,3) RETURN v1 ORDER BY v1.age, v1.name DESC}) }
      end

      describe %{       node(1,2,3).asc(:age).desc(:name).as(:kalle)} do
        it { Proc.new { node(1,2,3).asc(:age).desc(:name).as(:kalle) }.should be_cypher(%{START kalle=node(1,2,3) RETURN kalle ORDER BY kalle.age, kalle.name DESC}) }
      end


      describe %{       a=node(3,4,5,1,2); ret(a).asc(a[:name]).skip(3)} do
        it { Proc.new { a=node(3, 4, 5, 1, 2); ret(a).asc(a[:name]).skip(3) }.should be_cypher(%{START v1=node(3,4,5,1,2) RETURN v1 ORDER BY v1.name SKIP 3}) }
      end

      describe %{       a=node(3,4,5,1,2); ret(a).asc(a[:name]).skip(1).limit(2} do
        it { Proc.new { a=node(3, 4, 5, 1, 2); ret(a).asc(a[:name]).skip(1).limit(2) }.should be_cypher(%{START v1=node(3,4,5,1,2) RETURN v1 ORDER BY v1.name SKIP 1 LIMIT 2}) }
      end

      describe %{       a=node(3,4,5,1,2); ret a, :asc => a[:name], :skip => 1, :limit => 2} do
        it { Proc.new { a=node(3, 4, 5, 1, 2); ret a, :asc => a[:name], :skip => 1, :limit => 2 }.should be_cypher(%{START v1=node(3,4,5,1,2) RETURN v1 ORDER BY v1.name SKIP 1 LIMIT 2}) }
      end


    end

    describe 'node, relationships' do

      describe %{       a=node(3); c = node(2); p = a >> :b >> c; nodes(p) } do
        it { Proc.new { a=node(3); c = node(2); p = a >> :b >> c; nodes(p) }.should be_cypher(%{START v2=node(3),v3=node(2) MATCH v1 = (v2)-->(b)-->(v3) RETURN nodes(v1)}) }
      end


      describe %{       a=node(3); c = node(2); p = a >> :b >> c; rels(p) } do
        it { Proc.new { a=node(3); c = node(2); p = a >> :b >> c; rels(p) }.should be_cypher(%{START v2=node(3),v3=node(2) MATCH v1 = (v2)-->(b)-->(v3) RETURN relationships(v1)}) }
      end
    end

    describe "sum, avg, max, min" do
      describe %{ n=node(2, 3, 4); n[:property].sum} do
        it { Proc.new { n=node(2, 3, 4); n[:property].sum }.should be_cypher(%{START v1=node(2,3,4) RETURN sum(v1.property)}) }
      end

      describe %{ n=node(2, 3, 4); n[:property].avg} do
        it { Proc.new { n=node(2, 3, 4); n[:property].avg }.should be_cypher(%{START v1=node(2,3,4) RETURN avg(v1.property)}) }
      end

      describe %{ n=node(2, 3, 4); n[:property].max} do
        it { Proc.new { n=node(2, 3, 4); n[:property].max }.should be_cypher(%{START v1=node(2,3,4) RETURN max(v1.property)}) }
      end

      describe %{ n=node(2, 3, 4); n[:property].min} do
        it { Proc.new { n=node(2, 3, 4); n[:property].min }.should be_cypher(%{START v1=node(2,3,4) RETURN min(v1.property)}) }
      end

    end


    describe "last value evaluated is the return value" do
      describe "a = node(1); b=node(2); ret(a, b)" do
        it { Proc.new { a = node(1); b=node(2); ret(a, b) }.should be_cypher(%q[START v1=node(1),v2=node(2) RETURN v1,v2]) }
      end

      describe "[node(1), node(2)]" do
        it { Proc.new { [node(1), node(2)] }.should be_cypher(%q[START v1=node(1),v2=node(2) RETURN v1,v2]) }
      end

      describe "node(3) >> :x; :x" do
        it { Proc.new { node(3) >> :x; :x }.should be_cypher("START v1=node(3) MATCH (v1)-->(x) RETURN x") }
      end

      describe %{node(1,2,3)[:name]} do
        it { Proc.new { node(1,2,3)[:name] }.should be_cypher(%{START v1=node(1,2,3) RETURN v1.name}) }
      end

      describe %{p = node(3) >> :b; [:b, p.length]} do
        it { Proc.new { p = node(3) >> :b; [:b, p.length] }.should be_cypher(%{START v1=node(3) MATCH v2 = (v1)-->(b) RETURN b,length(v2)}) }
      end


      describe %{n=node(1,2).as(:n); n[:age?]} do
        it { Proc.new { n=node(1, 2).as(:n); n[:age?] }.should be_cypher(%{START n=node(1,2) RETURN n.age?}) }
      end

      describe "node(1,2).as(:n); nil" do
        it { Proc.new { node(1,2).as(:n); nil }.should be_cypher(%{START n=node(1,2) RETURN n}) }
      end

      describe "node(1,2).outgoing(:friends); nil" do
        it { Proc.new { node(1,2).outgoing(:friends); nil }.should be_cypher(%{START v1=node(1,2) MATCH v3 = (v1)-[:`friends`]->(v2) RETURN v3}) }
      end


      describe %{p1 = (node(3).as(:a) > ":knows*0..1" > :b).as(:p1); p2=node(:b) > ':blocks*0..1' > :c; [:a,:b,:c, p1.length, p2.length]} do
        it do
          Proc.new do
            p1 = (node(3).as(:a) > ":knows*0..1" > :b).as(:p1)
            p2=node(:b) > ':blocks*0..1' > :c
            [:a, :b, :c, p1.length, p2.length]
          end.should be_cypher(%{START a=node(3) MATCH p1 = (a)-[:knows*0..1]->(b),v1 = (b)-[:blocks*0..1]->(c) RETURN a,b,c,length(p1),length(v1)})
        end
      end


    end

    describe 'count' do

      describe %{(n = node(2))>>:x; [n,count]} do
        it { Proc.new { (n = node(2))>>:x; [n, count] }.should be_cypher(%{START v1=node(2) MATCH (v1)-->(x) RETURN v1,count(*)}) }
      end

      describe %{ (node(2))>>:x; count} do
        it { Proc.new { (node(2))>>:x; count }.should be_cypher(%{START v1=node(2) MATCH (v1)-->(x) RETURN count(*)}) }
      end

      describe %{node(2).outgoing.ret(count.as(:x))} do
        it { Proc.new { node(2).outgoing.ret(count.as(:x)) }.should be_cypher(%{START v1=node(2) MATCH (v1)-[?]->(v2) RETURN count(*) as x}) }
      end

      describe 'node(3,4,5,6).ret <=> node.ret{|r| r.count.desc.as(:score)}' do
        it { Proc.new{node(3,4,5,6).ret <=> node.ret{|r| r.count.desc.as(:score)}}.should be_cypher('START v2=node(3,4,5,6) MATCH (v2)--(v1) RETURN v2,count(v1) as score ORDER BY score DESC')}
      end

      describe 'node(3,4,5,6).as(:x) <=> node(:y); ret :x, count(:y).desc.as(:score)' do
        it { Proc.new{node(3,4,5,6).as(:x) <=> node(:y); ret :x, count(:y).desc.as(:score)}.should be_cypher('START x=node(3,4,5,6) MATCH (x)--(y) RETURN x,count(y) as score ORDER BY score DESC')}
      end

      describe %{ r=rel('r'); node(2)>r>node; ret r.rel_type, count} do
        it { Proc.new { r=rel('r'); node(2)>r>node; ret r.rel_type, count }.should be_cypher(%{START v1=node(2) MATCH (v1)-[r]->(v2) RETURN type(r),count(*)}) }
      end

      describe %{ node(2)>>:x; count(:x)} do
        it { Proc.new { node(2)>>:x; count(:x) }.should be_cypher(%{START v1=node(2) MATCH (v1)-->(x) RETURN count(x)}) }
      end

      describe %{ n=node(2, 3, 4, 1); n[:property?].count} do
        it { Proc.new { n=node(2, 3, 4, 1); n[:property?].count }.should be_cypher(%{START v1=node(2,3,4,1) RETURN count(v1.property?)}) }
      end

      describe %{ n=node(2); n>>:b; n[:eyes].distinct.count} do
        it { Proc.new { n=node(2); n>>:b; n[:eyes].distinct.count }.should be_cypher(%{START v1=node(2) MATCH (v1)-->(b) RETURN count(distinct(v1.eyes))}) }
      end



    end

    describe 'distinct' do

      describe %{n=node(1); n>>:b; n.distinct} do
        it { Proc.new { n=node(1); n>>:b; n.distinct }.should be_cypher(%{START v1=node(1) MATCH (v1)-->(b) RETURN distinct(v1)}) }
      end

      describe %{node(1)>>(b=node(:b)); b.distinct} do
        it { Proc.new { node(1)>>(b=node(:b)); b.distinct }.should be_cypher(%{START v1=node(1) MATCH (v1)-->(b) RETURN distinct(b)}) }
      end

      describe %{node(1)>>(b=node(:b)); b.distinct} do
        it { Proc.new { node(1).outgoing(:friends).as(:friends).incoming(:knows).ret(distinct(:friends)) }.should be_cypher(%{START v1=node(1) MATCH (v1)-[:`friends`]->(friends),(friends)<-[:`knows`]-(v2) RETURN distinct(friends)}) }
      end

      describe %{node(1).outgoing.outgoing.as(:friends_of_friends); ret(node(:friends_of_friends).distinct.count, node(:friends_of_friends).count)} do
        it { Proc.new { node(1).outgoing.outgoing.as(:friends_of_friends); ret(node(:friends_of_friends).distinct.count, node(:friends_of_friends).count) }.should \
      be_cypher("START v1=node(1) MATCH (v1)-[?]->(v2),(v2)-[?]->(friends_of_friends) RETURN count(distinct(friends_of_friends)),count(friends_of_friends)")}
      end

      describe "node(1).outgoing(:friends).outgoing(:bar).as(:f).incoming(:bar).ret(node(:f).distinct)" do
        it do
          Proc.new do
            node(1).outgoing(:friends).outgoing(:bar).as(:f).incoming(:bar).ret(node(:f).distinct)
          end.should be_cypher("START v1=node(1) MATCH (v1)-[:`friends`]->(v2),(v2)-[:`bar`]->(f),(f)<-[:`bar`]-(v3) RETURN distinct(f)")
        end
      end
    end

  end
end
