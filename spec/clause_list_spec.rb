require 'spec_helper'



describe Neo4j::Cypher::ClauseList do


  let(:expression) do
    Class.new do
      include Neo4j::Cypher::Clause
      attr_accessor :name

      def initialize(c, name = self.object_id.to_s)
        @clause_type = c
        @name = "(#{clause_type} #{name})"
      end

      def to_cypher
        @name
      end
    end
  end


  def clause(c)
    expression.new(c)
  end

  let(:start) {clause(:start)}
  let(:where) {clause(:where)}
  let(:match) {clause(:match)}
  let(:ret) {clause(:return)}

  context 'A clause' do
    it 'can be sorted' do
      [where, ret, start, match].sort.should == [start, match, where, ret]
    end
  end

  context 'an empty stack' do
    subject { Neo4j::Cypher::ClauseList.new }

    it 'is empty' do
      subject.to_a.should be_empty
    end

    it 'to_cypher is empty' do
      subject.to_cypher.should == ''
    end

    it 'insert an item last' do
      subject.insert where
      subject.to_a.should == [where]
    end
  end

  context 'it has a start node' do
    subject do
      s = Neo4j::Cypher::ClauseList.new
      s.insert(start)
    end

    it 'insert an where clause last' do
      subject.insert(where)
      subject.to_a.should == [start, where]
    end

    it 'insert another start after the first start clause' do
      start2 = clause(:start)
      subject.insert(start2)
      subject.to_a.should == [start, start2]
    end

    it 'to_cypher contains a START string' do
      start.name = 'hello'
      subject.to_cypher.should == 'START hello'
    end
  end

  context 'it has a where node' do
    subject do
      s = Neo4j::Cypher::ClauseList.new
      s.insert(where)
    end

    it 'insert start before where' do
      subject.insert(start)
      subject.to_a.should == [start, where]
    end

    it 'insert return after where' do
      subject.insert(ret)
      subject.to_a.should == [where, ret]
    end

    it 'insert another where after previous where' do
      where2 = clause(:where)
      subject.insert(where2)
      subject.to_a.should == [where, where2]
    end

    it 'to_cypher contains a WHERE string' do
      where.name = 'hello'
      subject.to_cypher.should == 'WHERE hello'
    end

    context 'when pushed' do
      before do
        subject.push
      end

      it 'is empty' do
        subject.should be_empty
      end

      it 'can add none return and start items' do
        subject.insert(where)
        subject.to_a.should == [where]
      end


      it 'does not add start and return items' do
        subject.insert(start)
        subject.insert(ret)
        subject.to_a.should == []
      end

      context 'when popped' do
        before do
          subject.pop
        end

        it 'contains the old clauses' do
          subject.to_a.should == [where]
        end
      end

      context 'when popped after pushed a start clause' do
        before do
          subject.insert(start)
          subject.pop
        end

        it 'contains the old clauses and the start clause' do
          subject.to_a.should == [start, where]
        end
      end

    end

    context 'adds several other where nodes' do
      subject do
        s = Neo4j::Cypher::ClauseList.new
        s.insert(where)
      end

      it 'returns them in the order it was inserted' do
        w1 = clause(:where)
        w2 = clause(:where)
        subject.insert(w2)
        subject.insert(w1)
        subject.to_a.should == [where, w2, w1]
      end
    end

  end



  context 'it has a match and return clause' do
    subject do
      s = Neo4j::Cypher::ClauseList.new
      s.insert(match)
      s.insert(ret)
    end

    it 'to_cypher contains a WHERE string' do
      match.name = 'hello'
      ret.name = 'world'
      subject.to_cypher.should == 'MATCH hello RETURN world'
    end

    it 'insert start first' do
      subject.insert(start)
      subject.to_a.should == [start, match, ret]
    end

    it 'insert where between match and return' do
      subject.insert(where)
      subject.to_a.should == [match, where, ret]
    end

    it 'insert another match after previous match' do
      match2 = clause(:match)
      subject.insert(match2)
      subject.to_a.should == [match, match2, ret]
    end

  end
end
