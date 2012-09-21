require 'spec_helper'

describe Neo4j::Cypher::Result do

  context 'no arguments for the DSL' do
    describe 'when empty DSL' do
      it 'returns an empty string' do
        Neo4j::Cypher::Result.new {}.to_s.should == ''
      end
    end

    describe 'when not empty DSL' do
      it 'translate the DSL to a Cypher String' do
        Neo4j::Cypher::Result.new { node(1) }.to_s.should == 'START v1=node(1) RETURN v1'
      end
    end

    describe '#return_names' do
      context 'node(1)' do
        subject { Neo4j::Cypher::Result.new { node(1) } }
        its(:return_names) { should == [:v1]}
      end

      context 'node(1,2,3)[:name]' do
        subject { Neo4j::Cypher::Result.new { node(1,2,3)[:name] } }
        its(:to_s) { should == 'START v1=node(1,2,3) RETURN v1.name'}
        its(:return_names) { should == [:'v1.name']}
      end

      context 'node(1,2,3)[:name].desc' do
        subject { Neo4j::Cypher::Result.new { node(1,2,3)[:name].desc } }
        its(:to_s) { should == 'START v1=node(1,2,3) RETURN v1.name ORDER BY v1.name DESC'}
        its(:return_names) { should == [:'v1.name']}
      end

      context 'node(1,2,3).count.as(:score)' do
        subject { Neo4j::Cypher::Result.new { node(1,2,3).count.as(:score) } }
        its(:to_s) { should == 'START v1=node(1,2,3) RETURN count(v1) as score'}
        its(:return_names) { should == [:'score']}
      end

      context '[node(1), node(2)]' do
        subject { Neo4j::Cypher::Result.new { [node(1), node(2)] } }
        its(:to_s) { should == 'START v1=node(1),v2=node(2) RETURN v1,v2'}
        its(:return_names) { should == [:v1, :v2]}
      end


    end
  end

  describe 'Illegal Argument' do
    it 'raise an exception' do
      lambda do
        Neo4j::Cypher::Result.new('kalle') { node(1) }
      end.should raise_error
    end
  end

  context 'a Java Node argument (_java_node)' do

    let(:java_node_with_id) do
      o = 'java_node_with_id'
      o.stub!(:_java_node).and_return('hej')
      o.stub!(:neo_id).and_return(123)
      o
    end

    let(:java_node_without_id) do
      o = 'java_node_without_id'
      o.stub!(:_java_node).and_return('hej')
      o
    end

    describe 'when empty DSL' do
      it 'returns an empty string' do
        Neo4j::Cypher::Result.new(java_node_with_id) { |_|}.to_s.should == 'START v1=node(123) RETURN v1'
      end
    end

    describe 'when not empty DSL' do
      it 'translate the DSL to a Cypher String' do
        Neo4j::Cypher::Result.new(java_node_with_id) { |n| n }.to_s.should == 'START v1=node(123) RETURN v1'
      end
    end

    describe 'when node does not have an neo_id' do
      it 'use the string value of the node as the node key' do
        Neo4j::Cypher::Result.new(java_node_without_id) { |n| n }.to_s.should == 'START v1=node(java_node_without_id) RETURN v1'
      end

    end
  end

  context 'an array of Java Node argument (_java_node)' do

    let(:array_of_java_nodes) do
      [1, 2, 3].map do |i|
        o = 'java_node_with_id'
        o.stub!(:_java_node).and_return('hej')
        o.stub!(:neo_id).and_return(i)
        o
      end.to_a
    end

    describe 'when not empty DSL' do
      it 'translate the DSL to a Cypher String' do
        Neo4j::Cypher::Result.new(array_of_java_nodes) { |n| n }.to_s.should == 'START v1=node(1,2,3) RETURN v1'
      end
    end
  end


  context 'a Java Rel argument (_java_rel)' do

    let(:java_rel_with_id) do
      o = Object.new
      o.stub!(:_java_rel).and_return('hej')
      o.stub!(:neo_id).and_return(123)
      o
    end


    describe 'when empty DSL' do
      it 'returns an empty string' do
        Neo4j::Cypher::Result.new(java_rel_with_id) { |_|}.to_s.should == 'START v1=relationship(123) RETURN v1'
      end
    end

    describe 'when not empty DSL' do
      it 'translate the DSL to a Cypher String' do
        Neo4j::Cypher::Result.new(java_rel_with_id) { |n| n }.to_s.should == 'START v1=relationship(123) RETURN v1'
      end
    end
  end


  context 'an array of Java Rels argument (_java_rel)' do

    let(:array_of_java_nodes) do
      [1, 2, 3].map do |i|
        o = Object.new
        o.stub!(:_java_rel).and_return('hej')
        o.stub!(:neo_id).and_return(i)
        o
      end.to_a
    end

    describe 'when not empty DSL' do
      it 'translate the DSL to a Cypher String' do
        Neo4j::Cypher::Result.new(array_of_java_nodes) { |n| n }.to_s.should == 'START v1=relationship(1,2,3) RETURN v1'
      end
    end
  end
end
