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
        super(clause_list, :create, EvalContext)
        delete_none_start_clauses_from(args)
        @arg_list = create_arg_list(args)

        self.clause_type = :with unless args.empty?

        old_match_clauses = clause_list.find_all(:match, :create)
        clause_list.remove_all(:match, :create)
        RootClause::EvalContext.new(self).instance_exec(*args, &cypher_dsl)
        # Create Path means that we convert all the match clauses to create clauses
        new_match_clauses = clause_list.find_all(:match)

        # The create node is done a bit different if it's in a create path clause
        clause_list.find_all(:create).find_all { |c| c.is_a?(Create) }.each { |c| c.as_create_path! }
        clause_list.remove_all(:match, :create)
        old_match_clauses.each { |c| clause_list.insert(c) }

        @body = clause_list.join_group(new_match_clauses)
      end

      def unique!
        @unique = true
        self
      end

      def delete_none_start_clauses_from(args)
        args.each { |a| clause_list.delete(a) if a.respond_to?(:clause) && a.clause.clause_type != :start }
      end

      def create_arg_list(args)
        args.map do |a|
          if a.is_a?(String) || a.is_a?(Symbol)
            a.to_sym
          else
            a.clause.var_name.to_sym
          end
        end
      end

      def to_cypher
        clause_type == :create ? "#{var_name} = #{@body}" : "#{@arg_list.join(',')} CREATE #{@unique && "UNIQUE "}#{@body}"
      end

      class EvalContext
        include Context
        include Variable
        include Alias
      end

    end

  end
end
