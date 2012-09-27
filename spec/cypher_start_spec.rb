require 'spec_helper'

class FooIndex

  class << self
    def index_type(field)
      field.to_s == 'name' ? :exact : :fulltext
    end

    def index_name_for_type(type)
      "fooindex_#{type}"
    end
  end
end


describe "Neo4j::Cypher" do
  let(:an_entity) do
    Struct.new(:neo_id).new(42)
  end

  describe "return_names" do

    describe 'node(2)' do
      subject do
        Neo4j::Cypher.query do
          node(2)
        end
      end
      its(:return_names) { should == [:v1] }
    end

    describe '[node(2), node(3)]' do
      subject do
        Neo4j::Cypher.query do
          [node(2), node(3)]
        end
      end
      its(:return_names) { should == [:v1, :v2] }
    end

    describe 'node(2).outgoing' do
      subject do
        Neo4j::Cypher.query do
          node(2).outgoing(:friends)
        end
      end
      its(:to_s) { should == 'START v1=node(2) MATCH (v1)-[:`friends`]->(v2) RETURN v2'}
      its(:return_names) { should == [:v2] }
    end

  end

  describe "node" do
    describe "node(3)" do
      it { Proc.new { node(3) }.should be_cypher("START v1=node(3) RETURN v1") }
    end

    describe "node(Neo4j::Node.new)" do
      it { a = an_entity; Proc.new { node(a) }.should be_cypher("START v1=node(42) RETURN v1") }
    end

    describe "node(3,4)" do
      it { Proc.new { node(3, 4) }.should be_cypher("START v1=node(3,4) RETURN v1") }
    end

    describe "node(5) >> node" do
      it { Proc.new { node(5) >> node }.should be_cypher("START v1=node(5) MATCH v3 = (v1)-->(v2) RETURN v3") }
    end

    describe "node(5) >> node(:foo)" do
      it { Proc.new { node(5) >> node(:foo) }.should be_cypher("START v1=node(5) MATCH v2 = (v1)-->(foo) RETURN v2") }
    end

    describe "n = node(1, 2, 3); ret n" do
      it { Proc.new { n = node(1, 2, 3); ret n }.should be_cypher("START v1=node(1,2,3) RETURN v1") }
    end

  end


  describe "rel" do
    describe "rel(3)" do
      it { Proc.new { rel(3) }.should be_cypher("START v1=relationship(3) RETURN v1") }
    end

    describe "rel(Neo4j::Relationship.new)" do
      it { a = an_entity; Proc.new { rel(a) }.should be_cypher("START v1=relationship(42) RETURN v1") }
    end

    describe "rel(3, Neo4j::Relationship)" do
      it { a = an_entity; Proc.new { rel(3, a) }.should be_cypher("START v1=relationship(3,42) RETURN v1") }
    end

    describe "node(3) > rel > :x" do
      it { Proc.new { node(3) > rel > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[?]->(x) RETURN v2") }
    end

    describe "node(3) > rel('r:friends') > :x" do
      it { Proc.new { node(3) > rel('r:friends') > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[r:friends]->(x) RETURN v2") }
    end

    describe "node(3) > rel(:friends) > :x" do
      it { Proc.new { node(3) > rel(:friends) > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[:`friends`]->(x) RETURN v2") }
    end

    describe "node(3) > rel(:friends, :work, :family) > :x" do
      it { Proc.new { node(3) > rel(:friends, :work, :family) > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[:`friends`|`work`|`family`]->(x) RETURN v2") }
    end

    describe "r = rel('r:friends'); node(3) > r > :x; r" do
      it { Proc.new { r = rel('r:friends'); node(3) > r > :x; r }.should be_cypher("START v1=node(3) MATCH (v1)-[r:friends]->(x) RETURN r") }
    end

    describe "r = rel('r?:friends'); node(3) > r > :x; r" do
      it { Proc.new { r = rel('r?:friends'); node(3) > r > :x; r }.should be_cypher("START v1=node(3) MATCH (v1)-[r?:friends]->(x) RETURN r") }
    end

    describe "node(3) > rel('?') > :x; :x" do
      it { Proc.new { node(3) > rel('?') > :x; :x }.should be_cypher("START v1=node(3) MATCH (v1)-[?]->(x) RETURN x") }
    end

    describe "node(3) > rel('r?') > :x; :x" do
      it { Proc.new { node(3) > rel('r?') > :x; :x }.should be_cypher("START v1=node(3) MATCH (v1)-[r?]->(x) RETURN x") }
    end

    describe "node(3) > rel('r?') > 'bla'; :x" do
      it { Proc.new { node(3) > rel('r?') > 'bla'; :x }.should be_cypher("START v1=node(3) MATCH (v1)-[r?]->(bla) RETURN x") }
    end

    describe "r = rel(0); ret r" do
      it { Proc.new { r = rel(0); ret r }.should be_cypher("START v1=relationship(0) RETURN v1") }
    end

  end

  describe "rel?" do
    describe "node(3) > rel? > :x" do
      it { Proc.new { node(3) > rel? > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[?]->(x) RETURN v2") }
    end

    describe "node(3) > rel?('friends') > :x" do
      it { Proc.new { node(3) > rel?('friends') > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[friends?]->(x) RETURN v2") }
    end

    describe "node(3) > rel?(:friends) > :x" do
      it { Proc.new { node(3) > rel?(:friends) > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[?:`friends`]->(x) RETURN v2") }
    end

    describe "node(3) > rel?('r:friends') > :x" do
      it { Proc.new { node(3) > rel?('r:friends') > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[r?:friends]->(x) RETURN v2") }
    end

    describe "node(3) > rel?(:friends, :work, :family) > :x" do
      it { Proc.new { node(3) > rel?(:friends, :work, :family) > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[?:`friends`|`work`|`family`]->(x) RETURN v2") }
    end

    describe "node(3) > rel?(:friends, :work, :family).as(:r) > :x" do
      it { Proc.new { node(3) > rel?(:friends, :work, :family).as(:r) > :x }.should be_cypher("START v1=node(3) MATCH v2 = (v1)-[r?:`friends`|`work`|`family`]->(x) RETURN v2") }
    end
  end

  describe "start" do
    describe "start n = node(3); match n <=> :x; ret :x" do
      it { Proc.new { start n = node(3); match n <=> :x; ret :x }.should be_cypher("START v1=node(3) MATCH (v1)--(x) RETURN x") }
    end
  end

  describe "as" do

    describe "node(1).as(:x)" do
      it { Proc.new { node(1).as(:x) }.should be_cypher(%{START x=node(1) RETURN x}) }
    end

    describe "node(1)[:name].as(:x)" do
      it { Proc.new { node(1)[:name].as(:x) }.should be_cypher(%{START v1=node(1) RETURN v1.name as x}) }
    end

    describe "rel(1).as(:x)" do
      it { Proc.new { rel(1).as(:x) }.should be_cypher(%{START x=relationship(1) RETURN x}) }
    end

    describe "rel(1)[:name].as(:x)" do
      it { Proc.new { rel(1)[:name].as(:x) }.should be_cypher(%{START v1=relationship(1) RETURN v1.name as x}) }
    end

    describe "(node(1) <=> node(2)).as(:x)" do
      it { Proc.new { (node(1) <=> node(2)).as(:x) }.should be_cypher(%{START v1=node(1),v2=node(2) MATCH x = (v1)--(v2) RETURN x}) }
    end

    describe "count(node(1,2,3)).as(:x)" do
      it { Proc.new { count(node(1,2,3)).as(:x) }.should be_cypher(%{START v1=node(1,2,3) RETURN count(v1) as x}) }
    end

    describe "[count(node(1,2,3)).as(:x), count(node(1,2,3)).as(:y)]" do
      it { Proc.new { [count(node(1,2,3)).as(:x), count(node(4,5,6)).as(:y)] }.should be_cypher(%{START v1=node(1,2,3),v2=node(4,5,6) RETURN count(v1) as x,count(v2) as y}) }
    end

    describe "node(1,2,3).count.as(:x)" do
      it { Proc.new { node(1,2,3).count.as(:x) }.should be_cypher(%{START v1=node(1,2,3) RETURN count(v1) as x}) }
    end

    describe "x = node(1); x[:name].as('SomethingTotallyDifferent')" do
      it { Proc.new { x = node(1); x[:name].as('SomethingTotallyDifferent') }.should be_cypher(%{START v1=node(1) RETURN v1.name as SomethingTotallyDifferent}) }
    end

    describe "n = node(3).as(:n); n <=> node.as(:x); :x" do
      it { Proc.new { n = node(3).as(:n); n <=> node.as(:x); :x }.should be_cypher("START n=node(3) MATCH (n)--(x) RETURN x") }
    end
  end


  describe "query" do

    describe %q[query('myindex', "name:A")] do
      it { Proc.new { query('myindex', "name:A") }.should be_cypher(%q[START v1=node:myindex(name:A) RETURN v1]) }
    end


    describe %q[query_rel('myindex', "name:A")] do
      it { Proc.new { query_rel('myindex', "name:A") }.should be_cypher(%q[START v1=relationship:myindex(name:A) RETURN v1]) }
    end

    describe %q[query(FooIndex, "name:A")] do
      it { Proc.new { query(FooIndex, "name:A") }.should be_cypher(%q[START v1=node:fooindex_exact(name:A) RETURN v1]) }
    end

    describe %q[query(FooIndex, "name:A", :fulltext)] do
      it { Proc.new { query(FooIndex, "name:A", :fulltext) }.should be_cypher(%q[START v1=node:fooindex_fulltext(name:A) RETURN v1]) }
    end
  end
  
  describe "lookup" do

    describe %q[lookup_rel('myindex', "name", "A")] do
      it { Proc.new { lookup_rel('myindex', "name", "A") }.should be_cypher(%q[START v1=relationship:myindex(name="A") RETURN v1]) }
    end

    describe %q[lookup(FooIndex, "name", "A")] do
      it { Proc.new { lookup(FooIndex, "name", "A") }.should be_cypher(%q[START v1=node:fooindex_exact(name="A") RETURN v1]) }
    end

    describe %q[lookup(FooIndex, "desc", "A")] do
      it { Proc.new { lookup(FooIndex, "desc", "A") }.should be_cypher(%q[START v1=node:fooindex_fulltext(desc="A") RETURN v1]) }
    end
  end

  describe 'with' do
    describe %{node(2).outgoing(:friends).as(:b).outgoing(:knows).as(:c).with(count(:b).as(:bc)){|_, c| c > 2}.ret(:a,:bc)} do
      it { Proc.new { node(2).outgoing(:friends).as(:b).outgoing(:knows).as(:c).with(count(:b).as(:bc)){|_, c| c > 2}.ret(:c,:bc) }.should \
      be_cypher(%{START v1=node(2) MATCH (v1)-[:`friends`]->(b),(b)-[:`knows`]->(c) WITH c,count(b) as bc WHERE bc > 2 RETURN c,bc}) }
    end
  end


  if RUBY_VERSION > "1.9.0"

    describe "a=node(5);b=node(7);x=node; a > ':friends' > x; !(x > ':friends' > node > ':work' > b); x" do
      it do
        Proc.new do
          a=node(5); b=node(7); x=node; a > ':friends' > x; !(x > ':friends' > node > ':work' > b); x
        end.should be_cypher("START v1=node(5),v2=node(7) MATCH (v1)-[:friends]->(v3) WHERE not((v3)-[:friends]->(v4)-[:work]->(v2)) RETURN v3")
      end
    end

    # the ! operator is only available in Ruby 1.9.x
    describe %# node(3).where{|n| !(n[:desc] =~ ".\d+")}# do
      it { Proc.new { node(3).where{|n| !(n[:desc] =~ ".\d+")}}.should be_cypher(%q[START v1=node(3) WHERE not(v1.desc =~ '.d+') RETURN v1]) }
    end

    describe %{n=node(3).as(:n); where((n[:desc] != "hej")); ret n} do
      it { Proc.new { n=node(3).as(:n); where((n[:desc] != "hej")); ret n }.should be_cypher(%q[START n=node(3) WHERE n.desc <> "hej" RETURN n]) }
    end

    describe %{a=node(1).as(:a);b=node(3,2); r=rel('r?'); a < r < b; !r.exist? ; b} do
      it { Proc.new { a=node(1).as(:a); b=node(3, 2); r=rel('r?'); a < r < b; !r.null; b }.should be_cypher(%{START a=node(1),v1=node(3,2) MATCH (a)<-[r?]-(v1) WHERE not(r is null) RETURN v1}) }
    end

  end

  describe "Examples" do
    describe "using model classes and declared relationship" do
      it "escape relationships name and allows is_a? instead of [:_classname] = klass" do
        class User
          def self._load_wrapper;
          end

          def self.rc
            :"User#rc"
          end
        end

        class Place
          def self._load_wrapper;
          end

          def self.rs
            :"Place#rs"
          end
        end

        class RC
          def self._load_wrapper;
          end
        end

        Proc.new do
          u = node(2)
          p = node(3)
          rc = node(:rc)
          u > rel(User.rc) > rc < rel(Place.rs) < p
          rc < rel(:active) < node
          rc.is_a?(RC)
          rc
        end.should be_cypher(%{START v1=node(2),v2=node(3) MATCH (v1)-[:`User#rc`]->(rc)<-[:`Place#rs`]-(v2),(rc)<-[:`active`]-(v3) WHERE rc._classname = "RC" RETURN rc})
      end
    end

    describe "5.4. Find people based on similar favorites" do
      it do
        Proc.new do
          node(42).where_not { |m| m - ':friend' - :person } > ':favorite' > :stuff < ':favorite' < :person
          ret(node(:person)[:name], count(:stuff).desc)
        end.should be_cypher(%Q[START v1=node(42) MATCH (v1)-[:favorite]->(stuff)<-[:favorite]-(person) WHERE not((v1)-[:friend]-(person)) RETURN person.name,count(stuff) ORDER BY count(stuff) DESC])
      end
    end

  end
end
