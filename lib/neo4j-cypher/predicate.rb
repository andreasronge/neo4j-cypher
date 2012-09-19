module Neo4j
  module Cypher
    class Predicate
      include Clause
      include Referenceable
      attr_accessor :params

      def initialize(clause_list, params)
        super(clause_list, params[:clause])
        @params = params
        @identifier = :x
        @separator = params[:separator] || ','
        params[:input].referenced! if params[:input].respond_to?(:referenced!)
      end

      def return_value
        to_cypher
      end


      def separator
        @separator
      end

      def identifier(i)
        @identifier = i
        self
      end

      def to_cypher
        input = params[:input]

        sub_clause_list = clause_list.create_sub_list
        var = NodeVar.as_var(sub_clause_list, @identifier)

        if input.kind_of?(Property)
          eval_prop = Property.new(var)
          eval_prop.expr = @identifier
          yield_param = eval_prop.eval_context
          args = ""
        else
          yield_param = var.eval_context
          args = "(#{input.var_name})"
        end
        # RootClause::EvalContext.new # TODO
        result = Object.new.instance_exec(yield_param, &params[:predicate_block]) # TODO check this

        case @params[:clause]
          when :return_item
            block_result = result.clause.to_cypher
            "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} : #{block_result})"
          when :foreach
            block_result = sub_clause_list.to_cypher
            "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} : #{block_result})"
          else
            block_result = sub_clause_list.to_cypher
            "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} #{block_result})"
        end
      end
    end

  end
end
