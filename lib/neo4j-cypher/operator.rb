module Neo4j
  module Cypher

    class Operand
      attr_reader :obj

      def initialize(obj)
        @obj = obj.respond_to?(:clause) ? obj.clause : obj
      end

      def regexp?
        @obj.kind_of?(Regexp)
      end

      def to_s
        if @obj.is_a?(String)
          %Q["#{@obj}"]
        elsif @obj.is_a?(Operator)
          "(#{@obj.to_s})"
        elsif @obj.is_a?(MatchStart)
          "(#{@obj.to_cypher})"
        elsif @obj.respond_to?(:expr) && @obj.expr
          @obj.expr
        elsif @obj.respond_to?(:source)
          "'#{@obj.source}'"
        elsif @obj.respond_to?(:return_value)
          @obj.return_value.to_s
        else
          @obj.to_s
        end
      end
    end

    class Operator
      attr_reader :left_operand, :right_operand, :op, :neg, :eval_context
      include Clause

      def initialize(clause_list, left_operand, right_operand, op, clause_type = :where, post_fix = nil, &dsl)
        super(clause_list, clause_type, EvalContext)
        if op == '='
          right_operand = right_operand.nil? ? :NULL : right_operand
        end
        right_operand = Regexp.new(right_operand) if op == '=~' && right_operand.is_a?(String)
        @left_operand = Operand.new(left_operand)
        raise "No Leftoperatnd #{left_operand.class}" unless @left_operand.obj
        @right_operand = Operand.new(right_operand) unless right_operand.nil?
        @op = (@right_operand && @right_operand.regexp?) ? '=~' : op
        @post_fix = post_fix
        @valid = true

        # since we handle it ourself in to_cypher method unless it needs to be declared (as a cypher start node/relationship)
        clause_list.delete(left_operand) if remove_operand?(left_operand)
        clause_list.delete(right_operand) if remove_operand?(right_operand)
        @neg = nil
      end

      def remove_operand?(operand)
        clause = operand.respond_to?(:clause) ? operand.clause : operand
        clause.kind_of?(Clause) && clause.clause_type == :where
      end

      def match_value
        @left_operand.obj.match_value || expr
      end


      def var_name
        @left_operand.obj.var_name
      end

      def return_value
        (@right_operand || @unary) ? @left_operand.obj.var_name : to_cypher
      end

      def not
        @neg = "not"
      end

      def unary!
        @unary = true # TODO needed ?
        eval_context
      end

      def to_s
        to_cypher
      end

      def to_cypher
        if @right_operand
          neg ? "#{neg}(#{@left_operand.to_s} #{op} #{@right_operand.to_s})" : "#{@left_operand.to_s} #{op} #{@right_operand.to_s}"
        else
          left_p, right_p = @left_operand.to_s[0..0] == '(' ? ['', ''] : ['(', ')']
          # binary operator
          neg ? "#{neg}#{op}(#{@left_operand.to_s}#{@post_fix})" : "#{op}#{left_p}#{@left_operand.to_s}#{@post_fix}#{right_p}"
        end
      end


      class EvalContext
        include Context
        include MathFunctions

        def &(other)
          Operator.new(clause.clause_list, clause, other.clause, "and").eval_context
        end

        def |(other)
          Operator.new(clause.clause_list, clause, other.clause, "or").eval_context
        end

        def not
          clause.not
          self
        end

        # Only in 1.9
        if RUBY_VERSION > "1.9.0"
          eval %{
             def !
               clause.not
               self
             end
             }
        end

      end

    end

  end
end
