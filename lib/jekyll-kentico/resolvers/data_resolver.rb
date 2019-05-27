module Jekyll
  module Kentico
    module Resolvers
      class DataResolver
        def initialize(global_config)
          @global_config = global_config
        end

        def execute(content_item)
          data = custom_resolver && custom_resolver.resolve(content_item)
          data || resolve_internal(content_item)
        end

        private

        def custom_resolver
          return @custom_resolver if @custom_resolver

          resolver_name = @global_config.data_resolver
          return unless resolver_name

          @custom_resolver =  Module.const_get(resolver_name).new
        end

        def resolve_internal(item)
          OpenStruct.new(
            system: item.system,
            elements: item.elements,
          )
        end
      end
    end
  end
end
