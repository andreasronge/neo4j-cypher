module Neo4j
  module Cypher
    class Predicate
      include Clause
      include Referenceable
      attr_accessor :params

      def initialize(clause_list, params)
        super(clause_list, params[:clause])
        @identifier = :x
        @separator = params[:separator] || ','
        params[:input].referenced! if params[:input].respond_to?(:referenced!)

        clause_list.push

        var = NodeVar.as_var(clause_list, @identifier)

        input = params[:input]

        # TODO refactor please
        if input.kind_of?(Property)
          eval_prop = Property.new(var)
          eval_prop.expr = @identifier
          yield_param = eval_prop.eval_context
          args = ""
        else
          yield_param = var.eval_context
          args = "(#{input.var_name})"
        end

        result = RootClause::EvalContext.new(self).instance_exec(yield_param, &params[:predicate_block])

        result = case params[:clause]
          when :return_item
            block_result = result.clause.to_cypher
            "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} : #{block_result})"
          when :foreach
            block_result = clause_list.to_cypher
            "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} : #{block_result})"
          else
            block_result = clause_list.to_cypher
            "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} WHERE #{block_result})"
        end

        clause_list.pop
        @result = result
      end

      def return_value
        to_cypher
      end


      def separator
        @separator
      end

      def to_cypher
        @result
      end
    end

  end
end
