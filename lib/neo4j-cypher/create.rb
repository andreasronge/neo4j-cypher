module Neo4j
  module Cypher

    class Delete
      include Clause

      def initialize(clause_list, var)
        super(clause_list, :delete)
        @var = var
      end

      def to_cypher
        @var.var_name.to_s
      end

    end


    class Create
      include ToPropString
      include Clause
      include Referenceable

      def initialize(clause_list, props)
        super(clause_list, :create, EvalContext)
        @props = props
      end

      def as_create_path?
        !!@as_create_path
      end

      def as_create_path!
        @as_create_path = true # this is because create path has a little different syntax (extra parantheses)
      end

      def match_value
        to_cypher
      end

      def to_cypher
        without_parantheses = if @props
                                "#{var_name} #{to_prop_string(@props)}"
                              else
                                var_name
                              end

        as_create_path? ? without_parantheses : "(#{without_parantheses})"
      end

      class EvalContext
        include Context
        include Alias
        include Variable
        include Matchable
      end

    end

    class CreatePath
      include Clause
      include Referenceable

      attr_reader :arg_list

      def initialize(clause_list, *args, &cypher_dsl)
        super(clause_list, args.empty? ? :create : :with, EvalContext)

        clause_list.push

        @args = create_clause_args_for(args)
        @arg_list = @args.map { |a| a.return_value }.join(',')
        arg_exec = @args.map(&:eval_context)

        RootClause::EvalContext.new(self).instance_exec(*arg_exec, &cypher_dsl)

        @body = "#{clause_list.to_cypher}"
        clause_list.pop
      end

      def unique!
        @unique = true
        self
      end

      def to_cypher
        clause_type == :create ? "#{var_name} = #{@body}" : "#{@arg_list} CREATE #{@unique && "UNIQUE "}#{@body}"
      end

      class EvalContext
        include Context
        include Variable
        include Alias
      end

    end

  end
end
