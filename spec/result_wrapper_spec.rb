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
      results = subject.to_a
      results[0].keys.should =~ [:key1, :key2]
      results[1].keys.should =~ [:key1, :key2]
    end

    it 'leaves the values as it is' do
      results = subject.to_a
      results[0].values.should =~ %w[value1 value2]
      results[1].values.should =~ %w[value3 value4]
    end

  end

  context 'used neo4j-wrapper gem, wrapped nodes and relationships' do
    let(:wrapper) do
      o = Object.new
      o.stub(:wrapper).and_return('something')
    end

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

  context 'each works like a standard ruby Enumerator' do
    let(:source) { [{a: 10, b: 20}, {a: 100, b: 200}] }

    subject do
      Neo4j::Cypher::ResultWrapper.new(source)
    end

    it 'iterates over the source if given a block' do
      acc = []
      subject.each {|e| acc << e}
      acc.should == [{a: 10, b: 20}, {a: 100, b: 200}]
    end

    it 'return an Enumerator object if not given a block' do
      subject.each.should be_an(Enumerator)
    end

    it 'chains enumerable calls' do
      pairs = subject.each_with_index.map{|row, i| [i, row[:a]] }
      pairs.should == [[0, 10], [1, 100]]
    end
  end

  context 'results are read-once' do
    let(:source) { [{a: 10, b: 20}, {a: 100, b: 200}] }

    subject do
      Neo4j::Cypher::ResultWrapper.new(source)
    end

    it 'raises an exception upon second pass' do
      subject.to_a
      expect do
        subject.to_a
      end.to raise_error(Neo4j::Cypher::ResultWrapper::ResultsAlreadyConsumedException)
    end
  end

end
