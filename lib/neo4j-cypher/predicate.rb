module Neo4j
  module Cypher
    class Predicate
      include Clause

      def initialize(clause_list, method_name, input_context, &block)
        super(clause_list, :where, input_context)
        # Input can either be a property array or a node/relationship collection
        input = input_context.clause
        puts "input_context #{input.class}"

        @cypher = method_name

        var = NodeVar.as_var(clause_list, 'x')

        if input.is_a?(Neo4j::Cypher::Property)
          @cypher << "(x in #{input.expr}"
          filter_input = Property.new(var)
          filter_input.expr = 'x'
          input.expr = :x
        else
          filter_input = var
          @cypher << "(x in #{input.return_value}"
        end
        clause_list.push

        x = RootClause::EvalContext.new(self).instance_exec(filter_input.eval_context, &block)
        filter_expr = clause_list.to_cypher
        puts "PREDICATE ___ #{x.class}, returned #{x.class}, filter_expr #{filter_expr}"

        @cypher << " #{filter_expr})"
        # WHERE all(x in nodes(v1) WHERE x.age > 30)
        clause_list.pop

        # TODO
        #input.var_name = old_var_name
      end

      def to_cypher
        @cypher
      end

      #attr_accessor :params, :input
      #
      #def initialize(clause_list, params)
      #  super(clause_list, params[:clause])
      #  @identifier = :x
      #  @separator = params[:separator] || ','
      #  puts "@separator #{@separator}"
      #  # TODO
      #  @separator = ' and '
      #  params[:input].referenced! if params[:input].respond_to?(:referenced!)
      #
      #  clause_list.push
      #
      #  var = NodeVar.as_var(clause_list, @identifier)
      #
      #  input = params[:input]
      #  puts "INPUT #{input.class}"
      #  # TODO refactor please
      #  if input.kind_of?(Property)
      #    eval_prop = Property.new(var)
      #    eval_prop.expr = @identifier
      #    yield_param = eval_prop.eval_context
      #    args = ""
      #  else
      #    yield_param = var.eval_context
      #    args = "(#{input.var_name})"
      #  end
      #
      #  result = RootClause::EvalContext.new(self).instance_exec(yield_param, &params[:predicate_block])
      #
      #  result = case params[:clause]
      #    when :return_item
      #      block_result = result.clause.to_cypher
      #      "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} : #{block_result})"
      #    when :foreach
      #      block_result = clause_list.to_cypher
      #      "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} : #{block_result})"
      #    else
      #      block_result = clause_list.to_cypher
      #      "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} WHERE #{block_result})"
      #  end
      #
      #  clause_list.pop
      #  @result = result
      #end
      #
      #def return_value
      #  to_cypher
      #end
      #
      #
      #def separator
      #  @separator
      #end
      #
      #def to_cypher
      #  @result
      #end
    end

  end
end
