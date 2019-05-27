module Jekyll
  module Kentico
    module Resolvers
      class ContentResolver
        def initialize(global_config)
          @global_config = global_config
        end

        def execute(content_item, config)
          content = custom_resolver && custom_resolver.resolve(content_item)
          content || resolve_internal(content_item, config)
        end

        private

        def custom_resolver
          return @custom_resolver if @custom_resolver

          resolver_name = @global_config.content_resolver
          return unless resolver_name

          @custom_resolver =  Module.const_get(resolver_name).new
        end

        def resolve_internal(content_item, config)
          element_name = config.content || 'content'
          element = content_item.elements[element_name]
          element && content_item.get_string(element_name)
        end
      end
    end
  end
end
