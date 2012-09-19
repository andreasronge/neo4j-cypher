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
        elsif @obj.respond_to?(:clause)
          "#{@obj.clause.to_s}"
        else
          @obj.to_s
        end

      end
    end

    class Operator
      attr_reader :left_operand, :right_operand, :op, :neg, :eval_context
      include Clause
      include Referenceable

      def initialize(clause_list, left_operand, right_operand, op, clause_type = :where, post_fix = nil, &dsl)
        super(clause_list, clause_type, EvalContext)
        right_operand = Regexp.new(right_operand) if op == '=~' && right_operand.is_a?(String)
        @left_operand = Operand.new(left_operand)
        raise "No Leftoperatnd #{left_operand.class}" unless @left_operand.obj
        @right_operand = Operand.new(right_operand) if right_operand
        @op = (@right_operand && @right_operand.regexp?) ? '=~' : op
        @post_fix = post_fix
        @valid = true

        # since we handle it our self in to_cypher method
        clause_list.delete(left_operand) if left_operand.kind_of?(Clause)
        clause_list.delete(right_operand) if right_operand.kind_of?(Clause)

        @neg = nil
        if dsl
          clause_list.delete(self)
          eval_context.instance_exec(left_operand.as_property(self).eval_context, &dsl)
        end
      end

      def separator
        " and "
      end

      def quote(val)
        if val.respond_to?(:var_name) && !val.kind_of?(Match)
          val.var_name
        else
          val.is_a?(String) ? %Q["#{val}"] : val
        end
      end

      def match_value
        @left_operand.obj.match_value || expr
      end

      def expr
        @left_operand.to_s
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

        def -@
          clause.not
          self
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
