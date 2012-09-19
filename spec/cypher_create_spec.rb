require 'spec_helper'

describe "Neo4j::Cypher" do

  describe 'DELETE' do
    describe "node(4).del" do
      it do
        Proc.new do
          node(4).del
        end.should be_cypher(%Q[START v1=node(4) DELETE v1])
      end
    end

    describe "node(3) > rel('r').del > node.del" do
      it do
        Proc.new do
          node(3) > rel('r').del > node.del
        end.should be_cypher("START v1=node(3) MATCH (v1)-[r]->(v2) DELETE r,v2")
      end
    end
  end


  describe 'CREATE' do

    describe 'node.new' do

      describe "node.new" do
        it do
          Proc.new do
            node.new
          end.should be_cypher(%Q[CREATE (v1) RETURN v1])
        end
      end

      describe "node.new(:name => 'Andres', :age => 42)" do
        it do
          Proc.new do
          end.should be_cypher("CREATE (v1 {name : 'Andres', age : 42}) RETURN v1", "CREATE (v1 {age : 42, name : 'Andres'}) RETURN v1")
        end
      end

      describe "node.new(:name => 'Andres').as(:a); :a" do
        it do
          Proc.new do
            node.new(:name => 'Andres').as(:a)
            :a
          end.should be_cypher(%Q[CREATE (a {name : 'Andres'}) RETURN a])
        end
      end

      describe "node.new(:_name => 'Andres').as(:a); :a" do
        it do
          Proc.new do
            node.new(:_name => 'Andres').as(:a) # Notice, no "" around the string !
            :a
          end.should be_cypher(%Q[CREATE (a {name : Andres}) RETURN a])
        end
      end

    end

    describe 'create_path' do

      describe "create_path{node(1) > rel(:friends) > node(2)}" do
        it do
          Proc.new do
            create_path { node(1) > rel(:friends) > node(2) }.as(:new_node)
          end.should be_cypher(%Q[START v1=node(1),v2=node(2) CREATE new_node = (v1)-[:`friends`]->(v2) RETURN new_node])
        end
      end

      describe "n2 = node(2); node(1).create_path{|n| n > rel(:friends) > node(2) }" do
        it do
          Proc.new do
            n2 = node(2)
            node(1).create_path { |n| n > rel(:friends) > n2 }
          end.should be_cypher(%Q[START v2=node(2),v1=node(1) WITH v1 CREATE (v1)-[:`friends`]->(v2)])
        end
      end

      describe "node(1).create_path{|n| n > rel(:friends) > node(2) }" do
        it do
          Proc.new do
            node(1).create_path { |n| n > rel(:friends) > node(2) }
          end.should be_cypher(%Q[START v1=node(1),v2=node(2) WITH v1 CREATE (v1)-[:`friends`]->(v2)])
        end
      end

      describe "node(1).create_path{|n| n > rel(:friends) > node(2) }" do
        it do
          Proc.new do
            node(1).create_path { |n| n > "f:friends" > node(2) }; :f
          end.should be_cypher(%Q[START v1=node(1),v2=node(2) WITH v1 CREATE (v1)-[f:friends]->(v2) RETURN f])
        end
      end


      describe "node(1).create_path{|n| n > rel(:friends) > node.new(:name => 'Andreas') }" do
        it do
          Proc.new do
            node(1).create_path { |n| n > rel(:friends) > node.new(:name => 'Andreas') }
          end.should be_cypher(%Q[START v1=node(1) WITH v1 CREATE (v1)-[:`friends`]->(v2 {name : 'Andreas'})])
        end
      end

      describe %Q[a = node(1).as(:a); b = node(2).as(:b); create_path { a > rel(:friends, :_name => "a.name + '<->' + b.name") > b }] do
        it do
          Proc.new do
            a = node(1).as(:a)
            b = node(2).as(:b)
            create_path { a > rel(:friends, :_name => "a.name + '<->' + b.name") > b }
          end.should be_cypher(%Q[START a=node(1),b=node(2) CREATE v1 = (a)-[:`friends` {name : a.name + '<->' + b.name}]->(b) RETURN v1])
        end
      end

      describe "create_path{node.new(:name => 'Andres') > rel(:WORKS_AT) > node < rel(:WORKS_AT) < node.new(:name => 'Micahel')}" do
        it do
          Proc.new do
            create_path { node.new(:name => 'Andres') > rel(:WORKS_AT) > node < rel(:WORKS_AT) < node.new(:name => 'Micahel') }
          end.should be_cypher(%Q[CREATE v4 = (v1 {name : 'Andres'})-[:`WORKS_AT`]->(v2)<-[:`WORKS_AT`]-(v3 {name : 'Micahel'}) RETURN v4])
        end
      end

      describe "node(2) > :knows > node(:other).create_path { |other| other > :like > :new_person }" do
        it do
          Proc.new do
            node(2) > :knows > node(:other).create_path { |other| other > :like > :new_person }
          end.should be_cypher(%Q[START v1=node(2) MATCH (v1)-[:`knows`]->(other) WITH other CREATE (other)-[:`like`]->(new_person)])
        end
      end

      describe "node(2).as(:morpheus) > :knows > node(:other).create_path(:morpheus) { |other, morpheus| other > :like > morpheus }" do
        it do
          Proc.new do
            node(2).as(:morpheus) > :knows > node(:other).create_path(:morpheus) { |other, morpheus| other > :like > morpheus }
          end.should be_cypher("START morpheus=node(2) MATCH (morpheus)-[:`knows`]->(other) WITH other,morpheus CREATE (other)-[:`like`]->(morpheus)")
        end
      end

      describe "node(1).outgoing(:knows).create_path { |other| other > rel(:works) > node(:newfoo) }.outgoing(:loves)" do
        it do
          Proc.new do
            node(1).outgoing(:knows).create_path { |other| other > rel(:works) > node(:newfoo) }.outgoing(:loves)
          end.should be_cypher(%Q[START v2=node(1) MATCH (v2)-[:`knows`]->(v1),(v1)-[:`loves`]->(v3) WITH v1 CREATE (v1)-[:`works`]->(newfoo)])
        end
      end

      describe "node(1) > rel(:knows) > node(:other).create_path{ |other| other > rel(:works) > node } > rel(:loves) > node(2)" do
        it do
          Proc.new do
            node(1) > rel(:KNOWS) > node(:other).create_path { |other| other > rel(:works) > node } > rel(:KNOWS) > node(2).create_path(node(:other)) { |_, t| node > rel(:friends) > t }; :other
          end.should be_cypher(%Q[START v4=node(1),v2=node(2) MATCH (v4)-[:`KNOWS`]->(other)-[:`KNOWS`]->(v2) WITH other CREATE (other)-[:`works`]->(v1),v2,other CREATE (v3)-[:`friends`]->(other) RETURN other])
        end
      end

    end

    describe 'create unique' do
      describe "node(1).create_unique_path { |other| other > rel(' r :KNOWS ').ret > node(3, 4) }" do
        it do
          Proc.new do
            node(1).create_unique_path { |other| other > rel('r:KNOWS').ret > node(3, 4) }
          end.should be_cypher(%Q[START v1=node(1),v2=node(3,4) WITH v1 CREATE UNIQUE (v1)-[r:KNOWS]->(v2) RETURN r])
        end
      end
    end

    describe 'set' do
      describe "node(2).tap{|n| n[:surname] = 'Taylor'}" do
        it do
          Proc.new { node(2).tap { |n| n[:surname] = 'Taylor' } }.should be_cypher('START v1=node(2) SET v1.surname = "Taylor" RETURN v1')
        end
      end

      describe "node(2).ret[:surname] = 'Taylor'" do
        it do
          Proc.new { node(2).ret[:surname] = 'Taylor' }.should be_cypher('START v1=node(2) SET v1.surname = "Taylor" RETURN v1')
        end
      end

      describe "node(2) >> node.ret.tap{|n| n[:surname] = 'Taylor'}" do
        it do
          Proc.new { node(2) >> node.ret.tap { |n| n[:surname] = 'Taylor' } }.should be_cypher('START v2=node(2) MATCH (v2)-->(v1) SET v1.surname = "Taylor" RETURN v1')
        end
      end

    end

    describe 'foreach' do

      describe "(node(2) > rel > node(1)).nodes.foreach {|n| n[:marked] = true}" do
        it do
          Proc.new { (node(2) > rel > node(1)).nodes.foreach {|n| n[:marked] = true}}.should \
            be_cypher "START v2=node(2),v3=node(1) MATCH v1 = (v2)-[?]->(v3) FOREACH (x in nodes(v1) : SET x.marked = true) RETURN v1"
        end

      end

    end

  end
end
