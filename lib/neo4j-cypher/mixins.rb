module Neo4j
  module Cypher
    module Referenceable
      def var_name
        @var_name ||= @clause_list.create_variable(self)
      end

      def var_name=(new_name)
        @var_name = new_name.to_sym
      end

      def referenced?
        !!@referenced
      end

      def referenced!
        @referenced = true
      end

      def as_alias(new_name)
        @alias = new_name
        self.var_name = new_name
      end

      def alias_name
        @alias
      end

      def as_alias?
        !!@alias && var_name != return_value
      end

    end

    module ToPropString
      def to_prop_string(props)
        key_values = props.keys.map do |key|
          raw = key.to_s[0, 1] == '_'
          val = props[key].is_a?(String) && !raw ? "'#{props[key]}'" : props[key]
          "#{raw ? key.to_s[1..-1] : key} : #{val}"
        end
        "{#{key_values.join(', ')}}"
      end
    end

  end
end
