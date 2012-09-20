require 'spec_helper'

describe Neo4j::Cypher::ResultWrapper do

  describe 'columns' do
    let(:columns) do
      o = Object.new
      o.stub(:columns).and_return(['a','b'])
      o
    end

    subject do
      Neo4j::Cypher::ResultWrapper.new(columns)
    end

    it 'returns the columns for the result set' do
      subject.columns.should == [:a, :b]
    end
  end

  context 'used without neo4j-wrapper gem' do
    subject do
      Neo4j::Cypher::ResultWrapper.new([{'key1' => 'value1', 'key2' => 'value2'}, {'key1' => 'value3', 'key2' => 'value4'}])
    end

    it 'symbolize the keys' do
      subject.first.keys.should == [:key1, :key2]
      subject.to_a[1].keys.should == [:key1, :key2]
    end

    it 'leaves the values as it is' do
      subject.first.values.should == %w[value1 value2]
      subject.to_a[1].values.should == %w[value3 value4]
    end

  end

  context 'used neo4j-wrapper gem, wrapped nodes and relationships' do
    let(:wrapper) do
      o = Object.new
      o.stub(:wrapper).and_return('something')
    end\

    subject do
      Neo4j::Cypher::ResultWrapper.new([{'key1' => wrapper}])
    end

    it 'symbolize the keys' do
      subject.first.keys.should == [:key1]
    end

    it 'returns the wrapped value instead' do
      subject.first.values.should == [wrapper]
    end

  end

end
