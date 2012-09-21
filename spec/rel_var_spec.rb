require 'spec_helper'


describe Neo4j::Cypher::RelVar do
  let(:clause_list) { [] }

  context 'rel(Object.new)' do
    it 'should raise an exception' do
      lambda do
        Neo4j::Cypher::RelVar.new(clause_list, Object.new)
      end.should raise_error
    end
  end
  context "rel('')" do
    before { clause_list.stub(:create_variable).and_return(:v1) }
    subject { Neo4j::Cypher::RelVar.new(clause_list, '') }
    its (:match_value) {should == '?'}
    its (:rel_type) { should == ''}
    its (:var_name) {should == :v1}
  end

  context "rel('foo')" do
    subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo') }
    its (:match_value) {should == 'foo'}
    its (:var_name) {should == :foo}
    its (:rel_type) { should == 'foo'}
  end

  context "rel(':foo')" do
    before { clause_list.stub(:create_variable).and_return(:v1) }

    subject { Neo4j::Cypher::RelVar.new(clause_list, ':foo') }
    its (:match_value) {should == ':foo'}
    its (:var_name) {should == :v1}
    its (:rel_type) { should == 'foo'}
  end

  context "rel(:foo)" do
    before { clause_list.stub(:create_variable).and_return(:v1) }
    subject { Neo4j::Cypher::RelVar.new(clause_list, :foo) }
    its (:match_value) {should == ':`foo`'}
    its (:var_name) {should == :v1}
    its (:rel_type) { should == '`foo`'}
  end

  context "rel('bar:foo')" do
    subject { Neo4j::Cypher::RelVar.new(clause_list, 'bar:foo') }
    its (:match_value) {should == 'bar:foo'}
    its (:var_name) {should == :bar}
  end

  context "rel('bar:foo')" do
    subject { Neo4j::Cypher::RelVar.new(clause_list, 'bar:foo') }
    its (:match_value) {should == 'bar:foo'}
    its (:var_name) {should == :bar}
  end

  context "rel('r?:KNOWS|CODED_BY')" do
    subject { Neo4j::Cypher::RelVar.new(clause_list, 'r?:KNOWS|CODED_BY') }
    its (:match_value) {should == 'r?:KNOWS|CODED_BY'}
    its (:var_name) {should == :r}
    its (:rel_type) { should == 'KNOWS|CODED_BY'}
  end

  context "rel('?')" do
    before { clause_list.stub(:create_variable).and_return(:v1) }
    subject { Neo4j::Cypher::RelVar.new(clause_list, '?') }
    its (:match_value) {should == '?'}
    its (:var_name) {should == :v1}
  end

  describe "optionally" do
    before { subject.optionally! }

    context "rel('foo')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo') }
      its (:match_value) {should == 'foo?'}
      its (:var_name) {should == :foo}
    end

    context "rel(:foo)" do
      before { clause_list.stub(:create_variable).and_return(:v1) }
      subject { Neo4j::Cypher::RelVar.new(clause_list, :foo) }
      its (:match_value) {should == '?:`foo`'}
      its (:var_name) {should == :v1}
    end

    context "rel(':foo')" do
      before { clause_list.stub(:create_variable).and_return(:v1) }

      subject { Neo4j::Cypher::RelVar.new(clause_list, ':foo') }
      its (:match_value) {should == '?:foo'}
      its (:var_name) {should == :v1}
    end

    context "rel('bar:foo')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'bar:foo') }
      its (:match_value) {should == 'bar?:foo'}
      its (:var_name) {should == :bar}
    end

    context "rel('bar?:foo')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'bar?:foo') }
      its (:match_value) {should == 'bar?:foo'}
      its (:var_name) {should == :bar}
    end

    context "rel('?')" do
      before { clause_list.stub(:create_variable).and_return(:v1) }
      subject { Neo4j::Cypher::RelVar.new(clause_list, '?') }
      its (:match_value) {should == '?'}
      its (:var_name) {should == :v1}
    end

    describe 'null' do
      before do
        clause_list.stub(:create_variable).and_return("v2")
        subject.eval_context.null
      end

      context "rel(:friends)" do
        subject { Neo4j::Cypher::RelVar.new(clause_list, :friends) }
        its (:match_value) {should == 'v2?:`friends`'}
        its (:var_name) {should == :v2}
        its (:rel_type) { should == '`friends`'}
      end

      context "rel('friends')" do
        subject { Neo4j::Cypher::RelVar.new(clause_list, 'friends') }
        its (:match_value) {should == 'friends?'}
        its (:var_name) {should == :friends}
        its (:rel_type) { should == 'friends'}
      end

    end
  end

  context 'as(:baaz)' do

    before { subject.eval_context.as(:baaz) }

    context "rel('foo')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo') }
      its (:match_value) {should == 'baaz'}
      its (:var_name) {should == :baaz}
    end

    context "rel(:foo)" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, :foo) }
      its (:match_value) {should == 'baaz:`foo`'}
      its (:var_name) {should == :baaz}
    end

    context "rel('?')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, '?') }
      its (:match_value) {should == 'baaz?'}
      its (:var_name) {should == :baaz}
    end

    context 'optionally!' do
      before do
        subject.optionally!
      end

      context "rel('foo')" do
        subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo') }
        its (:match_value) {should == 'baaz?'}
        its (:var_name) {should == :baaz}
      end

      context "rel(:foo)" do
        subject { Neo4j::Cypher::RelVar.new(clause_list, :foo) }
        its (:match_value) {should == 'baaz?:`foo`'}
        its (:var_name) {should == :baaz}
      end
    end
  end

  context 'when referenced' do
    before do
      clause_list.stub(:create_variable).and_return(:v1)
      subject.referenced!
    end

    context "rel('?')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, '?') }
      its (:match_value) {should == 'v1?'}
      its (:var_name) {should == :v1}
    end

    context "rel('foo')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo') }
      its (:match_value) {should == 'foo'}
      its (:var_name) {should == :foo}
    end

    context "rel(:foo)" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, :foo) }
      its (:match_value) {should == 'v1:`foo`'}
      its (:var_name) {should == :v1}
    end

    context "rel('foo?')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo?') }
      its (:match_value) {should == 'foo?'}
      its (:var_name) {should == :foo}
    end

    context "rel(':friends')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, ':friends') }
      its (:match_value) {should == 'v1:friends'}
      its (:var_name) {should == :v1}
    end

    context "rel('foo?:friends')" do
      subject { Neo4j::Cypher::RelVar.new(clause_list, 'foo?:friends') }
      its (:match_value) {should == 'foo?:friends'}
      its (:var_name) {should == :foo}
    end

  end
end